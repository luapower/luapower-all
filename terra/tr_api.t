--[[

	Text rendering API for C, Terra and LuaJIT ffi use.

	- self-allocating constructors.
	- fatal and non-fatal error checking and reporting.
	- validation and clamping of enums, indices, counts, sizes, offsets, etc.
	- state invalidation when changing input values.
	- state checking when accessing computed values.
	- utf8 text input and output.
	- text representation for features, lang, script.
	- checking if a span property has the same value across an offset range.
	- updating span properties on an offset range with removing duplicate spans.
	- inserting and removing text at an offset with adjusting span offsets.
	- text navigation, selection and editing through cursor objects.

	- using consecutive enum values for forward ABI compatibility.
	- using enlarged number types for forward ABI compat. and clamping inf/-inf.
	- renaming functions and types to C conventions for C use.
	- binding methods and getters/setters via ffi.metatype for LuaJIT use.

	Design considerations:

	- invalid input data should never cause fatal errors or crashes. At worst
	  (eg. on invalid span offsets), nothing is displayed and some sensible
	  default is returned for computed values. Invalid API _usage_ however
	  (eg. wrong call order or missing calls) should cause an assertion failure.
	- the order in which layout and span properties are set is not important
	  in order to avoid call-order dependencies.

	Usage:

	- make a renderer object, supplying font load and unload callbacks.
	- make a layout object from said renderer.
	- set the text and text properties on the layout object.
	- add text spans and set text span properties on the layout object.
	- you can set any font_id except -1: the font load callback will be called
	  with your font_ids, but note: never use the same font id for a different
	  font because caches work on font_id! if you load files with embedded
	  fonts like PDFs, always generate new font ids or perfect-hash the font
	  contents and use that as an id.
	- call layout() then paint(<cairo-context>). change any properties,
	  check if `pixels_valid` is false and issue a repaint if it is.
	- navigate, hit-test, select and edit the text with cursors.

]]

require'terra.memcheck'
require'terra.tr_paint_cairo'
local utf8 = require'terra.utf8'
require'terra.rawstringview'
require'terra.tr_cursor'
require'terra.tr_underline'
local tr = require'terra.tr'
setfenv(1, require'terra.low'.module(tr))

num = double
MAX_SPAN_COUNT = 10^9
MAX_CURSOR_COUNT = 2^16
MAX_FONT_SIZE = 10000
MAX_MAXLEN = maxint - 1 --maxint is used as sentinel in tr_itemize.

FontLoadFunc.type.cname = 'tr_font_load_func_t'
FontUnloadFunc.type.cname = 'tr_font_unload_func_t'

struct Layout;
struct Renderer;

--Renderer & Layout wrappers and self-allocating constructors ----------------

ErrorFunc = {rawstring} -> {}
ErrorFunc.type.cname = 'error_func_t'

local terra default_error_function(message: rawstring)
	fprintf(stderr(), '%s\n', message)
end

struct Renderer (gettersandsetters) {
	r: tr.Renderer;
	error_function: ErrorFunc;
}

terra Renderer:init(load_font: FontLoadFunc, unload_font: FontUnloadFunc)
	self.r:init(load_font, unload_font)
	self.error_function = default_error_function
end

terra Renderer:free()
	self.r:free()
end

terra tr_renderer_sizeof()
	return [int](sizeof(Renderer))
end

terra tr_renderer(load_font: FontLoadFunc, unload_font: FontUnloadFunc)
	return new(Renderer, load_font, unload_font)
end

terra Renderer:release()
	release(self)
end

terra Renderer:get_error_function(): ErrorFunc return self.error_function end
terra Renderer:set_error_function(v: ErrorFunc) self.error_function = v end

EmbedDrawFunc = {&context, double, double, &Layout, int, &Embed, &Span, bool} -> {}
EmbedDrawFunc.type.cname = 'embed_draw_func_t'

terra Renderer:get_embed_draw_function(): EmbedDrawFunc
	return EmbedDrawFunc(self.r.embed_draw_function)
end
terra Renderer:set_embed_draw_function(v: EmbedDrawFunc)
	self.r.embed_draw_function = tr.EmbedDrawFunc(v)
end

struct Layout (gettersandsetters) {
	l: tr.Layout;
	cursors: arr(Cursor);
	_min_w: num;
	_max_w: num;
	_maxlen: int;
	state: enum; --STATE_*
	_offsets_valid: bool; --span offsets are good so spans can be split/merged.
	_valid: bool; --span offsets _and_ values are good so shaping won't crash.
}

terra Layout:get_r() return [&Renderer](self.l.r) end

terra Layout:init(r: &Renderer)
	self.l:init(&r.r)
	self.cursors:init()
	self._min_w = -inf
	self._max_w =  inf
	self._maxlen = MAX_MAXLEN
	self.state = 0
	self._offsets_valid = false
	self._valid = false
end

terra Layout:free()
	self.cursors:free()
	self.l:free()
end

terra tr_layout_sizeof()
	return [int](sizeof(Layout))
end

terra Renderer:layout()
	return new(Layout, self)
end

terra Layout:release()
	release(self)
end

--non-fatal error checking and reporting -------------------------------------

Renderer.methods.error = macro(function(self, ...)
	local args = args(...)
	return quote
		if self.error_function ~= nil then
			var s: char[256]
			snprintf(s, 256, [args])
			self.error_function(s)
		end
	end
end)

Renderer.methods.check = macro(function(self, NAME, v, valid)
	NAME = NAME:asvalue()
	FORMAT = 'invalid '..NAME..': %d'
	return quote
		if not valid then
			self:error(FORMAT, v)
		end
		in valid
	end
end)

Renderer.methods.checkrange = macro(function(self, NAME, v, MIN, MAX)
	NAME = NAME:asvalue()
	MIN = MIN:asvalue()
	MAX = MAX:asvalue()
	FORMAT = 'invalid '..NAME..': %d (range: '..MIN..'..'..MAX..')'
	return quote
		var ok = v >= MIN and v <= MAX
		if not ok then
			self:error(FORMAT, v)
		end
		in ok
	end
end)

