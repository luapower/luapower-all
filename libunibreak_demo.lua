local ub = require'libunibreak'

local line_break_names = {[0] = '!', 'Y', 'N', '?'}
local word_break_names = {[0] = 'Y', 'N', '?'}
local grap_break_names = {[0] = 'Y', 'N', '?'}

print('version', ub.version)
print()

local s = 'The quick (“brown”) fox can’t jump 32.3 feet,\xC2\x85right?'

print('len', ub.len_utf8(s), #s)
print()

local j = 0
for c, i in ub.chars_utf8(s) do
	j = j + 1
	print(j, i, c < 256 and string.char(c) or '', string.format('0x%X', c))
end
print()

local line_brks = ub.linebreaks_utf8(s)
local word_brks = ub.wordbreaks_utf8(s)
local grap_brks = ub.graphemebreaks_utf8(s)
for i=1,#s do
	print(s:sub(i,i),
		line_break_names[line_brks[i-1]],
		word_break_names[word_brks[i-1]],
		grap_break_names[grap_brks[i-1]])
end

