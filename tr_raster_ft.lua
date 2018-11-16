
--glyph caching & rasterization based on freetype's rasterizer.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
local glue = require'glue'
local lrucache = require'lrucache'
local ft = require'freetype'
local font_db = require'tr_font_db'
local zone = require'jit.zone' --glue.noop

local band, bor = bit.band, bit.bor
local update = glue.update
local assert = glue.assert --assert with string formatting
local snap = glue.snap
local pass = glue.pass
local round = glue.round
local tuples = glue.tuples

--glyph rasterizer -----------------------------------------------------------

local rs = {}
setmetatable(rs, rs)

rs.glyph_cache_size = 1024^2 * 10 --10MB net (arbitrary default)
rs.font_size_resolution = 1/8 --in pixels
rs.subpixel_x_resolution = 1/16 --1/64 pixels is max with freetype
rs.subpixel_y_resolution = 1/16 --no subpixel positioning with vertical hinting

function rs:__call()
	local self = update({}, self)

	self.freetype = ft()

	self.font_db = font_db()

	self.glyphs = lrucache{max_size = self.glyph_cache_size}
	function self.glyphs:value_size(glyph)
		return glyph.mem_size
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
	self.glyphs = false

	self.freetype:free()
	self.freetype = false

	self.font_db:free()
	self.font_db = false
end

function rs:warn(...)
	io.stderr:write(string.format(...))
	io.stderr:write'\n'
end

--font loading ---------------------------------------------------------------

local font = {}
setmetatable(font, font)

function font:__call(fields)
	local self = update({}, self, fields)
	self.refcount = 0
	return self
end

function font:ref()
	if self.invalid then return end
	if self.refcount == 0 then
		if not self:load() then
			self.invalid = true
			return
		end
	end
	self.refcount = self.refcount + 1
	return true
end

function font:unref()
	assert(self.refcount > 0)
	self.refcount = self.refcount - 1
	if self.refcount == 0 then
		self:unload()
	end
end

--get font's internal name

local function str(s)
	return s ~= nil and ffi.string(s) or nil
end
function font:internal_name(font)
	local ft_face = self.ft_face
	local ft_name = str(ft_face.family_name)
	if not ft_name then return nil end
	local ft_style = str(ft_face.style_name)
	local ft_italic = band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_ITALIC) ~= 0
	local ft_bold = band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_BOLD) ~= 0
	--TODO: we shouldn't call methods on the class
	return font_db:normalized_font_name(ft_name)
		.. (ft_style and ' '..ft_style or '')
		.. (ft_italic and ' italic' or '')
		.. (ft_bold and ' bold' or '')
end

--set font size

local function select_font_size_index(face, size)
	local best_diff = 1/0
	local index, best_size
	for i=0,face.num_fixed_sizes-1 do
		local sz = face.available_sizes[i]
		local this_size = sz.height
		local diff = math.abs(size - this_size)
		if diff < best_diff then
			index = i
			best_size = this_size
		end
	end
	return index, best_size or size
end

function font:size_changed() end --stub

function font:setsize(size)
	if self.wanted_size == size then return end
	self.wanted_size = size
	local size_index, fixed_size = select_font_size_index(self.ft_face, size)
	local scale
	if size_index then
		scale = size / fixed_size
		self.ft_face:select_size(size_index)
	else
		scale = 1
		self.ft_face:set_pixel_sizes(fixed_size)
	end
	self.scale = scale
	local ft_scale = scale / 64
	local m = self.ft_face.size.metrics
	self.ascent = m.ascender * ft_scale
	self.descent = m.descender * ft_scale
	self:size_changed()
end

--memory fonts

local mem_font = update({}, font)
setmetatable(mem_font, mem_font)

function mem_font:load()
	assert(not self.ft_face)
	self.ft_face = self.freetype:memory_face(self.data, self.data_size)
	if not self.ft_face then
		self.rs:warn('Font loading failed: "%s"', self.file or '[cdata]')
		return
	end
	self.tuple = tuples()
	self.tuple2 = tuples(2) --faster impl. with 2 fixed args
	return true
end

function mem_font:unload()
	self.tuple = false
	self.tuple2 = false
	self.ft_face:free()
	self.ft_face = false
end

--font files

local font_file = update({}, font)
setmetatable(font_file, font_file)

function font_file:load()
	assert(not self.mmap)
	local bundle = require'bundle'
	local mmap = bundle.mmap(self.file)
	if not mmap then
		self.rs:warn('Font file not found: "%s"', self.file)
		return
	end
	self.data = mmap.data
	self.data_size = mmap.size
	self.mmap = mmap --pin it
	return mem_font.load(self)
end

function font_file:unload()
	mem_font.unload(self)
	self.mmap:close()
	self.mmap = false
end

--user API for adding fonts

function rs:add_font_file(file, ...)
	local font = font_file{rs = self, file = file,
		freetype = self.freetype, ft_load_flags = self.ft_load_flags}
	self.font_db:add_font(font, ...)
	return font
end

function rs:add_mem_font(data, size, ...)
	local font = mem_font{rs = self, data = data, data_size = size,
		freetype = self.freetype, ft_load_flags = self.ft_load_flags}
	self.font_db:add_font(font, ...)
	return font