Layout.methods.check = macro(function(self, NAME, v, valid)
	return `self.r:check(NAME, v, valid)
end)

Layout.methods.checkrange = macro(function(self, NAME, v, MIN, MAX)
	return `self.r:checkrange(NAME, v, MIN, MAX)
end)

Layout.methods.checkindex = macro(function(self, NAME, i, MAX)
	return `self:check(NAME, i, i >= 0) and i < MAX
end)

Layout.methods.checkcount = macro(function(self, NAME, n, MAX)
	return `self:check(NAME, n, n >= 0) and n <= MAX
end)

--Renderer config ------------------------------------------------------------

local terra subpixel_resolution(v: num)
	return 1.0 / nextpow2(int(1.0 / clamp(v, 1.0/64, 1.0)))
end

terra Renderer:get_subpixel_x_resolution(): num
	return self.r.subpixel_x_resolution
end
terra Renderer:set_subpixel_x_resolution(v: num)
	self.r.subpixel_x_resolution = subpixel_resolution(v)
end

terra Renderer:get_word_subpixel_x_resolution(): num
	return self.r.word_subpixel_x_resolution
end
terra Renderer:set_word_subpixel_x_resolution(v: num)
	self.r.word_subpixel_x_resolution = subpixel_resolution(v)
end

terra Renderer:get_font_size_resolution(): num
	return self.r.font_size_resolution
end
terra Renderer:set_font_size_resolution(v: num)
	self.r.font_size_resolution = subpixel_resolution(v)
end

terra Renderer:get_glyph_run_cache_max_size(): double
	return self.r.glyph_runs.max_size
end
terra Renderer:set_glyph_run_cache_max_size(v: double)
	if self:checkrange('glyph_run_cache_max_size', v, 0, inf) then
		self.r.glyph_runs.max_size = min(v, [GlyphRunCache.size_t:max()])
	end
end

terra Renderer:get_glyph_cache_max_size(): double
	return self.r.glyphs.max_size
end
terra Renderer:set_glyph_cache_max_size(v: double)
	if self:checkrange('glyph_cache_max_size', v, 0, inf) then
		self.r.glyphs.max_size = min(v, [GlyphCache.size_t:max()])
	end
end

terra Renderer:get_mem_font_cache_max_size(): double
	return self.r.mem_fonts.max_size
end
terra Renderer:set_mem_font_cache_max_size(v: double)
	if self:checkrange('mem_font_cache_max_size', v, 0, inf) then
		self.r.mem_fonts.max_size = min(v, [FontCache.size_t:max()])
	end
end

terra Renderer:get_mmapped_font_cache_max_count(): double
	return self.r.mmapped_fonts.max_count
end
terra Renderer:set_mmapped_font_cache_max_count(v: double)
	if self:checkrange('mmapped_font_cache_max_count', v, 0, inf) then
		self.r.mmapped_fonts.max_count = min(v, [FontCache.size_t:max()])
	end
end

--Renderer statistics API ----------------------------------------------------

terra Renderer:get_glyph_run_cache_size        (): double return self.r.glyph_runs.size end
terra Renderer:get_glyph_run_cache_count       (): double return self.r.glyph_runs.count end
terra Renderer:get_glyph_cache_size            (): double return self.r.glyphs.size end
terra Renderer:get_glyph_cache_count           (): double return self.r.glyphs.count end
terra Renderer:get_mem_font_cache_size         (): double return self.r.mem_fonts.size end
terra Renderer:get_mem_font_cache_count        (): double return self.r.mem_fonts.count end
terra Renderer:get_mmapped_font_cache_count    (): double return self.r.mmapped_fonts.count end

terra Renderer:get_paint_glyph_num(): int64 return self.r.paint_glyph_num end
terra Renderer:set_paint_glyph_num(n: int)       self.r.paint_glyph_num = n end

--Renderer font API -----------------------------------------------------------

terra Renderer:font_face_num(font_id: int)
	var font = self.r:font(font_id)
	return self.r:font_face_num(font)
end

--state invalidation ---------------------------------------------------------

STATE_VALIDATED = 1
STATE_SHAPED    = 2
STATE_WRAPPED   = 3
STATE_ALIGNED   = 4
STATE_CLIPPED   = 5
STATE_PAINTED   = 6

terra Layout:_invalidate_all()
	self.state = 0
	self._valid = false
	self._offsets_valid = false
end
terra Layout:_invalidate_shape() self.state = min(self.state, STATE_SHAPED  - 1) end
terra Layout:_invalidate_wrap () self.state = min(self.state, STATE_WRAPPED - 1) end
terra Layout:_invalidate_align() self.state = min(self.state, STATE_ALIGNED - 1) end
terra Layout:_invalidate_clip () self.state = min(self.state, STATE_CLIPPED - 1) end
terra Layout:_invalidate_paint() self.state = min(self.state, STATE_PAINTED - 1) end

terra Layout:_invalidate_min_w()
	self._min_w = -inf
end

terra Layout:_invalidate_max_w()
	self._max_w =  inf
end

--macro to generate multiple invalidation calls in one go.
Layout.methods.invalidate = macro(function(self, WHAT)
	WHAT = WHAT and WHAT:asvalue() or 'all'
	return quote
		escape
			for s in WHAT:gmatch'[^%s]+' do
				emit quote self:['_invalidate_'..s]() end
			end
		end
	end
end)

--state validation -----------------------------------------------------------

terra Layout:_advance_state(state: enum)
	if self.state < state then
		assert(self.state == state - 1)
		self.state = state
		return true
	else
		return false
	end
end

--check that there's at least one span and it has offset zero.
--check that spans have monotonically increasing offsets.
--check that all spans cover at least one codepoint except the last span
--which can start at text.len and thus cover zero codepoints in order to make
--valid spans possible with empty text and thus allow text insertion.
--check that all spans can be displayed (font face is loaded and font size > 0).
terra Layout:_validate()
	if not self:_advance_state(STATE_VALIDATED) then
		return
	end
	if self.l.spans.len == 0 or self.l.spans:at(0).offset ~= 0 then
		self._offsets_valid = false
		self._valid = false
		return
	end
	self._offsets_valid = true
	self._valid = true
	var prev_offset = -1
	for _,s in self.l.spans do
		if s.offset <= prev_offset         --offset overlapping
			or s.offset > self.l.text.len   --offset out-of-range
		then
			self._offsets_valid = false
			self._valid = false
			return
		end
		if s.font == nil       --font not set or font loading failed
			or s.font_size <= 0 --font size not set
			or s.face == nil    --invalid face index
		then
			self._valid = false
		end
		prev_offset = s.offset
	end
