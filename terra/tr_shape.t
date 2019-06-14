
--Shaping rich text into an array of segments.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_shape_word'
require'terra/tr_rle'

local detect_scripts  = require'terra/tr_shape_detect_script'
local lang_for_script = require'terra/tr_shape_detect_lang'

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

--iterate text segments with the same language.

local lang1 = symbol(hb_language_t)
local lang0 = symbol(hb_language_t)

local langs_iter = rle_iterator{
	state = &arr(hb_language_t),
	for_variables = {lang0},
	declare_variables = function()        return quote var [lang1], [lang0] end end,
	save_values       = function()        return quote lang0 = lang1 end end,
	load_values       = function(self, i) return quote lang1 = self(i) end end,
	values_different  = function()        return `lang0 ~= lang1 end,
}

Renderer.methods.lang_spans = macro(function(self, len)
	return `langs_iter{&self.langs, 0, len}
end)

--iterate paragraphs (empty paragraphs are kept separate).

local c0 = symbol(codepoint)
local c1 = symbol(codepoint)

local para_iter = rle_iterator{
	state = &Layout,
	for_variables = {},
	declare_variables = function()        return quote var [c0], [c1] end end,
	save_values       = function()        return quote c0 = c1 end end,
	load_values       = function(self, i) return quote c1 = self.text.elements[i] end end,
	values_different  = function()        return `c0 == PS end,
}

Layout.methods.paragraphs = macro(function(self)
	return `para_iter{&self, 0, self.text.len}
end)

--iterate text segments having the same shaping-relevant properties.

local word_iter_state = struct {
	layout: &Layout;
	levels: &FriBidiLevel;
	scripts: &hb_script_t;
	langs: &hb_language_t;
	linebreaks: &char;
}

local iter = {state = word_iter_state}

local span_index = symbol(int)
local span_eof   = symbol(int)
local span_diff  = symbol(bool)
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
		var [span_index] = -1
		var [span_eof] = 0
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
		level1     = self.levels[i]
		script1    = self.scripts[i]
		lang1      = self.langs[i]
		if i >= span_eof then --time to load a new text run
			inc(span_index)
			span_eof = self.layout:eof(span_index)
			span1 = self.layout.spans:at(span_index)
			span_diff = span0 == nil
				or span1.font_id         ~= span0.font_id
				or span1.font_size_16_6  ~= span0.font_size_16_6
				or span1.features        ~= span0.features
		else
			span_diff = false
		end
	end
end

iter.values_different = function(self, i)
	return `
		span_diff
		or self.linebreaks[i-1] < 2 --0: required, 1: allowed, 2: not allowed
		or level1  ~= level0
		or script1 ~= script0
		or lang1   ~= lang0
end

local word_iter = rle_iterator(iter)

Layout.methods.word_spans = macro(function(self, levels, scripts, langs, linebreaks)
	return `word_iter{
		word_iter_state{
			layout = &self,
			levels = levels,
			scripts = scripts,
			langs = langs,
			linebreaks = linebreaks
		}, 0, self.text.len}
end)

--search for the text run that is spanning over a specific text position.

terra Layout:span_index_at_offset(offset: int, i0: int)
	for i = i0 + 1, self.spans.len do
		if self.spans:at(i).offset > offset then
			return i-1
		end
	end
	return self.spans.len-1
end

--for harfbuzz, language is a IETF BCP 47 language code + country code,
--but libunibreak only uses the language code part for a few languages.

terra Renderer:init_ub_lang()
	self.HB_LANGUAGE_EN = hb_language_from_string('en', 2)
	self.HB_LANGUAGE_DE = hb_language_from_string('de', 2)
	self.HB_LANGUAGE_ES = hb_language_from_string('es', 2)
	self.HB_LANGUAGE_FR = hb_language_from_string('fr', 2)
	self.HB_LANGUAGE_RU = hb_language_from_string('ru', 2)
	self.HB_LANGUAGE_ZH = hb_language_from_string('zh', 2)
end

terra Renderer:ub_lang(hb_lang: hb_language_t): rawstring
	    if hb_lang == self.HB_LANGUAGE_EN then return 'en'
	elseif hb_lang == self.HB_LANGUAGE_DE then return 'de'
	elseif hb_lang == self.HB_LANGUAGE_ES then return 'es'
	elseif hb_lang == self.HB_LANGUAGE_FR then return 'fr'
	elseif hb_lang == self.HB_LANGUAGE_RU then return 'ru'
	elseif hb_lang == self.HB_LANGUAGE_ZH then return 'zh'
	else return nil end
end

