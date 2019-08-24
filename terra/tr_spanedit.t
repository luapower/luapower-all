
--get/set individual Span attributes between any two text offsets
--with minimal invalidation of state and minimum number of spans.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_font'
require'terra/tr_shape'
require'terra/rawstringview'

local FIELDS = {
	'font_id',
	'font_size',
	'features',
	'script',
	'lang',
	'paragraph_dir',
	'nowrap',
	'color',
	'opacity',
	'operator',
}

local FIELD_INDICES = index(FIELDS)

local BIT = function(field)
	local i = type(field) == 'string' and FIELD_INDICES[field] or field
	return 2^(i-1)
end
local BIT_ALL = 2^(#FIELDS)-1

local hasbit = macro(function(mask, bit)
	return `(mask and bit) ~= 0
end)

--compare s<->d and return a bitmask showing which field values are the same.
terra Layout:compare_spans(d: &Span, s: &Span)
	var mask = 0
	escape
		for i,FIELD in ipairs(FIELDS) do
			emit quote
				if d.[FIELD] == s.[FIELD] then
					mask = mask or [BIT(i)]
				end
			end
		end
	end
	return mask
end

local terra cmp_spans(s1: &Span, s2: &Span)
	return s1.offset <= s2.offset  -- < < = = [>] >
end
terra Layout:find_span(offset: int) --always returns a valid span index
	offset = max(0, offset)
	return self.spans:binsearch(Span{offset = offset}, cmp_spans) - 1
end

terra Layout:split_spans(offset: int, allow_add: bool)
	if not allow_add and self.spans:at(self.spans.len-1).offset < offset then
		return self.spans.len --return that span that would have been added
	end
	var i = self:find_span(offset)
	var s = self.spans:at(i)
	if s.offset < offset then
		inc(i)
		var s1 = s:copy()
		s1.offset = offset
		self.spans:insert(i, s1)
	else
		assert(s.offset == offset)
	end
	return i
end

terra Layout:remove_duplicate_spans(i1: int, i2: int)
	i1 = self.spans:clamp(i1)
	i2 = self.spans:clamp(i2)
	var s = self.spans:at(i2)
	var i = i2 - 1
	while i >= i1 do
		var d = self.spans:at(i)
		if self:compare_spans(d, s) == BIT_ALL then
			self.spans:remove(i+1)
		end
		s = d
		dec(i)
	end
end

--get a span and a bitmask showing which values are the same for an offset range.
terra Layout:get_span_common_values(offset1: int, offset2: int)
	var mask = BIT_ALL --presume all field values are equal
	var i = self:find_span(offset1)
	var s = self.spans:at(i)
	if offset2 > offset1 then
		var i2 = self:find_span(offset2-1)+1
		for i = i+1, i2 do
			var d = self.spans:at(i)
			mask = mask and self:compare_spans(s, d)
		end
	end
	return s, mask
end

terra Span:load_features(layout: &Layout, s: rawstring)
	self.features.len = 0
	var sview = rawstringview(s)
	var j = 0
	var gs = sview:gsplit' '
	for i,len in gs do
		var feat: hb_feature_t
		if hb_feature_from_string(sview:at(i), len, &feat) ~= 0 then
			self.features:add(feat)
		end
	end
end

terra Span:save_features(layout: &Layout, out: &rawstring)
	var sbuf = &layout.r.sbuf
	sbuf.len = 0
	for i,feat in self.features do
		sbuf.min_capacity = sbuf.len + 128
		var p = sbuf:at(sbuf.len)
		hb_feature_to_string(feat, p, 128)
		var n = strnlen(p, 128)
		sbuf.len = sbuf.len + n
		if i < self.features.len-1 then
			sbuf:add(32) --space char
		end
	end
	sbuf:add(0) --null-terminate
	@out = iif(sbuf.len > 1, sbuf.elements, nil)
end

terra Span:load_lang(layout: &Layout, s: rawstring)
	self.lang = hb_language_from_string(s, -1)
end

terra Span:save_lang(layout: &Layout, out: &rawstring)
	@out = hb_language_to_string(self.lang)
end

terra Span:load_script(layout: &Layout, s: rawstring)
	self.script = hb_script_from_string(s, -1)
end

terra Span:save_script(layout: &Layout, out: &rawstring)
	var sbuf = &layout.r.sbuf
	sbuf.len = 5
	var tag = hb_script_to_iso15924_tag(self.script)
	hb_tag_to_string(tag, sbuf.elements)
	@out = iif(sbuf(0) ~= 0, sbuf.elements, nil)
end

terra Span:load_font_id(layout: &Layout, font_id: font_id_t)
	var font = layout.r.fonts:at(font_id, nil)
	self.font_id = iif(font ~= nil, iif(font:ref(), font_id, -1), -1)
end

terra Span:load_nowrap(layout: &Layout, nowrap: bool)
	if self.nowrap ~= nowrap then
		self.nowrap = nowrap
		layout:invalidate_min_w()
	end
end

--NOTE: -1 is two positions outside the text, not one. This allows
--range (0, -1) on empty text to have length 1 otherwise setting span
--attributes on range (0, -1) would not have any effect on empty text.
terra Layout:offset_range(o1: int, o2: int)
	if o1 < 0 then o1 = self.text.len + o1 + 2 end
	if o2 < 0 then o2 = self.text.len + o2 + 2 end
	if o2 < o1 then o2 = o1 end
	return o1, o2
end

SPAN_FIELD_TYPES = {
	font_id           = int       ,
	font_size         = double    ,
	features          = rawstring ,
	script            = rawstring ,
	lang              = rawstring ,
	paragraph_dir     = int       ,
	nowrap            = bool      ,
	color             = uint32    ,
	opacity           = double    ,
	operator          = enum      ,
}

local SPAN_FIELD_MAX_STATE = {
	nowrap            = STATE_SHAPED,
	color             = STATE_ALIGNED,
	opacity           = STATE_ALIGNED,
	operator          = STATE_ALIGNED,
}

--Generate getters and setters for each text attr that can be set on an offset range.
--Uses Layout:save_<field>() and Layout:load_<field> methods if available.
for i,FIELD in ipairs(FIELDS) do

	local T = SPAN_FIELD_TYPES[FIELD]
	local MAX_STATE = SPAN_FIELD_MAX_STATE[FIELD] or 0
	T = T or Span:getfield(FIELD).type

	local SAVE = Span:getmethod('save_'..FIELD)
		or macro(function(self, layout, out) return quote @out = self.[FIELD] end end)

	Layout.methods['get_'..FIELD] = terra(self: &Layout, offset1: int, offset2: int, out: &T)
		offset1, offset2 = self:offset_range(offset1, offset2)
		var span, mask = self:get_span_common_values(offset1, offset2)
		if hasbit(mask, [BIT(i)]) then
			SAVE(span, self, out)
			return true
		else
			return false
		end
	end

	local LOAD = Span:getmethod('load_'..FIELD)
		or macro(function(self, layout, val) return quote self.[FIELD] = val end end)

	Layout.methods['set_'..FIELD] = terra(self: &Layout, offset1: int, offset2: int, val: T)
		offset1, offset2 = self:offset_range(offset1, offset2)
		var i1 = self:split_spans(offset1, true)
		var i2 = self:split_spans(offset2, false)
		for i = i1, i2 do
			var span = self.spans:at(i)
			LOAD(span, self, val)
		end
		self:remove_duplicate_spans(i1-1, i2+1)
		self.state = min(self.state, MAX_STATE)
	end

	--generate an API for working with spans directly as an array.

	Layout.methods['get_span_'..FIELD] = terra(self: &Layout, span_i: int)
		var span = self.spans(span_i, [Span.empty])
		var out: T
		SAVE(&span, self, &out)
		return out
	end

	Layout.methods['set_span_'..FIELD] = terra(self: &Layout, span_i: int, val: T)
		var span = self.spans:getat(span_i, [Span.empty])
		LOAD(span, self, val)
		self.state = min(self.state, MAX_STATE)
	end

end

terra Layout:get_span_offset(span_i: int): int
	return self.spans(span_i, [Span.empty]).offset
end

terra Layout:set_span_offset(span_i: int, val: int)
	self.spans:getat(span_i, [Span.empty]).offset = val
	self.state = 0
end

terra Layout:get_span_count()
	return self.spans.len
end

terra Layout:set_span_count(n: int)
	n = max(n, 0)
	if self.spans.len ~= n then
		self.spans:setlen(n, [Span.empty])
		if self.spans.len == 0 then
			self.spans:add([Span.empty])
		end
		self.state = 0
	end
end

--text editing ---------------------------------------------------------------

--[[
--remove text between two offsets. return offset at removal point.
local terra cmp_remove_first(s1: &Span, s2: &Span)
	return s1.offset < s2.offset  -- < < [=] = > >
end
local terra cmp_remove_last(s1: &Span, s2: &Span)
	return s1.offset <= s2.offset  -- < < = = [>] >
end
terra Layout:remove(i1: int, i2: int)
	i1 = self.spans:clamp(i1)
	i2 = self.spans:clamp(i2)
	self.text:remove(i1, i2-i1)
	--adjust/remove affected spans.
	--NOTE: this includes all zero-length text runs at both ends.

	--1. find the first and last text runs which need to be entirely removed.
	local tr_i1 = self.spans:binsearch(Span{offset = i1}, cmp_remove_first) or #self + 1
	local tr_i2 = self.spans:binsearch(Span{offset = i2}, cmp_remove_last) or #self + 1) - 1
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
]]

--[[
--insert text at offset. return offset after inserted text.
local function cmp_insert(text_runs, i, offset)
	return text_runs[i].offset <= offset -- < < = = [>] >
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
]]
