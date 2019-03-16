
--UTF-8 encoding and decoding in Terra.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'utf8lib_test'; return end

setfenv(1, require'low')

local utf8 = {}

-- byte 1     byte 2      byte 3     byte 4
--------------------------------------------
-- 00 - 7F
-- C2 - DF    80 - BF
-- E0         A0 - BF     80 - BF
-- E1 - EC    80 - BF     80 - BF
-- ED         80 - 9F     80 - BF
-- EE - EF    80 - BF     80 - BF
-- F0         90 - BF     80 - BF    80 - BF
-- F1 - F3    80 - BF     80 - BF    80 - BF
-- F4         80 - 8F     80 - BF    80 - BF

local terra decode_counts(p: rawstring, len: intptr, stop_on_invalid: bool): {intptr, intptr}
	var p = [&uint8](p)
	var eof = p+len
	var n: intptr = 0 --valid codepoint count
 	var q: intptr = 0 --invalid byte count
	while p < eof do
		if p[0] <= 0x7F then --ASCII
			inc(p); inc(n); goto continue
		elseif p[0] < 0xC2 then --invalid
		elseif p[0] <= 0xDF then --2-byte
			if p + 1 < eof and p[1] >= 0x80 and p[1] <= 0xBF then
				inc(p, 2); inc(n); goto continue
			end
		elseif p[0] <= 0xEF then --3-byte
			if p + 2 < eof and not (
				   p[1] < 0x80 or p[1] > 0xBF
				or p[2] < 0x80 or p[2] > 0xBF
				or (p[0] == 0xE0 and p[1] < 0xA0)
				or (p[0] == 0xED and p[1] > 0x9F)
			) then
				inc(p, 3); inc(n); goto continue
			end
		elseif p[0] <= 0xF4 then --4-byte
			if p + 3 < eof and not (
					 p[1] < 0x80 or p[1] > 0xBF
				or  p[2] < 0x80 or p[2] > 0xBF
				or  p[2] < 0x80 or p[2] > 0xBF
				or  p[3] < 0x80 or p[3] > 0xBF
				or (p[0] == 0xF0 and p[1] < 0x90)
				or (p[0] == 0xF4 and p[1] > 0x8F)
			) then
				inc(p, 4); inc(n); goto continue
			end
		end
		if stop_on_invalid then
			return n, eof-p-1
		end
		inc(p); inc(q)
		::continue::
	end
	return n, q
end

terra utf8.next(buf: rawstring, len: intptr, i: intptr): {intptr, codepoint}
	var buf = [&uint8](buf)
	if i >= len then
		return -1, 0 --EOF
	end
	var c1 = buf[i]
	i = i + 1
	if c1 <= 0x7F then
		return i, c1 --ASCII
	elseif c1 < 0xC2 then
		--invalid
	elseif c1 <= 0xDF then --2-byte
		if i < len then
			var c2 = buf[i]
			if c2 >= 0x80 and c2 <= 0xBF then
				return i + 1,
					  ((c1 and 0x1F) << 6)
					+  (c2 and 0x3F)
			end
		end
	elseif c1 <= 0xEF then --3-byte
		if i < len + 1 then
			var c2, c3 = buf[i], buf[i+1]
			if not (
				   c2 < 0x80 or c2 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or (c1 == 0xE0 and c2 < 0xA0)
				or (c1 == 0xED and c2 > 0x9F)
			) then
				return i + 2,
					  ((c1 and 0x0F) << 12)
					+ ((c2 and 0x3F) << 6)
					+  (c3 and 0x3F)
			end
		end
	elseif c1 <= 0xF4 then --4-byte
		if i < len + 2 then
			var c2, c3, c4 = buf[i], buf[i+1], buf[i+2]
			if not (
				   c2 < 0x80 or c2 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or c4 < 0x80 or c4 > 0xBF
				or (c1 == 0xF0 and c2 < 0x90)
				or (c1 == 0xF4 and c2 > 0x8F)
			) then
				return i + 3,
					  ((c1 and 0x07) << 18)
					+ ((c2 and 0x3F) << 12)
				   + ((c3 and 0x3F) << 6)
				   +  (c4 and 0x3F)
			end
		end
	end
	return -2, c1 --invalid
end

struct utf8.codepoints {
	buf: rawstring;
	len: intptr;
}
utf8.codepoints.metamethods.__for = function(self, body)
	return quote
		var i: intptr = 0
		while true do
			var i1, cp = utf8.next(self.buf, self.len, i)
			if i1 == -1 then break end
			[ body(i1, cp) ]
			i = i1
		end
	end
end

utf8.REPLACE = 1 --replace each invalid byte with a specific codepoint
utf8.KEEP    = 2 --interpret invalid bytes as iso-8859-1 chars like browsers do
utf8.SKIP    = 3 --skip invalid bytes
utf8.STOP    = 4 --stop processing on first invalid byte