end

terra Layout:get_offsets_valid()
	self:_validate()
	return self._offsets_valid
end

terra Layout:get_valid()
	self:_validate()
	return self._valid
end

terra Layout:shape()
	self:_validate()
	if self:_advance_state(STATE_SHAPED) and self._valid then
		self:_invalidate_min_w()
		self:_invalidate_max_w()
		self.l:shape()
	end
end

terra Layout:wrap()
	if self:_advance_state(STATE_WRAPPED) and self._valid then
		self.l:wrap()
		self.l:spaceout()
	end
end

terra Layout:align()
	if self:_advance_state(STATE_ALIGNED) and self._valid then
		self.l:align()
	end
end

terra Layout:clip()
	if self:_advance_state(STATE_CLIPPED) and self._valid then
		self.l:clip()
	end
end

terra Layout:layout()
	self:shape()
	self:wrap()
	self:align()
	self:clip()
end

terra Layout:paint(cr: &context, for_shadow: bool)
	assert(self.state >= STATE_PAINTED - 1)
	self.state = STATE_PAINTED
	if self._valid then --paint() must paint from STATE_PAINTED too.
		for i,c in self.cursors do
			c:draw_selection(cr, true, for_shadow)
		end
		self.l:paint_text(cr, for_shadow)
		self.l:draw_underlines(cr, for_shadow)
		for i,c in self.cursors do
			c:draw_caret(cr, for_shadow)
		end
	end
end

--macros to a update value when changed and invalidate state -----------------

local change = macro(function(self, FIELD, v)
	FIELD = FIELD:asvalue()
	return quote
		var changed = self.[FIELD] ~= v
		if changed then
			self.[FIELD] = v
		end
		in changed
	end
end)

Layout.methods.change = macro(function(self, target, FIELD, v, WHAT)
	WHAT = WHAT or `nil
	return quote
		var changed = change(target, FIELD, v)
		if changed then
			self:invalidate(WHAT)
		end
		in changed
	end
end)

--layout editing -------------------------------------------------------------

terra Layout:get_maxlen(): int return self._maxlen end

terra Layout:set_maxlen(v: int)
	if self:change(self, '_maxlen', clamp(v, 0, MAX_MAXLEN)) then
		if self.l.text.len > self.maxlen then --truncate the text
			self.l.text.len = v
			self:invalidate()
		end
	end
end

terra Layout:get_text_len(): int return self.l.text.len end
terra Layout:get_text() return self.l.text.elements end

terra Layout:set_text(s: &codepoint, len: int)
	if s == nil then
		assert(len == 0)
		self.l.text.len = 0
	else
		self.l.text.len = 0
		self.l.text:add(s, min(self.maxlen, len))
	end
	self:invalidate()
end

terra Layout:_get_utf8(s: arrview(codepoint), out: rawstring, max_outlen: int): int
	if max_outlen < 0 then
		max_outlen = maxint
	end
	if out == nil then --out buffer size requested
		return utf8.encode.count(s.elements, s.len,
			max_outlen, utf8.REPLACE, utf8.INVALID)._0
	else
		return utf8.encode.tobuffer(s.elements, s.len, out,
			max_outlen, utf8.REPLACE, utf8.INVALID)._0
	end
end

terra Layout:get_text_utf8(out: rawstring, max_outlen: int): int
	return self:_get_utf8(self.l.text.view, out, max_outlen)
end

terra Layout:get_text_utf8_len(): int
	return self:get_text_utf8(nil, -1)
end

terra Layout:set_text_utf8(s: rawstring, len: int)
	if s == nil then
		assert(len == 0)
		self.l.text.len = 0
	else
		if len < 0 then
			len = strnlen(s, self.maxlen)
		end
		utf8.decode.toarr(s, len, &self.l.text,
			self.maxlen, utf8.REPLACE, utf8.INVALID)
	end
	self:invalidate()
end

terra Layout:get_dir(): enum return self.l.dir end

terra Layout:set_dir(v: enum)
	if self:checkrange('dir', v, DIR_MIN, DIR_MAX) then
		self:change(self.l, 'dir', v, 'shape')
	end
end

terra Layout:get_align_w(): num return self.l.align_w end
terra Layout:get_align_h(): num return self.l.align_h end

terra Layout:set_align_w(v: num) self:change(self.l, 'align_w', v, 'wrap') end
terra Layout:set_align_h(v: num) self:change(self.l, 'align_h', v, 'align') end

terra Layout:get_align_x(): enum return self.l.align_x end
terra Layout:get_align_y(): enum return self.l.align_y end

terra Layout:set_align_x(v: enum)
	if self:check('align_x', v,
			   v == ALIGN_LEFT
			or v == ALIGN_RIGHT
			or v == ALIGN_CENTER
			or v == ALIGN_JUSTIFY
			or v == ALIGN_START
			or v == ALIGN_END
	) then
		self:change(self.l, 'align_x', v, 'align')
	end
end

terra Layout:set_align_y(v: enum)
	if self:check('align_y', v,
			   v == ALIGN_TOP
			or v == ALIGN_BOTTOM
			or v == ALIGN_CENTER
	) then
		self:change(self.l, 'align_y', v, 'align')
	end
end

terra Layout:get_line_spacing      (): num return self.l.line_spacing      end
terra Layout:get_hardline_spacing  (): num return self.l.hardline_spacing  end
terra Layout:get_paragraph_spacing (): num return self.l.paragraph_spacing end

terra Layout:set_line_spacing      (v: num) self:change(self.l, 'line_spacing'     , v, 'wrap') end
terra Layout:set_hardline_spacing  (v: num) self:change(self.l, 'hardline_spacing' , v, 'wrap') end
terra Layout:set_paragraph_spacing (v: num) self:change(self.l, 'paragraph_spacing', v, 'wrap') end

terra Layout:get_clip_x(): num return self.l.clip_x end
terra Layout:get_clip_y(): num return self.l.clip_y end
terra Layout:get_clip_w(): num return self.l.clip_w end
terra Layout:get_clip_h(): num return self.l.clip_h end

terra Layout:set_clip_x(v: num) self:change(self.l, 'clip_x', v, 'clip') end
terra Layout:set_clip_y(v: num) self:change(self.l, 'clip_y', v, 'clip') end
terra Layout:set_clip_w(v: num) self:change(self.l, 'clip_w', v, 'clip') end
terra Layout:set_clip_h(v: num) self:change(self.l, 'clip_h', v, 'clip') end

terra Layout:set_clip_extents(x1: num, y1: num, x2: num, y2: num)
	self.clip_x = x1
	self.clip_y = y1
	self.clip_w = x2-x1
	self.clip_h = y2-y1
end

terra Layout:get_x(): num return self.l.x end
terra Layout:get_y(): num return self.l.y end

terra Layout:set_x(v: num) self:change(self.l, 'x', v, 'clip') end
terra Layout:set_y(v: num) self:change(self.l, 'y', v, 'clip') end

--span editing ---------------------------------------------------------------

SPAN_FIELDS = {
	'font_id',
	'font_face_index',
	'font_size',
	'features',
	'script',
	'lang',
	'paragraph_dir',
	'wrap',
	'color',
	'opacity',
	'operator',
	'underline',
	'underline_color',
	'underline_opacity',
	'baseline',
}
local SPAN_FIELD_INDICES = index(SPAN_FIELDS)

local BIT = function(field)
	local i = SPAN_FIELD_INDICES[field]
	return 2^(i-1)
end
local BIT_ALL = 2^(#SPAN_FIELDS)-1

local span_mask_has_bit = macro(function(mask, FIELD)
	local bit = BIT(FIELD:asvalue())
	return `(mask and bit) ~= 0
end)

