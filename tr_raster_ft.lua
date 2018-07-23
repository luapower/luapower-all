
--glyph caching & rasterization based on freetype's rasterizer.
--Written by Cosmin Apreutesei. Public Domain.

local bit = require'bit'
local ffi = require'ffi'
local glue = require'glue'
local tuple = require'tuple'
local lrucache = require'lrucache'
local ft = require'freetype'
local font_db = require'tr_font_db'

local band, bor = bit.band, bit.bor
local object = glue.object
local merge = glue.merge
local snap = glue.snap
local assert = glue.assert --assert with string formatting

local rs = object()

rs.glyph_cache_size = 1024^2 * 20 --20MB net (arbitrary default)
rs.font_size_resolutiob = 1/8
rs.subpixel_resolution = 1/64 --1/64 is max with freetype

function rs:__call()
	local self = object(self)

	--speed up method access by caching methods
	local super = self.__index
	while super do
		merge(self, super)
		super = super.__index
	end

	self.freetype = ft()
	self.loaded_fonts = {} --{data -> font}
	self.font_db = font_db()

	self.glyphs = lrucache{max_size = self.glyph_cache_size}
	function self.glyphs:value_size(glyph)
		return glyph:size()
	end
	function self.glyphs:free_value(glyph)
		glyph:free()
	end

	return self
end

function rs:free()
	if not self.freetype then return end

	self.buffers = false

	self.glyphs:free()

	for font in pairs(self.loaded_fonts) do
		self:unload_font(font)
	end

	self.freetype:free()
	self.freetype = false

	self.font_db:free()
	self.font_db = false
end

--font loading ---------------------------------------------------------------

function rs:add_font_file(file, ...)
	local font = {
		file = file,
		load = self.load_font_file,
		unload = self.unload_font_file,
	}
	self.font_db:add_font(font, ...)
end

function rs:add_mem_font(data, data_size, ...)
	local font = {
		data = data,
		data_size = data_size,
		load = self.load_mem_font,
		unload = self.unload_mem_font,
	}
	self.font_db:add_font(font, ...)
end

function rs:load_font_file(font)
	local bundle = require'bundle'
	local mmap = bundle.mmap(font.file)
	assert(mmap, 'Font file not found: %s', font.file)
	font.data = mmap.data
	font.data_size = mmap.size
	font.mmap = mmap --pin it
	self:load_mem_font(font)
end

local function str(s)
	return s ~= nil and ffi.string(s) or nil
end

function rs:internal_font_name(font)
	local ft_face = font.ft_face
	local ft_name = str(ft_face.family_name)
	if not ft_name then return nil end
	local ft_style = str(ft_face.style_name)
	local ft_italic = band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_ITALIC) ~= 0
	local ft_bold = band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_BOLD) ~= 0
	return self.font_db:parse_font(
		self.font_db:normalized_font_name(ft_name)
		.. (ft_style and ' '..ft_style or '')
		.. (ft_italic and ' italic' or '')
		.. (ft_bold and ' bold' or ''))
end

function rs:load_mem_font(font, ...)
	local ft_face = assert(self.freetype:memory_face(font.data, font.data_size))
	font.ft_face = ft_face
	font.size_info = {} --{size -> info_table}
end

function rs:load_font(...)
	local font, size = self.font_db:find_font(...)
	assert(font, 'Font not found: %s', (...))
	if not font.loaded then
		font.load(self, font, ...)
		font.loaded = true
		self.loaded_fonts[font] = true
		self:font_loaded(font) --event
	end
	return font, size
end

function rs:unload_mem_font(font)
	font.ft_face:free()
	font.ft_face = false
end

function rs:unload_font_file(font)
	self:unload_mem_font(font)
end

function rs:unload_font(font)
	if font.loaded then
		self:font_unloading(font) --event
		font.unload(self, font)
		font.loaded = false
		self.loaded_fonts[font] = nil
	end
end

function rs:font_loaded(font) end --stub
function rs:font_unloading(font) end --stub

--glyph rendering ------------------------------------------------------------

