
--Unicode text shaping and rendering.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
local utf8 = require'utf8'
local hb = require'harfbuzz'
local fb = require'fribidi'
local ub = require'libunibreak'
local ft = require'freetype'
local glue = require'glue'
local box2d = require'box2d'
local lrucache = require'lrucache_lua'
local detect_scripts = require'tr_shape_script'
local lang_for_script = require'tr_shape_lang'
local reorder_segs = require'tr_shape_reorder'
local zone = glue.noop
--local zone = require'jit.zone' --enable for profiling

local band = bit.band
local push = table.insert
local max = math.max
local min = math.min
local floor = math.floor

local update = glue.update
local assert = glue.assert --assert with string formatting
local clamp = glue.clamp
local snap = glue.snap
local binsearch = glue.binsearch
local memoize = glue.memoize
local shift = glue.shift
local growbuffer = glue.growbuffer
local trim = glue.trim

local box_overlapping = box2d.overlapping
local box_hit = box2d.hit

local odd = function(x) return band(x, 1) == 1 end
local PS = fb.C.FRIBIDI_CHAR_PS --paragraph separator codepoint
local LS = fb.C.FRIBIDI_CHAR_LS --line separator codepoint

--iterate a list of values in run-length encoded form.
local function index_it(t, i) return t[i] end
local function rle_runs(t, len, get_value, start)
	get_value = get_value or index_it
	local i = (start or 0)
	len = len + i
	return function()
		if i >= len then
			return nil
		end
		local i1, n, val1 = i, 1, get_value(t, i)
		while true do
			i = i + 1
			if i >= len then
				return i1, n, val1
			end
			local val = get_value(t, i)
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

tr.rasterizer_module = 'tr_raster_cairo' --who does rs:paint_glyph()

function tr:create_rasterizer()
	return require(self.rasterizer_module)()
end

function tr:__call()
	self = update({}, self)

	self.rs = self:create_rasterizer()

	function self.rs.warn(rs, ...)
		return self:warn(...)
	end

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

function tr:warn(...)
	io.stderr:write(string.format(...))
	io.stderr:write'\n'
end

--font management ------------------------------------------------------------

local function override_font(font)
	local inherited = font.load
	function font:load()
		if not inherited(self) then return end
		assert(not self.hb_font)
		self.hb_font = assert(hb.ft_font(self.ft_face, nil))
		self.hb_font:set_ft_load_flags(self.ft_load_flags)
		return true
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

--hb_feature_t lists ---------------------------------------------------------

local alloc_hb_features = ffi.typeof'hb_feature_t[?]'

--parse a string of harfbuzz features into a `hb_feature_t` array.
local function parse_features(s)
	local n = 0
	for _ in s:gmatch'()[^%s]+' do
		n = n + 1
	end
	local feats = alloc_hb_features(n)
	local i = 0
	for s in s:gmatch'[^%s]+' do
		assert(hb.feature(s, feats[i]), 'Invalid feature: %s', s)
		i = i + 1
	end
	return {feats, n}
end
parse_features = memoize(parse_features)

local function hb_features(s)
	if not s then return nil, 0 end
	return unpack(parse_features(s))
end

--shaping a single word into an array of glyphs ------------------------------

local glyph_run = {} --glyph run methods
tr.glyph_run_class = glyph_run

local hb_glyph_size =
	ffi.sizeof'hb_glyph_info_t'
	+ ffi.sizeof'hb_glyph_position_t'

local function isnewline(c)
	return
		(c >= 10 and c <= 13) --LF, VT, FF, CR
		or c == PS
		or c == LS
		or c == 0x85 --NEL
end

--for harfbuzz, language is a IETF BCP 47 language code + country code,
--but libunibreak only uses the language code part.
local function ub_lang(hb_lang)
	local s = hb.language_tostring(hb_lang)
	return s and s:gsub('[%-_].*$', '')
end

local function count_graphemes(grapheme_breaks, start, len)
	local n = 0
	for i = start, start+len-1 do
		if grapheme_breaks[i] == 0 then
			n = n + 1
		end
	end
	return n
end

local function next_grapheme(grapheme_breaks, i, len)
	while grapheme_breaks[i] ~= 0 do
		i = i + 1
	end
	i = i + 1
	return i < len and i or nil
end

local alloc_grapheme_breaks = growbuffer'char[?]'

local function cmp_clusters(glyph_info, i, cluster)
	return glyph_info[i].cluster < cluster -- < < [=] = < <
end

local function cmp_clusters_reverse(glyph_info, i, cluster)
	return cluster < glyph_info[i].cluster -- < < [=] = < <
end

local alloc_int_array = ffi.typeof'int[?]'
local alloc_double_array = ffi.typeof'double[?]'

local function get_cluster(glyph_info, i)
	return glyph_info[i].cluster
end
function tr:shape_word(
	str, str_offset, len, trailing_space,
	font, font_size, features,
	rtl, script, lang
)
	zone'hb_shape' ------------------------------------------------------------

	if not font:ref() then return end
	font:setsize(font_size)

	local hb_dir = rtl and hb.C.HB_DIRECTION_RTL or hb.C.HB_DIRECTION_LTR
	local hb_buf = hb.buffer()
	hb_buf:set_cluster_level(
		--hb.C.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
		hb.C.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
		--hb.C.HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
	)
	hb_buf:set_direction(hb_dir)
	hb_buf:set_script(script)
	hb_buf:set_language(lang)
	hb_buf:add_codepoints(str + str_offset, len)
	hb_buf:shape(font.hb_font, hb_features(features))

	local glyph_count = hb_buf:get_length()
	local glyph_info  = hb_buf:get_glyph_infos()
	local glyph_pos   = hb_buf:get_glyph_positions()

	--1. scale advances and offsets based on `font.scale` (for bitmap fonts).
	--2. make the advance of each glyph relative to the start of the run
	--   so that pos_x() is O(1) for any index.
	--3. compute the run's total advance.
	local scale = font.scale
	local ax = 0
	for i = 0, glyph_count-1 do
		ax = (ax + glyph_pos[i].x_advance) * scale
		glyph_pos[i].x_offset = glyph_pos[i].x_offset * scale
		glyph_pos[i].x_advance = ax
	end
	ax = ax / 64

	local function pos_x(i)
		assert(i >= 0)
		assert(i <= glyph_count)
		return i > 0 and glyph_pos[i-1].x_advance / 64 or 0
	end

	zone()

	zone'hb_shape_cursor_pos' -------------------------------------------------

	local cursor_offsets = alloc_int_array(len + 1) --in logical order
	local cursor_xs = alloc_double_array(len + 1) --in logical order
	for i = 0, len do
		cursor_offsets[i] = -1 --invalid offset, fixed later
	end

	local grapheme_breaks --allocated on demand for multi-codepoint clusters

	local function add_cursors(
		glyph_offset, glyph_len,
		cluster, cluster_len, cluster_x
	)
		cursor_offsets[cluster] = cluster
		cursor_xs[cluster] = cluster_x
		if cluster_len > 1 then
			--the cluster is made of multiple codepoints. check how many
			--graphemes it contains since we need to add additional cursor
			--positions at each grapheme boundary.
			if not grapheme_breaks then
				grapheme_breaks = alloc_grapheme_breaks(len)
				local lang = nil --not used in current libunibreak impl.
				ub.graphemebreaks(str + str_offset, len, lang, grapheme_breaks)
			end
			local grapheme_count =
				count_graphemes(grapheme_breaks, cluster, cluster_len)
			if grapheme_count > 1 then
				--the cluster is made of multiple graphemes, which can be the
				--result of forming ligatures, which the font can provide carets
				--for. missing ligature carets, we divide the combined x-advance
				--of the glyphs evenly between graphemes.
				for i = glyph_offset, glyph_offset + glyph_len - 1 do
					local glyph_index = glyph_info[i].codepoint
					local cluster_x = pos_x(i)
					local carets, caret_count =
						font.hb_font:get_ligature_carets(hb_dir, glyph_index)
					if caret_count > 0 then
						-- there shouldn't be more carets than grapheme_count-1.
						caret_count = min(caret_count, grapheme_count - 1)
						--add the ligature carets from the font.
						for i = 0, caret_count-1 do
							--create a synthetic cluster at each grapheme boundary.
							cluster = next_grapheme(grapheme_breaks, cluster, len)
							local lig_x = carets[i] / 64
							cursor_offsets[cluster] = cluster
							cursor_xs[cluster] = cluster_x + lig_x
						end
						--infer the number of graphemes in the glyph as being
						--the number of ligature carets in the glyph + 1.
						grapheme_count = grapheme_count - (caret_count + 1)
					else
						--font doesn't provide carets: add synthetic carets by
						--dividing the total x-advance of the remaining glyphs
						--evenly between remaining graphemes.
						local next_i = glyph_offset + glyph_len
						local total_advance_x = pos_x(next_i) - pos_x(i)
						local w = total_advance_x / grapheme_count
						for i = 1, grapheme_count-1 do
							--create a synthetic cluster at each grapheme boundary.
							cluster = next_grapheme(grapheme_breaks, cluster, len)
							local lig_x = i * w
							cursor_offsets[cluster] = cluster
							cursor_xs[cluster] = cluster_x + lig_x
						end
						grapheme_count = 0
					end
					if grapheme_count == 0 then
						break --all graphemes have carets
					end
				end
			end
		end
	end

	if rtl then
		--add last logical (first visual), after-the-text cursor
		cursor_offsets[len] = len
		cursor_xs[len] = 0
		local i, n --index in glyph_info, glyph count.
		local c, cn, cx --cluster, cluster len, cluster x.
		c = len
		for i1, n1, c1 in rle_runs(glyph_info, glyph_count, get_cluster) do
			cx = pos_x(i1)
			if i then
				add_cursors(i, n, c, cn, cx)
			end
			local cn1 = c - c1
			i, n, c, cn = i1, n1, c1, cn1
		end
		if i then
			cx = ax
			add_cursors(i, n, c, cn, cx)
		end
	else
		local i, n, c, cx
		for i1, n1, c1 in rle_runs(glyph_info, glyph_count, get_cluster) do
			if c then
				local cn = c1 - c
				add_cursors(i, n, c, cn, cx)
			end
			local cx1 = pos_x(i1)
			i, n, c, cx = i1, n1, c1, cx1
		end
		if i then
			local cn = len - c
			add_cursors(i, n, c, cn, cx)
		end
		--add last logical (last visual), after-the-text cursor
		cursor_offsets[len] = len
		cursor_xs[len] = ax
	end

	--add cursor offsets for all codepoints which are missing one.
	if grapheme_breaks then --there are clusters with multiple codepoints.
		local c, x --cluster, cluster x.
		for i = 0, len do
			if cursor_offsets[i] == -1 then
				cursor_offsets[i] = c
				cursor_xs[i] = x
			else
				c = cursor_offsets[i]
				x = cursor_xs[i]
			end
		end
	end

	zone()

	--compute `wrap_advance_x` by removing the advance of the trailing space.
	local wx = ax
	if trailing_space then
		local i = rtl and 0 or glyph_count-1
		assert(glyph_info[i].cluster == len-1)
		wx = wx - (pos_x(i+1) - pos_x(i))
	end

	local glyph_run = update({
		tr = self,
		--for glyph painting
		font = font,
		font_size = font_size,
		len = glyph_count,
		info = glyph_info, --0..len-1
		pos = glyph_pos,   --0..len-1
		hb_buf = hb_buf, --anchored
		--for positioning in horizontal flow
		advance_x = ax,
		wrap_advance_x = wx,
		--for positioning in multi-line flow
		ascent = font.ascent,
		descent = font.descent,
		--for lru cache
		mem_size =
			224 + hb_glyph_size * max(len, glyph_count) --hb_buffer_t[]
			+ (8 + 8) * (len + 1) --cursor_offsets[], cursor_xs[]
			+ 400 --this table
		,
		--for cursor positioning and hit testing
		text_len = len,
		cursor_offsets = cursor_offsets, --0..text_len
		cursor_xs = cursor_xs, --0..text_len
		rtl = rtl,
		trailing_space = trailing_space,
	}, self.glyph_run_class)

	return glyph_run
