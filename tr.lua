
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
local update = glue.update
local assert = glue.assert --assert with string formatting
local count = glue.count
local clamp = glue.clamp

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
	self = update(object(self), self)

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

		local glyph, bmpx, bmpy = self.rs:glyph(glyph_index, px, py)
		self.rs:paint_glyph(glyph, bmpx, bmpy)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end

	return x, y
end

local hb_extents = ffi.new'hb_glyph_extents_t'

local function hb_buf_extents(hb_buf, hb_font)

	local glyph_count = hb_buf:get_length()
	local glyph_info  = hb_buf:get_glyph_infos()
	local glyph_pos   = hb_buf:get_glyph_positions()

	local x, y = 0, 0
	local bx, by, bw, bh = 0, 0, 0, 0

	for i = 0, glyph_count-1 do

		local glyph_index = glyph_info[i].codepoint

		local px = x + glyph_pos[i].x_offset / 64
		local py = y - glyph_pos[i].y_offset / 64

		hb_font:get_glyph_extents(glyph_index, hb_extents)

		bx, by, bw, bh = bounding_box(bx, by, bw, bh,
			x + hb_extents.x_bearing / 64,
			x + hb_extents.y_bearing / 64,
			hb_extents.width / 64,
			hb_extents.height / 64)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end

	return bw, bh, x, y
end