end

--glyph loading --------------------------------------------------------------

rs.ft_load_flags = bor(
	ft.C.FT_LOAD_COLOR,
	ft.C.FT_LOAD_PEDANTIC
	--ft.C.FT_LOAD_NO_HINTING,
	--ft.C.FT_LOAD_NO_AUTOHINT
	--ft.C.FT_LOAD_FORCE_AUTOHINT
)

function rs:load_glyph(font, font_size, glyph_index)
	font:setsize(font_size)
	font.ft_face:load_glyph(glyph_index, self.ft_load_flags)
	local ft_glyph = font.ft_face.glyph
	local w = ft_glyph.metrics.width
	local h = ft_glyph.metrics.height
	if w == 0 or h == 0 then
		return nil
	end
	return ft_glyph
end

--glyph rendering ------------------------------------------------------------

rs.ft_render_flags = bor(
	ft.C.FT_RENDER_MODE_LIGHT --disable hinting on the x-axis
)

local empty_glyph = {
	bitmap_left = 0, bitmap_top = 0,
	mem_size = 0, free = pass, --for the lru cache
}

function rs:rasterize_glyph(font, font_size, glyph_index, offset_x, offset_y)

	local ft_glyph = self:load_glyph(font, font_size, glyph_index)
	if not ft_glyph then
		return empty_glyph
	end

	if ft_glyph.format == ft.C.FT_GLYPH_FORMAT_OUTLINE then
		ft_glyph.outline:translate(offset_x * 64, -offset_y * 64)
	end
	local fmt = ft_glyph.format
	if ft_glyph.format ~= ft.C.FT_GLYPH_FORMAT_BITMAP then
		ft_glyph:render(self.ft_render_flags)
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

	local format =
		bitmap.pixel_mode == ft.C.FT_PIXEL_MODE_BGRA and 'bgra8' or 'g8'

	local glyph = {}

	glyph.bitmap = bitmap
	glyph.bitmap_left = round(ft_glyph.bitmap_left * font.scale)
	glyph.bitmap_top = round(ft_glyph.bitmap_top * font.scale)
	glyph.bitmap_format = format

	font:ref()
	local freetype = self.freetype
	function glyph:free()
		freetype:free_bitmap(self.bitmap)
		self.bitmap = false
		font:unref()
	end

	glyph.mem_size = bitmap.rows * bitmap.pitch + 200 --cache load

	return glyph
end

function rs:glyph(font, font_size, glyph_index, x, y)
	if glyph_index == 0 then --freetype code for "missing glyph"
		return empty_glyph, x, y
	end
	zone'glyph'
	font_size = snap(font_size, self.font_size_resolution)
	local pixel_x = math.floor(x)
	local pixel_y = math.floor(y)
	local offset_x = snap(x - pixel_x, self.subpixel_x_resolution)
	local offset_y = snap(y - pixel_y, self.subpixel_y_resolution)
	local glyph_key = font.tuple(font_size, glyph_index, offset_x, offset_y)
	local glyph = self.glyphs:get(glyph_key)
	if not glyph then
		glyph = self:rasterize_glyph(
			font, font_size, glyph_index,
			offset_x, offset_y
		)
		self.glyphs:put(glyph_key, glyph)
	end
	local x = pixel_x + glyph.bitmap_left
	local y = pixel_y - glyph.bitmap_top
	zone()
	return glyph, x, y
end

--glyph measuring ------------------------------------------------------------

local empty_glyph_metrics = {
	w = 0, h = 0, hlsb = 0, htsb = 0, vlsb = 0, vtsb = 0, --null metrics
	mem_size = 0, free = pass, --for the lru cache
}

function rs:load_glyph_metrics(font, font_size, glyph_index)
	local ft_glyph = self:load_glyph(font, font_size, glyph_index)
	if not ft_glyph then
		return empty_glyph_metrics
	end
	local m = {}
	local ft_scale = font.scale / 64
	m.w = ft_glyph.metrics.width * ft_scale
	m.h = ft_glyph.metrics.height * ft_scale
	m.hlsb = ft_glyph.metrics.horiBearingX * ft_scale
	m.htsb = ft_glyph.metrics.horiBearingY * ft_scale
	m.vlsb = ft_glyph.metrics.vertBearingX * ft_scale
	m.vtsb = ft_glyph.metrics.vertBearingY * ft_scale
	m.mem_size = 4 * 8 + 40 --cache load
	font:ref()
	function m:free()
		font:unref()
	end
	return m
end

function rs:glyph_metrics(font, font_size, glyph_index)
	if glyph_index == 0 then --freetype code for "missing glyph"
		return empty_glyph_metrics
	end
	font_size = snap(font_size, self.font_size_resolution)
	local glyph_key = font.tuple2(font_size, glyph_index)
	local glyph = self.glyphs:get(glyph_key)
	if not glyph then
		glyph = self:load_glyph_metrics(font, font_size, glyph_index)
		self.glyphs:put(glyph_key, glyph)
	end
	return glyph
end

return rs