--compare s<->d and return a bitmask showing which field values are the same.
local terra compare_spans(d: &Span, s: &Span)
	var mask = 0
	escape
		for _,FIELD in ipairs(SPAN_FIELDS) do
			emit quote
				if d.[FIELD] == s.[FIELD] then
					mask = mask or [BIT(FIELD)]
				end
			end
		end
	end
	return mask
end

--always returns a valid span index except it returns -1 when spans.len == 0.
local terra cmp_spans(s1: &Span, s2: &Span)
	return s1.offset <= s2.offset  -- < < = = [>] >
end
terra tr.Layout:span_at_offset(offset: int)
	offset = max(0, offset)
	return self.spans:binsearch(Span{offset = offset}, cmp_spans) - 1
end

--NOTE: -1 is one position outside the text, not the last position in the text.
terra tr.Layout:offset_range(o1: int, o2: int)
	if o1 < 0 then o1 = self.text.len + o1 + 1 end
	if o2 < 0 then o2 = self.text.len + o2 + 1 end
	o1 = clamp(o1, 0, self.text.len)
	o2 = clamp(o2, 0, self.text.len)
	if o2 < o1 then o1, o2 = o2, o1 end
	return o1, o2
end

terra tr.Layout:split_spans_at_offset(offset: int)
	if offset >= self.text.len then --don't create an empty span.
		return self.spans.len
	end
	var i = self:span_at_offset(offset)
	var s = self.spans:at(i)
	if s.offset < offset then
		inc(i)
		var s1 = s:copy(self)
		s1.offset = offset
		self.spans:insert(i, s1)
	else
		assert(s.offset == offset)
	end
	return i
end

terra tr.Layout:split_spans(o1: int, o2: int)
	--create the first span automatically.
	if self.spans.len == 0 then
		self.spans:add([Span.empty_const])
	end
	var o1, o2 = self:offset_range(o1, o2)
	--empty selection: return the span _covering_ the cursor position.
	if o1 == o2 then
		var i = self:span_at_offset(o1)
		return i, i+1
	end
	--non-empty selection, non-empty text, at least one span: split spans.
	var i1 = self:split_spans_at_offset(o1)
	var i2 = self:split_spans_at_offset(o2)
	return i1, i2
end

terra tr.Layout:remove_duplicate_spans(i1: int, i2: int)
	i1 = self.spans:clamp(i1)
	i2 = self.spans:clamp(i2)
	var s = self.spans:at(i2)
	var i = i2 - 1
	while i >= i1 do
		var d = self.spans:at(i)
		if compare_spans(d, s) == BIT_ALL then
			self.spans:remove(i+1) --TODO: remove in chunks to avoid O(n^2)
		end
		s = d
		dec(i)
	end
end

--remove all spans that are out of the text range.
terra Layout:remove_trailing_spans()
	for i,s in self.l.spans:backwards() do
		if s.offset < self.l.text.len then
			self.l.spans:remove(i+1, maxint)
			self:invalidate()
			break
		end
	end
end

--get a bitmask showing which span values are the same for an offset range
--and the span id at o1 for which to get the actual values.
terra tr.Layout:get_span_same_mask(o1: int, o2: int)
	o1, o2 = self:offset_range(o1, o2)
	var mask: uint32 = BIT_ALL --presume all field values are the same.
	var i = self:span_at_offset(o1)
	var s = self.spans:at(i)
	if o2 > o1 then
		var i2 = self:span_at_offset(o2-1)+1
		for i = i+1, i2 do
			var d = self.spans:at(i)
			mask = mask and compare_spans(s, d)
			if mask == 0 then break end --all field values are different.
		end
	end
	return mask, i
end

terra Span:save_features(layout: &Layout)
	var sbuf = &layout.l.r.sbuf
	sbuf.len = 0
	for i,feat in self.features do
		var eof = sbuf.len
		sbuf.len = sbuf.len + 128
		var p = sbuf:at(eof)
		hb_feature_to_string(feat, p, 128)
		sbuf.len = eof + strnlen(p, 128)
		if i < self.features.len-1 then
			sbuf:add(32) --space char
		end
	end
	sbuf:add(0) --null-terminate
	return iif(sbuf.len > 1, sbuf.elements, nil)