end

function glyph_run:free()
	self.hb_buf:free()
	self.hb_buf = false
	self.info = false
	self.pos = false
	self.len = 0
	self.font:unref()
	self.font = false
end

function tr:glyph_run(
	str, str_offset, len, trailing_space,
	font, font_size, features,
	rtl, script, lang
)
	if not font:ref() then return end

	--compute cache key for this run.
	local text = ffi.string(str + str_offset, 4 * len)
	local lang_id = tonumber(lang) or false
	local key = font.tuple(text, font_size, rtl, script, lang_id)

	--get the shaped run from cache or shape it and cache it.
	local glyph_run = self.glyph_runs:get(key)
	if not glyph_run then
		glyph_run = self:shape_word(
			str, str_offset, len, trailing_space,
			font, font_size, features,
			rtl, script, lang
		)
		self.glyph_runs:put(key, glyph_run)
	end

	font:unref()
	return glyph_run
end

--flattening a text tree into a utf32 string + metadata ----------------------

local uint32_ct = ffi.typeof'uint32_t[?]'
local const_char_ct = ffi.typeof'const char*'

--convert a tree of nested text runs into a flat list of runs with properties
--dynamically inherited from the parent nodes.
--NOTE: one text run is always created for each node, even when there's
--no text, in order to anchor the node attributes to a text run.
local function flatten_text_tree(parent, runs)
	for i = 1, max(1, #parent) do
		local run_or_text = parent[i] or ''
		local run
		if type(run_or_text) == 'string' then
			run = {text = run_or_text}
			push(runs, run)
		else
			run = run_or_text
			flatten_text_tree(run, runs)
		end
		run.__index = parent
		setmetatable(run, run)
	end
end

function tr:flatten(text_tree)

	local text_runs = update({tr = self}, self.text_runs_class)

	flatten_text_tree(text_tree, text_runs)

	--for each text run: set `font` `font_size` and `len`.
	--also compute total text length in codepoints.
	local len = 0
	for _,run in ipairs(text_runs) do
		local charset

		--resolve `font` and `font_size`.
		local font_db = self.rs.font_db
		if not run.font or type(run.font) == 'string' then
			local font_name = run.font_name or run.font or nil
			local weight = run.font_weight
			local bold = run.bold or run.b
			local slant = (run.italic or run.i) and 'italic' or run.font_slant
			local font_size = run.font_size
			local found_font, found_font_size =
				font_db:find_font(font_name, weight, slant, font_size, bold)
			if not found_font then
				self:warn('Font not found: "%s" %s %s %s',
					font_name, weight or '', slant or '', font_size or '')
				goto invalid
			else
				run.font = found_font
				run.font_size = found_font_size
			end
		end

		if not run.font_size then
			self:warn('Font size missing')
			goto invalid
		else
			run.font_size = snap(run.font_size, self.rs.font_size_resolution)
		end

		--resolve `len` (length in codepoints).
		charset = run.charset or 'utf8'
		if charset == 'utf8' then
			local size = run.size or #run.text
			if not size then
				self:warn('Text buffer size missing')
				goto invalid
			else
				run.len = utf8.decode(run.text, size, false, run.maxlen)
					or run.maxlen --buffer overflow because of run.maxlen
			end
		elseif charset == 'utf32' then
			local size = run.size or (run.len and run.len * 4) or #run.text
			if not size then
				self:warn('Text buffer size missing')
				goto invalid
			else
				run.len = min(floor(size / 4), run.maxlen or 1/0)
			end
		else
			self:warn('Invalid charset: %s', run.charset)
			goto invalid
		end

		--resolve `script`
		if run.script then
			local script = hb.script(run.script)
			if not script then
				self:warn('Invalid script: %s', run.script)
				goto invalid
			else
				run.script = script
			end
		end

		--resolve `lang`
		if run.lang then
			local lang = hb.language(run.lang)
			if not lang then
				self:warn('Invalid lang: %s', run.lang)
				goto invalid
			else
				run.lang = lang
			end
		end

		len = len + run.len
		goto continue
		::invalid::
		run.invalid = true
		::continue::
	end

	text_runs.alloc_codepoints = growbuffer(uint32_ct, 2)
	local str = text_runs.alloc_codepoints(len + 1) -- +1 for linebreaks

	--resolve `offset` and convert/place text into a linear utf32 buffer.
	local offset = 0
	for _,run in ipairs(text_runs) do
		if not run.invalid then
			local charset = run.charset or 'utf8'
			if charset == 'utf8' then
				local size = run.size or #run.text
				utf8.decode(run.text, size, str + offset, run.len)
			elseif charset == 'utf32' then
				ffi.copy(str + offset, ffi.cast(const_char_ct, run.text), run.len * 4)
			end
			run.offset = offset
			offset = offset + run.len
		end
	end

	--remove invalid text runs.
	for i = #text_runs, 1, -1 do
		if text_runs[i].invalid then
			table.remove(text_runs, i)
		end
	end

	text_runs.codepoints = str
	text_runs.len = len

	return text_runs
end

--itemizing and shaping a flat text into array of segments -------------------

local alloc_scripts = growbuffer'hb_script_t[?]'
local alloc_langs = growbuffer'hb_language_t[?]'
local alloc_bidi_types = growbuffer'FriBidiCharType[?]'
local alloc_bracket_types = growbuffer'FriBidiBracketType[?]'
local alloc_levels = growbuffer'FriBidiLevel[?]'
local alloc_linebreaks = growbuffer'char[?]'

local tr_free = tr.free
function tr:free()
	alloc_scripts(false)
	alloc_langs(false)
	alloc_bidi_types(false)
	alloc_bracket_types(false)
	alloc_levels(false)
	alloc_linebreaks(false)
	alloc_grapheme_breaks(false)
	tr_free(self)
end

local const_uint32_ct = ffi.typeof'const uint32_t*'

function tr:shape(text_runs, segments)

	if not text_runs.codepoints then --it's a text tree, flatten it.
		text_runs = self:flatten(text_runs)
	else --it's a text runs array, wrap it.
		update(text_runs, self.text_runs_class)
		text_runs.tr = self
	end

	local str = ffi.cast(const_uint32_ct, text_runs.codepoints)
	local len = text_runs.len

	--detect the script property for each char of the entire text.
	local scripts = alloc_scripts(len)
	local langs = alloc_langs(len)
	zone'detect_script'
	detect_scripts(str, len, scripts)
	zone()

	--detect the lang property based on script.
	zone'detect_lang'
	for i = 0, len-1 do
		langs[i] = lang_for_script(scripts[i])
	end
	zone()

	--override scripts and langs with user-provided values.
	for _,run in ipairs(text_runs) do
		local script, lang = run.script, run.lang
		if script then
			for i = run.offset, run.offset + run.len - 1 do
				scripts[i] = script
			end
		end
		if lang then
			for i = run.offset, run.offset + run.len - 1 do
				langs[i] = lang
			end
		end
	end

	--Split text into paragraphs and run fribidi over each paragraph as follows:
	--Skip mirroring since harfbuzz also does that.
	--Skip arabic shaping since harfbuzz does that better with font assistance.
	--Skip RTL reordering because 1) fribidi also reverses the _contents_ of
	--the RTL runs, which harfbuzz also does, and 2) because bidi reordering
	--needs to be done after line breaking and so it's part of layouting.
	zone'bidi'
	local bidi_types    = alloc_bidi_types(len)
	local bracket_types = alloc_bracket_types(len)
	local levels        = alloc_levels(len)

	--flag indicating that bidi reordering will be needed on line-wrapping.
	local reorder_segments = false
	--bidi direction for the first paragraph of the text.
	local base_dir = false

	if #text_runs > 0 then

		local text_run_index = 0
		local next_i = 0 --char offset of the next text run
		local par_offset = 0
		local dir --last text run's paragraph's base direction

		for i = 0, len do --NOTE: going one char beyond the text!

			--per-text-run attrs for the current char.
			local dir1 = dir

			--change to the next text run if we're past the current text run.
			--NOTE: the paragraph `dir` is that of the last text run which sets it.
			--NOTE: this runs when i == 0 and when len == 0 but not when i == len.
			if i == next_i then
				text_run_index = text_run_index + 1
				local text_run = text_runs[text_run_index]

				dir1 = text_run.dir or dir

				next_i = text_run.offset + text_run.len
				next_i = next_i < len and next_i
			end

			if i == len or (i > 0 and str[i-1] == PS) then

				local par_len = i - par_offset

				if par_len > 0 then

					local dir = (dir or 'auto'):lower()
					local fb_dir =
							dir == 'rtl'  and fb.C.FRIBIDI_PAR_RTL
						or dir == 'ltr'  and fb.C.FRIBIDI_PAR_LTR
						or dir == 'auto' and fb.C.FRIBIDI_PAR_ON

					fb.bidi_types(
						str + par_offset,
						par_len,
						bidi_types + par_offset
					)

					fb.bracket_types(
						str + par_offset,
						par_len,
						bidi_types + par_offset,
						bracket_types + par_offset
					)

					local max_bidi_level, fb_dir = fb.par_embedding_levels(
						bidi_types + par_offset,
						bracket_types + par_offset,
						par_len,
						fb_dir,
						levels + par_offset
					)
					assert(max_bidi_level)

					reorder_segments = reorder_segments
						or max_bidi_level > (dir == 'rtl' and 1 or 0)

					base_dir = base_dir or fb.par_type_name(fb_dir)

				end

				par_offset = i
			end

			dir = dir1
		end

	end --if #text_runs > 0
	zone()

	--run Unicode line breaking over each run of text with the same language.
	--NOTE: libunibreak always puts a hard break at the end of the text:
	--we don't want that so we're passing it one more codepoint than needed.
	zone'linebreak'
	local linebreaks = alloc_linebreaks(len + 1)
	for i, len, lang in rle_runs(langs, len) do
		ub.linebreaks(str + i, len + 1, ub_lang(lang), linebreaks + i)
	end
	zone()

	--split the text into segments of characters with the same properties,
	--shape the segments individually and cache the shaped results.
	--the splitting is two-level: each text segment that requires separate
	--shaping can contain sub-segments that require separate styling.
	zone'segment'

	segments = segments or update({tr = self}, self.segments_class) --{seg1, ...}
	local old_seg_count = #segments

	segments.text_runs = text_runs --for accessing codepoints by clients
	segments.bidi = reorder_segments --for optimization
	segments.base_dir = base_dir

	local seg_count = 0
	local line_num = 1

	if #text_runs > 0 then

		local text_run_index = 0
		local next_i = 0 --char offset of the next text run
		local text_run, font, font_size, features --per-text-run attrs
		local level, script, lang --per-char attrs

		local seg_offset = 0 --curent segment's offset in text
		local sub_offset = 0 --current sub-segment's relative text offset
		local substack
		local substack_n = 0

		for i = 0, len do --NOTE: going one char beyond the text!

			--per-text-run attts for the current char.
			local text_run1, font1, font_size1, features1

			--change to the next text run if we're past the current text run.
			--NOTE: this runs when i == 0 and when len == 0 but not when i == len.
			if i == next_i then

				text_run_index = text_run_index + 1
				text_run1 = text_runs[text_run_index]

				font1 = text_run1.font
				font_size1 = text_run1.font_size
				features1 = text_run1.features

				next_i = text_run1.offset + text_run1.len
				next_i = next_i < len and next_i

			elseif i < len then

				--use last char's attrs.
				text_run1 = text_run
				font1 = font
				font_size1 = font_size
				features1 = features

			end

			--per-char attrs for the current char.
			local level1, script1, lang1
			if len == 0 then

				--the string is empty so init those with defaults.
				local dir = (text_run1.dir or 'auto'):lower()
				level1 = dir == 'rtl' and 1 or 0
				script1 = text_run1.script or hb.C.HB_SCRIPT_COMMON
				lang1 = text_run1.lang

			elseif i < len then

				level1 = levels[i]
				script1 = scripts[i]
				lang1 = langs[i]

			end

			--init last char's state on first iteration. this works both to prevent
			--making a first empty segment and to provide state for when len == 0.
			if i == 0 then

				text_run = text_run1
				font = font1
				font_size = font_size1
				features = features1

				level = level1
				script = script1
				lang = lang1

				if len == 0 then
					font1 = nil --force making a new segment
				end
			end

			--unicode line breaking: 0: required, 1: allowed, 2: not allowed.
			local linebreak_code = i > 0 and linebreaks[i-1] or 2

			--check if any attributes that require a new segment have changed.
			local new_segment =
				linebreak_code < 2
				or font1 ~= font
				or font_size1 ~= font_size
				or features1 ~= features
				or level1 ~= level
				or script1 ~= script
				or lang1 ~= lang

			--check if any attributes that require a new sub-segment have changed.
			local new_subsegment =
				new_segment
				or text_run1 ~= text_run

			if new_segment then

				::again::

				local seg_len = i - seg_offset
				local rtl = odd(level)

				--find the segment length without trailing linebreak chars.
				--NOTE: this can result in seg_len == 0, which is still valid.
				for i = seg_offset + seg_len-1, seg_offset, -1 do
					if isnewline(str[i]) then
						seg_len = seg_len - 1
					else
						break
					end
				end

				--find if the segment has a trailing space char.
				local trailing_space = seg_len > 0
					and fb.IS_EXPLICIT_OR_BN_OR_WS(bidi_types[seg_offset + seg_len-1])

				--shape the segment excluding trailing linebreak chars.
				local glyph_run = self:glyph_run(
					str, seg_offset, seg_len, trailing_space,
					font, font_size, features,
					rtl, script, lang
				)

				local linebreak = linebreak_code == 0
					and (str[i-1] == PS and 'paragraph' or 'line')

				if glyph_run then --font loaded successfully

					seg_count = seg_count + 1

					local segment = {
						glyph_run = glyph_run,
						--for line breaking
						linebreak = linebreak, --hard break
						--for bidi reordering
						bidi_level = level,
						--for cursor positioning
						text_run = text_run, --text run of the last sub-segment
						offset = seg_offset,
						index = seg_count,
						--slots filled by layouting
						x = false, advance_x = false, --segment's x-axis boundaries
						next = false, --next segment on the same line in text order
						next_vis = false, --next segment on the same line in visual order
						line = false,
						line_num = line_num, --physical line number
						wrapped = false, --segment is the last on a wrapped line
						visible = true, --segment is not entirely clipped
					}

					segments[seg_count] = segment

					--add sub-segments from the sub-segment stack and empty the stack.
					if substack_n > 0 then
						local last_sub_len = seg_len - sub_offset
						local sub_offset = 0
						local glyph_i = 0
						local clip_left, clip_right = false, false --from run's origin
						for i = 1, substack_n + 1, 2 do
							local sub_len, sub_text_run
							if i < substack_n  then
								sub_len, sub_text_run = substack[i], substack[i+1]
							else --last iteration outside the stack for last sub-segment
								sub_len, sub_text_run = last_sub_len, text_run
							end

							--adjust `next_sub_offset` to a grapheme position.
							local next_sub_offset = sub_offset + sub_len
							assert(next_sub_offset >= 0)
							assert(next_sub_offset <= seg_len)
							local next_sub_offset = glyph_run.cursor_offsets[next_sub_offset]
							local sub_len = next_sub_offset - sub_offset

							if sub_len == 0 then
								break
							end

							--find the last sub's glyph which is before any glyph which
							--*starts* representing the graphemes at `next_sub_offset`,
							--IOW the last glyph with a cluster value < `next_sub_offset`.

							local last_glyph_i

							if rtl then

								last_glyph_i = (binsearch(
									next_sub_offset, glyph_run.info,
									cmp_clusters_reverse,
									glyph_i, 0
								) or -1) + 1

								assert(last_glyph_i >= 0)
								assert(last_glyph_i < glyph_run.len)

								--check whether the last glyph represents additional graphemes
								--beyond the current sub-segment, if so we have to clip it.
								local next_cluster =
									last_glyph_i > 0
									and glyph_run.info[last_glyph_i-1].cluster
									or 0

								clip_left = next_cluster > next_sub_offset
								clip_left = clip_left and glyph_run.cursor_xs[next_sub_offset]

								push(segment, glyph_i)
								push(segment, last_glyph_i)
								push(segment, sub_text_run)
								push(segment, clip_left)
								push(segment, clip_right)

								sub_offset = next_sub_offset
								glyph_i = last_glyph_i - (clip_left and 0 or 1)
								clip_right = clip_left

							else --ltr

								last_glyph_i = (binsearch(
									next_sub_offset, glyph_run.info,
									cmp_clusters,
									glyph_i, glyph_run.len-1
								) or glyph_run.len) - 1

								assert(last_glyph_i >= 0)
								assert(last_glyph_i < glyph_run.len)

								--check whether the last glyph represents additional graphemes
								--beyond the current sub-segment, if so we have to clip it.
								local next_cluster =
									last_glyph_i < glyph_run.len-1
									and glyph_run.info[last_glyph_i+1].cluster
									or seg_len

								clip_right = next_cluster > next_sub_offset
								clip_right = clip_right and glyph_run.cursor_xs[next_sub_offset]

								push(segment, glyph_i)
								push(segment, last_glyph_i)
								push(segment, sub_text_run)
								push(segment, clip_left)
								push(segment, clip_right)

								sub_offset = next_sub_offset
								glyph_i = last_glyph_i + (clip_right and 0 or 1)
								clip_left = clip_right

							end

						end --for each subsegment
						substack_n = 0 --empty the stack
					end --if subsegments

				end --if glyph_run

				if linebreak then
					line_num = line_num + 1
				end

				seg_offset = i
				sub_offset = 0

				--if the last segment ended with a hard line break, add another
				--empty segment at the end, in order to have a cursor on the last
				--empty line.
				if i == len and linebreak then
					linebreak_code = 2 --prevent recursion
					goto again
				end

			elseif new_subsegment then

				local sub_len = i - (seg_offset + sub_offset)
				substack = substack or {}
				substack[substack_n + 1] = sub_len
				substack[substack_n + 2] = text_run
				substack_n = substack_n + 2

				sub_offset = sub_offset + sub_len
			end

			--update last char state with current char state.
			text_run = text_run1
			font = font1
			font_size = font_size1
			features = features1

			level = level1
			script = script1
			lang = lang1
		end
		zone()

	end --if #text_runs > 0

	--clean up excess old segments from previous segments list, if any.
	while old_seg_count > seg_count do
		segments[old_seg_count] = nil
		old_seg_count = old_seg_count - 1
	end

	--remove cached values.
	segments._min_w = false
	segments._max_w = false
	segments.lines = false

	return segments
