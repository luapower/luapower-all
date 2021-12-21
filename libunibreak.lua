
--libunibreak ffi binding
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libunibreak_demo'; return end

local ffi = require'ffi'
require'libunibreak_h'

local C = ffi.load'unibreak'
local M = {C = C}

C.init_linebreak()
C.init_wordbreak()
C.init_graphemebreak()

M.version = C.unibreak_version
M.is_line_breakable = C.is_line_breakable

local function set_breaks_func(set_func, code_size)
	return function(s, len, lang, brks)
		len = len or math.floor(#s / code_size)
		brks = brks or ffi.new('char[?]', len)
		set_func(s, len, lang, brks)
		return brks, len
	end
end

M.linebreaks     = set_breaks_func(C.set_linebreaks_utf32    , 4)
M.wordbreaks     = set_breaks_func(C.set_wordbreaks_utf32    , 4)
M.graphemebreaks = set_breaks_func(C.set_graphemebreaks_utf32, 4)

--utf8/16 APIs (deprecated but used in tests)

M.linebreaks_utf8      = set_breaks_func(C.set_linebreaks_utf8     , 1)
M.linebreaks_utf16     = set_breaks_func(C.set_linebreaks_utf16    , 2)
M.wordbreaks_utf8      = set_breaks_func(C.set_wordbreaks_utf8     , 1)
M.wordbreaks_utf16     = set_breaks_func(C.set_wordbreaks_utf16    , 2)
M.graphemebreaks_utf8  = set_breaks_func(C.set_graphemebreaks_utf8 , 1)
M.graphemebreaks_utf16 = set_breaks_func(C.set_graphemebreaks_utf16, 2)

local EOS = 0xFFFFFFFF

local ip = ffi.new'size_t[1]'
local function next_char_func(next_char_func, code_size)
	return function(s, len, start)
		local str = type(s) == 'string'
		len = len or math.floor(#s / code_size)
		ip[0] = start and start + (str and -1 or 0) or 0
		local uc = next_char_func(s, len, ip)
		if uc == EOS then return nil end
		return uc, tonumber(ip[0]) + (str and 1 or 0)
	end
end
M.next_char_utf8  = next_char_func(C.ub_get_next_char_utf8 , 1)
M.next_char_utf16 = next_char_func(C.ub_get_next_char_utf16, 2)

local function iter_func(next_char_func, code_size)
	return function(s, len, start, ip)
		local str = type(s) == 'string'
		len = len or math.floor(#s / code_size)
		local i = str and 0 or -1
		ip = ip or ffi.new'size_t[1]'
		ip[0] = start and start + (str and -1 or 0) or 0
		return function()
			local uc = next_char_func(s, len, ip)
			if uc == EOS then return nil end
			i = i + 1
			return i, uc, tonumber(ip[0]) + (str and 1 or 0)
		end
	end
end

M.chars_utf8  = iter_func(C.ub_get_next_char_utf8 , 1)
M.chars_utf16 = iter_func(C.ub_get_next_char_utf16, 2)

local function len_func(next_char_func, code_size)
	return function(s, len, ip)
		len = len or math.floor(#s / code_size)
		local n = 0
		local uc, start
		while true do
			uc, start = next_char_func(s, len, start)
			if not uc then break end
			n = n + 1
		end
		return n
	end
end
M.len_utf8  = len_func(M.next_char_utf8 , 1)
M.len_utf16 = len_func(M.next_char_utf16, 2)

return M
