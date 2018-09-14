
--UTF-8 encoding and decoding for LuaJIT
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'utf8_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local band, shl, shr = bit.band, bit.lshift, bit.rshift
local utf8 = {}

local uint32_array = ffi.typeof'uint32_t[?]'
local uint8_array = ffi.typeof'uint8_t[?]'
local uint32_ptr = ffi.typeof'const uint32_t*'
local uint8_ptr = ffi.typeof'const uint8_t*'

local function tobuf(s, len, ct, sizeof_ct)
	if type(s) == 'string' then
		return s, ffi.cast(ct or uint8_ptr, s),
			math.min(len or 1/0, #s / (sizeof_ct or 1))
	else
		return nil, s, len
	end
end

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

function utf8.next(buf, len, i)
	if i >= len then
		return nil --EOS
	end
	local c1 = buf[i]
	i = i + 1
	if c1 <= 0x7F then
		return i, c1 --ASCII
	elseif c1 < 0xC2 then
		--invalid
	elseif c1 <= 0xDF then --2-byte
		if i < len then
			local c2 = buf[i]
			if c2 >= 0x80 and c2 <= 0xBF then
				return i + 1,
				      shl(band(c1, 0x1F), 6)
				        + band(c2, 0x3F)
			end
		end
	elseif c1 <= 0xEF then --3-byte
		if i < len + 1 then
			local c2, c3 = buf[i], buf[i+1]
			if not (
				   c2 < 0x80 or c2 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or (c1 == 0xE0 and c2 < 0xA0)
				or (c1 == 0xED and c2 > 0x9F)
			) then
				return i + 2,
				      shl(band(c1, 0x0F), 12)
				    + shl(band(c2, 0x3F), 6)
				        + band(c3, 0x3F)
			end
		end
	elseif c1 <= 0xF4 then --4-byte
		if i < len + 2 then
			local c2, c3, c4 = buf[i], buf[i+1], buf[i+2]
			if not (
				   c2 < 0x80 or c2 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or c3 < 0x80 or c3 > 0xBF
				or c4 < 0x80 or c4 > 0xBF
				or (c1 == 0xF0 and c2 < 0x90)
				or (c1 == 0xF4 and c2 > 0x8F)
			) then
				return i + 3,
				     shl(band(c1, 0x07), 18)
				   + shl(band(c2, 0x3F), 12)
				   + shl(band(c3, 0x3F), 6)
				       + band(c4, 0x3F)
			end
		end
	end
	return i, nil, c1 --invalid
end

function utf8.prev(buf, len, i)
	if i <= 0 then
		return nil
	end
	local j = i
	while i > 0 do --go back to a previous possible start byte
		i = i - 1
		local c = buf[i]
		if c < 0x80 or c > 0xBF or i == j-4 then
			break
		end
	end
	while true do --go forward to the real previous character
		local i1, c, b = utf8.next(buf, len, i)
		i1 = i1 or len
		if i1 == j then
			return i, c, b
		end
		i = i1
		assert(i < j)
	end
end

function utf8.chars(s, i)
	local _, buf, len = tobuf(s)
	i = i and i-1 or 0
	return function()
		local c, b
		i, c, b = utf8.next(buf, len, i)
		if not i then return nil end
		return i+1, c, b
	end
end

--pass `false` to `out` to only get the output length.
--pass `nil` to `out` to have the function allocate the buffer.
function utf8.decode(buf, len, out, outlen, repl)
	local _, buf, len = tobuf(buf, len)
	if out == nil then
		outlen = outlen or utf8.decode(buf, len, false, nil, repl)
		out = uint32_array(outlen + 1)
	end
	outlen = outlen or 1/0
	local j, p, i = 0, 0, 0
	while true do
		local i1, c = utf8.next(buf, len, i)
		if not i1 then
			break
		end
		if not c then
			p = p + 1
			if repl == 'iso-8859-1' then
				c = buf[i] --interpret as iso-8859-1 like browsers do
			else
				c = repl
			end
		end
		if c then
			if j >= outlen then
				return nil, 'buffer overflow', i
			end
			if out then
				out[j] = c
			end
			j = j + 1
		end
		i = i1
	end
	if out then
		return out, j, p
	else
		return j, p
	end
end

local function char_byte_count(c, invalid_size)
	if c < 0 or c > 0x10FFFF or (c >= 0xD800 and c <= 0xDFFF) then
		return invalid_size
	elseif c <= 0x7F then
		return 1
	elseif c <= 0x7FF then
		return 2
	elseif c <= 0xFFFF then
		return 3
	else
		return 4
	end
end

local function byte_count(buf, len, repl)
	local n = 0
	local invalid_size = repl and char_byte_count(repl, 0) or 0
	for i = 0, len-1 do
		n = n + char_byte_count(buf[i], invalid_size)
	end
	return n
end

local function encode_char(c, repl)
	local n, b1, b2, b3, b4 = 0
	if c >= 0xD800 and c <= 0xDFFF then --surrogate pair
		if repl then
			return encode_char(repl)
		end
	elseif c <= 0x7F then
		b1 = c
		n = 1
	elseif c <= 0x7FF then
		b2 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b1 = 0xC0 + c
		n = 2
	elseif c <= 0xFFFF then
		b3 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b2 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b1 = 0xE0 + c
		n = 3
	elseif c <= 0x10FFFF then
		b4 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b3 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b2 = 0x80 + band(c, 0x3F); c = shr(c, 6)
		b1 = 0xF0 + c
		n = 4
	elseif repl then
		return enncode_char(repl)
	end
	return n, b1, b2, b3, b4
end

function utf8.encode(buf, len, out, outlen, repl)
	local _, buf, len = tobuf(buf, len, uint32_ptr, 4)
	if out == nil then --allocate output buffer
		outlen = outlen or utf8.encode(buf, len, false, nil, repl)
		out = uint8_array(outlen + 1)
	elseif not out then --compute output length
		return byte_count(buf, len, repl)
	end
	local j = 0
	for i = 0, len-1 do
		local n, b1, b2, b3, b4 = encode_char(buf[i], repl)
		if n > outlen then
			return nil, 'buffer overflow'
		end
		if b1 then out[j  ] = b1 end
		if b2 then out[j+1] = b2 end
		if b3 then out[j+2] = b3 end
		if b4 then out[j+3] = b4 end
		j = j + n
		outlen = outlen - n
	end
	return out, j
end

function utf8.encode_chars(...)
	local char = string.char
	local out = {}
	local t, repl = ...
	if type(t) == 'table' then
		local j = 1
		for i = 1, #t do
			local c = t[i]
			local n, b1, b2, b3, b4 = encode_char(c, repl)
			if b1 then out[j  ] = char(b1) end
			if b2 then out[j+1] = char(b2) end
			if b3 then out[j+2] = char(b3) end
			if b4 then out[j+3] = char(b4) end
			j = j + n
		end
	else
		local j = 1
		for i = 1, select('#',...) do
			local c = select(i, ...)
			local n, b1, b2, b3, b4 = encode_char(c)
			if b1 then out[j  ] = char(b1) end
			if b2 then out[j+1] = char(b2) end
			if b3 then out[j+2] = char(b3) end
			if b4 then out[j+3] = char(b4) end
			j = j + n
		end
	end
	return table.concat(out)
end

return utf8