end

--feature format: '[+|-]feat[=val] ...', eg. '+kern -liga smcp'.
--see: https://harfbuzz.github.io/harfbuzz-hb-common.html#hb-feature-from-string
terra Span:load_features(layout: &Layout, s: rawstring)
	var s0 = self:save_features(layout)
	if s0 == s then --both nil
		return false
	end
	var sv0 = rawstringview(s0)
	var sv  = rawstringview(s)
	if sv0 == sv then --same contents
		return false
	end
	self.features.len = 0
	var j = 0
	for i,len in sv:gsplit' ' do
		var feat: hb_feature_t
		if hb_feature_from_string(sv:at(i), len, &feat) ~= 0 then
			self.features:add(feat)
		end
	end
	return true
end

--accepts BCP-47 language-country codes.
terra Span:load_lang(layout: &Layout, s: rawstring)
	var lang = hb_language_from_string(s, -1)
	return change(self, 'lang', lang)
end

terra Span:save_lang(layout: &Layout)
	return hb_language_to_string(self.lang)
end

--accepts ISO-15924 script tags.
terra Span:load_script(layout: &Layout, s: rawstring)
	var script = hb_script_from_string(s, -1)
	return change(self, 'script', script)
end

terra Span:save_script(layout: &Layout)
	var sbuf = &layout.l.r.sbuf
	sbuf.len = 5
	var tag = hb_script_to_iso15924_tag(self.script)
	hb_tag_to_string(tag, sbuf.elements)
	sbuf:set(4, 0) --hb_tag_to_string() doesn't null terminate.
	return iif(sbuf(0) ~= 0, sbuf.elements, nil)
end

terra Span:save_color(layout: &Layout)
	return self.color.uint
end

terra Span:load_color(layout: &Layout, v: uint32)
	return change(self.color, 'uint', v)
end

terra Span:load_font_id(layout: &Layout, font_id: int)
	if self.font_id ~= font_id then
		forget_font(layout.l.r, self.font_id)
		var font_before = self.font
		self.font = layout.l.r:font(font_id)
		self.font_id = iif(self.font ~= nil, font_id, -1)
		return not (font_before == nil and self.font == nil)
	else
		return false
	end
end

terra Span:load_font_size(layout: &Layout, v: double)
	return change(self, 'font_size', clamp(v, 0, MAX_FONT_SIZE))
end

terra Span:save_underline_color(layout: &Layout)
	return self.underline_color.uint
end

terra Span:load_underline_color(layout: &Layout, v: uint32)
	return change(self.underline_color, 'uint', v)
end

terra Span:load_operator(layout: &Layout, v: enum)
	if layout:checkrange('span_operator', v, OPERATOR_MIN, OPERATOR_MAX) then
		return change(self, 'operator', v)
	else
		return false
	end
end

terra Span:load_underline(layout: &Layout, v: enum)
	if layout:checkrange('span_underline', v, UNDERLINE_MIN, UNDERLINE_MAX) then
		return change(self, 'underline', v)
	else
		return false
	end
end

SPAN_FIELD_TYPES = {
	font_id           = int       ,
	font_face_index   = int       ,
	font_size         = double    ,
	features          = rawstring ,
	script            = rawstring ,
	lang              = rawstring ,
	paragraph_dir     = int       ,
	wrap              = enum      ,
	color             = uint32    ,
	opacity           = double    ,
	operator          = enum      ,
	underline         = enum      ,
	underline_color   = uint32    ,
	underline_opacity = double    ,
	baseline          = double    ,
}

local SPAN_FIELD_INVALIDATE = {
	features          = 'shape',
	script            = 'shape',
	lang              = 'shape',
	paragraph_dir     = 'wrap',
	wrap              = 'wrap min_w',
	color             = 'paint',
	opacity           = 'paint',
	operator          = 'paint',
	underline         = 'paint',
	underline_color   = 'paint',
	underline_opacity = 'paint',
	baseline          = 'wrap',
}

