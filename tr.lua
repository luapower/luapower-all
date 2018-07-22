
--Text shaping and rendering based on harfbuzz and freetype.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'textrender_demo'; return end

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

--font selection -------------------------------------------------------------

local font_db = object()

function font_db:__call()
	self = object(self, {})
	self.db = {} --{name -> {slant -> {weight -> font}}}
	self.namecache = {} --{name -> font_name}
	self.searchers = {} --{searcher1, ...}
	return self
end

function font_db:free() end --stub

font_db.weights = {
	thin       = 100,
	ultralight = 200,
	extralight = 200,
	light      = 300,
	semibold   = 600,
	bold       = 700,
	ultrabold  = 800,
	extrabold  = 800,
	heavy      = 800,
}

font_db.slants = {
	italic  = 'italic',
	oblique = 'italic',
}

local function remove_suffixes(s, func)
	local removed
	local function remove_suffix(s)
		if func(s) then
			removed = true
			return ''
		end
	end
	repeat
		removed = false
		s = s:gsub('_([^_]+)$', remove_suffix)
	until not removed
	return s
end

font_db.redundant_suffixes = {regular=1, normal=1}

function font_db:parse_font(name, weight, slant, size)
	local weight_str, slant_str, size_str
	if type(name) == 'string' then
		name = name:gsub(',([^,]*)$', function(s)
			size_str = tonumber(s)
			return ''
		end)
		name = trim(name):lower():gsub('[%-%s_]+', '_')
		name = name:gsub('_([%d%.]+)', function(s)
			weight_str = tonumber(s)
			return weight_str and ''
		end)
		name = remove_suffixes(name, function(s)
			if self.weights[s] then
				weight_str = self.weights[s]
				return true
			elseif self.slants[s] then
				slant_str = self.slants[s]
				return true
			elseif self.redundant_suffixes[s] then
				return true
			end
		end)
	end
	if weight then
		weight = weights[weight] or tonumber(weight)
	else
		weight = weight_str
	end
	if slant then
		slant = slants[slant]
	else
		slant = slant_str
	end
	size = size or size_str
	return name, weight, slant, size
end

function font_db:normalized_font_name(name)
	name = trim(name):lower()
		:gsub('[%-%s_]+', '_') --normalize word separators
		:gsub('_[%d%.]+', '') --remove numbers because they mean `weight'
	name = remove_suffixes(name, function(s)
		if self.redundant_suffixes[s] then return true end
	end)
	return name
end

--NOTE: multiple (name, weight, slant) can be registered with the same font.
--NOTE: `name' doesn't have to be a string, it can be any indexable value.
function font_db:add_font(font, name, weight, slant)
	local name, weight, slant = self:parse_font(name, weight, slant)
	attr(attr(self.db, name or false), slant or 'normal')[weight or 400] = font
end

local function closest_weight(t, wanted_weight)
	local font = t[wanted_weight] --direct lookup
	if font then
		return font
	end
	local best_diff = 1/0
	local best_font
	for weight, font in pairs(t) do
		local diff = math.abs(wanted_weight - weight)
		if diff < best_diff then
			best_diff = diff
			best_font = font
		end
	end
	return best_font
end
function font_db:find_font(name, weight, slant, size)
	if type(name) ~= 'string' then
		return name --font object: pass-through
	end
	local name_only = not (weight or slant or size)
	local font = name_only and self.namecache[name] --try to skip parsing
	if font then
		return font
	end
	local name, weight, slant, size = self:parse_font(name, weight, slant, size)
	local t = self.db[name or false]
	local t = t and t[slant or 'normal']
	local font = t and closest_weight(t, weight or 400)
	if font and name_only then
		self.namecache[name] = font
	end
	return font, size
end