terra utf8.decode(
	buf: rawstring, len: intptr, out: &codepoint, outlen: intptr,
	invalid_action: enum, repl_cp: codepoint
): {intptr, intptr}
	if out == nil then --requesting counts
		var n, q = decode_counts(buf, len, invalid_action == utf8.STOP)
		if invalid_action == utf8.REPLACE then
			return n + q, q
		elseif invalid_action == utf8.KEEP then
			return n + q, q
		elseif invalid_action == utf8.SKIP then
			return n, q
		elseif invalid_action == utf8.STOP then
			return n, q
		else
			assert(false)
		end
	end
	var i: intptr = 0
	var j: intptr = 0
	while true do
		var i1, cp = utf8.next(buf, len, i)
		if i1 == -1 then --EOF
			break
		elseif i1 == -2 then --invalid sequence, c is the next byte
			i1 = i + 1
			if invalid_action == utf8.REPLACE then
				cp = repl_cp
				goto set
			elseif invalid_action == utf8.KEEP then
				goto set
			elseif invalid_action == utf8.SKIP then
				--
			elseif invalid_action == utf8.STOP then
				return j, eof-j
			else
				assert(false)
			end
		else
			::set::
			if j < outlen then
				out[j] = cp
				inc(j)
			else
				break
			end
		end
		i = i1
	end
	return j, i
end

terra utf8.isvalid(c: codepoint)
	return c <= 0x10FFFF and (c < 0xD800 or c > 0xDFFF)
end

local terra utf8len(c: codepoint)
	if c <= 0x7F then
		return 1
	elseif c <= 0x7FF then
		return 2
	elseif c <= 0xFFFF then
		return 3
	else
		return 4
	end
end

local terra encode_counts(
	buf: &codepoint, len: intptr,
	invalid_action: enum, repl_cp: codepoint
): {intptr, intptr}
	var b: intptr = 0 --number of output bytes needed to encode the buffer
	var q: intptr = 0 --number of invalid codepoints
	var repl_len: int8 = 0
	if invalid_action == utf8.REPLACE then
		assert(utf8.isvalid(repl_cp))
		repl_len = utf8len(repl_cp)
	elseif invalid_action == utf8.SKIP then
	elseif invalid_action == utf8.STOP then
	else
		assert(false)
	end
	for i: intptr = 0, len do
		if utf8.isvalid(buf[i]) then
			inc(b, utf8len(buf[i]))
		elseif invalid_action == utf8.REPLACE then
			inc(b, repl_len)
			inc(q)
		elseif invalid_action == utf8.SKIP then
			inc(q)
		elseif invalid_action == utf8.STOP then
			q = i
			break
		else
			assert(false)
		end
	end
	return b, q
end

terra utf8.encode(
	buf: &codepoint, len: intptr, out: rawstring, outlen: intptr,
	invalid_action: enum, repl_cp: codepoint
): {intptr, intptr}
	if out == nil then
		return encode_counts(buf, len, invalid_action, repl_cp)
	end
	if invalid_action == utf8.REPLACE then
		assert(utf8.isvalid(repl_cp))
	end
	var j: intptr = 0
	var eof = out + outlen
	for i: intptr = 0, len do
		var c = buf[i]
		if (c >= 0xD800 and c <= 0xDFFF) or c > 0x10FFFF then --invalid
			if invalid_action == utf8.REPLACE then
				c = repl_cp
			elseif invalid_action == utf8.SKIP then
				goto continue
			elseif invalid_action == utf8.STOP then
				break
			else
				assert(false)
			end
		end
		if c <= 0x7F then
			if out >= eof then break end
			out[0] = c
			inc(out, 1)
		elseif c <= 0x7FF then
			if out + 1 >= eof then break end
			out[1] = 0x80 + ((c      ) and 0x3F)
			out[0] = 0xC0 + ((c >>  6)         )
			inc(out, 2)
		elseif c <= 0xFFFF then
			if out + 2 >= eof then break end
			out[2] = 0x80 + ((c      ) and 0x3F)
			out[1] = 0x80 + ((c >>  6) and 0x3F)
			out[0] = 0xE0 + ((c >> 12)         )
			inc(out, 3)
		else
			if out + 3 >= eof then break end
			out[3] = 0x80 + ((c      ) and 0x3F)
			out[2] = 0x80 + ((c >>  6) and 0x3F)
			out[1] = 0x80 + ((c >> 12) and 0x3F)
			out[0] = 0xF0 + ((c >> 18)         )
			inc(out, 4)
		end
		::continue::
	end
	return outlen-(eof-out)
end

return utf8