function rs:_select_font_size_index(face, size)
	local best_diff = 1/0
	local index, best_size
	for i=0,face.num_fixed_sizes-1 do
		local sz = face.available_sizes[i]
		local this_size = sz.width
		local diff = math.abs(size - this_size)
		if diff < best_diff then
			index = i
			best_size = this_size
		end
	end
	return index, best_size or size
end

function rs:setfont(font, size, ...)
	font, size = self:load_font(font, size, ...)
	assert(size, 'Invalid font size: %s', tostring(size))
	local face = font.ft_face
	local size = snap(size, self.font_size_resolutiob)
	local info = font.size_info[size]
	if not info then
		local size_index, fixed_size = self:_select_font_size_index(face, size)
		info = font.size_info[fixed_size]
		if not info then
			info = {
				size = fixed_size,
				size_index = size_index,
			}
			font.size_info[fixed_size] = info
		end
		font.size_info[size] = info
	end
	self.font = font
	self.size = size
	self.size_info = info
end

rs.ft_load_mode = bor(
	ft.C.FT_LOAD_COLOR,
	ft.C.FT_LOAD_PEDANTIC
)
rs.ft_render_mode = bor(
	ft.C.FT_RENDER_MODE_LIGHT --disable hinting on the x-axis
)

local empty_glyph = {}

function rs:rasterize_glyph(glyph_index, subpixel_x_offset)

	local font = self.font
	local face = font.ft_face

	local info = self.size_info
	if font.size_info ~= info then
		if info.size_index then
			face:select_size(info.size_index)
		else
			face:set_pixel_sizes(info.size)
		end
		font.size_info = info
	end
	if not info.line_h then
		info.line_h = face.size.metrics.height / 64
		info.ascender = face.size.metrics.ascender / 64
	end

	face:load_glyph(glyph_index, self.ft_load_mode)

	local glyph = face.glyph

	if glyph.format == ft.C.FT_GLYPH_FORMAT_OUTLINE then
		glyph.outline:translate(subpixel_x_offset * 64, 0)
	end
	local fmt = glyph.format
	if glyph.format ~= ft.C.FT_GLYPH_FORMAT_BITMAP then
		glyph:render(self.ft_render_mode)
	end
	assert(glyph.format == ft.C.FT_GLYPH_FORMAT_BITMAP)

	--BGRA bitmaps must already have aligned pitch because we can't change that
	assert(glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_BGRA
		or glyph.bitmap.pitch % 4 == 0)

	--bitmaps must be top-down because we can't change that
	assert(glyph.bitmap.pitch >= 0) --top-down

	local bitmap = self.freetype:bitmap()

	if glyph.bitmap.pitch % 4 ~= 0
		or (glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_GRAY
			and glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_BGRA)
	then
		self.freetype:convert_bitmap(glyph.bitmap, bitmap, 4)
		assert(bitmap.pixel_mode == ft.C.FT_PIXEL_MODE_GRAY)
		assert(bitmap.pitch % 4 == 0)
	else
		self.freetype:copy_bitmap(glyph.bitmap, bitmap)
	end

	local ft_glyph = glyph
	local glyph = {}

	glyph.bitmap = bitmap
	glyph.bitmap_left = ft_glyph.bitmap_left
	glyph.bitmap_top = ft_glyph.bitmap_top

	local freetype = self.freetype
	function glyph:free()
		freetype:free_bitmap(self.bitmap)
		self.bitmap = false
	end

	function glyph:size()
		return self.bitmap.width * self.bitmap.rows
	end

	return glyph
end

function rs:load_glyph(glyph_index, x, y)
	local pixel_x = math.floor(x)
	local subpixel_x_offset = snap(x - pixel_x, self.subpixel_resolution)
	local glyph_key = tuple(self.size_info, glyph_index, subpixel_x_offset)
	local glyph = self.glyphs:get(glyph_key)
	if not glyph then
		glyph = self:rasterize_glyph(glyph_index, subpixel_x_offset)
		self.glyphs:put(glyph_key, glyph, glyph.size)
	end
	local x = pixel_x + glyph.bitmap_left
	local y = y - glyph.bitmap_top
	return glyph, x, y
end

return rs