function font_db:dump()
	local weight_names = glue.index(self.weights)
	weight_names[400] = 'regular'
	for name,t in glue.sortedpairs(self.db) do
		local dt = {}
		for slant,t in glue.sortedpairs(t) do
			for weight, font in glue.sortedpairs(t) do
				local weight_name = weight_names[weight]
				dt[#dt+1] = weight_name..' ('..weight..')'..' '..(slant or '')
			end
		end
		print(string.format('%-30s %s', tostring(name), table.concat(dt, ', ')))
	end
end

--glyph tr -------------------------------------------------------------

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

--cairo glyph tr -------------------------------------------------------

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

--unicode script detection ---------------------------------------------------

local non_scripts = index{
	hb.C.HB_SCRIPT_INVALID,
	hb.C.HB_SCRIPT_COMMON,
	hb.C.HB_SCRIPT_INHERITED,
	hb.C.HB_SCRIPT_UNKNOWN, --unassigned, private use, non-characters
}
local function real_script(script)
	return not non_scripts[script]
end

local pair_indices = index{
  0x0028, 0x0029, -- ascii paired punctuation
  0x003c, 0x003e,
  0x005b, 0x005d,
  0x007b, 0x007d,
  0x00ab, 0x00bb, -- guillemets
  0x2018, 0x2019, -- general punctuation
  0x201c, 0x201d,
  0x2039, 0x203a,
  0x3008, 0x3009, -- chinese paired punctuation
  0x300a, 0x300b,
  0x300c, 0x300d,
  0x300e, 0x300f,
  0x3010, 0x3011,
  0x3014, 0x3015,
  0x3016, 0x3017,
  0x3018, 0x3019,
  0x301a, 0x301b
}
local function pair(c)
	local i = pair_indices[c]
	if not i then return nil end
	local open = i % 2 == 1
	return i - (open and 0 or 1), open
end

local function is_combining_mark(c)
	local cat = hb.unicode_general_category(c)
	return
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK or
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK or
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK
end

--fills a buffer with the Script property for each char in a utf32 buffer.
--uses UAX#24 Section 5.1 and 5.2 to resolve chars with implicit scripts.
local function detect_scripts(s, len, outbuf)
	local script = hb.C.HB_SCRIPT_COMMON
	local first_script
	local base_char_i = 0
	local stack = {}
	for i = 0, len-1 do
		local c = s[i]
		if is_combining_mark(c) then --Section 5.2
			if not real_script(script) then --base char has no script
				local sc = hb.unicode_script(c)
				if real_script(sc) then --this combining mark has a script
					script = sc --subsequent marks must use this script too
					--resolve all previous marks and the base char
					for i = base_char_i, i-1 do
						outbuf[i] = script
					end
				end
			end
		else
			local sc = hb.unicode_script(c)
			if sc == hb.C.HB_SCRIPT_COMMON then --Section 5.1
				local pair, open = pair(c)
				if pair then
					if open then --remember the enclosing script
						push(stack, script)
						push(stack, pair)
					else --restore the enclosing script
						for i = #stack, 1, -2 do
							if stack[i] == pair then --pair opened here
								for i = #stack, i, -2 do
									pop(stack)
									script = pop(stack)
								end
								break
							end
						end
					end
				end
			elseif real_script(sc) then
				if script == hb.C.HB_SCRIPT_COMMON then
					--found a script for the first time: resolve all previous
					--unresolved chars.
					for i = 0, i-1 do
						if outbuf[i] == hb.C.HB_SCRIPT_COMMON then
							outbuf[i] = sc
						end
					end
					--resolve unresolved scripts of open pairs too.
					for i = 2, #stack, 2 do
						if stack[i] == hb.C.HB_SCRIPT_COMMON then
							stack[i] = sc
						end
					end
				end
				script = sc
			end
			base_char_i = base_char_i + 1
		end
		outbuf[i] = script
	end
end

--unicode text shaping -------------------------------------------------------

function tr:text_run(run)
	self.runs = self.runs or {}
	push(self.runs, run)
end

function tr:clear_runs()
	self.runs = false
end

function tr:process_runs()

	--get entire text length in codepoints
	local len = 0
	for _,run in ipairs(self.runs) do
		run.length = run.length or #run.text
		run.charset = run.charset or 'utf8'
		if run.charset == 'utf8' then
			run.cp_length = utf8.decode(run.text, run.length)
			len = len + run.cp_length
		elseif run.charset == 'utf32' then
			run.cp_length = run.cp_length
			len = len + run.cp_length
		else
			assert(false, 'invalid charset %s', tostring(run.charset))
		end
	end

	--convert text to utf32
	local b = fb.buffers(len, nil, 'utf-8')
	local offset = 0
	for _,run in ipairs(self.runs) do
		local out = b.str + offset
		if run.charset == 'utf8' then
			utf8.decode(run.text, run.length, out, run.cp_length)
		elseif run.charset == 'utf32' then
			ffi.copy(out, run.text, run.cp_length * 4)
		end
		offset = offset + run.cp_length
	end


	--[[
	local run = self.run
	run.font, run.font_size = self.font_db:find_font(...)
	assert(run.font, 'Font not found: %s', (...))

	charset = charset or 'utf-8'
	len = len or (charset == 'utf-8' and #s)
	local run = self.run
	run.text = ffi.new('uint32_t[?]', len)
	run.length = len
	assert(fb.charset_to_unicode(charset, s, len, run.text, run.length))

	for i,run in ipairs(self.runs) do
		if run.font == font
			and run.font_size = size
			and run.script == script
			and run.language == language
		then
			local scripts = ffi.new('hb_script_t[?]', run.length)
			detect_scripts(run.text, run.length, scripts)
			local script
			for i = 0, run.length-1 do
				local sc = scripts[i]
				if sc ~= script then

				end
			end
		end
	end
	self.runs = runs
	self.run = false
	]]
end

function tr:itemize_text(s, len)

	len = len or #s
	local b = fb.buffers(len, nil, 'utf-8')

	local s, len = fb.charset_to_unicode('utf-8', s, len, b.str, b.len)
	assert(s, len)

	local function line_offsets(s, len, b)
		local line_brks = ub.linebreaks_utf32(b.str, len)
		local i
		local function next_line_break()
			if not i then
				i = 0
			else
				i = i + 1
				while i < len and line_brks[i] ~= 0 do
					i = i + 1
				end
			end
			if i == len then
				return
			end
			return i
		end
		return next_line_break
	end

	local s, len = fb.log2vis(s, len, 'ucs-4', b,
		fb.C.FRIBIDI_FLAGS_DEFAULT, --no arabic shaping
		fb.C.FRIBIDI_PAR_ON,
		line_offsets
	)
	assert(s, len)

	local buf = hb.buffer()

	local last_rtl = b.par_base_dir == fb.C.FRIBIDI_PAR_RTL
	for i=0,len-1 do
		local rtl = b.levels[i] % 2 == 1
		if last_rtl ~= rtl then

			buf:clear()
			buf:set_direction(rtl and hb.C.HB_DIRECTION_RTL or hb.C.HB_DIRECTION_LTR)

			last_rtl = rtl
		end
	end

	--[[
		local bidi_type_name = fb.bidi_type_name(b.bidi_types[i])
		local joining_type_name = fb.joining_type_name(b.ar_props[i])
		print(
			s:sub(i+1, i+1),
			bidi_type_name,
			b.levels[i],
			joining_type_name,
			b.visual_str[i],
			b.v_to_l[i],
			b.l_to_v[i])
	end
	]]
end

function tr:shape_text(s, len, direction, script, language, features)

	local buf = self.hb_buf
	if not buf then
		buf = hb.buffer()
		self.hb_buf = buf
	end

	buf:set_direction(direction or hb.C.HB_DIRECTION_LTR)
	buf:set_script(script or hb.C.HB_SCRIPT_UNKNOWN)
	if language then
		buf:set_language(language)
	end

	buf:add_utf8(s, len)

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
	buf:shape(font.hb_font, feats, feats_count)
end

function tr:clear()
	self.hb_buf:clear()
end

function tr:paint_text(x, y)
	local buf = self.hb_buf

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