local function hb_feature_list(features)
	local feats_count = count(features)
	if feats_count == 0 then return nil end
	local feats = ffi.new('hb_feature_t[?]', feats_count)
	local i = 0
	for k,v in pairs(features) do
		assert(hb.feature(k, #k, feats[i]) == 1)
		feats[i].value = v
		i = i + 1
	end
	return feats, feats_count
end

--convert a tree of nested text runs with inherited properties into a flat
--list of runs with properties resolved.
local function flatten_text_tree(parent, runs)
	for _,run_or_text in ipairs(parent) do
		local run
		if type(run_or_text) == 'string' and #run_or_text > 0 then
			run = {text = run_or_text}
			push(runs, run)
		else
			run = run_or_text
			flatten_text_tree(run, runs)
		end
		if run.features then
			run.features, run.feat_count = hb_feature_list(run.features)
		end
		run.__index = parent
		setmetatable(run, run)
	end
	return runs
end

function tr:shape(text_tree)

	local text_runs = flatten_text_tree(text_tree, {})

	--get text length in codepoints.
	local len = 0
	for _,run in ipairs(text_runs) do
		run.size = assert(run.size or #run.text, 'text buffer size missing')
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
		return {}
	end

	--convert and concatenate text into a utf32 buffer.
	local str = ffi.new('uint32_t[?]', len)
	local offset = 0
	for _,run in ipairs(text_runs) do
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
	for _,run in ipairs(text_runs) do
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
	local dir = (text_tree.dir or 'auto'):lower()
	dir = dir == 'rtl'  and fb.C.FRIBIDI_PAR_RTL
		or dir == 'ltr'  and fb.C.FRIBIDI_PAR_LTR
		or dir == 'auto' and fb.C.FRIBIDI_PAR_ON

	local bidi_types    = ffi.new('FriBidiCharType[?]', len)
	local bracket_types = ffi.new('FriBidiBracketType[?]', len)
	local levels        = ffi.new('FriBidiLevel[?]', len)
	local vstr          = ffi.new('FriBidiChar[?]', len)

	fb.bidi_types(str, len, bidi_types)
	fb.bracket_types(str, len, bidi_types, bracket_types)
	local max_level, dir = fb.par_embedding_levels(bidi_types,
		bracket_types, len, dir, levels)
	assert(max_level, dir)
	ffi.copy(vstr, str, len * 4)
	fb.shape_mirroring(levels, len, vstr)

	--run Unicode line breaking algorithm over each run of text with same language.
	local linebreaks = ffi.new('char[?]', len)
	for i, len, lang in runs(langs, len, 0) do
		local lang = hb.language_tostring(lang)
		lang = lang and lang:sub(1, 2)
		ub.linebreaks(vstr + i, len, lang, linebreaks + i)
	end

	--make an iterator of text segments which share the same text properties
	--for the purpose of shaping them separately.

	--current-char state
	local i = 0
	local tri = 1
	local text_run = text_runs[1]
	--current-segment state
	local offset = 0
	local font = text_run.font
	local font_size = text_run.font_size
	local features, feat_count = text_run.features, text_run.feat_count
	local level = levels[0]
	local script = scripts[0]
	local lang = langs[0]

	local function next_segment()

		if i == len then --exit condition
			return nil
		end
		i = i + 1
		if i == len then --last segment
			local seglen = i - offset
			return
				offset, seglen,
				font, font_size, features, feat_count, level, script, lang,
				false
		end

		--change to the next text_run if we're past the current text run.
		if i > text_run.offset + text_run.len - 1 then
			tri = tri + 1
			text_run = text_runs[tri]
		end

		--check for a softbreak point in which case return the last segment.
		local font1 = text_run.font
		local font_size1 = text_run.font_size
		local features1, feat_count1 = text_run.features, text_run.feat_count
		local level1 = levels[i]
		local script1 = scripts[i]
		local lang1 = langs[i]
		local linebreak = linebreaks[i-1]
		local hardbreak = linebreak == 0
		local softbreak = linebreak == 1
		local softbreak = softbreak or hardbreak
			or font1 ~= font
			or font_size1 ~= font_size
			or features1 ~= features
			or level1 ~= level
			or script1 ~= script
			or lang1 ~= lang

		if not softbreak then
			return next_segment() --tail call
		end

		local seglen0 = i - offset
		local
			offset0, font0, font_size0, features0, feat_count0, level0, script0, lang0 =
			offset,  font,  font_size,  features,  feat_count,  level,  script,  lang

		offset = i
		font,  font_size,  features,  feat_count,  level,  script,  lang =
		font1, font_size1, features1, feat_count1, level1, script1, lang1

		return
			offset0, seglen0,
			font0, font_size0, features0, feat_count0, level0, script0, lang0,
			hardbreak
	end

	--shape the text segments.
	local glyph_runs = {}
	for
		i, len,
		font, font_size, features, feat_count, level, script, lang,
		hardbreak in next_segment
	do
		local buf = hb.buffer()

		buf:set_direction(level % 2 == 1
			and hb.C.HB_DIRECTION_RTL
			 or hb.C.HB_DIRECTION_LTR)
		buf:set_script(script)
		buf:set_language(lang)
		buf:add_utf32(vstr + i, len)

		self.rs:setfont(font, nil, nil, font_size)
		local hb_font = self.rs.font.hb_font

		buf:shape_full(hb_font, features, feat_count)

		local bw, bh, adv_x, adv_y = hb_buf_extents(buf, hb_font)

		local glyph_run = {
			level = level, --for reordering
			linebreak = hardbreak, --for wrapping
			font = font, font_size = font_size, buf = buf, --for painting
			text_run = text_run, --for debugging
		}
		glyph_run.w = bw
		glyph_run.h = bh
		glyph_run.advance_x = adv_x
		glyph_run.advance_y = adv_y

		push(glyph_runs, glyph_run)
	end

	function glyph_runs:free()
		self.__gc = nil
		for _,glyph_run in ipairs(self) do
			glyph_run.buf:free()
		end
	end
	glyph_runs.__gc = glyph_runs.free
	setmetatable(glyph_runs, glyph_runs)

	return glyph_runs
end

function tr:paint(glyph_runs, x0, y0, w, h, halign, valign)

	halign = halign or 'left'
	valign = valign or 'top'

	--do line wrapping.
	local lines = {}
	local line
	for i,run in ipairs(glyph_runs) do
		if not line or run.linebreak or line.advance_x + run.w > w then
			line = {advance_x = 0, w = 0}
			push(lines, line)
		end
		line.w = line.advance_x + run.w
		line.advance_x = line.advance_x + run.advance_x
		push(line, run)
	end

	--reorder RTL runs on each line separately, and concatenate the runs.
	for _,line in ipairs(lines) do
		for i,run in ipairs(line) do
			run.next = line[i+1]
		end
		line.first_visual_run = reorder_runs(line[1])
	end

	--compute paragraph's baseline based on vertical alignment.
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

	--paint the glyph runs.
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
		local run = line.first_visual_run
		while run do
			x, y = self:paint_glyph_run(run, x, y)
			run = run.next
		end
		line_y = line_y + line_h
	end

end

return tr
