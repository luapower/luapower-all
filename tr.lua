
--Unicode text shaping and rendering.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
local utf8 = require'utf8'
local hb = require'harfbuzz'
local fb = require'fribidi'
local ub = require'libunibreak'
local glue = require'glue'
local box2d = require'box2d'
local lrucache = require'lrucache'
local xxhash64 = require'xxhash'.hash64
local detect_scripts = require'tr_shape_script'
local reorder_runs = require'tr_shape_reorder'
local zone = require'jit.zone' --glue.noop

local band = bit.band
local push = table.insert
local update = glue.update
local assert = glue.assert --assert with string formatting
local count = glue.count
local clamp = glue.clamp
local snap = glue.snap
local bounding_box = box2d.bounding_box
local odd = function(x) return band(x, 1) == 1 end

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

local tr = {}
setmetatable(tr, tr)

tr.glyph_run_cache_size = 1024^2 * 10 --10MB net (arbitrary default)

tr.rasterizer_module = 'tr_raster_cairo'

function tr:create_rasterizer()
	return require(self.rasterizer_module)()
end

function tr:__call()
	self = update({}, self)

	self.rs = self:create_rasterizer()

	self.glyph_runs = lrucache{max_size = self.glyph_run_cache_size}
	function self.glyph_runs:value_size(glyph_run)
		return glyph_run.mem_size
	end
	function self.glyph_runs:free_value(glyph_run)
		glyph_run:free()
	end

	return self
end

function tr:free()
	self.glyph_runs:free()
	self.glyph_runs = false

	self.rs:free()
	self.rs = false
end

local function override_font(font)
	local inherited = font.load
	function font:load()
		inherited(self)
		assert(not self.hb_font)
		self.hb_font = assert(hb.ft_font(self.ft_face, nil))
	end
	local inherited = font.unload
	function font:unload()
		self.hb_font:free()
		self.hb_font = false
		inherited(self)
	end
	function font:size_changed()
		self.hb_font:ft_changed()
	end
	return font
end

function tr:add_font_file(...)
	return override_font(self.rs:add_font_file(...))
end

function tr:add_mem_font(...)
	return override_font(self.rs:add_mem_font(...))
end

function tr:paint_glyph_run(cr, run, x, y)
	zone'paint_glyph_run'

	local font = run.font
	local font_size = run.font_size
	local hb_buf = run.hb_buf

	local glyph_count = hb_buf:get_length()
	local glyph_info  = hb_buf:get_glyph_infos()
	local glyph_pos   = hb_buf:get_glyph_positions()

	for i = 0, glyph_count-1 do
		local glyph_index = glyph_info[i].codepoint

		local px = x + glyph_pos[i].x_offset / 64
		local py = y - glyph_pos[i].y_offset / 64

		local glyph, bmpx, bmpy = self.rs:glyph(
			font, font_size, glyph_index, px, py)

		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64

		self.rs:paint_glyph(cr, glyph, bmpx, bmpy)
	end

	zone()
	return x, y
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
		--TODO: make features individually inheritable.
		if run.features then
			run.features, run.feat_count = hb_feature_list(run.features)
		end
		run.__index = parent
		setmetatable(run, run)
	end
	return runs
end

local len0 = 0

local function realloc(var, ctype, len)
	if len > len0 then
		return ffi.new(ctype, len)
	else
		return var
	end
end

local
	str, scripts, langs,
	bidi_types, bracket_types, levels, vstr,
	linebreaks

local tr_free = tr.free
function tr:free()
	str, scripts, langs,
	bidi_types, bracket_types, levels, vstr,
	linebreaks = nil
	tr_free(self)
end

local function free_glyph_run(self)
	self.hb_buf:free()
	self.hb_buf = false
	self.font:unref()
	self.font = false
end

local hb_glyph_size =
	ffi.sizeof'hb_glyph_info_t'
	+ ffi.sizeof'hb_glyph_position_t'

