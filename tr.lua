
--Unicode text rendering based on harfbuzz and freetype.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local ffi = require'ffi'
local bit = require'bit'
local utf8 = require'utf8'
local hb = require'harfbuzz'
local ft = require'freetype'
local fb = require'fribidi'
local ub = require'libunibreak'
local glue = require'glue'
local tuple = require'tuple'
local lrucache = require'lrucache'
local cairo = require'cairo'
local font_db = require'tr_font_db'
local detect_scripts = require'tr_shape_script'
local reorder_runs = require'tr_shape_reorder'

local push = table.insert
local pop = table.remove
local merge = glue.merge
local object = glue.object
local snap = glue.snap
local assert = glue.assert --assert with string formatting
local count = glue.count
local attr = glue.attr
local trim = glue.trim
local index = glue.index

--glyph rendering ------------------------------------------------------------

local tr = object()

tr.glyph_cache_size = 1024^2 * 20 --20MB net (arbitrary default)
tr.font_size_resolutiob = 1/8
tr.subpixel_resolution = 1/64 --1/64 is max with freetype

function tr:__call()
	local self = object(self, {})

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

function tr:free()
	if not self.freetype then return end

	self.buffers = false

	self.glyphs:free()

	for font in pairs(self.loaded_fonts) do
		self:unload_font(font)
	end
	self.fonts = false

	self.freetype:free()
	self.freetype = false

	self.font_db:free()
	self.font_db = false
end

--font loading ---------------------------------------------------------------

function tr:add_font_file(file, ...)
	local font = {file = file, load = self.load_font_file}
	self.font_db:add_font(font, ...)
end

function tr:add_mem_font(data, data_size, ...)
	local font = {data = data, data_size = data_size, load = self.load_mem_font}
	self.font_db:add_font(font, ...)
end

function tr:load_font_file(font)
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

function tr:internal_font_name(font)
	local ft_face = font.ft_face
	local ft_name = str(ft_face.family_name)
	if not ft_name then return nil end
	local ft_style = str(ft_face.style_name)
	local ft_italic = bit.band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_ITALIC) ~= 0
	local ft_bold = bit.band(ft_face.style_flags, ft.C.FT_STYLE_FLAG_BOLD) ~= 0
	return self.font_db:parse_font(
		self.font_db:normalized_font_name(ft_name)
		.. (ft_style and ' '..ft_style or '')
		.. (ft_italic and ' italic' or '')
		.. (ft_bold and ' bold' or ''))
end

function tr:load_mem_font(font, ...)
	local ft_face = assert(self.freetype:memory_face(font.data, font.data_size))
	font.ft_face = ft_face
	font.hb_font = assert(hb.ft_font(ft_face, nil))
	font.size_info = {} --{size -> info_table}
	font.loaded = true
	self.loaded_fonts[font] = true
end

function tr:load_font(...)
	local font, size = self.font_db:find_font(...)
	assert(font, 'Font not found: %s', (...))
	if not font.loaded then
		font.load(self, font, ...)
	end
	return font, size
end

function tr:unload_font(font)
	if not font.loaded then return end
	font.hb_font:free()
	font.ft_face:free()
	font.hb_font = false
	font.ft_face = false
	font.loaded = false
	self.loaded_fonts[font] = nil
end

--glyph rendering ------------------------------------------------------------

function tr:_select_font_size_index(face, size)
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

function tr:setfont(font, size, ...)
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

tr.ft_load_mode = bit.bor(
	ft.C.FT_LOAD_COLOR,
	ft.C.FT_LOAD_PEDANTIC
)
tr.ft_render_mode = bit.bor(
	ft.C.FT_RENDER_MODE_LIGHT --disable hinting on the x-axis
)

local empty_glyph = {}

function tr:rasterize_glyph(glyph_index, subpixel_x_offset)

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

function tr:load_glyph(glyph_index, x, y)
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

function tr:paint_glyph(glyph, x, y) end --stub

--cairo glyph rendering ------------------------------------------------------

local cairo_tr = object(tr)

cairo_tr.rasterize_glyph_freetype = tr.rasterize_glyph

function cairo_tr:rasterize_glyph(glyph_index, subpixel_x_offset)

	local glyph = self:rasterize_glyph_freetype(glyph_index, subpixel_x_offset)

	glyph.surface = cairo.image_surface{
		data = glyph.bitmap.buffer,
		format = glyph.bitmap.pixel_mode == ft.C.FT_PIXEL_MODE_BGRA
			and 'bgra8' or 'g8',
		w = glyph.bitmap.width,
		h = glyph.bitmap.rows,
		stride = glyph.bitmap.pitch,
	}

	local free_bitmap = glyph.free
	function glyph:free()
		free_bitmap(self)
		self.surface:free()
	end

	return glyph