end

--layouting ------------------------------------------------------------------

local segments = {} --methods for segment list
tr.segments_class = segments

--wrap-width and advance-width of all the nowrap segments starting with the
--segment at seg_i and the seg_i after those segments.
function segments:nowrap_segments(seg_i)
	local seg = self[seg_i]
	local run = seg.glyph_run
	if not seg.text_run.nowrap then
		local wx = run.wrap_advance_x
		local ax = run.advance_x
		local wx = (seg.linebreak or seg_i == #self) and ax or wx
		return wx, ax, seg_i + 1
	end
	local ax = 0
	local n = #self
	for i = seg_i, n do
		local seg = self[i]
		local run = seg.glyph_run
		local ax1 = ax + run.advance_x
		if i == n or seg.linebreak then --hard break, w == ax
			return ax1, ax1, i + 1
		elseif i < n and not self[i+1].text_run.nowrap then
			local wx = ax + run.wrap_advance_x
			return wx, ax1, i + 1
		end
		ax = ax1
	end
end

--minimum width that the text can wrap into without overflowing.
function segments:min_w()
	local min_w = self._min_w
	if not min_w then
		min_w = 0
		local seg_i, n = 1, #self
		while seg_i <= n do
			local segs_wx, _, next_seg_i = self:nowrap_segments(seg_i)
			min_w = max(min_w, segs_wx)
			seg_i = next_seg_i
		end
		self._min_w = min_w
	end
	return min_w
end

--text width when there's no wrapping.
function segments:max_w()
	local max_w = self._max_w
	if not max_w then
		max_w = 0
		local line_w = 0
		local n = #self
		for i = 1, #self do
			local seg = self[i]
			local run = seg.glyph_run
			local wx = run.wrap_advance_x
			local ax = run.advance_x
			local linebreak = seg.linebreak or i == n
			local wx = linebreak and ax or wx
			line_w = line_w + wx
			if linebreak then
				max_w = max(max_w, line_w)
				line_w = 0
			end
		end
		self._max_w = max_w
	end
	return max_w
end

function segments:wrap(w)

	--NOTE: users expect this table to be re-created from scratch on
	--re-layouting (they will add data to this table that must only be valid
	--for the lifetime of a single computed layout).
	local lines = {
		h = 0,
		spaced_h = 0,
		baseline = 0,
		max_ax = 0,
		first_visible = 1,
		last_visible = 0,
	}
	self.lines = lines

	--do line wrapping and compute line advance.
	zone'linewrap'
	local line_i = 0
	local seg_i, seg_count = 1, #self
	local line
	while seg_i <= seg_count do
		local segs_wx, segs_ax, next_seg_i = self:nowrap_segments(seg_i)

		local hardbreak = not line
		local softbreak = not hardbreak
			and segs_wx > 0 --don't create a new line for an empty segment
			and line.advance_x + segs_wx > w

		if hardbreak or softbreak then

			local prev_seg = self[seg_i-1] --last segment of the previous line

			--adjust last segment due to being wrapped.
			if softbreak then
				local prev_run = prev_seg.glyph_run
				line.advance_x = line.advance_x - prev_seg.advance_x
				prev_seg.advance_x = prev_run.wrap_advance_x
				prev_seg.x = prev_run.rtl
					and -(prev_run.advance_x - prev_run.wrap_advance_x) or 0
				prev_seg.wrapped = true
				line.advance_x = line.advance_x + prev_seg.advance_x
			end

			if prev_seg then --break the next* chain.
				prev_seg.next = false
				prev_seg.next_vis = false
			end

			line_i = line_i + 1
			line = {
				index = line_i,
				first = self[seg_i], --first segment in text order
				first_vis = self[seg_i], --first segment in visual order
				x = 0, y = 0,
				advance_x = 0,
				ascent = 0, descent = 0,
				spaced_ascent = 0, spaced_descent = 0,
				visible = true, --entirely clipped or not
			}
			self.lines[line_i] = line

		end

		line.advance_x = line.advance_x + segs_ax

		for seg_i = seg_i, next_seg_i-1 do
			local seg = self[seg_i]
			local run = seg.glyph_run
			seg.advance_x = run.advance_x
			seg.x = 0
			seg.line = line
			seg.wrapped = false
			seg.next = self[seg_i+1]
			seg.next_vis = self[seg_i+1]
		end

		local last_seg = self[next_seg_i-1]
		if last_seg.linebreak then
			if last_seg.linebreak == 'paragraph' then
				--we use this particular segment's `paragraph_spacing` property
				--since this is the segment asking for a paragraph break.
				--TODO: is there a more logical way to select this property?
				line.spacing = last_seg.text_run.paragraph_spacing or 2
			else
				line.spacing = last_seg.text_run.hardline_spacing or 1
			end
			line = nil
		end

		seg_i = next_seg_i
	end
	zone()

	--reorder RTL segments on each line separately and concatenate the runs.
	if self.bidi then
		zone'reorder'
		for _,line in ipairs(lines) do
			--UAX#9/L2: reorder segments based on their bidi_level property.
			line.first_vis = reorder_segs(line.first_vis)
		end
		zone()
	end

	local last_line
	for _,line in ipairs(lines) do

		lines.max_ax = max(lines.max_ax, line.advance_x)

		--compute line ascent and descent scaling based on paragraph spacing.
		local ascent_factor = last_line and last_line.spacing or 1
		local descent_factor = line.spacing or 1

		local ax = 0
		local seg = line.first_vis
		while seg do
			--compute line's vertical metrics.
			local run = seg.glyph_run
			line.ascent = max(line.ascent, run.ascent)
			line.descent = min(line.descent, run.descent)
			local run_h = run.ascent - run.descent
			local line_spacing = seg.text_run.line_spacing or 1
			local half_line_gap = run_h * (line_spacing - 1) / 2
			line.spaced_ascent
				= max(line.spaced_ascent,
					(run.ascent + half_line_gap) * ascent_factor)
			line.spaced_descent
				= min(line.spaced_descent,
					(run.descent - half_line_gap) * descent_factor)
			--set segments `x` to be relative to the line's origin.
			seg.x = ax + seg.x
			ax = ax + seg.advance_x
			seg = seg.next_vis
		end

		--compute line's y position relative to first line's baseline.
		if last_line then
			local baseline_h = line.spaced_ascent - last_line.spaced_descent
			line.y = last_line.y + baseline_h
		end
		last_line = line
	end

	local first_line = lines[1]
	if first_line then
		local last_line = lines[#lines]
		--compute the bounding-box height excluding paragraph spacing.
		lines.h =
			first_line.ascent
			+ last_line.y
			- last_line.descent
		--compute the bounding-box height including paragraph spacing.
		lines.spaced_h =
			first_line.spaced_ascent
			+ last_line.y
			- last_line.spaced_descent
		--set the default visible line range.
		lines.last_visible = #lines
	end

	return self
end

function segments:checklines()
	return assert(self.lines, 'Text not laid out')
end

local aligns_x = {left = 'left', center = 'center', right = 'right', auto = 'auto'}
local aligns_y = {top = 'top', center = 'center', bottom = 'bottom'}

local dir_aligns = {
	ltr = 'left', rtl = 'right', on = 'left',
	wltr = 'left', wrtl = 'right'}

function segments:align(x, y, w, h, align_x, align_y)

	local lines = self:checklines()
	align_x = assert(aligns_x[align_x], 'Invalid align_x: %s', align_x)
	align_y = assert(aligns_y[align_y], 'Invalid align_y: %s', align_y)

	w = w or lines.max_ax
	h = h or lines.spaced_h

	lines.min_x = 1/0

	if align_x == 'auto' then
		align_x = dir_aligns[self.base_dir]
	end
	for line_i, line in ipairs(lines) do
		--compute line's aligned x position relative to the textbox origin.
		if align_x == 'right' then
			line.x = w - line.advance_x
		elseif align_x == 'center' then
			line.x = (w - line.advance_x) / 2
		end
		lines.min_x = min(lines.min_x, line.x)
	end

	--compute first line's baseline based on vertical alignment.
	local first_line = lines[1]
	local last_line  = lines[#lines]
	if not first_line then
		lines.baseline = 0
	else
		if align_y == 'top' then
			lines.baseline = first_line.spaced_ascent
		else
			if align_y == 'bottom' then
				lines.baseline = h - (last_line.y - last_line.spaced_descent)
			elseif align_y == 'center' then
				lines.baseline = first_line.spaced_ascent + (h - lines.spaced_h) / 2
			end
		end
	end

	--store textbox's origin, which can be changed anytime after layouting.
	lines.x = x
	lines.y = y

	--store textbox's height to be used for page up/down cursor navigation.
	self.page_h = h

	--store the actual x-alignment for adjusting the caret x-coord.
	lines.align_x = align_x

	if lines.clip_valid then
		--must reset clip on paint() if clip() won't be called until paint().
		lines.clip_valid = false
	end

	return self
end

function segments:layout(x, y, w, h, align_x, align_y)
	return self:wrap(w):align(x, y, w, h, align_x, align_y)
end

function segments:bounding_box()
	local lines = self:checklines()
	local bx = lines.x + lines.min_x
	local bw = lines.max_ax
	local by = lines.y + lines.baseline
		- (lines[1] and lines[1].spaced_ascent or 0)
	local bh = lines.spaced_h
	return bx, by, bw, bh
end

--clipping -------------------------------------------------------------------

--hit-test the lines array for a line number given a relative(!) y-coord.
local function cmp_ys(lines, i, y)
	return lines[i].y - lines[i].spaced_descent < y -- < < [=] = < <
end
local function line_at_y(y, lines)
	if not lines[1] then
		return nil --no lines
	end
	if y < -lines[1].spaced_ascent then
		return 1, 'above' --above first line
	end
	local line_i = binsearch(y, lines, cmp_ys)
	if not line_i then
		return #lines, 'below'
	end
	return line_i
end

--NOTE: doesn't take into account side bearings, so it's not 100% accurate!
function segments:clip(x, y, w, h)
	local lines = self:checklines()
	x = x - lines.x
	y = y - lines.y - lines.baseline
	local first_visible = line_at_y(y, lines) or 1
	local last_visible = line_at_y(y + h - 1/256, lines) or 0
	for line_i = first_visible, last_visible do
		local line = lines[line_i]
		local bx = line.x
		local bw = line.advance_x
		local by = line.y - line.ascent
		local bh = line.ascent - line.descent
		line.visible = box_overlapping(x, y, w, h, bx, by, bw, bh)
		if line.visible then
			local seg = line.first_vis
			while seg do
				local bx = bx + seg.x
				local bw = seg.advance_x
				seg.visible = box_overlapping(x, y, w, h, bx, by, bw, bh)
				seg = seg.next_vis
			end
			first_visible = first_visible or line_i
			last_visible = line_i
		end
	end
	lines.first_visible = first_visible
	lines.last_visible = last_visible
	lines.clip_valid = true
	return self
end

function segments:reset_clip()
	return self:clip(-1/0, -1/0, 1/0, 1/0)
end

function tr:textbox(text_tree, cr, x, y, w, h, align_x, align_y)
	return self
		:shape(text_tree)
		:wrap(w)
		:align(x, y, w, h, align_x, align_y)
		:clip()
		:paint(cr)
end

--painting -------------------------------------------------------------------

--NOTE: clip_left and clip_right are relative to glyph run's origin.
local function paint_glyph_run(cr, rs, run, i, j, ax, ay, clip_left, clip_right)
	for i = i, j do

		local glyph_index = run.info[i].codepoint
		local px = i > 0 and run.pos[i-1].x_advance / 64 or 0
		local ox = run.pos[i].x_offset / 64
		local oy = run.pos[i].y_offset / 64

		local glyph, bmpx, bmpy = rs:glyph(
			run.font, run.font_size, glyph_index,
			ax + px + ox,
			ay - oy
		)

		--make clip_left and clip_right relative to bitmap's left edge.
		clip_left = clip_left and clip_left + ax - bmpx
		clip_right = clip_right and clip_right + ax - bmpx

		rs:paint_glyph(cr, glyph, bmpx, bmpy, clip_left, clip_right)
	end
end

function segments:paint(cr)
	zone'paint'

	local rs = self.tr.rs
	local lines = self:checklines()

	if self.clip_valid == false then
		self:reset_clip()
	end

	for line_i = lines.first_visible, lines.last_visible do
		local line = lines[line_i]
		if line.visible then

			local ax = lines.x + line.x
			local ay = lines.y + lines.baseline + line.y

			local seg = line.first_vis
			while seg do
				if seg.visible then

					local run = seg.glyph_run
					local x, y = ax + seg.x, ay

					if #seg > 0 then --has sub-segments, paint them separately
						for i = 1, #seg, 5 do
							local i, j, text_run, clip_left, clip_right = unpack(seg, i, i + 4)
							rs:setcontext(cr, text_run)
							paint_glyph_run(cr, rs, run, i, j, x, y, clip_left, clip_right)
						end
					else
						rs:setcontext(cr, seg.text_run)
						paint_glyph_run(cr, rs, run, 0, run.len-1, x, y)
					end

				end
				seg = seg.next_vis
			end
		end
	end

	zone()
	return self
end

--cursors --------------------------------------------------------------------

function segments:line_pos(line)
	local lines = self:checklines()
	local line = type(line) == 'table' and line or lines[line]
	local x = lines.x + line.x
	local y = lines.y + lines.baseline + line.y
	return x, y
end

function segments:cursor_x(seg, i) --relative to line_pos().
	local run = seg.glyph_run
	local i = clamp(i, 0, run.text_len)
	return seg.x + run.cursor_xs[i]
end

function segments:cursor_rect(seg, i, w, forward) --relative to line_pos().
	local line = seg.line
	local x = self:cursor_x(seg, i)
	local y = -line.ascent
	local w = (forward ~= false and 1 or -1) * (w or 1)
	local h = line.ascent - line.descent
	if w < 0 then
		x, w = x + w, -w
	end
	return x, y, w, h
end

--iterate all visually-unique cursor positions in visual order.
function segments:cursor_xs()
	return coroutine.wrap(function()
		for line_i, line in ipairs(self.lines) do
			local last_x
			local seg = line.first_vis
			while seg do
				local run = seg.glyph_run
				local i, j, step = 0, run.text_len, 1
				if run.rtl then
					i, j, step = j, i, -step
				end
				for i = i, j, step do
					local x = seg.x + run.cursor_xs[i]
					if x ~= last_x then
						coroutine.yield(line_i, x)
					end
					last_x = x
				end
				seg = seg.next_vis
			end
		end
	end)
end

--next/prev valid cursor position.
function segments:rel_physical_cursor(seg, i, dir, valid, obj, ...)
	dir = dir or 'next'
	repeat
		if dir == 'next' then
			if i >= seg.glyph_run.text_len then
				seg = self[seg.index + 1]
				if not seg then return nil end
				i = 0
			else
				i = i+1
			end
		elseif dir == 'prev' then
			if i <= 0 then
				seg = self[seg.index - 1]
				if not seg then return nil end
				i = seg.glyph_run.text_len
			else
				i = i-1
			end
		else
			assert(false)
		end
	until (not valid or valid(obj, seg, i, ...))
	return seg, i
end

--next/prev cursor position filtered by a is-different-than-other-position
--question and a is-valid-position question.
--`dir` controls which distinct cursor to return. `which` controls which
--non-distinct cursor to return once a distinct cursor was found.
function segments:rel_cursor(seg, i, dir, which, diff, valid, obj, ...)
	dir = dir or 'this' --'next', 'prev', 'this'
	which = which or 'first' --'first', 'last'
	assert(which == 'last' or which == 'first')
	if dir == 'next' or dir == 'prev' then --find prev/next distinct
		::again::
		local seg1, i1 = self:rel_physical_cursor(seg, i, dir, valid, obj, ...)
		if not seg1 then --bos/eos
			return nil
		elseif diff and not diff(obj, seg1, i1, seg, i, ...) then
			seg, i = seg1, i1
			goto again
		elseif which == (dir == 'next' and 'first' or 'last') then --already there
			return seg1, i1
		end
		local last = dir == 'next' and 'last' or 'first'
		return self:rel_cursor(seg1, i1, 'this', last, diff, valid, obj, ...)
	elseif dir == 'this' then --find first/last non-distinct position
		if not diff then
			return seg, i
		end
		local dir = which == 'first' and 'prev' or 'next'
		local seg1, i1 = self:rel_physical_cursor(seg, i, dir, valid, obj, ...)
		if not seg1 then --bos/eos
			return seg, i
		elseif diff(obj, seg1, i1, seg, i, ...) then --distinct position
			return seg, i
		end
		return self:rel_cursor(seg1, i1, 'this', which, diff, valid, obj, ...)
	else
		assert(false)
	end
end

--hit-test the lines array for a line number given an y-coord.
function segments:hit_test_lines(y)
	local lines = self:checklines()
	local y = y - (lines.y + lines.baseline)
	return line_at_y(y, lines)
end

--hit-test a line for a cursor position given a line number and an x-coord.
function segments:hit_test_cursors(line_i, x, diff, valid, obj, ...)
	local lines = self:checklines()
	local line_i = clamp(line_i, 1, #lines)
	local line = lines[line_i]
	--find the cursor position closest to x.
	local x = x - lines.x - line.x
	local min_d = 1/0
	local cseg, ci --closest cursor
	local seg, i = line.first, 0
	local seg0, i0
	while seg do
		local run = seg.glyph_run
		local x = x - seg.x
		local d = math.abs(run.cursor_xs[i] - x)
		if not seg0
			or (d < min_d
				and (not valid or valid(obj, seg, i, ...))
				and (not diff or diff(obj, seg, i, seg0, i0, ...)))
		then
			min_d = d
			cseg, ci = seg, i
		end
		seg0, i0 = seg, i
		i = i + 1
		if i > run.text_len then
			seg = seg.next
			i = 0
		end
	end
	return cseg, ci
end

--hit test the text boundaries.
function segments:hit_test(x, y)
	local lines = self:checklines()
	local y = y - (lines.y + lines.baseline)
	local line_i, outside_y = line_at_y(y, lines)
	if not line_i then
		return false
	end
	local line = lines[line_i]
	local x = x - lines.x - line.x
	if outside_y then
		return false, line_i, outside_y
	elseif x < 0 then
		return false, line_i, 'left'
	elseif x > line.advance_x then
		return false, line_i, 'right'
	else
		return true, line_i
	end
end

local function cmp_offsets(segments, i, offset)
	return segments[i].offset <= offset -- < < = = [<] <
end
function segments:cursor_at_offset(offset)
	local seg_i = (binsearch(offset, self, cmp_offsets) or #self + 1) - 1
	local seg = self[seg_i]
	local run = seg.glyph_run
	local i = offset - seg.offset
	assert(i >= 0)
	local i = min(i, run.text_len) --fix if inside inter-segment gap.
	local i = run.cursor_offsets[i] --normalize to the first cursor.
	return seg, i
end

function segments:offset_at_cursor(seg, i)
	local run = seg.glyph_run
	assert(i >= 0)
	assert(i <= run.text_len)
	return seg.offset + run.cursor_offsets[i]
end

--selection rectangles -------------------------------------------------------

--return the line-relative (x, w) of a selection rectangle on two cursor
--positions in the same segment (in whatever order).
local function segment_xw(seg, i1, i2)
	local run = seg.glyph_run
	local i1 = clamp(i1, 0, run.text_len)
	local i2 = clamp(i2, 0, run.text_len)
	local cx1 = run.cursor_xs[i1]
	local cx2 = run.cursor_xs[i2]
	if cx1 > cx2 then
		cx1, cx2 = cx2, cx1
	end
	return seg.x + cx1, cx2 - cx1
end

--return the selection rectangle of an entire line.
local function line_xywh(line, lines, spaced)
	local ascent, descent
	if spaced then
		ascent, descent = line.spaced_ascent, line.spaced_descent
	else
		ascent, descent = line.ascent, line.descent
	end
	local x = lines.x + line.x
	local y = lines.y + lines.baseline + line.y - ascent
	local w = line.advance_x
	local h = ascent - descent
	return x, y, w, h
end

--merge two (x, w) segments together, if possible.
local function merge_xw(x1, w1, x2, w2)
	if not x1 then --is first
		return x2, w2
	elseif x2 == x1 + w1 then --comes after
		return x1, w1 + w2
	elseif x1 == x2 + w2 then --comes before
		return x2, w1 + w2
	else --not connected
		return x2, w2, true
	end
end

function segments:selection_rectangles(seg1, i1, seg2, i2, spaced, write, obj, ...)
	if seg1.offset > seg2.offset then
		seg1, i1, seg2, i2 = seg2, i2, seg1, i1
	end
	assert(seg1.index <= seg2.index)
	local lines = self.lines
	local seg = seg1
	while seg and seg.index <= seg2.index do
		local line = seg.line
		if line.visible then
			local line_x, line_y, line_w, line_h = line_xywh(line, lines, spaced)
			local x, w
			while seg and seg.index <= seg2.index and seg.line == line do
				local i1 = seg == seg1 and i1 or 0
				local i2 = seg == seg2 and i2 or 1/0
				local x1, w1 = segment_xw(seg, i1, i2)
				local x1, w1, failed = merge_xw(x, w, x1, w1)
				if failed then
					local ret = write(obj, line_x + x, line_y, w, line_h, ...)
					if ret then return ret end
				end
				x, w = x1, w1
				seg = self[seg.index + 1]
			end
			local ret = write(obj, line_x + x, line_y, w, line_h, ...)
			if ret then return ret end
		else
			local next_line = lines[line.index + 1]
			seg = next_line and next_line.first
		end
	end
end

--editing --------------------------------------------------------------------

local text_runs = {}
tr.text_runs_class = text_runs

function text_runs:text_range(i1, i2)
	local len = self.len
	local i1 = clamp(i1 or 0, 0, len)
	local i2 = clamp(i2 or 1/0, 0, len)
	return i1, max(0, i2-i1)
end

function text_runs:string(i1, i2)
	local i, len = self:text_range(i1 or 0, i2 or 1/0)
	return ffi.string(utf8.encode(self.codepoints + i, len))
end

--remove text between two offsets. return offset at removal point.
local function cmp_remove_first(text_runs, i, offset)
	return text_runs[i].offset < offset -- < < [=] = < <
end
local function cmp_remove_last(text_runs, i, offset)
	return text_runs[i].offset + text_runs[i].len <= offset  -- < < = = [<] <
end
function text_runs:remove(i1, i2)

	local i1, len = self:text_range(i1, i2)
	local i2 = i1 + len
	local changed = false

	--reallocate and copy the remaining ends of the codepoints buffer.
	if len > 0 then
		local old_len = self.len
		local old_str = self.codepoints
		local new_len = old_len - len
		local new_str = self.alloc_codepoints(new_len + 1) -- +1 for linebreaks
		ffi.copy(new_str, old_str, i1 * 4)
		ffi.copy(new_str + i1, old_str + i2, (old_len - i2) * 4)
		self.len = new_len
		self.codepoints = new_str
		changed = true
	end

	--adjust/remove affected text runs.
	--NOTE: this includes all zero-length text runs at both ends.

	--1. find the first and last text runs which need to be entirely removed.
	local tr_i1 = binsearch(i1, self, cmp_remove_first) or #self + 1
	local tr_i2 = (binsearch(i2, self, cmp_remove_last) or #self + 1) - 1
	--NOTE: clamping to #self-1 so that the last text run cannot be removed.
	local tr_remove_count = clamp(tr_i2 - tr_i1 + 1, 0, #self-1)

	local offset = 0

	--2. adjust the length of the run before the first run that needs removing.
	if tr_i1 > 1 then
		local run = self[tr_i1-1]
		local part_before_i1 = i1 - run.offset
		local part_after_i2 = max(run.offset + run.len - i2, 0)
		local new_len = part_before_i1 + part_after_i2
		changed = changed or run.len ~= new_len
		run.len = new_len
		offset = run.offset + run.len
	end

	if tr_remove_count > 0 then

		--3. adjust the offset of all runs after the last run that needs removing.
		for tr_i = tr_i2+1, #self do
			self[tr_i].offset = offset
			offset = offset + self[tr_i].len
		end

		--4. remove all text runs that need removing from the text run list.
		shift(self, tr_i1, -tr_remove_count)
		for tr_i = #self, tr_i1 + tr_remove_count, -1 do
			self[tr_i] = nil
		end

		changed = true
	end

	return i1, changed
end

--insert text at offset. return offset after inserted text.
local function cmp_insert(text_runs, i, offset)
	return text_runs[i].offset <= offset -- < < = = [<] <
end
function text_runs:insert(i, s, sz, charset, maxlen)
	sz = sz or #s
	charset = charset or 'utf8'
	if sz <= 0 then return i, false end

	--get the length of the inserted text in codepoints.
	local len
	if charset == 'utf8' then
		maxlen = maxlen and max(0, floor(maxlen))
		len = utf8.decode(s, sz, false, maxlen) or maxlen
	elseif charset == 'utf32' then
		len = sz
	else
		assert(false, 'Invalid charset: %s', charset)
	end
	if len <= 0 then return i, false end

	--reallocate the codepoints buffer and copy over the existing codepoints
	--and copy/convert the new codepoints at the insert point.
	local old_len = self.len
	local old_str = self.codepoints
	local new_len = old_len + len
	local new_str = self.alloc_codepoints(new_len + 1)
	i = clamp(i, 0, old_len)
	ffi.copy(new_str, old_str, i * 4)
	ffi.copy(new_str + i + len, old_str + i, (old_len - i) * 4)
	if charset == 'utf8' then
		utf8.decode(s, sz, new_str + i, len)
	else
		ffi.copy(new_str + i, ffi.cast(const_char_ct, s), len * 4)
	end
	self.len = new_len
	self.codepoints = new_str

	--adjust affected text runs.

	--1. find the text run which needs to be extended to include the new text.
	local tr_i = (binsearch(i, self, cmp_insert) or #self + 1) - 1
	assert(tr_i >= 0)

	--2. adjust the length of that run to include the length of the new text.
	self[tr_i].len = self[tr_i].len + len

	--3. adjust offset for all runs after the extended run.
	for tr_i = tr_i+1, #self do
		self[tr_i].offset = self[tr_i].offset + len
	end

	return i+len, true
end

--editing text from segments which includes reshaping and relayouting.

function segments:reshape()
	self.tr:shape(self.text_runs, self)
	return self
end

function segments:insert(...)
	local offset, changed = self.text_runs:insert(...)
	if changed then
		self:reshape()
	end
	return offset, changed
end

function segments:remove(...)
	local offset, changed = self.text_runs:remove(...)
	if changed then
		self:reshape()
	end
	return offset, changed
end

function segments:replace(i1, i2, ...)
	local i1, removed = self.text_runs:remove(i1, i2)
	local i2, inserted = self.text_runs:insert(i1, ...)
	local changed = removed or inserted
	if changed then
		self:reshape()
	end
	return i2, changed
end

--cursor object --------------------------------------------------------------

local cursor = {}
tr.cursor_class = cursor

--park cursor to home/end if vertical nav goes above/beyond available lines.
cursor.park_home = true
cursor.park_end = true

--jump-through same-text-offset cursors: most text editors remove duplicate
--cursors to keep a 1:1 relationship between text positions and cursor
--positions, which gets funny with BiDi and you also can't tell if there's
--a space at the end of a wrapped line or not.
cursor.unique_offsets = false

--keep a cursor after the last space char on a wrapped line: this cursor can
--be trouble because it is outside the textbox and if there's not enough room
--on the wrap-side of the textbox it can get clipped out.
cursor.wrapped_space = false

cursor.insert_mode = false --full-width caret rect

function segments:cursor(offset)
	if #self == 0 then return end
	self = update({
		tr = self.tr,
		segments = self,
	}, self.tr.cursor_class)
	self:move('offset', offset or 0)
	return self
end

function cursor:changed() end --event stub

function cursor:set(seg, i, x)
	if not seg then return false end
	if not i then --set to another cursor
		local cur = seg
		assert(cur.segments == self.segments)
		seg, i, x = cur.seg, cur.i, cur.x
	end
	local changed = seg ~= self.seg or i ~= self.i
	if changed then
		self.seg, self.i = seg, i
		self:changed()
	end
	if x ~= nil then
		self.x = x
	end
	return changed
end

function cursor:get()
	return self.seg, self.i, self.x
end

function cursor:offset()
	return self.segments:offset_at_cursor(self.seg, self.i)
end

function cursor:rtl()
	return self.seg.glyph_run.rtl
end

function cursor:rect(w)
	--wide caret (spanning two adjacent cursor positions).
	if self.insert_mode then
		local seg1, i1 = self:find('rel_cursor', 'next')
		if seg1 and seg1.line == self.seg.line then
			local x, y, _, h = self.segments:cursor_rect(self.seg, self.i)
			local x1 = self.segments:cursor_rect(seg1, i1)
			local w = x1 - x
			if w < 0 then
				x, w = x + w, -w
			end
			local x0, y0 = self.segments:line_pos(self.seg.line)
			return x0 + x, y0 + y, w, h
		end
	end
	--normal caret, `w`-wide to the left or right of a cursor position.
	local forward =
		not self.seg.glyph_run.rtl
		and self.segments.lines.align_x ~= 'right'
	local x, y, w, h = self.segments:cursor_rect(self.seg, self.i, w, forward)
	local x0, y0 = self.segments:line_pos(self.seg.line)
	return x0 + x, y0 + y, w, h
end

function cursor:valid(seg, i)
	return not (
		not self.wrapped_space
		and seg.wrapped
		and i == seg.glyph_run.len
		and seg.glyph_run.trailing_space
	)
end

function cursor:cmp(seg, i, seg0, i0, mode)
	if not seg0 then
		return true
	end
	local segs = self.segments
	local mode = mode or 'pos'
	if mode == 'pos' and self.unique_offsets then
		mode = 'char'
	end
	if mode == 'pos' then
		return
			seg.line ~= seg0.line
			or segs:cursor_x(seg, i) ~= segs:cursor_x(seg0, i0)
			or segs:offset_at_cursor(seg, i) ~= segs:offset_at_cursor(seg0, i0)
	elseif mode == 'char' then
		return segs:offset_at_cursor(seg, i) ~= segs:offset_at_cursor(seg0, i0)
	elseif mode == 'word' then
		return seg ~= seg0
	elseif mode == 'line' then
		return seg.line_num ~= seg0.line_num
	else
		assert(false)
	end
end

function cursor:find(what, ...)
	if what == 'offset' then
		local offset, which = ...
		local seg, i = self.segments:cursor_at_offset(offset)
		if which then
			return self:find('cursor', seg, i, 'this', 'char', which)
		else
			return seg, i
		end
	elseif what == 'cursor' then
		local seg, i, dir, mode, which, clamp = ...
		local seg, i = self.segments:rel_cursor(seg, i, dir, which,
			self.cmp, self.valid, self, mode)
		if not seg and clamp then
			local last = dir == 'next' or (dir == 'this' and which == 'last')
			return self:find('offset', last and 1/0 or 0)
		end
		return seg, i
	elseif what == 'rel_cursor' then
		return self:find('cursor', self.seg, self.i, ...)
	elseif what == 'line' then
		local line_i, x = ...
		x = x or self.x
		if line_i < 1 and self.park_home then
			return self:find('offset', 0)
		elseif line_i > #self.segments.lines and self.park_end then
			return self:find('offset', 1/0)
		end
		return self.segments:hit_test_cursors(line_i, x,
			self.cmp, self.valid, self)
	elseif what == 'rel_line' then
		local delta_lines, x = ...
		local line_i = self.seg.line.index + (delta_lines or 0)
		return self:find('line', line_i, x)
	elseif what == 'pos' then
		local x, y = ...
		local line_i = self.segments:hit_test_lines(y)
		return self:find('line', line_i, x)
	elseif what == 'page' then
		local page, x = ...
		local _, line1_y = self.segments:line_pos(1)
		local y = line1_y + (page - 1) * self.segments.page_h
		return self:find('pos', x, y)
	elseif what == 'rel_page' then
		local delta_pages, x = ...
		local _, line_y = self.segments:line_pos(self.seg.line)
		local y = line_y + (delta_pages or 0) * self.segments.page_h
		return self:find('pos', x, y)
	else
		assert(false, 'invalid arg#1: "%s"', what)
	end
end

function cursor:move(what, ...)
	local vertical =
		what == 'line' or what == 'rel_line'
		or what == 'page' or what == 'rel_page'
	self.x = vertical and (self.x or self:rect()) or false
	local seg, i = self:find(what, ...)
	return self:set(seg, i)
end

function cursor:insert(...) --insert text at cursor.
	local offset = self.seg.offset + self.i
	local offset, changed = self.segments:insert(offset, ...)
	if changed then
		self:move('offset', offset, 'first')
	end
	return changed
end

function cursor:remove(delta) --remove delta cursor positions of text.
	local i1 = self.seg.offset + self.i
	local i2 = self:next_cursor(delta, 'char')
	local offset, changed = self.segments:remove(i1, i2)
	if changed then
		self:move('offset', offset)
	end
	return changed
end

--selection object -----------------------------------------------------------

local selection = {}
tr.selection_class = selection

function selection:changed(cursor) end --event stub

function segments:selection(offset1, offset2)
	if #self == 0 then return end
	self = update({
		tr = self.tr,
		segments = self,
		cursor1 = self:cursor(offset1),
		cursor2 = self:cursor(offset2),
	}, self.tr.selection_class)
	function self.cursor1.changed(cursor)
		self:changed(cursor)
	end
	self.cursor2.changed = self.cursor1.changed
	return self
end

function selection:offsets()
	local c1 = self.cursor1
	local c2 = self.cursor2
	local o1 = c1.seg.offset + c1.i
	local o2 = c2.seg.offset + c2.i
	return min(o1, o2), max(o1, o2), o1 < o2
end

function selection:cursors()
	local c1 = self.cursor1
	local c2 = self.cursor2
	local o1 = c1.seg.offset + c1.i
	local o2 = c2.seg.offset + c2.i
	local fw = o1 < o2
	if fw then
		return c1, c2, fw
	else
		return c2, c1, fw
	end
end

function selection:empty()
	local o1, o2 = self:offsets()
	return o1 == o2
end

--selecting

function selection:select_all()
	local changed1 = self.cursor1:move('offset', 0)
	local changed2 = self.cursor2:move('offset', 1/0)
	return changed1 or changed2
end

function selection:reset()
	return self.cursor1:set(self.cursor2)
end

function selection:select_word()
	local changed1 = self.cursor1:move('rel_cursor', 'this', 'word')
	local changed2 = self.cursor2:move('rel_cursor', 'this', 'word', 'last', true)
	return changed1 or changed2
end

function selection:select_line()
	local changed1 = self.cursor1:move('rel_cursor', 'this', 'line', nil, true)
	local changed2 = self.cursor2:move('rel_cursor', 'next', 'line', nil, true)
	return changed1 or changed2
end

--drawing & hit-testing

function selection:rectangles(...)
	local c1, c2 = self:cursors()
	return self.segments:selection_rectangles(
		c1.seg, c1.i,
		c2.seg, c2.i,
		false, ...)
end

function selection:hit_rectangles(...)
	local c1, c2 = self:cursors()
	return self.segments:selection_rectangles(
		c1.seg, c1.i,
		c2.seg, c2.i,
		true, ...)
end

local function hit_test_rect(x, y, w, h, mx, my)
	return box_hit(mx, my, x, y, w, h)
end
function selection:hit_test(x, y)
	if self:empty() then return false end
	return self:hit_rectangles(hit_test_rect, x, y) or false
end

--editing

function selection:codepoints()
	local offset1, offset2 = self:offsets()
	local i, len = self.segments.text_runs:text_range(offset1, offset2)
	return self.segments.text_runs.codepoints, i, len
end

function selection:string()
	local offset1, offset2 = self:offsets()
	return self.segments.text_runs:string(offset1, offset2)
end

function selection:remove() --remove selected text.
	if self:empty() then return false end
	local offset1, offset2 = self:offsets()
	local offset, changed = self.segments:remove(offset1, offset2)
	if changed then
		local c1, c2 = self:cursors()
		--same offset, but we need to reset c1.seg!
		c1:move('offset', offset, 'first')
		c2:set(c1)
	end
	return changed
end

function selection:replace(...) --replace selection with text.
	local removed = self:remove()
	local c1, c2 = self:cursors()
	local inserted = c1:insert(...)
	c2:set(c1)
	return removed or inserted
end

return tr