function tr:shape_text_run(
	vstr, i, len,
	font, font_size, features, feat_count, rtl, script, lang
)
	font:ref()
	font:setsize(font_size)

	local hb_buf = hb.buffer()

	local dir = rtl and hb.C.HB_DIRECTION_RTL or hb.C.HB_DIRECTION_LTR
	hb_buf:set_direction(dir)
	hb_buf:set_script(script)
	hb_buf:set_language(lang)

	hb_buf:add_utf32(vstr + i, len)

	zone'hb_shape_full'
	hb_buf:shape_full(font.hb_font, features, feat_count)
	zone()

	local glyph_count = hb_buf:get_length()
	local glyph_info  = hb_buf:get_glyph_infos()
	local glyph_pos   = hb_buf:get_glyph_positions()

	zone'hb_shape_metrics'
	local ax, ay = 0, 0
	local bx, by, bw, bh = 0, 0, 0, 0
	for i = 0, glyph_count-1 do
		local m = self.rs:glyph_metrics(font, font_size, glyph_info[i].codepoint)
		bx, by, bw, bh = bounding_box(bx, by, bw, bh,
			ax + m.bearing_x,
			ax + m.bearing_y,
			m.w,
			m.h)
		ax = ax + glyph_pos[i].x_advance / 64
		ay = ay - glyph_pos[i].y_advance / 64
	end
	zone()

	local glyph_run = {
		--for painting
		font = font,
		font_size = font_size,
		hb_buf = hb_buf,
		--for layouting
		w = bw,
		h = bh,
		advance_x = ax,
		advance_y = ay,
		font_height = font.height,
		font_ascent = font.ascent,
		font_descent = font.descent,
		--for lru cache
		free = free_glyph_run,
		mem_size =
			224 --hb_buffer_t
			+ 200 --this table
			+ 4 * len --input text
			+ hb_glyph_size * glyph_count, --output glyphs
		--for debugging
		--text = ffi.string(utf8.encode(vstr + i, len)),
	}

	return glyph_run
end

function tr:glyph_run(
	vstr, i, len,
	font, font_size, features, feat_count, rtl, script, lang
)
	font:ref()
	local text_hash = tonumber(xxhash64(vstr + i, 4 * len, 0))
	local lang_id = tonumber(lang) or false
	local key = font.tuple(text_hash, font_size, rtl, script, lang_id)
	local glyph_run = self.glyph_runs:get(key)
	if not glyph_run then
		glyph_run = self:shape_text_run(
			vstr, i, len,
			font, font_size, features, feat_count, rtl, script, lang
		)
		self.glyph_runs:put(key, glyph_run)
	end
	font:unref()
	return glyph_run
end

function tr:shape(text_tree)

	local text_runs = flatten_text_tree(text_tree, {})

	--find (font, size) of each text run and get text length in codepoints.
	local len = 0
	for _,run in ipairs(text_runs) do

		--find (font, size) of each run.
		run.font, run.font_size = self.rs.font_db:find_font(
			run.font_name,
			run.font_weight,
			run.font_slant,
			run.font_size
		)
		assert(run.font, 'Font not found: %s', run.font_name)
		assert(run.font_size, 'Font size missing')
		run.font_size = snap(run.font_size, self.rs.font_size_resolution)

		--find length in codepoints of each run.
		run.text_size = run.text_size or #run.text
		assert(run.text_size, 'text buffer size missing')
		run.charset = run.charset or 'utf8'
		if run.charset == 'utf8' then
			run.len = utf8.decode(run.text, run.text_size, false)
		elseif run.charset == 'utf32' then
			run.len = math.floor(run.text_size / 4)
		else
			assert(false, 'invalid charset: %s', run.charset)
		end

		len = len + run.len
	end

	if len == 0 then
		return {}
	end

	--convert and concatenate text into a single utf32 buffer.
	str = realloc(str, 'uint32_t[?]', len)
	local offset = 0
	for _,run in ipairs(text_runs) do
		local str = str + offset
		if run.charset == 'utf8' then
			utf8.decode(run.text, run.text_size, str, run.len)
		elseif run.charset == 'utf32' then
			ffi.copy(str, run.text, run.text_size)
		end
		run.offset = offset
		offset = offset + run.len
	end

	--detect the script and lang properties for each char of the entire text.
	scripts = realloc(scripts, 'hb_script_t[?]', len)
	langs = realloc(langs, 'hb_language_t[?]', len)
	zone'detect_script'
	detect_scripts(str, len, scripts)
	zone()

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
	--Skip RTL reordering because 1) fribidi also reverses the _contents_ of
	--the RTL runs which harfbuzz also does, and 2) because bidi reordering
	--needs to be done after line breaking and is thus part of layouting.
	zone'bidi'
	local dir = (text_tree.dir or 'auto'):lower()
	dir = dir == 'rtl'  and fb.C.FRIBIDI_PAR_RTL
		or dir == 'ltr'  and fb.C.FRIBIDI_PAR_LTR
		or dir == 'auto' and fb.C.FRIBIDI_PAR_ON

	bidi_types    = realloc(bidi_types, 'FriBidiCharType[?]', len)
	bracket_types = realloc(bracket_types, 'FriBidiBracketType[?]', len)
	levels        = realloc(levels, 'FriBidiLevel[?]', len)
	vstr          = realloc(vstr, 'FriBidiChar[?]', len)

	fb.bidi_types(str, len, bidi_types)
	fb.bracket_types(str, len, bidi_types, bracket_types)
	local max_level, dir = fb.par_embedding_levels(bidi_types,
		bracket_types, len, dir, levels)
	assert(max_level, dir)
	ffi.copy(vstr, str, len * 4)
	fb.shape_mirroring(levels, len, vstr)
	zone()

	--run Unicode line breaking over each run of text with same language.
	zone'linebreak'
	linebreaks = realloc(linebreaks, 'char[?]', len)
	for i, len, lang in runs(langs, len, 0) do
		local lang = hb.language_tostring(lang)
		lang = lang and lang:sub(1, 2)
		ub.linebreaks(vstr + i, len, lang, linebreaks + i)
	end
	zone()

	--split text into segments of characters with the same properties
	--and shape those individually with harfbuzz.

	zone'segment'
	local segments = {} --{seg1, ...}
	local offset = 0
	local text_run_index = 1
	local text_run = text_runs[1]
	local level, script, lang
	for i = 0, len do

		--0: break required, 1: break allowed, 2: break not allowed.
		local linebreak = i > 0 and linebreaks[i-1] or 2

		local text_run1, level1, script1, lang1
		local text_run_same_props

		if i == len then
			goto process
		end

		--change to the next text_run if we're past the current text run.
		if i > text_run.offset + text_run.len - 1 then
			text_run_index = text_run_index + 1
			text_run1 = text_runs[text_run_index]
			text_run_same_props =
				text_run1.font == text_run.font
				and text_run1.font_size == text_run.font_size
				and text_run1.features == text_run.features
				and text_run1.line_spacing == text_run.line_spacing
		else
			text_run1 = text_run
			text_run_same_props = true
		end

		level1 = levels[i]
		script1 = scripts[i]
		lang1 = langs[i]

		if i == 0 then
			goto advance
		end

		if linebreak > 1
			and text_run_same_props
			and level1 == level
			and script1 == script
			and lang1 == lang
		then
			goto advance
		end

		::process::
		push(segments, {
			--reusable part
			run = self:glyph_run(
				vstr, offset, i - offset,
				text_run.font,
				text_run.font_size,
				text_run.features,
				text_run.feat_count,
				odd(level),
				script,
				lang
			),
			--non-reusable part
			level = level,
			linebreak = linebreak == 0, --hard break
			line_spacing = text_run.line_spacing,
		})
		offset = i

		::advance::
		text_run, level, script, lang = text_run1, level1, script1, lang1
	end
	zone()

	len0 = len
	return segments
