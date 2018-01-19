
--plain text boundaries
--Written by Cosmin Apreutesei. Public Domain.

--features: char, tab, whitespace, line and word boundaries.
--can be monkey-patched to work with utf8 grapheme clusters.

local str = {}

--char (i.e. grapheme cluster) boundaries ------------------------------------

--next_char() and prev_char() are the only functions that need to be
--overwritten with utf8 variants in order to fully support unicode.

function str.next_char(s, i)
	i = i or 0
	assert(i >= 0)
	if i >= #s then return end
	return i + 1
end

function str.prev_char(s, i)
	i = i or #s + 1
	assert(i <= #s + 1)
	if i <= 1 then return end
	return i - 1
end

function str.chars(s, i)
	return str.next_char, s, i
end

function str.chars_reverse(s, i)
	return str.prev_char, s, i
end

--tabs and whitespace boundaries ---------------------------------------------

function str.isascii(s, i)
	assert(i >= 1 and i <= #s)
	return s:byte(i) >= 0 and s:byte(i) <= 127
end

--check an ascii char at a byte index without string creation
function str.ischar(s, i, c)
	assert(i >= 1 and i <= #s)
	return s:byte(i) == c:byte(1)
end

function str.isspace(s, i)
	return str.ischar(s, i, ' ')
end

function str.istab(s, i)
	return str.ischar(s, i, '\t')
end

function str.isterm(s, i)
	return str.ischar(s, i, '\r') or str.ischar(s, i, '\n')
end

function str.iswhitespace(s, i)
	return str.isspace(s, i) or str.istab(s, i) or str.isterm(s, i)
end

function str.isnonspace(s, i)
	return not str.iswhitespace(s, i)
end

function str.next_char_which(s, i, is)
	for i in str.chars(s, i) do
		if is(s, i) then
			return i
		end
	end
end

function str.prev_char_which(s, i, is)
	for i in str.chars_reverse(s, i) do
		if is(s, i) then
			return i
		end
	end
end

--byte index of the last non-space char before some char (nil if none).
function str.prev_nonspace_char(s, i)
	return str.prev_char_which(s, i, str.isnonspace)
end

--byte index of the next non-space char after some char (nil if none).
function str.next_nonspace_char(s, i)
	return str.next_char_which(s, i, str.isnonspace)
end

--byte index of the next double-space char after some char (nil if none).
function str.next_double_space_char(s, i)
	repeat
		i = str.next_char(s, i)
		if i and str.iswhitespace(s, i) then
			local i0 = i
			i = str.next_char(s, i)
			if i and str.iswhitespace(s, i) then
				return i0
			end
		end
	until not i
end

--right trim of space and tab characters
function str.rtrim(s)
	local i = str.prev_nonspace_char(s)
	return i and s:sub(1, i) or ''
end

--number of tabs and number of spaces in indentation
function str.indent_counts(s)
	local tabs, spaces = 0, 0
	for i in str.chars(s) do
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

--word boundaries ------------------------------------------------------------

function str.isword(s, i, word_chars)
	return s:find(word_chars, i) ~= nil
end

--search forwards for:
	--1) 1..n spaces followed by a non-space char
	--2) 1..n non-space chars follwed by case 1
	--3) 1..n word chars followed by a non-word char
	--4) 1..n non-word chars followed by a word char
--if the next break should be on a different line, return nil.
function str.next_word_break_char(s, i, word_chars)
	i = i or 0
	assert(i >= 0)
	if i == 0 then return 1 end
	if i >= #s then return end
	if str.isterm(s, i) then return end
	local expect =
		str.iswhitespace(s, i) and 'space'
		or str.isword(s, i, word_chars) and 'word'
		or 'nonword'
	for i in str.chars(s, i) do
		if str.isterm(s, i) then return end
		if expect == 'space' then --case 1
			if not str.iswhitespace(s, i) then --case 1 exit
				return i
			end
		elseif str.iswhitespace(s, i) then --case 2 -> case 1
			expect = 'space'
		elseif
			expect ~= (str.isword(s, i, word_chars) and 'word' or 'nonword')
		then --case 3 and 4 exit
			return i
		end
	end
	return str.next_char(s, i)
end

