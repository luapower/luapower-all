local ub = require'libunibreak'
local ffi = require'ffi'

local line_break_names = {[0] = '=', '-', ' ', '?'}
local word_break_names = {[0] = '=', ' ', '?'}
local grap_break_names = {[0] = '=', ' ', '?'}

print('version', ub.version)
print()

local s = 'The \r\nquick (“brown”) fox can’t jump 32.3 feet,\xC2\x85right?'

local len = ub.len_utf8(s)
print('len', len, #s)
print()

local str = ffi.new('uint32_t[?]', len)
for j, c, i in ub.chars_utf8(s) do
	str[j-1] = c
	print(j, i, c < 256 and string.char(c) or '', string.format('0x%04X', c))
end
print()

local line_brks = ub.linebreaks(str, len)
local word_brks = ub.wordbreaks(str, len)
local grap_brks = ub.graphemebreaks(str, len)
for i=0,len do
	print(
		string.format('0x%04X', str[i]),
		str[i] > 32 and str[i] < 128 and string.char(str[i]) or '',
		line_break_names[line_brks[i]],
		word_break_names[word_brks[i]],
		grap_break_names[grap_brks[i]])
end

