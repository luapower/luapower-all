--[[

	Itemizing rich text into an array of segments and shaping them.

	Itemization deals with breaking down the text into the largest pieces that
	have enough relevant properties in common to be shaped as a unit, but are
	also the smallest pieces that are allowed to be word-wrapped.

	Script and language detection and BiDi level analysis is also included here.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_rle'
require'terra/tr_shape'
require'terra/tr_font'

require'terra/tr_itemize_detect_script'
require'terra/tr_itemize_detect_lang'

local MAX_WORD_LEN = 127

local PS = FRIBIDI_CHAR_PS --paragraph separator codepoint
local LS = FRIBIDI_CHAR_LS --line separator codepoint

local terra isnewline(c: codepoint)
	return
		(c >= 10 and c <= 13) --LF, VT, FF, CR
		or c == PS
		or c == LS
		or c == 0x85 --NEL
end

--Is explicit or BN or WS: LRE, RLE, LRO, RLO, PDF, BN, WS?
local FRIBIDI_IS_EXPLICIT_OR_BN_OR_WS = macro(function(p)
	return `(p and (FRIBIDI_MASK_EXPLICIT or FRIBIDI_MASK_BN or FRIBIDI_MASK_WS)) ~= 0
end)

do --iterate text segments with the same language.

	local lang1 = symbol(hb_language_t)
	local lang0 = symbol(hb_language_t)

	local langs_iter = rle_iterator{
		state_t = arrview(hb_language_t),
		for_variables = {lang0},
		declare_variables = function()        return quote var [lang1], [lang0] end end,
		save_values       = function()        return quote lang0 = lang1 end end,
		load_values       = function(self, i) return quote lang1 = self(i) end end,
		values_different  = function()        return `lang0 ~= lang1 end,
	}

	Renderer.methods.lang_spans = macro(function(self, len)
		return `langs_iter{self.langs.view, 0, len}
	end)

end

do --iterate paragraphs (empty paragraphs are kept separate).

	local c0 = symbol(codepoint)
	local c1 = symbol(codepoint)

	local para_iter = rle_iterator{
		state_t = &Layout,
		for_variables = {},
		declare_variables = function()        return quote var [c0], [c1] end end,
		save_values       = function()        return quote c0 = c1 end end,
		load_values       = function(self, i) return quote c1 = self.text(i) end end,
		values_different  = function()        return `c0 == PS end,
	}

	Layout.methods.paragraphs = macro(function(self)
		return `para_iter{&self, 0, self.text.len}
	end)

end

do --iterate text segments having the same shaping-relevant properties.

	local word_iter_state = struct {
		layout: &Layout;
		text: arrview(codepoint);
		levels: arrview(FriBidiLevel);
		scripts: arrview(hb_script_t);
		langs: arrview(hb_language_t);
		linebreaks: arrview(char);
	}

	local iter = {state_t = word_iter_state}

	local span_eof   = symbol(int) --offset of next span
	local span_diff  = symbol(bool)
	local span_i1    = symbol(int)
	local span0      = symbol(&Span)
	local span1      = symbol(&Span)
	local level0     = symbol(FriBidiLevel)
	local level1     = symbol(FriBidiLevel)
	local script0    = symbol(hb_script_t)
	local script1    = symbol(hb_script_t)
	local lang0      = symbol(hb_language_t)
	local lang1      = symbol(hb_language_t)

	iter.for_variables = {span0, level0, script0, lang0}

	iter.declare_variables = function(self)
		return quote
			var [span_i1] = -1
			var [span_eof] = 0 --load the first span on the first iteration.
			var [span_diff] = false
			var [span0], [level0], [script0], [lang0]
			var [span1], [level1], [script1], [lang1]
			span0 = nil
		end
	end

	iter.save_values = function()
		return quote
			span0, level0, script0, lang0 =
			span1, level1, script1, lang1
		end
	end

	iter.load_values = function(self, i)
		return quote
			level1  = self.levels(i)
			script1 = self.scripts(i)
			lang1   = self.langs(i)
			if i == span_eof then --time to load a new span
				inc(span_i1)
				span_eof = self.layout:span_end_offset(span_i1)
				span1 = self.layout.spans:at(span_i1)
				span_diff = span0 == nil
					or span1.font_id         ~= span0.font_id
					or span1.font_size_16_6  ~= span0.font_size_16_6
					or span1.features        ~= span0.features
					or span1.baseline        ~= span0.baseline
			else
				span_diff = false
			end
		end
	end

	iter.values_different = function(self, i)
		return `
			span_diff
			or self.linebreaks(i-1) <= LINEBREAK_ALLOWBREAK
			or level1  ~= level0
			or script1 ~= script0
			or lang1   ~= lang0
			or between(self.text(i-1), EMBED_MIN, EMBED_MAX) --before embed
			or between(self.text(i  ), EMBED_MIN, EMBED_MAX)  --after embed
	end

	local word_iter = rle_iterator(iter)

	Layout.methods.word_spans = macro(function(self, levels, scripts, langs, linebreaks)
		return `word_iter{
			word_iter_state{
				layout = &self,
				text = self.text.view,
				levels = levels,
				scripts = scripts,
				langs = langs,
				linebreaks = linebreaks
			}, 0, self.text.len}
	end)

end

--for harfbuzz, language is a BCP 47 language code + country code,
--but libunibreak only uses the language code part for a few languages.

local HB_LANGUAGE_EN = global(hb_language_t)
local HB_LANGUAGE_DE = global(hb_language_t)
local HB_LANGUAGE_ES = global(hb_language_t)
local HB_LANGUAGE_FR = global(hb_language_t)
local HB_LANGUAGE_RU = global(hb_language_t)
local HB_LANGUAGE_ZH = global(hb_language_t)

terra init_ub_lang()
	HB_LANGUAGE_EN = hb_language_from_string('en', 2)
	HB_LANGUAGE_DE = hb_language_from_string('de', 2)
	HB_LANGUAGE_ES = hb_language_from_string('es', 2)
	HB_LANGUAGE_FR = hb_language_from_string('fr', 2)
	HB_LANGUAGE_RU = hb_language_from_string('ru', 2)
	HB_LANGUAGE_ZH = hb_language_from_string('zh', 2)
end

terra ub_lang(hb_lang: hb_language_t): rawstring
	    if hb_lang == HB_LANGUAGE_EN then return 'en'
	elseif hb_lang == HB_LANGUAGE_DE then return 'de'
	elseif hb_lang == HB_LANGUAGE_ES then return 'es'
	elseif hb_lang == HB_LANGUAGE_FR then return 'fr'
	elseif hb_lang == HB_LANGUAGE_RU then return 'ru'
	elseif hb_lang == HB_LANGUAGE_ZH then return 'zh'
	else return nil end
end

--search for a following span that covers a certain text position.
terra Layout:_span_index_at_offset_after_span(offset: int, i0: int)
	for i = i0 + 1, self.spans.len do
		if self.spans:at(i).offset > offset then
			return i-1
		end
	end
	return self.spans.len-1
end

--the span that starts exactly where the paragraph starts can
--set the paragraph base direction otherwise the layout's dir is used.
terra Layout:_span_dir(span: &Span, paragraph_offset: int)
	return iif(span.offset == paragraph_offset and span.paragraph_dir ~= 0,
		span.paragraph_dir, self.dir)
end

local terra to_fribidi_dir(dir: enum): FriBidiParType
	if dir == DIR_AUTO then return FRIBIDI_PAR_ON   end
	if dir == DIR_LTR  then return FRIBIDI_PAR_LTR  end
	if dir == DIR_RTL  then return FRIBIDI_PAR_RTL  end
	if dir == DIR_WLTR then return FRIBIDI_PAR_WLTR end
	if dir == DIR_WRTL then return FRIBIDI_PAR_WRTL end
	assert(false)
end

local terra from_fribidi_dir(dir: FriBidiParType): enum
	if dir == FRIBIDI_PAR_ON   then return DIR_AUTO end
	if dir == FRIBIDI_PAR_LTR  then return DIR_LTR  end
	if dir == FRIBIDI_PAR_RTL  then return DIR_RTL  end
	if dir == FRIBIDI_PAR_WLTR then return DIR_WLTR end
	if dir == FRIBIDI_PAR_WRTL then return DIR_WRTL end
	assert(false)
end

terra Layout:shape()

	var r = self.r
	var segs = &self.segs

	--reset output
	segs.len = 0
	self.lines.len = 0

	--special-case empty text: we still want to set valid shaping output
	--in order to properly display a cursor.
	if self.text.len == 0 then
		self.bidi = self.dir == DIR_RTL or self.dir == DIR_WRTL
		return
	end

	--script and language detection and assignment
	r.scripts.len = self.text.len
	r.langs.len = self.text.len

	--script/lang detection is expensive: see if we can avoid it.
	var do_detect_scripts = false
	var do_detect_langs = false
	for i, span in self.spans do
		if span.script == HB_SCRIPT_INVALID then do_detect_scripts = true end
		if span.lang == nil then do_detect_langs = true end
		if do_detect_scripts and do_detect_langs then break end
	end

	--detect the script property for each char of the entire text.
	if do_detect_scripts then
		detect_scripts(r, self.text.elements, self.text.len, r.scripts.elements)
	end

	--override scripts with user-provided values.
	for span_index, span in self.spans do
		if span.script ~= HB_SCRIPT_INVALID then
			for i = span.offset, self:span_end_offset(span_index) do
				r.scripts:set(i, span.script)
			end
		end
	end

	--detect the lang property based on the script property.
	if do_detect_langs then
		for i = 0, self.text.len do
			r.langs:set(i, lang_for_script(r.scripts(i)))
		end
	end

	--override langs with user-provided values.
	for span_index, span in self.spans do
		if span.lang ~= nil then
			for i = span.offset, self:span_end_offset(span_index) do
				r.langs:set(i, span.lang)
			end
		end
	end

	--Split text into paragraphs and run fribidi over each paragraph as follows:
	--Skip mirroring since harfbuzz also does that.
	--Skip arabic shaping since harfbuzz does that better with font assistance.
	--Skip RTL reordering because 1) fribidi also reverses the _contents_ of
	--the RTL runs, which harfbuzz also does, and 2) because bidi reordering
	--needs to be done after line breaking and so it's part of layouting.

	r.bidi_types    .len = self.text.len
	r.bracket_types .len = self.text.len
	r.levels        .len = self.text.len

	self.bidi = false --is bidi reordering needed on line-wrapping or not?
	r.paragraph_dirs.len = 0

	var span_index = 0
	for offset, len in self:paragraphs() do
		var str = self.text:at(offset)

		span_index = self:_span_index_at_offset_after_span(offset, span_index)
		var span = self.spans:at(span_index)
		var dir = self:_span_dir(span, offset)
		var fb_dir = to_fribidi_dir(dir)

		fribidi_get_bidi_types(str, len, r.bidi_types:at(offset))

		fribidi_get_bracket_types(str, len,
			r.bidi_types:at(offset),
			r.bracket_types:at(offset))

		var max_bidi_level = fribidi_get_par_embedding_levels_ex(
			r.bidi_types:at(offset),
			r.bracket_types:at(offset),
			len,
			&fb_dir,
			r.levels:at(offset)) - 1

		assert(max_bidi_level >= 0)

		dir = from_fribidi_dir(fb_dir)
		self.bidi = self.bidi
			or max_bidi_level > 0 --mixed direction
			or dir == DIR_RTL or dir == DIR_WRTL --needs reversing

		r.paragraph_dirs:add(dir)
	end

	--Run Unicode line breaking over each span of text with the same language.
	--NOTE: libunibreak always puts a hard break at the end of the text.
	--We don't want that so we're passing it one codepoint beyond length.

	var len0 = self.text.len
	self.text.len = len0 + 1
	self.text:set(len0, @('.'))
	r.linebreaks.len = len0 + 1
	for offset, len, lang in r:lang_spans(len0) do
		self.text:at(offset + len) --upper-boundary check
		set_linebreaks_utf32(self.text:at(offset), len + 1,
			ub_lang(lang), r.linebreaks:at(offset))
	end
	self.text.len = len0
	r.linebreaks.len = len0

	--Insert artificial soft line breaks on words that are too long.
	var n = 0
	for i, code in r.linebreaks do
		n = iif(@code <= LINEBREAK_ALLOWBREAK, 0, n + 1)
		if n >= MAX_WORD_LEN then
			r.linebreaks:set(i, LINEBREAK_ALLOWBREAK)
		end
	end

	--Split the text into segs of characters with the same properties,
	--shape the segs individually and cache the shaped results.
	--The splitting is two-level: each text seg that requires separate
	--shaping can contain sub-segs that require separate styling.
	--NOTE: Empty segs array is valid.

	var line_num = 0
	var para_num = 0
	var para_dir = r.paragraph_dirs(0)

	for offset, len, span, level, script, lang in self:word_spans(
		r.levels.view,
		r.scripts.view,
		r.langs.view,
		r.linebreaks.view
	) do

		var last_cp = self.text(offset + len - 1)
		var linebreak_code = r.linebreaks(offset + len - 1)
		var linebreak =
			iif(linebreak_code == LINEBREAK_MUSTBREAK,
				iif(last_cp == PS, BREAK_PARA, BREAK_LINE),
				iif(linebreak_code == LINEBREAK_ALLOWBREAK
						or between(last_cp, EMBED_MIN, EMBED_MAX),
					BREAK_WRAP,
					BREAK_NONE))

		--find the seg length without trailing linebreak chars.
		--this can result in a zero-length segment which is fine.
		while isnewline(last_cp) do
			dec(len)
			if len == 0 then
				last_cp = 0
				break
			end
			last_cp = self.text(offset + len - 1)
		end

		--find if the seg has a trailing space char (before any linebreak chars).
		var trailing_space = len > 0
			and FRIBIDI_IS_EXPLICIT_OR_BN_OR_WS(r.bidi_types(offset + len - 1))

		var seg = segs:add()
		seg.line_num = line_num --physical line number (for code editors)
		seg.linebreak = linebreak
		seg.bidi_level = level --for bidi reordering
		seg.paragraph_dir = para_dir --for ALIGN_START|_END
		--for cursor positioning
		seg.span = span --span of the first sub-seg
		seg.offset = offset
		--slots filled by layouting
		seg.x = 0; seg.advance_x = 0 --seg's x-axis boundaries
		seg.next_vis = nil --next seg on the same line in visual order
		seg.wrapped = false --seg is the last on a wrapped line
		seg.visible = true --seg is not entirely clipped
		seg.subsegs:init()

		if linebreak >= BREAK_LINE then
			inc(line_num)
			if linebreak == BREAK_PARA then
				inc(para_num)
				para_dir = r.paragraph_dirs(para_num)
			end
		end

		if between(last_cp, EMBED_MIN, EMBED_MAX) then
			var embed_index = last_cp - EMBED_MIN
			seg.embed_index = embed_index
		else
			--shape the seg excluding trailing linebreak chars.
			var run_key = GlyphRun {
				--cache key
				text            = arr(codepoint);
				features        = span.features;
				lang            = lang;
				script          = script;
				font_id         = span.font_id;
				font_face_index = span.font_face_index;
				font_size_16_6  = span.font_size_16_6;
				rtl             = isodd(level);
				--info for shaping a new glyph run
				trailing_space  = trailing_space;
			}
			run_key.text.view = self.text:sub(offset, offset + len)
			--^^fake a dynarray to avoid copying.
			var glyph_run_id, run = r:shape(run_key, span.face)
			assert(glyph_run_id >= 0)
			seg.glyph_run_id = glyph_run_id
			self:create_subsegs(seg, run, span)
		end

	end

end

--find the glyph index that totally or partially represents the grapheme at
--an offset; also say whether the glyph contains anything before the grapheme
--in logical text direction, so that the glyph must be clipped (on the left
--side for LTR text and on the right side for RTL text).
terra GlyphRun:glyph_index_at_offset(offset: int)
	var last_i = iif(self.rtl, 0, self.glyphs.len-1)
	for i,g in self.glyphs:ipairs(not self.rtl) do
		if g.cluster == offset then
			return i, false
		elseif g.cluster > offset then
			return i - iif(self.rtl, -1, 1), true --previous glyph
		elseif i == last_i then
			if offset < self.text.len then
				return i, true
			else
				return i + iif(self.rtl, -1, 1), false --non-existent next glyph
			end
		end
	end
end

terra Layout:create_subsegs(seg: &Seg, run: &GlyphRun, span: &Span)
	var bof = seg.offset
	var eof = bof + run.text.len
	var next_span = self.spans:next(span, nil)
	if next_span == nil or next_span.offset >= eof then
		return --this segment is only covered by one span.
	end
	while true do
		var next_offset = iif(next_span ~= nil, next_span.offset, maxint)
		var o1 = max(span.offset, bof) - bof
		var o2 = min(next_offset, eof) - bof
		--adjust the offsets to grapheme positions.
		o1 = run.cursors.offsets(o1)
		o2 = run.cursors.offsets(o2)
		--find the relative clip x-coords at those offsets.
		var x1 = run.cursors.xs(o1)
		var x2 = run.cursors.xs(o2)
		x1, x2 = minmax(x1, x2)
		--find the glyph range covering o1..o2 and which sides need clipping.
		var i1, clip1 = run:glyph_index_at_offset(o1)
		var i2, clip2 = run:glyph_index_at_offset(o2)
		if clip2 then
			--if the glyph at o2 must be clipped, include it in the iteration
			--so that the part of the glyph up-until o2 can be displayed.
			inc(i2, iif(run.rtl, -1, 1))
		end
		if run.rtl then
			--reverse decreasing iteration range i1..i2 to an increasing range.
			inc(i1)
			inc(i2)
			swap(i1, i2)
			swap(clip1, clip2)
		end
		seg.subsegs:add(SubSeg {
			span = span,
			glyph_index1 = i1,
			glyph_index2 = i2,
			x1 = x1,
			x2 = x2,
			clip_left  = clip1,
			clip_right = clip2,
		})
		if next_offset >= eof then
			break
		end
		span = next_span
		next_span = self.spans:next(span, nil)
	end
end

