--string module for codedit (Cosmin Apreutesei, public domain).
--deals specifically with tabs, spaces, lines and words.
local glue = require'glue'
local utf8 = require'utf8'

local str = glue.update({}, utf8)

--tabs and whitespace ----------------------------------------------------------------------------------------------------

--check for an ascii char at a byte index without string creation
function str.isascii(s, i, c)
	assert(i >= 1 and i <= #s, 'out of range')
	return s:byte(i) == c:byte(1)
end

--check if the char at byte index i is a tab
function str.istab(s, i)
	return str.isascii(s, i, '\t')
end

--check if the char at byte index i is a space char
function str.isspacechar(s, i)
	return str.isascii(s, i, ' ')
end

--check if the char at byte index i is a whitespace char
function str.isspace(s, i)
	return str.isspacechar(s, i) or str.istab(s, i)
end

--char index of the next non-space char after some char (nil if none).
--if after_ci is ommited, the first non-space char in the string is returned.
function str.next_nonspace(s, after_ci)
	after_ci = after_ci or 0
	local ci = 0
	for i in str.byte_indices(s) do
		ci = ci + 1
		if ci > after_ci and not str.isspace(s, i) then
			return ci
		end
	end
end

--char index of the next double-space char after some char (nil if none).
--if after_ci is ommited, the first double-space char in the string is returned.
function str.next_double_space(s, after_ci)
	after_ci = after_ci or 0
	local ci = 0
	local was_space
	for i in str.byte_indices(s) do
		ci = ci + 1
		if ci > after_ci and str.isspace(s, i) then
			if was_space then
				return ci
			else
				was_space = true
			end
		else
			was_space = false
		end
	end
end

--char index of the last non-space char before some char (nil if none).
--if before_ci is ommited, the last non-space char in the string is returned.
function str.prev_nonspace(s, before_ci)
	before_ci = before_ci or 1/0
	local ci = 0
	local ns_ci
	for i in str.byte_indices(s) do
		ci = ci + 1
		if ci >= before_ci then
			return ns_ci
		end
		if not str.isspace(s, i) then
			ns_ci = ci
		end
	end
	return ns_ci
end

--left trim of space and tab characters
function str.ltrim(s)
	local ns_ci = str.next_nonspace(s)
	return ns_ci and str.sub(s, ns_ci) or ''
end

--right trim of space and tab characters
function str.rtrim(s)
	local ns_ci = str.prev_nonspace(s)
	return ns_ci and str.sub(s, 1, ns_ci) or ''
end

--number of tabs and of spaces in indentation
--TODO: use this
function str.indent_counts(s)
	local tabs, spaces = 0, 0
	for i in str.byte_indices(s) do
		if str.istab(s, i) then
			tabs = tabs + 1
		elseif str.isspace(s, i) then
			spaces = spaces + 1
		else
			break
		end
	end
	return tabs, spaces
end

--lines ------------------------------------------------------------------------------------------------------------------

--return the index where the next line starts (unimportant) and the indices of the line starting at a given index.
--the last line is the substring after the last line terminator to the end of the string (see tests).
function str.next_line_indices(s, i)
	i = i or 1
	if i == #s + 1 then --string ended with newline, or string is empty: iterate one more empty line
		return 1/0, i, i-1
	elseif i > #s then
		return
	end
	local j, nexti = s:match('^[^\r\n]*()\r?\n?()', i)
	if nexti > #s and j == nexti then --string ends without a newline, mark that by setting nexti to inf
		nexti = 1/0
	end
	return nexti, i, j-1
end

--iterate lines, returning the index where the next line starts (unimportant) and the indices of each line
function str.line_indices(s)
	return str.next_line_indices, s
end

--return the index where the next line starts (unimportant) and the contents of the line starting at a given index.
--the last line is the substring after the last line terminator to the end of the string (see tests).
function str.next_line(s, i)
	local _, i, j = str.next_line_indices(s, i)
	if not _ then return end
	return _, s:sub(i, j)
end

--iterate lines, returning the index where the next line starts (unimportant) and the contents of each line
function str.lines(s)
	return str.next_line, s
end

function str.line_count(s)
	local n = 0
	for _ in str.line_indices(s) do
		n = n + 1
	end
	return n
end

--words ------------------------------------------------------------------------------------------------------------------

function str.isword(s, i, word_chars)
	return s:find(word_chars, i) ~= nil
end

--from a char index, search forwards for:
	--1) 1..n spaces followed by a non-space char
	--2) 1..n word chars or non-word chars follwed by case 1
	--3) 1..n word chars followed by a non-word char
	--4) 1..n non-word chars followed by a word char
