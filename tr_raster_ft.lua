
--glyph caching & rasterization based on freetype's rasterizer.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
local glue = require'glue'
local tuple = require'tuple'
local lrucache = require'lrucache'
local ft = require'freetype'
local font_db = require'tr_font_db'

local band, bor = bit.band, bit.bor
local object = glue.object
local update = glue.update
local assert = glue.assert --assert with string formatting
local snap = glue.snap
local pass = glue.pass

local rs = object()

rs.glyph_cache_size = 1024^2 * 20 --20MB net (arbitrary default)
rs.font_size_resolution = 1/8 --in pixels
rs.subpixel_x_resolution = 1/64 --1/64 pixels is max with freetype
rs.subpixel_y_resolution = 1 --no subpixel positioning with vertical hinting
rs.line_spacing = 1.2

function rs:__call()
	local self = update(object(self), self)

	self.freetype = ft()
	self.loaded_fonts = {} --{data -> font}
	self.font_db = font_db()

	self.glyphs = lrucache{max_size = self.glyph_cache_size}
	function self.glyphs:value_size(glyph)
		return glyph.size
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
	return font
end

function rs:add_mem_font(data, data_size, ...)
	local font = {
		data = data,
		data_size = data_size,
		load = self.load_mem_font,
		unload = self.unload_mem_font,
	}
	self.font_db:add_font(font, ...)
	return font
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

function rs:setfont(font, ...)
	local font, size = self:load_font(font, ...)
	assert(size, 'Invalid font size: %s', tostring(size))
	local size = snap(size, self.font_size_resolution)
	if self.font ~= font or self._requested_size ~= size then
		local face = font.ft_face
		local size_index, fixed_size = self:_select_font_size_index(face, size)
		self.font = font
		self.font_size = fixed_size
		self._requested_size = size
		if size_index then
			face:select_size(size_index)
		else
			face:set_pixel_sizes(fixed_size)
		end
		local m = face.size.metrics
		self.font_height = m.height / 64
		self.font_ascent = m.ascender / 64
		self.font_descent = m.descender / 64
		self.line_height = self.font_height * self.line_spacing
	end
end

rs.ft_load_mode = bor(
	ft.C.FT_LOAD_COLOR,
	ft.C.FT_LOAD_PEDANTIC
)
rs.ft_render_mode = bor(
	ft.C.FT_RENDER_MODE_LIGHT --disable hinting on the x-axis
)

local empty_glyph = {bitmap_left = 0, bitmap_top = 0, size = 0, free = pass}

function rs:rasterize_glyph(glyph_index, x_offset, y_offset)

	self.font.ft_face:load_glyph(glyph_index, self.ft_load_mode)
	local ft_glyph = self.font.ft_face.glyph

	local w = ft_glyph.metrics.width
	local h = ft_glyph.metrics.height
	if w == 0 or h == 0 then
		return empty_glyph
	end

	if ft_glyph.format == ft.C.FT_GLYPH_FORMAT_OUTLINE then
		ft_glyph.outline:translate(x_offset * 64, y_offset * 64)
	end
	local fmt = ft_glyph.format
	if ft_glyph.format ~= ft.C.FT_GLYPH_FORMAT_BITMAP then
		ft_glyph:render(self.ft_render_mode)
	end
	assert(ft_glyph.format == ft.C.FT_GLYPH_FORMAT_BITMAP)

	--BGRA bitmaps must already have aligned pitch because we can't change that
	assert(ft_glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_BGRA
		or ft_glyph.bitmap.pitch % 4 == 0)

	--bitmaps must be top-down because we can't change that
	assert(ft_glyph.bitmap.pitch >= 0) --top-down

	local bitmap = self.freetype:bitmap()

	if ft_glyph.bitmap.pitch % 4 ~= 0
		or (ft_glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_GRAY
			and ft_glyph.bitmap.pixel_mode ~= ft.C.FT_PIXEL_MODE_BGRA)
	then
		self.freetype:convert_bitmap(ft_glyph.bitmap, bitmap, 4)
		assert(bitmap.pixel_mode == ft.C.FT_PIXEL_MODE_GRAY)
		assert(bitmap.pitch % 4 == 0)
	else
		self.freetype:copy_bitmap(ft_glyph.bitmap, bitmap)
	end

	local glyph = {}

	glyph.bitmap = bitmap
	glyph.bitmap_left = ft_glyph.bitmap_left
	glyph.bitmap_top = ft_glyph.bitmap_top

	local freetype = self.freetype
	function glyph:free()
		freetype:free_bitmap(self.bitmap)
		self.bitmap = false
	end

	glyph.size = bitmap.rows * bitmap.pitch + 200

	return glyph
end

function rs:glyph(glyph_index, x, y)
	if glyph_index == 0 then --freetype code for "missing glyph"
		return empty_glyph, x, y
	end
	local pixel_x = math.floor(x)
	local pixel_y = math.floor(y)
	local x_offset = snap(x - pixel_x, self.subpixel_x_resolution)
	local y_offset = snap(y - pixel_y, self.subpixel_y_resolution)
	local glyph_key = tuple(self.font, self.font_size, glyph_index, x_offset, y_offset)
	local glyph = self.glyphs:get(glyph_key)
	if not glyph then
		glyph = self:rasterize_glyph(glyph_index, x_offset, y_offset)
		self.glyphs:put(glyph_key, glyph)
	end
	local x = pixel_x + glyph.bitmap_left
	local y = pixel_y - glyph.bitmap_top
	return glyph, x, y
end

return rs
