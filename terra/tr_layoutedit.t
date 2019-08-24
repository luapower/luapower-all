
--get/set Layout attributes with minimal invalidation of state.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_cursor'
require'terra/tr_selection'
require'terra/utf8'

terra Layout:text_changed()
	var spans_bk = self.spans:backwards()
	for i,s in spans_bk do
		if s.offset < self.text.len then
			if self.spans:remove(i+1, maxint) > 0 then
				self.state = 0
			end
			break
		end
	end
	self.cursors:call'reset'
	self.selections:call'reset'
end

terra Layout:get_text_len() return self.text.len end
terra Layout:get_text() return self.text.elements end

terra Layout:set_text(s: &codepoint, len: int)
	assert(s ~= nil)
	self.state = 0
	self.text.len = 0
	self.text:add(s, min(self.maxlen, len))
	self:text_changed()
end

terra Layout:get_text_utf8(out: rawstring, max_outlen: int)
	if max_outlen < 0 then
		max_outlen = maxint
	end
	if out == nil then --out buffer size requested
		return utf8.encode.count(self.text.elements, self.text.len,
			max_outlen, utf8.REPLACE, utf8.INVALID)._0
	else
		return utf8.encode.tobuffer(self.text.elements, self.text.len, out,
			max_outlen, utf8.REPLACE, utf8.INVALID)._0
	end
end

terra Layout:get_text_utf8_len()
	return self:get_text_utf8(nil, -1)
end

terra Layout:set_text_utf8(s: rawstring, len: int)
	assert(s ~= nil)
	self.state = 0
	if len < 0 then
		len = strnlen(s, self.maxlen)
	end
	utf8.decode.toarr(s, len, &self.text,
		self.maxlen, utf8.REPLACE, utf8.INVALID)
	self:text_changed()
end

terra Layout:set_maxlen(v: int)
	v = max(v, 0)
	self._maxlen = v
	if self.text.len > v then --truncate the text
		self.text.len = v
		self:text_changed()
	end
end

terra Layout:set_dir(v: bidi_dir_t)
	if self._dir ~= v then
		assert(
			   v == DIR_AUTO
			or v == DIR_LTR
			or v == DIR_RTL
			or v == DIR_WLTR
			or v == DIR_WRTL
		)
		self._dir = v
		self.state = 0
	end
end

terra Layout:set_align_w(v: num)
	if self._align_w ~= v then
		self._align_w = v
		self.state = min(self.state, STATE_WRAPPED - 1)
	end
end

terra Layout:set_align_h(v: num)
	if self._align_h ~= v then
		self._align_h = v
		self.state = min(self.state, STATE_ALIGNED - 1)
	end
end

terra Layout:set_align_x(v: enum)
	if self._align_x ~= v then
		assert(
			   v == ALIGN_LEFT
			or v == ALIGN_RIGHT
			or v == ALIGN_CENTER
			or v == ALIGN_JUSTIFY
			or v == ALIGN_START
			or v == ALIGN_END
		)
		self._align_x = v
		self.state = min(self.state, STATE_ALIGNED - 1)
	end
end

terra Layout:set_align_y(v: enum)
	if self._align_y ~= v then
		assert(
			   v == ALIGN_TOP
			or v == ALIGN_BOTTOM
			or v == ALIGN_CENTER
		)
		self._align_y = v
		self.state = min(self.state, STATE_ALIGNED - 1)
	end
end

terra Layout:set_line_spacing(v: num)
	if self._line_spacing ~= v then
		self._line_spacing = v
		self.state = min(self.state, STATE_SPACED - 1)
	end
end

terra Layout:set_hardline_spacing(v: num)
	if self._hardline_spacing ~= v then
		self._hardline_spacing = v
		self.state = min(self.state, STATE_SPACED - 1)
	end
end

terra Layout:set_paragraph_spacing(v: num)
	if self._paragraph_spacing ~= v then
		self._paragraph_spacing = v
		self.state = min(self.state, STATE_SPACED - 1)
	end
end

terra Layout:set_clip_x(x: num) if self._clip_x ~= x then self._clip_x = x; self.clip_valid = false end end
terra Layout:set_clip_y(y: num) if self._clip_y ~= y then self._clip_y = y; self.clip_valid = false end end
terra Layout:set_clip_w(w: num) if self._clip_w ~= w then self._clip_w = w; self.clip_valid = false end end
terra Layout:set_clip_h(h: num) if self._clip_h ~= h then self._clip_h = h; self.clip_valid = false end end
terra Layout:set_clip_extents(x1: num, y1: num, x2: num, y2: num)
	self.clip_x = x1
	self.clip_y = y1
	self.clip_w = x2-x1
	self.clip_h = y2-y1
end

terra Layout:set_x(x: num)
	if self._x ~= x then
		self._x = x
		self.clip_valid = false
	end
end

terra Layout:set_y(y: num)
	if self._y ~= y then
		self._y = y
		self.clip_valid = false
	end
end