--Generate getters and setters for each text attr that can be set on an offset range.
--Uses Layout:save_<field>() and Layout:load_<field> methods if available.
for _,FIELD in ipairs(SPAN_FIELDS) do

	local T = SPAN_FIELD_TYPES[FIELD] or Span:getfield(FIELD).type
	local INVALIDATE = SPAN_FIELD_INVALIDATE[FIELD] or `nil

	local SAVE = Span:getmethod('save_'..FIELD)
		or macro(function(self) return `self.[FIELD] end)

	--API for getting/setting span properties on a text offset range.

	Layout.methods['has_'..FIELD] = terra(self: &Layout, o1: int, o2: int)
		if self.l.spans.len == 0 then
			--it's not an error to call has_*() with no spans because set_*()
			--creates spans automatically.
			return false
		elseif self.offsets_valid then
			var mask, span_i = self.l:get_span_same_mask(o1, o2)
			return span_mask_has_bit(mask, FIELD)
		else
			self.r:error('has_%s() error: invalid span offsets', FIELD)
			return false
		end
	end

	local LOAD = Span:getmethod('load_'..FIELD)
		or macro(function(self, layout, val)
			return `change(self, FIELD, val)
		end)

	Layout.methods['set_'..FIELD] = terra(self: &Layout, o1: int, o2: int, val: T)
		if self.l.spans.len == 0 or self.offsets_valid then
			var n = self.l.spans.len
			var i1, i2 = self.l:split_spans(o1, o2)
			if self.l.spans.len ~= n then
				self:invalidate()
			end
			for i = i1, i2 do
				var span = self.l.spans:at(i)
				if LOAD(span, self, val) then
					self:invalidate(INVALIDATE)
				end
			end
			n = self.l.spans.len
			self.l:remove_duplicate_spans(i1-1, i2+1)
			if self.l.spans.len ~= n then
				self:invalidate()
			end
		else
			self.r:error('set_%s() error: invalid span offsets', FIELD)
		end
	end

	--API for getting/setting spans directly as an array (for (de)serialization).

	Layout.methods['get_span_'..FIELD] = terra(self: &Layout, span_i: int): T
		var span = self.l.spans:at(span_i, &[Span.empty_const])
		return SAVE(span, self)
	end

	Layout.methods['set_span_'..FIELD] = terra(self: &Layout, span_i: int, val: T)
		if self:checkindex('span_index', span_i, MAX_SPAN_COUNT) then
			var span = self.l.spans:getat(span_i, [Span.empty_const])
			if LOAD(span, self, val) then
				self:invalidate(INVALIDATE)
			end
		end
	end

end

terra Layout:get_span_offset(span_i: int): int
	return self.l.spans:at(span_i, &[Span.empty_const]).offset
end

terra Layout:set_span_offset(span_i: int, val: int)
	self.l.spans:getat(span_i, [Span.empty_const]).offset = val
	self:invalidate()
end

terra Layout:get_span_count(): int
	return self.l.spans.len
end

terra Layout:set_span_count(n: int)
	if self:checkcount('span_count', n, MAX_SPAN_COUNT) then
		if self.l.spans.len ~= n then
			self.l.spans:setlen(n, [Span.empty_const])
			self:invalidate()
		end
	end
end

terra Layout:span_at_offset(offset: int): int
	assert(self.offsets_valid)
	return self.l:span_at_offset(offset)
end

--text editing ---------------------------------------------------------------

--remove text between two subsequent offsets. return the offset at removal point.
terra Layout:remove_text(o1: num, o2: num) --num to allow -inf and inf

	if not self.offsets_valid then
		self.r:error('remove: invalid span offsets')
		return -1
	end

	var eof = self.l.text.len
	var o1 = clamp(o1, 0, eof)
	var o2 = clamp(o2, 0, eof)
	var len = o2 - o1
	if len <= 0 then return o1 end

	--find the span range s1..s2-1 that needs to be removed.
	--find the span range s3..last that needs its offset adjusted.
	var s1 = self.l:span_at_offset(o1) -- s1.o <= o1
	var s2 = self.l:span_at_offset(o2) -- s2.o <= o2
	var s3 = s2
	if s2 > s1 then
		if o2 == eof then -- s2 can't cover beyond o2, remove it.
			inc(s2)
		else -- s2 covers beyond o2, move it to o2.
			self.l.spans:at(s2).offset = o2
		end
		s3 = s2
	else
		s3 = s1 + 1
	end
	if self.l.spans:at(s1).offset < o1 then --s1 covers before o1, skip it.
		inc(s1)
	elseif s1 == 0 and o2 == eof then --all spans would be removed.
		inc(s1)
	end

	--adjust offsets on right-side spans, remove dead spans and remove the text.
	for _, span in self.l.spans:sub(s3) do
		dec(span.offset, len)
	end
	self.l.spans:remove(s1, s2 - s1)
	self.l.text:remove(o1, len)

	self:invalidate'shape'
	return o1
end

--insert text (or make room for text) at offset. return offset after inserted text.
terra Layout:insert_text(offset: int, s: &codepoint, len: int)

	if not self.offsets_valid then
		self.r:error('insert: invalid span offsets')
		return -1
	end

	offset = clamp(offset, 0, self.l.text.len)
	len = min(len, self.maxlen - self.l.text.len)

	if len <= 0 then
		return offset
	end

	if s ~= nil then
		self.l.text:insert(offset, s, len)
	else --just make room so that utf8 text can be decoded in-place.
		self.l.text:insertn(offset, len)
	end

	--adjust the offsets of all spans after the insertion point.
	var span_i = self.l:span_at_offset(offset) + 1
	for _, span in self.l.spans:sub(span_i) do
		inc(span.offset, len)
	end

	self:invalidate'shape'
	return offset + len
end

--embed editing --------------------------------------------------------------

terra Layout:get_embed_count(): int
	return self.l.embeds.len
end

terra Layout:set_embed_count(n: int)
	if self:checkcount('embed_count', n, MAX_EMBED_COUNT) then
		if self.l.embeds.len ~= n then
			self.l.embeds:setlen(n, [Embed.empty_const])
			self:invalidate'wrap'
		end
	end
end

local get_metrics = macro(function(self, i, FIELD)
	return quote
		self:checkindex('embed_index', i, MAX_EMBED_COUNT)
		in self.l.embeds:at(i, &[Embed.empty_const]).metrics.[FIELD:asvalue()]
	end
end)
terra Layout:get_embed_advance_x(i: int): num return get_metrics(self, i, 'advance_x') end
terra Layout:get_embed_ascent   (i: int): num return get_metrics(self, i, 'ascent'   ) end
terra Layout:get_embed_descent  (i: int): num return get_metrics(self, i, 'descent'  ) end

local set_metrics = macro(function(self, i, FIELD, v, INVALID)
	return quote
		if self:checkindex('embed_index', i, MAX_EMBED_COUNT) then
			var embed = self.l.embeds:getat(i, [Embed.empty_const])
			self:change(&embed.metrics, [FIELD:asvalue()], v, INVALID)
		end
	end
end)
terra Layout:set_embed_advance_x(i: int, v: num)
	set_metrics(self, i, 'advance_x'     , v, 'wrap')
	set_metrics(self, i, 'wrap_advance_x', v, 'wrap')
end
terra Layout:set_embed_ascent (i: int, v: num) set_metrics(self, i, 'ascent' , v, 'wrap') end
terra Layout:set_embed_descent(i: int, v: num) set_metrics(self, i, 'descent', v, 'wrap') end

--layouting helper APIs ------------------------------------------------------

terra Layout:get_min_size_valid() --text box might need re-layouting.
	return self.state >= STATE_WRAPPED
end

terra Layout:get_align_valid() --text needs re-aligning.
	return self.state >= STATE_ALIGNED
end

terra Layout:get_pixels_valid() --text needs repainting.
	return self.state >= STATE_PAINTED
end

terra Layout:get_visible() --check if the text and/or cursor is visible.
	return self.valid and (self.l.text.len > 0 or self.cursors.len > 0)
end

terra Layout:get_min_w(): num --for page layouting min-size constraints.
	assert(self.state >= STATE_SHAPED)
	if self._valid then
		if self._min_w == -inf then
			self._min_w = self.l:min_w()
		end
		return self._min_w
	else
		return 0
	end
end

terra Layout:get_max_w(): num --not used yet
	assert(self.state >= STATE_SHAPED)
	if self._valid then
		if self._max_w == -inf then
			self._max_w = self.l:max_w()
		end
		return self._max_w
	else
		return 0
	end
end

terra Layout:get_baseline(): num --for page layouting baseline alignment.
	assert(self.state >= STATE_ALIGNED)
	return iif(self._valid, self.l.baseline, 0)
end

terra Layout:get_spaced_h(): num --for page layouting min-size constraints.
	assert(self.state >= STATE_WRAPPED)
	return iif(self._valid, self.l.spaced_h, 0)
end

terra Layout:bbox(): {num, num, num, num}
	assert(self.state >= STATE_ALIGNED)
	return iif(self._valid, self.l:bbox(), {0.0, 0.0, 0.0, 0.0})
end

--cursor & selection API -----------------------------------------------------

terra Layout:get_cursor_count(): int
	return self.cursors.len
end
terra Layout:set_cursor_count(n: int): int --TODO: checklen
	n = clamp(n, 0, MAX_CURSOR_COUNT)
	if self.cursors.len ~= n then
		for _,c in self.cursors:setlen(n) do
			(@c):init(&self.l)
		end
		self:invalidate'paint'
	end
end

Layout.methods.check_cursor_index = macro(function(self, i)
	return `self:checkindex('cursor index', i, MAX_CURSOR_COUNT)
end)

