--[[

	UTF-8 encoding and decoding in Terra.
	Written by Cosmin Apreutesei. Public Domain.

	NOTE: An unfinished sequence gets replaced with a single codepoint.
	NOTE: An invalid byte gets replaced with one codepoint.

	utf8.decode.count    (s,len,    outlen,on_reject,repl_c) -> n, i, q
	utf8.decode.tobuffer (s,len,out,outlen,on_reject,repl_c) -> n, i, q
	utf8.decode.toarr    (s,len,out,outlen,on_reject,repl_c) -> n, i, q

	for valid,i,c in utf8.decode.codepoints(s,len) do ... end

	utf8.encode.count    (s,len,    outlen,on_reject,repl_c) -> n, i, q
	utf8.encode.tobuffer (s,len,out,outlen,on_reject,repl_c) -> n, i, q
	utf8.encode.toarr    (s,len,out,outlen,on_reject,repl_c) -> n, i, q

	on_reject : utf8.REPLACE | utf8.KEEP | utf8.SKIP | utf8.STOP
	repl_c    : utf8.INVALID | any-codepoint

]]

if not ... then require'utf8lib_test'; return end

setfenv(1, require'low')

utf8 = {decode = {}, encode = {}}

--decoding -------------------------------------------------------------------

local C = includecstring[[
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;

// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.

#define UTF8_ACCEPT 0
#define UTF8_REJECT 12

static const uint8_t utf8d[] = {
  // The first part of the table maps bytes to character classes that
  // to reduce the size of the transition table and create bitmasks.
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
   8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

  // The second part is a transition table that maps a combination
  // of a state of the automaton and a character class to a state.
   0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
  12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
  12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
  12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
  12,36,12,12,12,12,12,12,12,12,12,12,
};

uint32_t inline
decode(uint32_t* state, uint32_t* codep, uint32_t byte) {
  uint32_t type = utf8d[byte];

  *codep = (*state != UTF8_ACCEPT) ?
    (byte & 0x3fu) | (*codep << 6) :
    (0xff >> type) & (byte);

  *state = utf8d[256 + *state + type];
  return *state;
}
]]
local ACCEPT = C.UTF8_ACCEPT
local REJECT = C.UTF8_REJECT

utf8.INVALID = 0xFFFD --to use for repl_cp