--NOTE: this is O(#s) so use it only on short strings (single lines of text).
function str.prev_word_break_char(s, firsti, word_chars)
	local lasti
	while true do
		local i = str.next_word_break_char(s, lasti, word_chars)
		if not i then return end
		if i >= firsti then return lasti end
		lasti = i
	end
end

--line boundaries ------------------------------------------------------------

--check if a string ends with a line terminator
function str.hasterm(s)
	return #s > 0 and str.isterm(s, #s)
end

--remove a possible line terminator at the end of the string
function str.remove_term(s)
	return str.hasterm(s) and s:gsub('[\r\n]+$', '') or s
end

--append a line terminator if the string doesn't have one
function str.add_term(s, term)
	return str.hasterm(s, #s) and s or s .. term
end

--position of the (first) line terminator char, or #s + 1
function str.term_char(s, i)
	return s:match'()[\r\n]*$'
end

--return the end and start byte indices (so in reverse order!) of the line
--starting at i. the last line is the one after the last line terminator.
--if the last line is empty it's iterated at two bytes beyond #s.
function str.next_line(s, i)
	i = i or 1
	if i > #s + 1 then
		return nil --empty line was iterated
	elseif i == #s + 1 then
		if #s == 0 or str.hasterm(s) then --iterate one more empty line
			return i+1, i+1
		else
			return nil
		end
	end
	local j = s:match('^[^\r\n]*\r?\n?()', i)
	return j, i
end

--iterate lines, returning the end and start indices for each line.
function str.lines(s)
	return str.next_line, s
end

function str.line_count(s)
	local n = 0
	for _ in str.lines(s) do
		n = n + 1
	end
	return n
end

--returns the most common line terminator in a string, if any, and whether
--the string contains mixed line terminators or not.
function str.detect_term(s)
	local n, r, rn = 0, 0, 0
	for i in str.chars(s) do
		if str.ischar(s, i, '\r') then
			if i < #s and str.ischar(s, i + 1, '\n') then
				rn = rn + 1
			else
				r = r + 1
			end
		elseif str.is(s, i, '\n') then
			n = n + 1
		end
	end
	local mixed = rn ~= n or rn ~= r or r ~= n
	local term =
		rn > n and rn > r and '\r\n'
		or r > n and '\r'
		or n > 0 and '\n'
		or nil
	return term, mixed
end

--tests ----------------------------------------------------------------------

if not ... then

assert(str.next_nonspace_char('') == nil)
assert(str.next_nonspace_char(' ') == nil)
assert(str.next_nonspace_char(' x') == 2)
assert(str.next_nonspace_char(' x ') == 2)
assert(str.next_nonspace_char('x ') == 1)

assert(str.prev_nonspace_char('') == nil)
assert(str.prev_nonspace_char(' ') == nil)
assert(str.prev_nonspace_char('x') == 1)
assert(str.prev_nonspace_char('x ') == 1)
assert(str.prev_nonspace_char(' x ') == 2)

assert(str.rtrim('abc \t ') == 'abc')
assert(str.rtrim(' \t abc  x \t ') == ' \t abc  x')
assert(str.rtrim('abc') == 'abc')
assert(str.rtrim('  ') == '')
assert(str.rtrim('') == '')

local function assert_lines(s, t)
	local i = 0
	local dt = {}
	for j1, i1 in str.lines(s) do
		local s = s:sub(i1, j1-1)
		i = i + 1
		assert(t[i] == s, i .. ': "' .. s .. '" ~= "' .. tostring(t[i]) .. '"')
		dt[i] = s
	end
	assert(i == #t, i .. ' ~= ' .. #t .. ': ' .. table.concat(dt, ', '))
end
assert_lines('', {''})
assert_lines(' ', {' '})
assert_lines('x\ny', {'x\n', 'y'})
assert_lines('x\ny\n', {'x\n', 'y\n', ''})
assert_lines('x\n\ny', {'x\n', '\n', 'y'})
assert_lines('\n', {'\n', ''})
assert_lines('\n\r\n', {'\n','\r\n',''})
assert_lines('\r\n\n', {'\r\n','\n',''})
assert_lines('\n\r', {'\n','\r',''})
assert_lines('\n\r\n\r', {'\n','\r\n','\r',''})
assert_lines('\n\n\r', {'\n','\n','\r',''})

--TODO: next_word_break, prev_word_break

end

return str