terra Layout:_cursor(c_i: int)
	var c, new_cursors = self.cursors:getat(c_i)
	for _,c in new_cursors do
		(@c):init(&self.l)
		self:invalidate'paint'
	end
	return c
end

Layout.methods.change_cursor = macro(function(self, c_i, FIELD, v, WHAT)
	return quote
		if self:check_cursor_index(c_i) then
			var c = self:_cursor(c_i)
			self:change(self:_cursor(c_i), FIELD, v, WHAT)
		end
	end
end)

Layout.methods.change_cursor_state = macro(function(self, c_i, FIELD, v, WHAT)
	return quote
		if self:check_cursor_index(c_i) then
			self:change(self:_cursor(c_i).state, FIELD, v, WHAT)
		end
	end
end)

terra Layout:get_cursor_offset     (c_i: int): int  return self.cursors:at(c_i, &[Cursor.empty_const]).state.offset     end
terra Layout:get_cursor_which      (c_i: int): int  return self.cursors:at(c_i, &[Cursor.empty_const]).state.which      end
terra Layout:get_cursor_sel_offset (c_i: int): int  return self.cursors:at(c_i, &[Cursor.empty_const]).state.sel_offset end
terra Layout:get_cursor_sel_which  (c_i: int): enum return self.cursors:at(c_i, &[Cursor.empty_const]).state.sel_which  end
terra Layout:get_cursor_x          (c_i: int): num  return self.cursors:at(c_i, &[Cursor.empty_const]).state.x          end

terra Layout:get_caret_visible     (c_i: int) var c = self.cursors:at(c_i, nil); return iif(c ~= nil, c.caret_visible    , false) end
terra Layout:get_selection_visible (c_i: int) var c = self.cursors:at(c_i, nil); return iif(c ~= nil, c.selection_visible, false) end
terra Layout:get_insert_mode       (c_i: int)         return self.cursors:at(c_i, &[Cursor.empty_const]).insert_mode          end
terra Layout:get_caret_opacity     (c_i: int): num    return self.cursors:at(c_i, &[Cursor.empty_const]).caret_opacity        end
terra Layout:get_caret_thickness   (c_i: int): num    return self.cursors:at(c_i, &[Cursor.empty_const]).caret_thickness      end
terra Layout:get_selection_color   (c_i: int): uint32 return self.cursors:at(c_i, &[Cursor.empty_const]).selection_color.uint end
terra Layout:get_selection_opacity (c_i: int): num    return self.cursors:at(c_i, &[Cursor.empty_const]).selection_opacity    end

terra Layout:set_cursor_offset(c_i: int, v: num) --num to allow inf and -inf as offsets
	self:change_cursor_state(c_i, 'offset', clamp(v, 0, maxint), 'paint')
end
terra Layout:set_cursor_which(c_i: int, v: enum)
	if self:checkrange('cursor_which', v, CURSOR_WHICH_FIRST, CURSOR_WHICH_LAST) then
		self:change_cursor_state(c_i, 'which', v, 'paint')
	end
end
terra Layout:set_cursor_sel_offset(c_i: int, v: num)
	self:change_cursor_state(c_i, 'sel_offset', clamp(v, 0, maxint), 'paint')
end
terra Layout:set_cursor_sel_which(c_i: int, v: enum)
	if self:checkrange('cursor_sel_which', v, CURSOR_WHICH_FIRST, CURSOR_WHICH_LAST) then
		self:change_cursor_state(c_i, 'sel_which' , v, 'paint')
	end
end
terra Layout:set_cursor_x(c_i: int, v: num)
	self:change_cursor_state(c_i, 'x', v, 'paint')
end

terra Layout:set_caret_visible    (c_i: int, v: bool) self:change_cursor(c_i, 'caret_visible'    , v, 'paint') end
terra Layout:set_selection_visible(c_i: int, v: bool) self:change_cursor(c_i, 'selection_visible', v, 'paint') end
terra Layout:set_insert_mode      (c_i: int, v: bool) self:change_cursor(c_i, 'insert_mode'      , v, 'paint') end
terra Layout:set_caret_opacity    (c_i: int, v: num ) self:change_cursor(c_i, 'caret_opacity'    , clamp(v, 0, 1), 'paint') end
terra Layout:set_caret_thickness  (c_i: int, v: num ) self:change_cursor(c_i, 'caret_thickness'  , clamp(v, 1, inf), 'paint') end
terra Layout:set_selection_color  (c_i: int, v: uint) self:change_cursor(c_i, 'selection_color'  , color{uint = v}, 'paint') end
terra Layout:set_selection_opacity(c_i: int, v: num ) self:change_cursor(c_i, 'selection_opacity', clamp(v, 0, 1), 'paint') end