--invalid_action enum:
utf8.REPLACE = 1 --replace each invalid byte with a specific codepoint
utf8.KEEP    = 2 --keep invalid bytes like browsers do (like it's iso-8859-1)
utf8.SKIP    = 3 --skip invalid bytes
utf8.STOP    = 4 --stop processing on first invalid byte

local decode = macro(function(s, len, add_c, outlen, on_reject, repl_c)
	return quote
		var s = [&uint8](s)
		var curr: uint = 0
		var prev: uint = 0
		var c: codepoint
		var n = 0 --number of output codepoints
		var i = 0 --number of decoded bytes
		var q = 0 --number of invalid sequences
		while i < len do
			var r = C.decode(&curr, &c, s[i])
			var valid = r == ACCEPT
			if r == ACCEPT then goto accept end
			if r == REJECT then
				curr = ACCEPT
				inc(q)
				if on_reject == utf8.REPLACE then
					c = repl_c
				elseif on_reject == utf8.KEEP then
					--
				elseif on_reject == utf8.SKIP then
					goto continue
				elseif on_reject == utf8.STOP then
					q = i
					break
				else
					assert(false)
				end
				if prev ~= ACCEPT then
					dec(i)
				end
				::accept::
				if n < outlen then
					add_c(c, n, i, valid)
					inc(n)
				else
					break
				end
				::continue::
			end
			prev = curr
			inc(i)
		end
		in n, i, q
	end
end)

terra utf8.decode.count(s: rawstring, len: int,
	outlen: int, on_reject: enum, repl_c: codepoint)
	return decode(s, len, noop, outlen, on_reject, repl_c)
end

terra utf8.decode.tobuffer(s: rawstring, len: int, out: &codepoint,
	outlen: int, on_reject: enum, repl_c: codepoint)
	return escape
		local add_c = macro(function(c, i)
			return quote out[i] = c end
		end)
		emit `decode(s, len, add_c, outlen, on_reject, repl_c)
	end
end

terra utf8.decode.toarr(s: rawstring, len: int, out: &arr(codepoint),
	outlen: int, on_reject: enum, repl_c: codepoint)
	out.min_capacity = min(len / 4, outlen)
	out.len = 0
	return escape
		local add_c = macro(function(c, i)
			return quote out:set(i, c) end
		end)
		emit `decode(s, len, add_c, outlen, on_reject, repl_c)
	end
end

local struct utf8_iter { s: rawstring; len: int; }
utf8_iter.metamethods.__for = function(self, body)
	local iter_c = macro(function(c, n, i, valid)
		return body(valid, i, c)
	end)
	return quote
		decode(self.s, self.len, iter_c, maxint, utf8.KEEP, 0)
	end
end
terra utf8.decode.codepoints(s: rawstring, len: int)
	return utf8_iter{s = s, len = len}
end

--encoding -------------------------------------------------------------------

terra utf8.encode.isvalid(c: codepoint)
	return c <= 0x10FFFF and (c < 0xD800 or c > 0xDFFF)
end
utf8.encode.isvalid:setinlined(true)

terra utf8.encode.size(c: codepoint)
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
utf8.encode.size:setinlined(true)

terra utf8.encode.count(
	buf: &codepoint, len: int, outlen: int,
	on_reject: enum, repl_cp: codepoint
)
	var n = 0 --number of output bytes
	var i = 0 --number of encoded codepoints
	var q = 0 --number of invalid codepoints
	var repl_len: int
	if on_reject == utf8.REPLACE then
		assert(utf8.encode.isvalid(repl_cp))
		repl_len = utf8.encode.size(repl_cp)
	elseif on_reject == utf8.SKIP then
	elseif on_reject == utf8.STOP then
	else
		assert(false)
	end
	while i < len do
		if utf8.encode.isvalid(buf[i]) then
			var b = utf8.encode.size(buf[i])
			if n + b < outlen then
				inc(n, b)
			else
				break
			end
		elseif on_reject == utf8.REPLACE then
			inc(n, repl_len)
			inc(q)
		elseif on_reject == utf8.SKIP then
			inc(q)
		elseif on_reject == utf8.STOP then
			q = i
			break
		else
			assert(false)
		end
		inc(i)
	end
	return n, i, q
end

local encode = macro(function(buf, len, add_bytes, outlen, on_reject, repl_cp)
	return quote
		if on_reject == utf8.REPLACE then
			assert(utf8.encode.isvalid(repl_cp))
		end
		var n = 0 --number of output bytes
		var i = 0 --number of encoded codepoints
		var q = 0 --number of invalid codepoints
		while i < len do
			var c = buf[i]
			if not utf8.encode.isvalid(c) then
				if on_reject == utf8.REPLACE then
					inc(q)
					c = repl_cp
				elseif on_reject == utf8.SKIP then
					inc(q)
					goto continue
				elseif on_reject == utf8.STOP then
					q = i
					break
				else
					assert(false)
				end
			end
			if c <= 0x7F then
				if n >= outlen then break end
				add_bytes(n, c)
				inc(n, 1)
			elseif c <= 0x7FF then
				if n + 1 >= outlen then break end
				add_bytes(n,
					0xC0 + ((c >>  6)         ),
					0x80 + ((c      ) and 0x3F))
				inc(n, 2)
			elseif c <= 0xFFFF then
				if n + 2 >= outlen then break end
				add_bytes(n,
					0xE0 + ((c >> 12)         ),
					0x80 + ((c >>  6) and 0x3F),
					0x80 + ((c      ) and 0x3F))
				inc(n, 3)
			else
				if n + 3 >= outlen then break end
				add_bytes(n,
					0xF0 + ((c >> 18)         ),
					0x80 + ((c >> 12) and 0x3F),
					0x80 + ((c >>  6) and 0x3F),
					0x80 + ((c      ) and 0x3F))
				inc(n, 4)
			end
			::continue::
			inc(i)
		end
		in n, i, q
	end
end)

terra utf8.encode.tobuffer(
	buf: &codepoint, len: int, out: rawstring, outlen: int,
	on_reject: enum, repl_cp: codepoint
)
	return escape
		local add_bytes = macro(function(n, ...)
			local t = {}
			for i=1,select('#',...) do
				local exp = select(i,...)
				add(t, quote [&uint8](out)[n+i-1] = exp end)
			end
			return t
		end)
		emit `encode(buf, len, add_bytes, outlen, on_reject, repl_cp)
	end
end

terra utf8.encode.toarr(
	buf: &codepoint, len: int, out: &arr(int8), outlen: int,
	on_reject: enum, repl_cp: codepoint
)
	out.min_capacity = min(len, outlen)
	out.len = 0
	return escape
		local add_bytes = macro(function(n, ...)
			local b = select('#',...)
			local t = {}
			add(t, quote out.len = n + b end)
			for i=1,b do
				local exp = select(i,...)
				add(t, quote [&uint8](out.elements)[n+i-1] = exp end)
			end
			return t
		end)
		emit `encode(buf, len, add_bytes, outlen, on_reject, repl_cp)
	end
end