end

function tr:paint(cr, segments, x0, y0, w, h, halign, valign)
	zone'paint'

	halign = halign or 'left'
	valign = valign or 'top'

	if #segments == 0 then
		zone()
		return
	end

	--do line wrapping.
	zone'linewrap'
	local lines = {}
	local line
	for i,seg in ipairs(segments) do
		if not line or line.advance_x + seg.run.w > w then
			line = {advance_x = 0, w = 0, h = 0, ascent = 0, descent = 0}
			push(lines, line)
		end
		line.w = line.advance_x + seg.run.w
		line.advance_x = line.advance_x + seg.run.advance_x
		line.h = math.max(line.h, seg.run.font_height * (seg.line_spacing or 1))
		line.ascent = math.max(line.ascent, seg.run.font_ascent)
		line.descent = math.min(line.descent, seg.run.font_descent)
		push(line, seg)
		if seg.linebreak then
			line = nil
		end
	end
	zone()

	--compute total line height.
	local lines_h = 0
	for _,line in ipairs(lines) do
		lines_h = lines_h + line.h
	end

	--reorder RTL segments on each line separately, and concatenate the runs.
	zone'reorder'
	for _,line in ipairs(lines) do
		local n = #line
		for i,seg in ipairs(line) do
			seg.next = line[i+1] or false
		end
		local seg = reorder_runs(line[1])
		local i = 0
		while seg do
			i = i + 1
			line[i] = seg
			seg = seg.next
		end
		assert(i == n)
	end
	zone()

	--compute first line's baseline based on vertical alignment.
	local x, y = x0, y0
	if valign == 'top' then
		y = y + lines[1].ascent
	else
		if valign == 'bottom' then
			y = y + h - lines_h + lines[1].h + lines[#lines].descent
		elseif valign == 'center' then
			y = y + (h - lines_h + lines[1].h
				+ lines[1].ascent + lines[#lines].descent) / 2
		else
			assert(false, 'invalid valign: %s', valign)
		end
	end

	--paint the glyph runs.
	zone'paint_lines'
	local line_y = y
	for i,line in ipairs(lines) do
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
		for _,seg in ipairs(line) do
			x, y = self:paint_glyph_run(cr, seg.run, x, y)
		end
		line_y = line_y + (lines[i+1] and lines[i+1].h or 0)
	end
	zone()

	zone()
end

return tr