terra Layout:cursor_move_to(c_i: int, offset: num, which: enum, select: bool)
	assert(self.state >= STATE_ALIGNED)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		if c:move_to(clamp(offset, 0, maxint), which, select) then
			self:invalidate'paint'
		end
	end
end

terra Layout:cursor_move_to_point(c_i: int, x: num, y: num, select: bool)
	assert(self.state >= STATE_ALIGNED)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		if c:move_to_point(x, y, select) then
			self:invalidate'paint'
		end
	end
end

terra Layout:cursor_move_near(
	c_i: int, dir: enum, mode: enum, which: enum, select: bool
)
	if     self:checkrange('text cursor dir'  , dir  , CURSOR_DIR_MIN  , CURSOR_DIR_MAX)
		and self:checkrange('text cursor mode' , mode , CURSOR_MODE_MIN , CURSOR_MODE_MAX)
		and self:checkrange('text cursor which', which, CURSOR_WHICH_MIN, CURSOR_WHICH_MAX)
	then
		assert(self.state >= STATE_ALIGNED)
		if self:check_cursor_index(c_i) then
			var c = self:_cursor(c_i)
			if c:move_near(dir, mode, which, select) then
				self:invalidate'paint'
			end
		end
	end
end

terra Layout:cursor_move_near_line(c_i: int, delta_lines: num, x: num, select: bool)
	assert(self.state >= STATE_ALIGNED)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		if c:move_near_line(clamp(delta_lines, minint, maxint), x, select) then
			self:invalidate'paint'
		end
	end
end

terra Layout:cursor_move_near_page(c_i: int, delta_pages: num, x: num, select: bool)
	assert(self.state >= STATE_ALIGNED)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		if c:move_near_page(clamp(delta_pages, minint, maxint), x, select) then
			self:invalidate'paint'
		end
	end
end

terra Layout:get_selection_first_span(c_i: int): int
	var c = self.cursors:at(c_i, nil)
	if c ~= nil then
		var is_forward = c.state.sel_offset < c.state.offset
		var offset = iif(is_forward, c.state.sel_offset, c.state.offset)
		return self:span_at_offset(offset)
	else
		return 0
	end
end

terra Layout:remove_selected_text(c_i: int)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		var o1, o2 = minmax(c.state.offset, c.state.sel_offset)
		self:remove_text(o1, o2)
		c.state.offset = o1
		c.state.sel_offset = o1
	end
end

terra Layout:insert_text_at_cursor(c_i: int, s: &codepoint, len: int)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		var o1, o2 = minmax(c.state.offset, c.state.sel_offset)
		self:remove_text(o1, o2)
		o2 = self:insert_text(o1, s, len)
		if o2 >= 0 then
			c.state.offset = o2
			c.state.sel_offset = o2
		end
	end
end

terra Layout:insert_text_utf8_at_cursor(c_i: int, s: rawstring, len: int)
	if self:check_cursor_index(c_i) then
		var c = self:_cursor(c_i)
		var o1, o2 = minmax(c.state.offset, c.state.sel_offset)
		self:remove_text(o1, o2)
		if s == nil then
			assert(len == 0)
		else
			var maxlen = self.maxlen - self.l.text.len
			if len < 0 then
				len = strnlen(s, maxlen)
			end
			var n = utf8.decode.count(s, len,
				maxlen, utf8.REPLACE, utf8.INVALID)._0
			o2 = self:insert_text(o1, nil, n)
			if o2 >= 0 then
				utf8.decode.tobuffer(s, len, self.l.text:at(o1),
					maxlen, utf8.REPLACE, utf8.INVALID)
				c.state.offset = o2
				c.state.sel_offset = o2
			end
		end
	end
end

terra Layout:_selected_text(c_i: int)
	var c = self:_cursor(c_i)
	var o1, o2 = c.state.offset, c.state.sel_offset
	if o1 > o2 then o1, o2 = o2, o1 end
	return self.l.text:sub(o1, o2)
end

terra Layout:get_selected_text_len(c_i: int)
	if self:check_cursor_index(c_i) then
		return self:_selected_text(c_i).len
	else
		return 0
	end
end

terra Layout:get_selected_text(c_i: int)
	if self:check_cursor_index(c_i) then
		return self:_selected_text(c_i).elements
	else
		return nil
	end
end

terra Layout:get_selected_text_utf8(c_i: int, out: rawstring, max_outlen: int): int
	if self:check_cursor_index(c_i) then
		var s = self:_selected_text(c_i)
		return self:_get_utf8(s, out, max_outlen)
	else
		return 0
	end
end

terra Layout:get_selected_text_utf8_len(c_i: int): int
	return self:get_selected_text_utf8(c_i, nil, -1)
end

terra Layout:load_cursor_xs(line_i: int)
	assert(self.state >= STATE_ALIGNED)
	self.l.r.xsbuf.len = 0
	if not self._valid then return end
	self.l:cursor_xs(line_i)
end
terra Layout:get_cursor_xs() return self.l.r.xsbuf.elements end
terra Layout:get_cursor_xs_len(): int return self.l.r.xsbuf.len end

--publish and build ----------------------------------------------------------

Renderer.cname = 'renderer_t'
Renderer.opaque = true
Layout.cname = 'layout_t'
Layout.opaque = true

function build(optimize)
	local binder = require'terra.binder'
	local trlib = binder.lib'tr'

	if memtotal then
		trlib(memtotal)
		trlib(memreport)
	end

	trlib(tr, 'ALIGN_')
	trlib(tr, 'DIR_')
	trlib(tr, 'CURSOR_')

	trlib(tr_renderer_sizeof)
	trlib(tr_layout_sizeof)
	trlib(tr_renderer)

	trlib(Renderer)
	trlib(Layout)

	trlib:build{
		linkto = {'cairo', 'freetype', 'harfbuzz', 'fribidi', 'unibreak', 'xxhash'},
		optimize = optimize,
	}

	trlib:gen_ffi_binding()

end

if not ... then
	print'Building non-optimized...'
	build(false)
	print('sizeof Layout ', sizeof(Layout))
	print('sizeof Span   ', sizeof(Span))
	print('sizeof Seg    ', sizeof(Seg))
	print('sizeof Line   ', sizeof(Line))
end

return _M