end

function cairo_tr:paint_glyph(glyph, x, y)
	local cr = self.cr
	if glyph.surface:format() == 'a8' then
		cr:mask(glyph.surface, x, y)
	else
		cr:source(glyph.surface, x, y)
		cr:paint()
		cr:rgb(0, 0, 0) --clear source
	end
end

--unicode text shaping -------------------------------------------------------

function tr:text_run(run)
	self.runs = self.runs or {}
	push(self.runs, run)
end

function tr:runs_base_dir(dir)
	self.runs = self.runs or {}
	assert(dir == 'rtl' or dir == 'ltr' or dir == false)
	self.runs.base_dir = dir
end

function tr:clear_runs()
	self.runs = false
end

function tr:shape_segment(s, len, dir, script, language, features)

	local buf = hb.buffer()

	buf:set_direction(dir == 'rtl' and hb.C.HB_DIRECTION_RTL or hb.C.HB_DIRECTION_LTR)
	buf:set_script(script)
	if language then
		buf:set_language(language)
	end

	buf:add_utf32(s, len)

	local feats, feats_count = nil, 0
	if features then
		feats_count = count(features)
		feats = ffi.new('hb_feature_t[?]', feats_count)
		local i = 0
		for k,v in pairs(features) do
			assert(hb.feature(k, #k, feats[i]) == 1)
			feats[i].value = v
			i = i + 1
		end
	end

	local font = self.font
	buf:shape_full(font.hb_font, feats, feats_count)

	return buf
end

function tr:paint_shaped_segment(buf, x, y)

	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()

	for i=0,glyph_count-1 do

		local glyph_index = glyph_info[i].codepoint

		local px = x + glyph_pos[i].x_offset / 64
		local py = y - glyph_pos[i].y_offset / 64

		local glyph, px, py = self:load_glyph(glyph_index, px, py)
		self:paint_glyph(glyph, px, py)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end

	buf:free()

	return x
end

--iterate a list of values in run-length encoded form.
local function runs(buf, len)
	local i = 0
	return function()
		if i >= len then
			return nil
		end
		local i1, n, val1 = i, 1, buf[i]
		while true do
			i = i + 1
			if i >= len then
				return i1, n, val1
			end
			local val = buf[i]
			if val ~= val1 then
				return i1, n, val1
			end
			n = n + 1
		end
	end
end

function tr:paint_runs(x, y)

	--get text length in codepoints for each run and total.
	local len = 0
	for _,run in ipairs(self.runs) do
		run.length = run.length or #run.text
		run.charset = run.charset or 'utf8'
		if run.charset == 'utf8' then
			run.cp_length = utf8.decode(run.text, run.length, false)
		elseif run.charset == 'utf32' then
			run.cp_length = run.length
		else
			assert(false, 'invalid charset %s', tostring(run.charset))
		end
		len = len + run.cp_length
	end

	if len == 0 then
		return
	end

	--convert and concatenate text into a utf32 buffer.
	local str = ffi.new('uint32_t[?]', len)
	local offset = 0
	for _,run in ipairs(self.runs) do
		local str = str + offset
		if run.charset == 'utf8' then
			utf8.decode(run.text, run.length, str, run.cp_length)
		elseif run.charset == 'utf32' then
			ffi.copy(str, run.text, run.cp_length * 4)
		end
		offset = offset + run.cp_length
	end

	--Run fribidi over the entire text as follows:
	--Request mirroring since it's part of BiDi and harfbuzz doesn't do that.
	--Skip arabic shaping since harfbuzz does that better with font assistance.
	--Skip RTL reordering since it also reverses the _contents_ of the RTL runs
	--which harfbuzz also does (we do UAX#9 line reordering separately below).
	local dir = (self.runs.dir or 'auto'):lower()
	dir = dir == 'rtl'  and fb.C.FRIBIDI_PAR_RTL
		or dir == 'ltr'  and fb.C.FRIBIDI_PAR_LTR
		or dir == 'auto' and fb.C.FRIBIDI_PAR_ON

	local bidi_types    = ffi.new('FriBidiCharType[?]', len)
	local bracket_types = ffi.new('FriBidiBracketType[?]', len)
	local levels        = ffi.new('FriBidiLevel[?]', len)
	local vstr          = ffi.new('FriBidiChar[?]', len)

	fb.bidi_types(str, len, bidi_types)
	fb.bracket_types(str, len, bidi_types, bracket_types)
	local max_level, dir = assert(fb.par_embedding_levels(
		bidi_types, bracket_types, len, dir, levels))
	ffi.copy(vstr, str, len * 4)
	fb.shape_mirroring(levels, len, vstr)

	--reorder the RTL runs based on UAX#9, keeping the _contents_ of each
	--run in logical order (harfbuzz will reverse the glyphs of each RTL run).
	local first_run, last_run
	local tlen = 0
	for i, len, level in runs(levels, len) do
		local run = {level = level, i = i, len = len}
		tlen = tlen + run.len
		if last_run then
			last_run.next = run
		else
			first_run = run
		end
		last_run = run
	end
	assert(tlen == len)

	local run = reorder_runs(first_run)

	local vstr0, levels0 = vstr, levels
	local vstr = ffi.new('uint32_t[?]', len)
	local levels = ffi.new('FriBidiLevel[?]', len)
	local i = 0
	while run do
		ffi.copy(vstr + i, vstr0 + run.i, run.len * 4)
		ffi.copy(levels + i, levels0 + run.i, run.len)
		i = i + run.len
		run = run.next
	end
	assert(i == len)

	--detect the script property for the entire visual text
	local scripts = ffi.new('hb_script_t[?]', len)
	detect_scripts(vstr, len, scripts)

	--run harfbuzz over segments of compatible properties
	local offset, rtl, script, lang, font, size
	for i = 0, len-1 do
		local rtl1 = levels[i] % 2 == 1
		local script1 = scripts[i]
		local font1 = self.font
		local size1 = self.size_info.size
		local lang1 = script1 == hb.C.HB_SCRIPT_ARABIC and 'ar' or 'en'

		--print(i, str[i], vstr[i], levels[i], self.buffers.levels[i], lang1)

		if rtl1 ~= rtl
			or script1 ~= script
			or lang1 ~= lang
			or font1 ~= font
			or size1 ~= size
		then

			if offset then

				local buf = self:shape_segment(
					vstr + offset, i - offset,
					rtl and 'rtl' or 'ltr',
					script,
					lang,
					nil)

				x = self:paint_shaped_segment(buf, x, y)

			end

			rtl = rtl1
			script = script1
			lang = lang1
			font = font1
			size = size1
			offset = i
		end

	end

	if offset < len-1 then

		local buf = self:shape_segment(
			vstr + offset, len - offset,
			rtl and 'rtl' or 'ltr',
			script,
			lang,
			nil)

		self:paint_shaped_segment(buf, x, y)
	end

	self.runs = false
end

--text markup parser ---------------------------------------------------------

--xml tag processor that dispatches the processing of tags inside <signatures> tag to a table of tag handlers.
--the tag handler gets the tag attributes and a conditional iterator to get any subtags.
local function process_tags(gettag)

	local function nextwhile(endtag)
		local start, tag, attrs = gettag()
		if not start then
			if tag == endtag then return end
			return nextwhile(endtag)
		end
		return tag, attrs
	end
	local function getwhile(endtag) --iterate tags until `endtag` ends, returning (tag, attrs) for each tag
		return nextwhile, endtag
	end

	for tagname, attrs in getwhile'signatures' do
		if tag[tagname] then
			tag[tagname](attrs, getwhile)
		end
	end
end

--fast, push-style xml parser.
local function parse_xml(s, write)
	for endtag, tag, attrs, tagends in s:gmatch'<(/?)([%a_][%w_]*)([^/>]*)(/?)>' do
		if endtag == '/' then
			write(false, tag)
		else
			local t = {}
			for name, val in attrs:gmatch'([%a_][%w_]*)=["\']([^"\']*)["\']' do
				if val:find('&quot;', 1, true) then --gsub alone is way slower
					val = val:gsub('&quot;', '"') --the only escaping found in all xml files tested
				end
				t[name] = val
			end
			write(true, tag, t)
			if tagends == '/' then
				write(false, tag)
			end
		end
	end
end

local function text_runs(s)
	--parse_xml(s,
end

--module ---------------------------------------------------------------------

return {
	font_db = font_db,
	tr = tr,
	cairo_tr = cairo_tr,
}

