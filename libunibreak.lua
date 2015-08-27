--libunibreak binding
local ffi = require'ffi'

--linebreak.h and wordbreak.h from libunibreak 1.0
ffi.cdef[[
const int linebreak_version;

typedef unsigned char utf8_t;
typedef unsigned short utf16_t;
typedef unsigned int utf32_t;

enum {
	LINEBREAK_MUSTBREAK   = 0,  // Break is mandatory.
	LINEBREAK_ALLOWBREAK  = 1,  // Break is allowed.
	LINEBREAK_NOBREAK     = 2,  // No break is possible.
	LINEBREAK_INSIDEACHAR = 3,  // A UTF-8/16 sequence is unfinished.
};

void init_linebreak(void);
void set_linebreaks_utf8(const utf8_t *s, size_t len, const char* lang, char *brks);
void set_linebreaks_utf16(const utf16_t *s, size_t len, const char* lang, char *brks);
void set_linebreaks_utf32(const utf32_t *s, size_t len, const char* lang, char *brks);
int is_line_breakable(utf32_t char1, utf32_t char2, const char* lang);

enum {
	WORDBREAK_BREAK       = 0,  // Break is allowed.
	WORDBREAK_NOBREAK     = 1,  // No break is allowed.
	WORDBREAK_INSIDEACHAR = 2,  // A UTF-8/16 sequence is unfinished.
};

void init_wordbreak(void);
void set_wordbreaks_utf8(const utf8_t *s, size_t len, const char* lang, char *brks);
void set_wordbreaks_utf16(const utf16_t *s, size_t len, const char* lang, char *brks);
void set_wordbreaks_utf32(const utf32_t *s, size_t len, const char* lang, char *brks);

utf32_t lb_get_next_char_utf8(const utf8_t *s, size_t len, size_t *ip);
utf32_t lb_get_next_char_utf16(const utf16_t *s, size_t len, size_t *ip);
utf32_t lb_get_next_char_utf32(const utf32_t *s, size_t len, size_t *ip);
]]

local C = ffi.load'unibreak'
local M = {C = C}

C.init_linebreak()
C.init_wordbreak()

M.version = C.linebreak_version
M.is_line_breakable = C.is_line_breakable

local function set_breaks_func(set_func, code_size)
	return function(s, len, lang, brks)
		len = len or math.floor(#s / code_size)
		brks = brks or ffi.new('char[?]', len)
		set_func(s, len, lang, brks)
		return brks, len
	end
end

M.linebreaks_utf8  = set_breaks_func(C.set_linebreaks_utf8, 1)
M.linebreaks_utf16 = set_breaks_func(C.set_linebreaks_utf16, 2)
M.linebreaks_utf32 = set_breaks_func(C.set_linebreaks_utf32, 4)

M.wordbreaks_utf8  = set_breaks_func(C.set_wordbreaks_utf8, 1)
M.wordbreaks_utf16 = set_breaks_func(C.set_wordbreaks_utf16, 2)
M.wordbreaks_utf32 = set_breaks_func(C.set_wordbreaks_utf32, 4)

local EOS = 0xFFFF

local function iter_func(next_char_func, code_size) --func(s[,len]) -> iter() -> uc
	return function(s, len, ip)
		len = len or math.floor(#s / code_size)
		ip = ip or ffi.new'size_t[1]'
		return function()
			local uc = next_char_func(s, len, ip)
			if uc == EOS then return nil end
			return ip[0]+1, uc
		end
	end
end

M.chars_utf8  = iter_func(C.lb_get_next_char_utf8, 1)
M.chars_utf16 = iter_func(C.lb_get_next_char_utf16, 2)
M.chars_utf32 = iter_func(C.lb_get_next_char_utf32, 4)

local function len_func(next_char_func, code_size)
	return function(s, len, ip)
		len = len or math.floor(#s / code_size)
		ip = ip or ffi.new'size_t[1]'
		local n = 0
		while next_char_func(s, len, ip) ~= EOS do
			n = n + 1
		end
		return n
	end
end

M.len_utf8  = len_func(C.lb_get_next_char_utf8, 1)
M.len_utf16 = len_func(C.lb_get_next_char_utf16, 2)
M.len_utf32 = len_func(C.lb_get_next_char_utf32, 4)


if not ... then require'libunibreak_demo' end

return M
