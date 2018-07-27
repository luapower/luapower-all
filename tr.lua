
--Unicode text shaping and rendering.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local ffi = require'ffi'
local utf8 = require'utf8'
local hb = require'harfbuzz'
local fb = require'fribidi'
local ub = require'libunibreak'
local glue = require'glue'
local box2d = require'box2d'
local font_db = require'tr_font_db'
local detect_scripts = require'tr_shape_script'
local reorder_runs = require'tr_shape_reorder'

local push = table.insert

local object = glue.object
local count = glue.count
local clamp = glue.clamp
local assert = glue.assert --assert with string formatting

local bounding_box = box2d.bounding_box

--iterate a list of values in run-length encoded form.
local function pass(t, i) return t[i] end
local function runs(t, len, start, run_value)
	run_value = run_value or pass
	len = len + start
	local i = start
	return function()
		if i >= len then
			return nil
		end
		local i1, n, val1 = i, 1, run_value(t, i)
		while true do
			i = i + 1
			if i >= len then
				return i1, n, val1
			end
			local val = run_value(t, i)
			if val ~= val1 then
				return i1, n, val1
			end
			n = n + 1
		end
	end
end

local tr = object()

tr.rasterizer_module = 'tr_raster_cairo'
function tr:create_rasterizer()
	return require(self.rasterizer_module)()
end

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
	if self.glyph_runs then
		for _,run in ipairs(self.glyph_runs) do
			run.buf:free()
		end
		self.glyph_runs = false
	end
end

function tr:paint_glyph_run(run, x, y)

	self.rs:setfont(run.font, nil, nil, run.font_size)

	local buf = run.buf
	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()

	for i=0,glyph_count-1 do

		local glyph_index = glyph_info[i].codepoint

		local px = x + glyph_pos[i].x_offset / 64
		local py = y - glyph_pos[i].y_offset / 64

		local glyph, bmpx, bmpy = self.rs:load_glyph(glyph_index, px, py)
		self.rs:paint_glyph(glyph, bmpx, bmpy)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end

	return x, y
end

function tr:measure_glyph_run(run, x, y)

	self.rs:setfont(run.font, nil, nil, run.font_size)

	local buf = run.buf
	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()

	local bx, by, bw, bh = 0, 0, 0, 0

	for i=0,glyph_count-1 do

		local glyph_index = glyph_info[i].codepoint

		local px = x + glyph_pos[i].x_offset / 64
		local py = y - glyph_pos[i].y_offset / 64

		local glyph, bmpx, bmpy = self.rs:load_glyph(glyph_index, px, py)

		bx, by, bw, bh = bounding_box(bx, by, bw, bh,
			bmpx + glyph.x,
			bmpy + glyph.y,
			glyph.w,
			glyph.h)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end

	return x, y, bx, by, bw, bh
end

--[[
--TODO: remove this
local function reorder_line(levels, offset, line_len)
	local first_run, last_run
	local run_len = 0
	for i, len, level in runs(levels + offset, line_len, 0) do
		local run = {level = level, i = i, len = len}
		run_len = run_len + run.len
		if last_run then
			last_run.next = run
		else
			first_run = run
		end
		last_run = run
	end
	assert(run_len == line_len)
	return reorder_runs(first_run)
end
]]

function text_run_at(i, runs, run, ri)
	if i > run.offset + run.len - 1 then
		return runs[ri+1], ri+1
	else
		return run, ri
	end
end

function current_run_value(i, buf, current_value)
	local val = buf[i]
	return val, val ~= current_value
end

