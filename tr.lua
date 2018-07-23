
--Unicode text shaping and rendering based on harfbuzz and freetype.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local ffi = require'ffi'
local utf8 = require'utf8'
local hb = require'harfbuzz'
local fb = require'fribidi'
local ub = require'libunibreak'
local glue = require'glue'
local font_db = require'tr_font_db'
local detect_scripts = require'tr_shape_script'
local reorder_runs = require'tr_shape_reorder'

local object = glue.object
local push = table.insert
local assert = glue.assert --assert with string formatting
local count = glue.count

local tr = object()

function tr:__call()
	self = object(self)
	self.rs = self:create_rasterizer()
	function self.rs:font_loaded(font)
		font.hb_font = assert(hb.ft_font(font.ft_face, nil))
	end
	function self.rs:font_unloading(font)
		font.hb_font:free()
		font.hb_font = false
	end
	return self
end

function tr:free()
	self.rs:free()
	self.rs = false
end

--rasterizer selection

tr.rasterizer_module = 'tr_raster_cairo'
function tr:create_rasterizer()
	return require(self.rasterizer_module)()
end

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

	local font = self.rs.font
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

		local glyph, px, py = self.rs:load_glyph(glyph_index, px, py)
		self.rs:paint_glyph(glyph, px, py)

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
		local font1 = self.rs.font
		local size1 = self.rs.size_info.size
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

return tr