--if the next break should be on a different line, return nil.
function str.next_word_break(s, first_ci, word_chars)
	if first_ci < 1 then return 1 end
	local firsti = str.byte_index(s, first_ci)
	if not firsti then return end
	local expect = str.isspace(s, firsti) and 'space' or str.isword(s, firsti, word_chars) and 'word' or 'nonword'
	local ci = first_ci
	for i in str.byte_indices(s, firsti) do
		ci = ci + 1
		if expect == 'space' then --case 1
			if not str.isspace(s, i) then --case 1 exit
				return ci
			end
		elseif str.isspace(s, i) then --case 2 -> case 1
			expect = 'space'
		elseif expect ~= (str.isword(s, i, word_chars) and 'word' or 'nonword') then --case 3 and 4 exit
			return ci
		end
	end
	return ci + 1
end

--from a char index, search backwards for:
	--1) 1..n spaces followed by 1..n words or non-words
	--2) 1 words or non-words followed by case 1
	--3) 2..n words or non-words follwed by a char of a differnt class
--in other words: look back until the char type changes from the type at firsti or of the prev. char, and skip spaces.
--if the prev. break should be on a different line, return nil.
function str.prev_word_break(s, first_ci, word_chars)
	if first_ci <= 1 then return end
	local firsti = str.byte_index(s, first_ci)
	local expect = not firsti and 'prev' or
			(str.isspace(s, firsti) and 'space' or str.isword(s, firsti, word_chars) and 'word' or 'nonword')
	local lasti = firsti
	local ci = first_ci
	for i in str.byte_indices_reverse(s, firsti) do
		ci = ci - 1
		if expect == 'space' then
			if not str.isspace(s, i) then
				expect = str.isword(s, i, word_chars) and 'word' or 'nonword'
			end
		elseif expect ~= (str.isspace(s, i) and 'space' or str.isword(s, i, word_chars) and 'word' or 'nonword') then
			if lasti == firsti then
				expect =
					str.isspace(s, i) and 'space' or
					str.isword(s, i, word_chars) and 'word' or 'nonword'
			else
				return ci + 1
			end
		end
		lasti = i
	end
	return 1
end


--tests ------------------------------------------------------------------------------------------------------------------

if not ... then

assert(str.next_nonspace('') == nil)
assert(str.next_nonspace(' ') == nil)
assert(str.next_nonspace(' x') == 2)
assert(str.next_nonspace(' x ') == 2)
assert(str.next_nonspace('x ') == 1)

assert(str.prev_nonspace('') == nil)
assert(str.prev_nonspace(' ') == nil)
assert(str.prev_nonspace('x') == 1)
assert(str.prev_nonspace('x ') == 1)
assert(str.prev_nonspace(' x ') == 2)

assert(str.rtrim('abc \t ') == 'abc')
assert(str.rtrim(' \t abc  x \t ') == ' \t abc  x')
assert(str.rtrim('abc') == 'abc')
assert(str.rtrim('  ') == '')
assert(str.rtrim('') == '')

local function assert_lines(s, t)
	local i = 0
	local dt = {}
	for _,s in str.lines(s) do
		i = i + 1
		assert(t[i] == s, i .. ': "' .. s .. '" ~= "' .. tostring(t[i]) .. '"')
		dt[i] = s
	end
	assert(i == #t, i .. ' ~= ' .. #t .. ': ' .. table.concat(dt, ', '))
end
assert_lines('', {''})
assert_lines(' ', {' '})
assert_lines('x\ny', {'x', 'y'})
assert_lines('x\ny\n', {'x', 'y', ''})
assert_lines('x\n\ny', {'x', '', 'y'})
assert_lines('\n', {'', ''})
assert_lines('\n\r\n', {'','',''})
assert_lines('\r\n\n', {'','',''})
assert_lines('\n\r', {'','',''})
assert_lines('\n\r\n\r', {'','','',''})
assert_lines('\n\n\r', {'','','',''})

--TODO: next_word_break, prev_word_break

end


if not ... then require'codedit_demo' end

return str