function tr:shape_runs()

	--get text length in codepoints.
	local len = 0
	for _,run in ipairs(self.runs) do
		run.size = run.size or #run.text
		run.charset = run.charset or 'utf8'
		if run.charset == 'utf8' then
			run.len = utf8.decode(run.text, run.size, false)
		elseif run.charset == 'utf32' then
			run.len = math.floor(run.size / 4)
		else
			assert(false, 'invalid charset: %s', run.charset)
		end
		len = len + run.len
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
			utf8.decode(run.text, run.size, str, run.len)
		elseif run.charset == 'utf32' then
			ffi.copy(str, run.text, run.size)
		end
		run.offset = offset
		offset = offset + run.len
	end

	--detect the script and lang properties for each char of the entire text.
	local scripts = ffi.new('hb_script_t[?]', len)
	local langs = ffi.new('hb_language_t[?]', len)
	detect_scripts(str, len, scripts)

	--override scripts and langs with user-provided values.
	for _,run in ipairs(self.runs) do
		if run.script then
			local script = hb.script(run.script)
			assert(script, 'invalid script: ', run.script)
			for i = run.offset, run.offset + run.len - 1 do
				scripts[i] = script
			end
		end
		if run.lang then
			local lang = hb.language(run.lang)
			assert(lang, 'invalid lang: ', run.lang)
			for i = run.offset, run.offset + run.len - 1 do
				langs[i] = lang
			end
		end
	end

	--Run fribidi over the entire text as follows:
	--Request mirroring since it's part of BiDi and harfbuzz doesn't do that.
	--Skip arabic shaping since harfbuzz does that better with font assistance.
	--Skip RTL reordering since it also reverses the _contents_ of the RTL runs
	--which harfbuzz also does (we do reordering separately below).
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
	local max_level, dir = assert(fb.par_embedding_levels(bidi_types,
		bracket_types, len, dir, levels))

	ffi.copy(vstr, str, len * 4)
	fb.shape_mirroring(levels, len, vstr)

	--run Unicode line breaking algorithm over each run of text with same language.
	local linebreaks = ffi.new('char[?]', len)
	for i, len, lang in runs(langs, len, 0) do
		local lang = hb.language_tostring(lang)
		ub.linebreaks(vstr + i, len, lang, linebreaks + i)
	end

	--shape all smallest non-breakable-same-properties text segments.
	if self.glyph_runs then
		for _,buf in ipairs(self.glyph_runs) do
			buf:free()
		end
	end
	self.glyph_runs = {}
	local font, font_size, level, script, lang
	local run, ri = self.runs[1], 1
	local offset = 0
	for i = 0, len-1 do
		local run1, ri1 = text_run_at(i, self.runs, run, ri)
		local font1 = run1.font
		local font_size1 = run1.font_size
		local level1 = levels[i]
		local script1 = scripts[i]
		local lang1 = langs[i]
		local linebreak = linebreaks[i]
		if i == 0 then
			font,  font_size,  level,  script,  lang  =
			font1, font_size1, level1, script1, lang1
		end
		if len == 1
			or font1 ~= font
			or font_size1 ~= font_size
			or level1 ~= level
			or script1 ~= script
			or lang1 ~= lang
			or linebreak == 0 --mandatory break
			or linebreak == 1 --break opportunity
		then
			local run_len = i - offset + 1
			local buf = hb.buffer()
			buf:set_direction(level % 2 == 1
				and hb.C.HB_DIRECTION_RTL
				 or hb.C.HB_DIRECTION_LTR)
			buf:set_script(script)
			buf:set_language(lang)
			buf:add_utf32(vstr + offset, run_len)
			local feats, feats_count = nil, 0
			--[[
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
			]]
			local run = {
				text_run = run,
				buf = buf,
				level = level, offset = offset, len = run_len,
				font = font, font_size = font_size,
			}

			self.rs:setfont(font, nil, nil, font_size)
			buf:shape_full(self.rs.font.hb_font, feats, feats_count)
			local _, _, _, _, w, h = self:measure_glyph_run(run, 0, 0)
			run.w = w
			run.h = h

			push(self.glyph_runs, run)

			font,  font_size,  level,  script,  lang  =
			font1, font_size1, level1, script1, lang1
			offset = i + 1
		end
		run, ri = run1, ri1
	end

	self.runs = false
end

function tr:measure_glyph_runs(x, y, i, len, bx, by, bw, bh)
	local i = i or 1
	local j = i + (len or 1/0) - 1
	local n = #self.glyph_runs
	i = clamp(i, 1, n)
	j = clamp(j, 1, n)
	for i = i, j do
		local sx, sy, sw, sh
		x, y, sx, sy, sw, sh = self:measure_glyph_run(self.glyph_runs[i], x, y)
		bx, by, bw, bh = bounding_box(bx, by, bw, bh, sx, sy, sw, sh)
	end
	return x, y, bx, by, bw, bh
end

function tr:paint_runs(x0, y0, w, h, halign, valign)

	--do line wrapping
	local line = {w = 0}
	local lines = {line}
	for _,run in ipairs(self.glyph_runs) do
		if line.w + run.w > w then
			line = {w = 0}
			push(lines, line)
		end
		line.w = line.w + run.w
		push(line, run)
	end

	--reorder RTL runs on each line separately, and concatenate the runs.
	for _,line in ipairs(lines) do
		for i,run in ipairs(line) do
			run.next = line[i+1]
		end
		line[1] = reorder_runs(line[1])
	end

	halign = halign or 'left'
	valign = valign or 'top'

	local line_h = self.rs.line_height
	local x, y = x0, y0
	if valign == 'top' then
		y = y + self.rs.font_ascent
	else
		local baseline_h = ((#lines - 1) * line_h)
		if valign == 'bottom' then
			y = y + h - baseline_h + self.rs.font_descent
		elseif valign == 'center' then
			y = y + (h + baseline_h + self.rs.font_ascent
				+ self.rs.font_descent) / 2
		else
			assert(false, 'invalid valign: %s', valign)
		end
	end

	local line_y = y
	for _,line in ipairs(lines) do
		local x
		if halign == 'left' then
			x = x0
		elseif halign == 'right' then
			x = x0 + w - line.w
		elseif halign == 'center' then
			x = x0 + (w - line.w) / 2
		else
			assert(false, 'invalid halign: %s', halign)
		end
		local y = line_y
		local run = line[1]
		while run do
			x, y = self:paint_glyph_run(run, x, y)
			run = run.next
		end
		line_y = line_y + line_h
	end

end

return tr