terra Layout:shape()

	var r = self.r
	var segs = &self.segs
	segs.len = 0
	self.lines.len = 0
	self._min_w = -inf
	self._max_w =  inf
	if self.spans.len == 0 then
		return
	end

	var str = self.text.elements
	var len = self.text.len

	--script and language detection and assignment
	r.scripts.len = len
	r.langs.len = len

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
		detect_scripts(r, str, len, r.scripts.elements)
	end

	--override scripts with user-provided values.
	for span_index, span in self.spans do
		if span.script ~= HB_SCRIPT_INVALID then
			for i = span.offset, self:eof(span_index) do
				r.scripts.elements[i] = span.script
			end
		end
	end

	--detect the lang property based on the script property.
	if do_detect_langs then
		for i = 0, len do
			r.langs.elements[i] = lang_for_script(r.scripts.elements[i])
		end
	end

	--override langs with user-provided values.
	for span_index, span in self.spans do
		if span.lang ~= nil then
			for i = span.offset, self:eof(span_index) do
				r.langs.elements[i] = span.lang
			end
		end
	end

	--Split text into paragraphs and run fribidi over each paragraph as follows:
	--Skip mirroring since harfbuzz also does that.
	--Skip arabic shaping since harfbuzz does that better with font assistance.
	--Skip RTL reordering because 1) fribidi also reverses the _contents_ of
	--the RTL runs, which harfbuzz also does, and 2) because bidi reordering
	--needs to be done after line breaking and so it's part of layouting.

	r.bidi_types    .len = len
	r.bracket_types .len = len
	r.levels        .len = len

	self.bidi = false --is bidi reordering needed on line-wrapping or not?
	self.base_dir = DIR_AUTO --bidi direction of the first paragraph of the text.

	var span_index = 0
	var paragraphs = self:paragraphs()
	for offset, len in paragraphs do
		var str = str + offset

		span_index = self:span_index_at_offset(offset, span_index)
		var span = self.spans:at(span_index)

		--the span that starts exactly where the paragraph starts can set
		--the paragraph base direction, otherwise it is auto-detected.
		var dir = iif(span.offset == offset, span.dir, DIR_AUTO)

		fribidi_get_bidi_types(str, len, r.bidi_types:at(offset))

		fribidi_get_bracket_types(str, len,
			r.bidi_types:at(offset),
			r.bracket_types:at(offset))

		var max_bidi_level = fribidi_get_par_embedding_levels_ex(
			r.bidi_types:at(offset),
			r.bracket_types:at(offset),
			len,
			&dir,
			r.levels:at(offset)) - 1

		assert(max_bidi_level >= 0)

		self.bidi = self.bidi
			or max_bidi_level > iif(dir == DIR_RTL, 1, 0)

		if self.base_dir == 0 then --take the dir of the first paragraph
			self.base_dir = dir
		end
	end

	--Run Unicode line breaking over each span of text with the same language.
	--NOTE: libunibreak always puts a hard break at the end of the text.
	--We don't want that so we're passing it one more codepoint than needed.

	r.linebreaks.len = len + 1
	var lang_spans = r:lang_spans(len)
	for offset, len, lang in lang_spans do
		set_linebreaks_utf32(str + offset, len + 1,
			r:ub_lang(lang), r.linebreaks:at(offset))
	end

	--Split the text into segs of characters with the same properties,
	--shape the segs individually and cache the shaped results.
	--The splitting is two-level: each text seg that requires separate
	--shaping can contain sub-segs that require separate styling.
	--NOTE: Empty segs (len=0) are valid.

	var line_num = 0

	var word_spans = self:word_spans(
		r.levels.elements,
		r.scripts.elements,
		r.langs.elements,
		r.linebreaks.elements
	)
	for offset, len, span, level, script, lang in word_spans do
		var str = str+offset

		--UBA codes: 0: required, 1: allowed, 2: not allowed.
		var linebreak_code = r.linebreaks(offset+len-1)
		--user codes: 2: paragraph, 1: line, 0: softbreak.
		var linebreak = iif(linebreak_code == 0,
			iif(str[len-1] == PS, BREAK_PARA, BREAK_LINE), BREAK_NONE)

		if linebreak ~= BREAK_NONE then
			inc(line_num)
		end

		--find the seg length without trailing linebreak chars.
		while len > 0 and isnewline(str[len-1]) do
			dec(len)
		end

		--find if the seg has a trailing space char (before any linebreak chars).
		var trailing_space = len > 0
			and FRIBIDI_IS_EXPLICIT_OR_BN_OR_WS(r.bidi_types(offset+len-1))

		--shape the seg excluding trailing linebreak chars.
		var gr = GlyphRun {
			--cache key
			text            = arr(codepoint);
			features        = span.features;
			lang            = lang;
			script          = script;
			font_id         = span.font_id;
			font_size_16_6  = span.font_size_16_6;
			rtl             = isodd(level);
			--info for shaping a new glyph run
			trailing_space  = trailing_space;
		}
		gr.text.view = arrview(str, len) --fake a dynarray to avoid copying
		var glyph_run_id, glyph_run = r:shape_word(gr)

		if glyph_run ~= nil then --font loaded successfully
			var seg = segs:add()
			seg.glyph_run_id = glyph_run_id
			seg.line_num = line_num --physical line number (for code editors)
			seg.linebreak = linebreak --means this segment _ends_ a line
			seg.bidi_level = level --for bidi reordering
			--for cursor positioning
			seg.span = span --span of the first sub-seg
			seg.offset = offset
			--slots filled by layouting
			seg.x = 0; seg.advance_x = 0 --seg's x-axis boundaries
			seg.next = nil --next seg on the same line in text order
			seg.next_vis = nil --next seg on the same line in visual order
			seg.wrapped = false --seg is the last on a wrapped line
			seg.visible = true --seg is not entirely clipped
			seg.subsegs:init()
		end

	end

end
