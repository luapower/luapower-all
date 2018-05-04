
--code editor engine.
--Written By Cosmin Apreutesei. Public Domain.

if not ... then require'codedit_demo'; return end

--prototype-based dynamic inheritance with __call constructor (from glue).
local function object(super, o)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	if not super then o.subclass = object end
	return setmetatable(o, o)
end

--update a table with the contents of another table if any.
local function update(dt, t)
	if t then
		for k,v in pairs(t) do
			dt[k] = v
		end
	end
	return dt
end

--str module: plain text boundaries ------------------------------------------

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

--[[ TODO:
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
]]

--right trim of space and tab characters
function str.rtrim(s)
	local i = str.prev_nonspace_char(s)
	if not i then return '' end
	i = str.next_char(s, i)
	if not i then return s end
	return s:sub(1, i-1)
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
	assert(i >= 1 and i <= #s)
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

--tab expansion module -------------------------------------------------------

--translates between visual columns and char columns based on a fixed tabsize.
--char columns map 1:1 to chars occupying a single fixed char width, while
--visual columns represent char columns after tab expansion.

--the first tabstop after a visual column
local function next_tabstop(vcol, tabsize)
	return (math.floor((vcol - 1) / tabsize) + 1) * tabsize + 1
end

--the first tabstop before a visual column
local function prev_tabstop(vcol, tabsize)
	return next_tabstop(vcol - 1, tabsize) - tabsize
end

--how wide should a tab character be if found at a certain visual position
local function tab_width(vcol, tabsize)
	return next_tabstop(vcol, tabsize) - vcol
end

--how many tabs and left-over spaces fit between two visual columns (vcol2 is the char right after the last tab/space)
local function tabs_and_spaces(vcol1, vcol2, tabsize)
	if vcol2 < vcol1 then
		return 0, 0
	end
	--the distance is covered by a first (full or partial) tab, a number of full tabs, and finally a number of spaces
	local distance_left = vcol2 - next_tabstop(vcol1, tabsize) --distance left after the first tab
	if distance_left >= 0 then
		local full_tabs = math.floor(distance_left / tabsize)
		local spaces = distance_left - full_tabs * tabsize
		return 1 + full_tabs, spaces
	else
		return 0, vcol2 - vcol1
	end
end

--real column -> visual column, for a fixed tabsize.
--the real column can be past string's end, in which case vcol will expand to the same amount.
local function visual_col(s, col, tabsize)
	local col1 = 0
	local vcol = 1
	for i in str.chars(s) do
		col1 = col1 + 1
		if col1 >= col then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and tab_width(vcol, tabsize) or 1)
	end
	vcol = vcol + col - col1 - 1 --extend vcol past eol
	return vcol
end

--visual column -> real column, for a fixed tabsize.
--if the target vcol is between two possible vcols, return the vcol that is closer.
local function real_col(s, vcol, tabsize)
	local vcol1 = 1
	local col = 0
	for i in str.chars(s) do
		col = col + 1
		local vcol2 = vcol1 + (str.istab(s, i) and tab_width(vcol1, tabsize) or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			return col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
		end
		vcol1 = vcol2
	end
	col = col + vcol - vcol1 + 1 --extend col past eol
	return col
end

local tabs = {
	tab_width = tab_width,
	next_tabstop = next_tabstop,
	prev_tabstop = prev_tabstop,
	tabs_and_spaces = tabs_and_spaces,
	visual_col = visual_col,
	real_col = real_col,
}

--buffer object: multi-line text navigation and editing ----------------------

local buffer = object()

buffer.multiline = true
buffer.line_terminator = '\n' --line terminator to use when inserting text

function buffer:__call(buffer)
	self = object(self, buffer)
	self:init()
	return self
end

--the convention for storing lines is that each line preserves its own line
--terminator at its end, except the last line which doesn't have one, never.
--the empty string is thus stored as a single line containing itself.

function buffer:init(lines)
	self.lines = lines or {}
	if #self.lines == 0 then
		self.lines[1] = '' --can't have zero lines
	end
	self:_init_undo()
	self:_init_changed()
end

local function whole_string(s, last)
	if not last then
		return #s + 1, 1
	end
end
function buffer:_lines(s)
	if self.multiline then
		return str.lines(s)
	else
		return whole_string, s
	end
end

--invalidation & events ------------------------------------------------------

function buffer:_init_changed()
	--you can add any flags, they will all be set when the buffer changes.
	self.changed = {} --{<flag> = true/false}
	--"file" is the default changed flag to decide when to save.
	self.changed.file = false
	self.event_handlers = self.event_handlers or {}
end

function buffer:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
	self.editor:invalidate()
end

--serialization --------------------------------------------------------------

function buffer:save(write)
	for i,s in ipairs(self.lines) do
		if #s > 0 then
			write(s, #s)
		end
	end
end

function buffer:_load_stream(read)
	local lines = {}
	while true do
		local s = read()
		if not s then break end
		local s0 = lines[#lines]
		for j,i in self:_lines(s) do
			local s = s:sub(i,j-1)
			if s0 and #s0 > 0 then
				s = s0 .. s --stitch to last line
				s0 = nil
				lubes[#lines] = s
			else
				lines[#lines+1] = s
			end
		end
	end
	self:init(lines)
end

function buffer:_load_string(s)
	local lines = {}
	for j,i in self:_lines(s) do
		lines[#lines+1] = s:sub(i,j-1)
	end
	self:init(lines)
end

function buffer:load(arg)
	if type(arg) == 'string' then
		self:_load_string(arg)
	else
		self:_load_stream(arg)
	end
end

--undo/redo ------------------------------------------------------------------

--the undo stack is a stack of undo groups. an undo group is a list of buffer
--methods to be executed in reverse order in order to perform a single undo
--operation. consecutive undo groups of the same type are merged together.
--the undo commands in the group can be any editor method with any arguments.

function buffer:_init_undo()
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
end

function buffer:start_undo_group(group_type)
	if self.undo_group then
		if self.undo_group.type == group_type then
			--same type of group, continue using the current group
			return
		end
		self:end_undo_group() --auto-close current group to start a new one
	end
	self.undo_group = {type = group_type}
	self.editor:save_state(self.undo_group)
end

function buffer:end_undo_group()
	if not self.undo_group then return end
	if #self.undo_group > 0 then --push group if not empty
		table.insert(self.undo_stack, self.undo_group)
	end
	self.undo_group = nil
end

--add an undo command to the current undo group, if any.
function buffer:undo_command(...)
	if not self.undo_group then return end
	table.insert(self.undo_group, {...})
end

local function undo_from(self, group_stack)
	self:end_undo_group()
	local group = table.remove(group_stack)
	if not group then return end
	self:start_undo_group(group.type)
	for i = #group, 1, -1 do
		local cmd = group[i]
		self[cmd[1]](self, unpack(cmd, 2))
	end
	self:end_undo_group()
	self.editor:load_state(group)
end

function buffer:undo()
	undo_from(self, self.undo_stack)
	if #self.undo_stack == 0 then return end
	table.insert(self.redo_stack, table.remove(self.undo_stack))
end

function buffer:redo()
	undo_from(self, self.redo_stack)
end

function buffer:last_undo_command()
	if not self.undo_group then return end
	local last_cmd = self.undo_group[#self.undo_group]
	if not last_cmd then return end
	return unpack(last_cmd)
end

--low-level undo-able commands -----------------------------------------------

function buffer:_ins(line, s)
	assert(line >= 1 and line <= #self.lines + 1)
	table.insert(self.lines, line, s)
	self:undo_command('_rem', line)
end

function buffer:_rem(line)
	assert(line >= 2 and line <= #self.lines)
	local s = table.remove(self.lines, line)
	self:undo_command('_ins', line, s)
end

function buffer:_upd(line, s)
	assert(line >= 1 and line <= #self.lines)
	local s0 = self.lines[line]
	if s0 == s then return end
	local cmd, arg = self:last_undo_command()
	if not (cmd == '_upd' and arg == line) then --optimization
		self:undo_command('_upd', line, s0)
	end
	self.lines[line] = s
end

--buffer boundaries ----------------------------------------------------------

--byte index at line terminator (or at #s + 1 if there's no terminator)
function buffer:eol(line)
	local s = self.lines[line]
	return s and str.term_char(s)
end

--iterate the chars of a line, excluding the line terminator
local function next_nonterm_char(s, i)
	local i = str.next_char(s, i)
	if not i then return end
	if str.isterm(s, i) then return end
	return i, s
end
local function next_char(s, i) --iterate the chars of a line
	return str.next_char(s, i), s
end
function buffer:chars(line)
	local s = self.lines[line]
	return self.multiline and next_nonterm_char or next_char, s or ''
end

--the position after the last char in the text
function buffer:end_pos()
	return #self.lines, self:eol(#self.lines)
end

--clamp a position to the available text
function buffer:clamp_pos(line, i)
	if line < 1 then
		return 1, 1
	elseif line > #self.lines then
		return self:end_pos()
	else
		return line, math.min(math.max(i, 1), self:eol(line))
	end
end

--select the string between two subsequent positions in the text.
--select(line) selects the contents of a line without the line terminator.
function buffer:select(line1, i1, line2, i2)
	line1, i1 = self:clamp_pos(line1 or 1, i1 or 1)
	line2, i2 = self:clamp_pos(line2 or line1, i2 or 1/0)
	if line1 == line2 then
		return self.lines[line1]:sub(i1, i2 - 1)
	else
		local lines = {}
		table.insert(lines, self.lines[line1]:sub(i1))
		for line = line1 + 1, line2 - 1 do
			table.insert(lines, self.lines[line])
		end
		table.insert(lines, self.lines[line2]:sub(1, i2 - 1))
		return table.concat(lines)
	end
end

--line-level editing ---------------------------------------------------------

function buffer:insert_line(line, s)
	if line <= #self.lines then
		s = str.add_term(s, self.line_terminator)
	else
		s = str.remove_term(s)
		--appending a line: add a line terminator on the prev. line
		if line > 1 then
			self:_upd(line-1, self.lines[line-1] .. self.line_terminator)
		end
	end
	self:_ins(line, s)
	self:invalidate()
end

function buffer:remove_line(line)
	self:_rem(line)
	if #self.lines == line-1 then
		--removed the last line: remove the line term from the prev. line
		self:_upd(line-1, self:select(line-1))
	end
	self:invalidate()
end

function buffer:setline(line, s)
	if line == #self.lines then
		s = str.remove_term(s)
	else
		s = str.add_term(s, self.line_terminator)
	end
	self:_upd(line, s)
	self:invalidate()
end

--switch two lines with one another
function buffer:move_line(line1, line2)
	local s1 = self.lines[line1]
	local s2 = self.lines[line2]
	if not s1 or not s2 then return end
	self:setline(line1, s2)
	self:setline(line2, s1)
end

--char-level editing ---------------------------------------------------------

--extend the buffer up to (line,i-1) with whitespace so we can edit there.
function buffer:extend(line, i)
	if line < 1 then
		line = 1
	end
	while line > #self.lines do
		self:insert_line(#self.lines + 1, '')
	end
	local eol = self:eol(line)
	if i < 1 then
		i = 1
	end
	if i > eol then
		local padding = (' '):rep(i - eol)
		self:setline(line, self:select(line) .. padding)
	end
end

--insert a multi-line string at a specific position in the text, returning the
--position after the last character. if the position is outside the text,
--the buffer is extended.
function buffer:insert(line, i, s)
	self:extend(line, i)
	local s0 = self:select(line)
	local s1 = s0:sub(1, i - 1)
	local s2 = s0:sub(i)
	s = s1 .. s .. s2
	local first_line = true
	for j, i in self:_lines(s) do
		local s = s:sub(i, j-1)
		if first_line then
			self:setline(line, s)
			first_line = false
		else
			line = line + 1
			self:insert_line(line, s)
		end
	end
	return line, self:eol(line) - #s2
end

--remove the string between two arbitrary, subsequent positions in the text.
--line2,i2 is the position after the last character to be removed.
function buffer:remove(line1, i1, line2, i2)
	line1, i1 = self:clamp_pos(line1, i1)
	line2, i2 = self:clamp_pos(line2, i2)
	local s1 = self.lines[line1]:sub(1, i1 - 1)
	local s2 = self.lines[line2]:sub(i2)
	for line = line2, line1 + 1, -1 do
		self:remove_line(line)
	end
	self:setline(line1, s1 .. s2)
end

--indentation ----------------------------------------------------------------

function buffer:_next_nonspace_char(line, i)
	local s = self.lines[line]
	return s and str.next_nonspace_char(s, i)
end

--check if a line is either invalid, empty or made entirely of whitespace
function buffer:isempty(line)
	return not self:_next_nonspace_char(line)
end

--check if a position is before the first non-space char, that is, check if
--it's in the indentation area.
function buffer:indenting(line, i)
	local nsi = self:_next_nonspace_char(line)
	return not nsi or i <= nsi
end

--return the indent of the line, optionally up to some char.
function buffer:select_indent(line, i)
	local nsi = self:_next_nonspace_char(line) or self:eol(line)
	local indent_i = math.min(i or 1/0, nsi)
	return self.lines[line] and self.lines[line]:sub(1, indent_i - 1)
end

--buffer normalization -------------------------------------------------------

buffer.eol_spaces = 'remove' --leave, remove.
buffer.eof_lines = 'leave' --leave, remove, ensure, or a number.
buffer.convert_indent = 'tabs' --tabs, spaces, leave: convert indentation to
	--tabs or spaces based on current tabsize

function buffer:detect_line_terminator(s)
	return str.line_terminator(s)
end

--detect indent type and tab size of current buffer
function buffer:detect_indent()
	local tabs, spaces = 0, 0
	for line = 1, self:last_line() do
		local tabs1, spaces1 = str.indent_counts(self:line(line))
		tabs = tabs + tabs1
		spaces = spaces + spaces1
	end
	--TODO: finish this
end

function buffer:remove_eol_spaces() --remove any spaces past eol
	for line = 1, self:last_line() do
		self:setline(line, str.rtrim(self:line(line)))
	end
end

function buffer:ensure_eof_line() --add an empty line at eof if there is none
	if not self:isempty(self:last_line()) then
		self:insert_line(self:last_line() + 1, '')
	end
end

function buffer:remove_eof_lines() --remove any empty lines at eof, except the first line
	while self:last_line() > 1 and self:isempty(self:last_line()) do
		self:remove_line(self:last_line())
	end
end

function buffer:convert_indent_to_tabs()
	for line = 1, self:last_line() do
		local indent_col = self:next_nonspace_col(line) or self:last_col(line)
		if indent_col > 0 then
			local indent_vcol = self:visual_col(line, indent_col)
			local tabs, spaces = self:tabs_and_spaces(1, indent_vcol)
			self:setline(line, string.rep('\t', tabs) .. string.rep(' ', spaces) .. self:sub(line, indent_col))
		end
	end
end

function buffer:convert_indent_to_spaces()
	for line = 1, self:last_line() do
		local indent_col = self:next_nonspace_col(line) or self:last_col(line)
		if indent_col > 0 then
			local indent_vcol = self:visual_col(line, indent_col)
			self:setline(line, string.rep(' ', indent_vcol - 1) .. self:sub(line, indent_col))
		end
	end
end

function buffer:normalize()
	if self.eol_spaces == 'remove' then
		self:remove_eol_spaces()
	end
	if self.convert_indent == 'tabs' then
		self:convert_indent_to_tabs()
	elseif self.convert_indent == 'spaces' then
		self:convert_indent_to_spaces()
	end
	if self.eof_lines == 'ensure' then
		self:ensure_eof_line()
	elseif self.eof_lines == 'remove' then
		self:remove_eof_lines()
	elseif type(self.eof_lines) == 'number' then
		self:remove_eof_lines()
		for i = 1, self.eof_lines do
			self:insert_line(self:last_line() + 1, '')
		end
	end
end

--cursor object: caret-based navigation and editing --------------------------

local cursor = object()

--navigation options
cursor.restrict_eol = true --don't allow caret past end-of-line
cursor.restrict_eof = true --don't allow caret past end-of-file
cursor.land_bof = true --go at bof if cursor goes up past it
cursor.land_eof = true --go at eof if cursor goes down past it (needs restrict_eof)
cursor.word_chars = '^[a-zA-Z_]' --for jumping between words
cursor.jump_tabstops = 'always' --'always', 'indent', 'never'

--where to move the cursor between tabstops instead of individual spaces.
cursor.delete_tabstops = 'always' --'always', 'indent', 'never'

--editing state
cursor.insert_mode = true --insert or overwrite when typing characters

--editing options
cursor.auto_indent = true

--pressing enter copies the indentation of the current line over to the following line
cursor.insert_tabs = 'indent' --'never', 'indent', 'always'

--where to insert a tab instead of enough spaces that make up a tab.
cursor.insert_align_list = false --TODO: insert whitespace up to the next word on the above line
cursor.insert_align_args = false --TODO: insert whitespace up to after '(' on the above line

--view overrides
cursor.thickness = nil
cursor.color = nil
cursor.line_highlight_color = nil

function cursor:__call(cursor)
	self = object(self, cursor)
	self.line = 1
	self.i = 1 --current byte index in current line
	self.x = 0 --wanted x offset when navigating up/down
	self.changed = {}
	if self.view then
		self.view:add_cursor(self)
	end
	return self
end

--state management -----------------------------------------------------------

function cursor:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
	self.editor:invalidate()
end

local function update_state(dst, src)
	dst.line = src.line
	dst.i = src.i
	dst.x = src.x
end

function cursor:save_state(state)
	update_state(state, self)
end

function cursor:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--navigation -----------------------------------------------------------------

--move to a specific position in the text, restricting the final position
--according to buffer boundaries and navigation policies.
function cursor:move(line, i, keep_x)
	if i < 1 then
		i = 1
	end
	if line < 1 then
		line = 1
		if self.land_bof then
			i = 1
			keep_x = false
		end
	elseif self.restrict_eof and line > #self.buffer.lines then
		line = #self.buffer.lines
		if self.land_eof then
			i = self.buffer:eol(line)
			keep_x = false
		end
	end
	if self.restrict_eol then
		if line <= #self.buffer.lines then
			i = math.min(i, self.buffer:eol(line))
		else
			i = 1
		end
	end
	self.line, self.i = line, i
	if not keep_x then
		--store the cursor x to be used as the wanted landing x by move_vert()
		self.x = self.view:cursor_coords(self)
	end
	self:invalidate()
end

function cursor:prev_pos(jump_tabstops)

	if self.i == 1 then --move to the end of the prev. line
		if self.line == 1 then
			return 1, 1
		elseif self.line - 1 > #self.buffer.lines then --outside buffer
			return self.line - 1, 1
		else
			return self.line - 1, self.buffer:eol(self.line - 1)
		end
	elseif self.line > #self.buffer.lines then --outside buffer
		return self.line, self.i - 1
	elseif self.i > self.buffer:eol(self.line) then --outside line
		return self.line, self.i - 1
	end

	local jump_tabstops =
		jump_tabstops == 'always'
		or (jump_tabstops == 'indent'
			and self.buffer:indenting(self.line, self.i))

	local s = self.buffer.lines[self.line]

	if jump_tabstops then
		local x0 = self.view:char_x(self.line, self.i)
		local ts_x = self.view:prev_tabstop_x(x0)
		local ts_i = self.view:char_at_line(self.line, ts_x)
		if ts_i == self.i then --tabstop too close, get the prev. one
			ts_x = self.view:prev_tabstop_x(ts_x)
			ts_i = self.view:char_at_line(self.line, ts_x)
		end
		local ns_i = str.prev_nonspace_char(s, self.i)
		local ps_i = str.next_char(s, ns_i) or #s + 1
		local prev_i = math.max(ps_i, ts_i) --whichever is closest
		if prev_i < self.i then
			return self.line, prev_i
		end
	end

	return self.line, str.prev_char(s, self.i)
end

function cursor:move_prev_pos()
	self:move(self:prev_pos(self.jump_tabstops))
end

function cursor:next_pos(restrict_eol, jump_tabstops)

	local lastline = #self.buffer.lines
	if self.line > lastline then --outside buffer
		if self.restrict_eof then
			return self.buffer:end_pos()
		elseif restrict_eol then
			return self.line + 1, 1
		else
			return self.line, self.i + 1
		end
	elseif self.i >= self.buffer:eol(self.line) then --outside line
		if restrict_eol then
			if self.restrict_eof and self.line == lastline then
				return self.buffer:end_pos()
			else
				return self.line + 1, 1
			end
		else
			return self.line, self.i + 1
		end
	end

	local s = self.buffer.lines[self.line]

	if jump_tabstops == 'always' then
		jump_tabstops = true
	elseif jump_tabstops == 'indent' then
		local i = str.next_char(s, self.i)
		jump_tabstops = i and self.buffer:indenting(self.line, i)
	else
		jump_tabstops = false
	end
	jump_tabstops = jump_tabstops and str.iswhitespace(s, self.i)

	if jump_tabstops then
		local x0 = self.view:char_x(self.line, self.i)
		local ts_x = self.view:next_tabstop_x(x0)
		local ts_i = self.view:char_at_line(self.line, ts_x)
		if ts_i == self.i then --tabstop too close, get the next one
			ts_x = self.view:next_tabstop_x(ts_x)
			ts_i = self.view:char_at_line(self.line, ts_x)
		end
		local ns_i =
			str.next_nonspace_char(s, self.i)
			or self.buffer:eol(self.line)
		local next_i = math.min(ts_i, ns_i) --whichever is closer
		if next_i > self.i then
			return self.line, next_i
		end
	end

	return self.line, str.next_char(s, self.i) or #s + 1
end

function cursor:move_next_pos()
	self:move(self:next_pos(self.restrict_eol, self.jump_tabstops))
end

function cursor:move_prev_word_break()
	local s = self.buffer.lines[self.line]
	local wb_i = s and str.prev_word_break_char(s, self.i, self.word_chars)
	if wb_i then
		self:move(self.line, wb_i)
	elseif self.line > #self.buffer.lines then
		if self.i == 1 then
			self:move(self.line - 1, self.buffer:eol(self.line - 1) or 1)
		else
			self:move(self.line, 1)
		end
	elseif self.line > #self.buffer.lines then
		self:move(self.line, self.buffer:eol(self.line))
	elseif self.i > self.buffer:eol(self.line) then
		self:move(self.line, self.buffer:eol(self.line))
	else
		self:move_prev_pos()
	end
end

function cursor:move_next_word_break()
	local s = self.buffer.lines[self.line]
	local wb_i = s and str.next_word_break_char(s, self.i, self.word_chars)
	if wb_i then
		self:move(self.line, wb_i)
	else
		self:move(self:next_pos(true, self.jump_tabstops))
	end
end

--cursor vertical navigation -------------------------------------------------

function cursor:move_vert(lines)
	local line = self.line + lines
	local i = self.view:cursor_char_at_line(math.max(1, line), self.x)
	self:move(line, i, true)
end

function cursor:move_up()    self:move_vert(-1) end
function cursor:move_down()  self:move_vert(1) end

function cursor:move_up_page()
	self:move_vert(-self.view:pagesize())
end

function cursor:move_down_page()
	self:move_vert(self.view:pagesize())
end

--cursor navigation to buffer boundaries -------------------------------------

function cursor:move_home()
	self:move(1, 1)
end

function cursor:move_end()
	local line, i = self.buffer:end_pos()
	self:move(line, i)
end

--cursor navigation to line boundaries ---------------------------------------

function cursor:move_bol()
	self:move(self.line, 1)
end

function cursor:move_eol()
	local line, i = self.buffer:clamp_pos(self.line, 1/0)
	self:move(line, i)
end

--cursor navigation to selection end -----------------------------------------

function cursor:move_to_selection(sel)
	self:move(sel.line2, sel.i2)
end

--cursor navigation to mouse coordinates -------------------------------------

function cursor:move_to_coords(x, y)
	x, y = self.view:screen_to_client(x, y)
	local line, i = self.view:cursor_char_at(x, y, self.restrict_eof)
	self:move(line, i)
end

--word boundaries surrounding at cursor --------------------------------------

function cursor:word_bounds()
	local s = self.buffer.lines[self.line]
	if not s then return self.i, self.i end
	local i1 = str.prev_word_break_char(s, self.i, self.word_chars) or 1
	local i2 = str.next_word_break_char(s, self.i, self.word_chars)
	i2 = (i2 and str.prev_nonspace_char(s, i2)
		or self.buffer:eol(self.line) - 1) + 1
	return i1, i2
end

--editing --------------------------------------------------------------------

--insert a string at cursor and move the cursor to after the string
function cursor:insert(s)
	local line, i = self.buffer:insert(self.line, self.i, s)
	self:move(line, i)
end

--insert a string block at cursor.
--does not move the cursor, but returns the position after the text.
function cursor:insert_block(s)
	return self.buffer:insert_block(self.line, self.i, s)
end

--insert or overwrite a char at cursor, depending on insert mode
function cursor:insert_char(c)
	if not self.insert_mode then
		self:delete_pos(false)
	end
	self:insert(c)
end

--delete the text up to the next cursor position
function cursor:delete_pos(restrict_eol)
	local line2, i2 = self:next_pos(restrict_eol, self.delete_tabstops)
	self.buffer:remove(self.line, self.i, line2, i2)
end

--delete the char before the cursor position.
function cursor:delete_prev_pos()
	self:move(self:prev_pos(self.delete_tabstops))
	self:delete_pos(true)
end

--add a new line, optionally copying the indent of the current line, and carry the cursor over
function cursor:insert_newline()
	if self.auto_indent then
		self.buffer:extend(self.line, self.i)
		local indent = self.buffer:select_indent(self.line, self.i)
		self:insert('\n' .. indent)
	else
		self:insert'\n'
	end
end

--insert a tab character, expanding it according to tab expansion policies
function cursor:insert_tab()

	if self.insert_align_list then
		local ls_x = self.buffer:next_list_aligned_vcol(self.line, self.i, self.restrict_eol)
		if ls_x then
			local line, i = self.buffer:insert_whitespace(self.line, self.i, ls_x, self.insert_tabs == 'always')
			self:move(line, i)
			return
		end
	end

	if false and self.insert_align_args then
		local arg_x = self.buffer:next_args_aligned_vcol(self.line, self.i, self.restrict_eol)
		if arg_x then
			if self.buffer:indenting(self.line, self.i) then
				local indent = self.buffer:select_indent(self.line - 1)
				local indent_x = tabs.visual_col(indent, str.len(indent) + 1, self.tabsize)
				local whitespace = self.buffer:gen_whitespace(indent_x, arg_x, self.insert_tabs == 'always')
				local line, i = self.buffer:insert(self.line, 1, indent .. whitespace)
				self:move(line, i)
			else
				local line, i = self.buffer:insert_whitespace(self.line, self.i, arg_x, self.insert_tabs == 'always')
				self:move(line, i)
			end
			return
		end
	end

	local use_tabs =
		self.insert_tabs == 'always' or
			(self.insert_tabs == 'indent' and
			 self.buffer:indenting(self.line, self.i))

	local line, i
	if use_tabs then
		line, i = self.buffer:insert(self.line, self.i, '\t')
	else
		--compute the number of spaces until the next tabstop
		local x = self.view:char_x(self.line, self.i)
		local tsx = self.view:next_tabstop_x(x)
		local w = tsx - x
		local n = math.floor(w / self.view:space_width(1) + 0.5)
		line, i = self.buffer:insert(self.line, self.i, (' '):rep(n))
	end
	self:move(line, i)
end

function cursor:outdent_line()
	if not self.buffer.lines[self.line] then
		self:move(self.line, self.i - 1)
		return
	end
	local old_sz = #self.buffer.lines[self.line]
	self.buffer:outdent_line(self.line)
	local new_sz = #self.buffer.lines[self.line]
	local i = self.i + new_sz - old_sz
	self:move(self.line, i)
end

function cursor:move_line_up()
	self.buffer:move_line(self.line, self.line - 1)
	self:move_up()
end

function cursor:move_line_down()
	self.buffer:move_line(self.line, self.line + 1)
	self:move_down()
end

--[==[

--editing based on tab expansion

--find the max number of tabs and minimum number of spaces that fit between two visual columns
function view:tabs_and_spaces(vcol1, vcol2)
	return tabs.tabs_and_spaces(vcol1, vcol2, self.tabsize)
end

--generate whitespace (tabs and spaces or just spaces, depending on the use_tabs flag) between two vcols.
function view:gen_whitespace(vcol1, vcol2, use_tabs)
	if vcol2 <= vcol1 then
		return '' --target before cursor: ignore
	end
	local tabs, spaces
	if use_tabs then
		tabs, spaces = self:tabs_and_spaces(vcol1, vcol2)
	else
		tabs, spaces = 0, vcol2 - vcol1
	end
	return string.rep('\t', tabs) .. string.rep(' ', spaces)
end

--insert whitespace on a line, from a position up to (but excluding) a visual col on the same line.
function view:insert_whitespace(line, col, vcol2, use_tabs)
	local vcol1 = self:visual_col(line, col)
	local whitespace = self:gen_whitespace(vcol1, vcol2, use_tabs)
	return self.buffer:insert(line, col, whitespace)
end

--editing based on tabfuls

--remove the space up to the next tabstop or non-space char, in other words, remove a tabful.
function view:outdent(line, col)
	local tf_col = self:next_tabful_col(line, col, true)
	if tf_col then
		self.buffer:remove_string(line, col, line, tf_col)
	end
end

function view:outdent_line(line)
	self.buffer:outdent(line, 1)
end

]==]

--scrolling ------------------------------------------------------------------

function cursor:make_visible()
	if not self.visible then return end
	self.view:cursor_make_visible(self)
end

--selection object: selecting contiguous text between two line,i pairs. ------

--line1,i1 is the first selected char and line2,i2 is the char immediately
--after the last selected char.

local selection = object()

--view overrides
selection.background_color = nil
selection.text_color = nil
selection.line_rect = nil --line_rect(line) -> x, y, w, h

--lifetime

function selection:__call(selection)
	self = object(self, selection)
	self.line1, self.i1 = 1, 1
	self.line2, self.i2 = 1, 1
	self.changed = {}
	if self.view then
		self.view:add_selection(self)
	end
	return self
end

--state management

function selection:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
	self.editor:invalidate()
end

local function update_state(dst, src)
	dst.line1 = src.line1
	dst.line2 = src.line2
	dst.i1 = src.i1
	dst.i2 = src.i2
end

function selection:save_state(state)
	update_state(state, self)
end

function selection:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--boundaries

function selection:isempty()
	return self.line2 == self.line1 and self.i2 == self.i1
end

--goes top-down and left-to-rigth
function selection:isforward()
	return self.line1 < self.line2 or (self.line1 == self.line2 and self.i1 <= self.i2)
end

--endpoints, ordered
function selection:endpoints()
	if self:isforward() then
		return self.line1, self.i1, self.line2, self.i2
	else
		return self.line2, self.i2, self.line1, self.i1
	end
end

--char index range of one selection line
function selection:chars(line)
	local line1, i1, line2, i2 = self:endpoints()
	local i1 = line == line1 and i1 or 1
	local i2 = line == line2 and i2 or self.buffer:eol(line)
	return i1, i2
end

function selection:next_line(line)
	line = line and line + 1 or math.min(self.line1, self.line2)
	if line > math.max(self.line1, self.line2) then
		return
	end
	return line, self:chars(line)
end

function selection:lines()
	return self.next_line, self
end

--the range of lines that the selection covers fully or partially
function selection:line_range()
	local line1, i1, line2, i2 = self:endpoints()
	if not self:isempty() and i2 == 1 then
		return line1, line2 - 1
	else
		return line1, line2
	end
end

function selection:contents()
	return self.buffer:select(self:endpoints())
end

--changing the selection

--empty and re-anchor the selection
function selection:reset(line, i)
	self.line1, self.i1 = self.buffer:clamp_pos(line, i)
	self.line2, self.i2 = self.line1, self.i1
	self:invalidate()
end

--move selection's free endpoint
function selection:extend(line, i)
	self.line2, self.i2 = self.buffer:clamp_pos(line, i)
	self:invalidate()
end

--reverse selection's direction
function selection:reverse()
	self.line1, self.i1, self.line2, self.i2 =
		self.line2, self.i2, self.line1, self.i1
	self:invalidate()
end

--set selection endpoints, preserving or setting its direction
function selection:set(line1, i1, line2, i2, forward)
	if forward == nil then
		forward = self:isforward()
	end
	self:reset(line1, i1)
	self:extend(line2, i2)
	if forward ~= self:isforward() then
		self:reverse()
	end
end

function selection:select_all()
	self:set(1, 1, 1/0, 1/0, true)
end

function selection:reset_to_cursor(cur)
	self:reset(cur.line, cur.i)
end

function selection:extend_to_cursor(cur)
	self:extend(cur.line, cur.i)
end

function selection:set_to_selection(sel)
	self:set(sel.line1, sel.i1, sel.line2, sel.i2, sel:isforward())
end

function selection:set_to_line_range()
	local line1, line2 = self:line_range()
	self:set(line1, 1, line2 + 1, 1)
end

--selection-based editing

function selection:remove()
	if self:isempty() then return end
	local line1, i1, line2, i2 = self:endpoints()
	self.buffer:remove(line1, i1, line2, i2)
	self:reset(line1, i1)
end

function selection:indent(use_tab)
	local line1, line2 = self:line_range()
	for line = line1, line2 do
		--TODO: implement this
		--self.buffer:indent_line(line, use_tab)
	end
	self:set_to_line_range()
end

function selection:outdent()
	local line1, line2 = self:line_range()
	for line = line1, line2 do
		self.buffer:outdent_line(line)
	end
	self:set_to_line_range()
end

function selection:move_up()
	local line1, line2 = self:line_range()
	if line1 == 1 then
		return
	end
	for line = line1, line2 do
		self.buffer:move_line(line, line - 1)
	end
	self:set(line1 - 1, 1, line2 - 1 + 1, 1)
end

function selection:move_down()
	local line1, line2 = self:line_range()
	if line2 == #self.buffer.lines then
		return
	end
	for line = line2, line1, -1 do
		self.buffer:move_line(line, line + 1)
	end
	self:set(line1 + 1, 1, line2 + 1 + 1, 1)
end

function selection:reflow(line_width, tabsize, align, wrap)
	local line1, line2 = self:line_range()
	local line2, i2 = self.buffer:reflow_lines(line1, line2, line_width, tabsize, align, wrap)
	self:set(line1, 1, line2, i2)
end

--hit testing

function selection:hit_test(x, y)
	return self.view:selection_hit_test(self, x, y)
end

--block selection object: selecting the text inside a rectangle. -------------

--line1,line2 are the horizontal boundaries and col1,col2 are the vertical
--boundaries of the rectangle.

local block_selection = object{block = true}

--inherited

block_selection.__call = selection.__call
block_selection.free = selection.free
block_selection.save_state = selection.save_state
block_selection.load_state = selection.load_state
block_selection.isempty = selection.isempty
block_selection.isforward = selection.isforward
block_selection.endpoints = selection.endpoints

--column range of one selection line
function block_selection:cols(line)
	local line1, i1, line2, i2 = self:endpoints()
	--local char_at_line(line1, i1)
end

block_selection.next_line = selection.next_line
block_selection.lines = selection.lines

--the range of lines that the selection covers
function block_selection:line_range()
	if self.line1 > self.line2 then
		return self.line2, self.line1
	else
		return self.line1, self.line2
	end
end

function block_selection:select()
	return self.buffer:select_block(self:endpoints())
end

block_selection.contents = selection.contents

--changing the selection

block_selection.invalidate = selection.invalidate

function block_selection:reset(line, col)
	line = math.min(math.max(line, 1), #self.buffer.lines)
	self.line1, self.col1 = line, col
	self.line2, self.col2 = self.line1, self.col1
	self:invalidate()
end

function block_selection:extend(line, col)
	line = math.min(math.max(line, 1), #self.buffer.lines)
	self.line2, self.col2 = line, col
	self:invalidate()
end

block_selection.set = selection.set
block_selection.reset_to_cursor = selection.reset_to_cursor
block_selection.extend_to_cursor = selection.extend_to_cursor
block_selection.set_to_selection = selection.set_to_selection

--selection-based editing

function block_selection:remove()
	self.buffer:remove_block(self:endpoints())
	self:reset(self.line1, self.col1)
end

--extend selection to the right contain all the available text
function block_selection:extend_to_last_col()
	local line1, col1, line2, col2 = self:endpoints()
	local max_col2 = 0
	for line = line1, line2 do
		max_col2 = math.max(max_col2, self.buffer:last_col(line) + 1)
	end
	self:set(line1, col1, line2, max_col2)
end

function block_selection:indent(use_tab)
	local line1, col1, line2, col2 = self:endpoints()
	self.buffer:indent_block(line1, col1, line2, col2, use_tab)
	self:extend_to_last_col()
end

function block_selection:outdent()
	local line1, col1, line2, col2 = self:endpoints()
	self.buffer:outdent_block(line1, col1, line2, col2)
	self:extend_to_last_col()
end

function block_selection:reflow(line_width, tabsize, align, wrap)
	local line1, col1, line2, col2 = self:endpoints()
	local line2, col2 = self.buffer:reflow_block(line1, col1, line2, col2, line_width, tabsize, align, wrap)
	self:set(line1, col1, line2, col2)
end

--hit testing

block_selection.hit_test = selection.hit_test

--syntax highlighting --------------------------------------------------------

--select text from buffer between (line1, p1) up to the end of line2 excluding line terminator.
local function select_text(buffer, line1, p1, line2)
	line2 = line2 or #buffer.lines
	local s = buffer:line(line1):sub(p1)
	if line2 > line1 then
		s = s .. buffer.line_terminator ..
				table.concat(buffer.lines, buffer.line_terminator, line1 + 1, line2)
	end
	return s
end

--lex selected text returning a list of token positions and styles.
--the token list is a zero-based array of form {[0] = pos1, style1, ..., posN, styleN, posN+1}
local function lex_text(s, lang)

	local lexer = require'lexer'
	lexer.LEXERPATH = 'media/lexers/?.lua'

	local lex = lexer.load(lang)
	local t = lexer.lex(lex, s)
	t[0] = 1
	return t
end

--token lists can also have explicit length, so we use len() to test for length.
local function len(t)
	return t.len or #t
end

local function unpack_token_pos(t, i) --i, p
	if i > len(t) then return end
	return i, t[i]
end

local function next_token_pos(t, i)
	return unpack_token_pos(t, i and i + 2 or 0)
end

local function tokens_pos(t)
	return next_token_pos, t
end

local function unpack_token(t, i) --i, p1, p2, style
	if i >= len(t) then return end
	return i, t[i], t[i + 2], t[i + 1]
end

local function next_token(t, i)
	return unpack_token(t, i and i + 2 or 0)
end

local function tokens(t)
	return next_token, t
end

local function linesize(line, buffer)
	return #buffer:line(line) + #buffer.line_terminator
end

--project token positions originated from text at (line1, p1) back into the text,
--returning (i, line, p) for each position.
local function project_pos(t, line1, p1, buffer)
	local line = line1
	local minp, maxp = 1, linesize(line1, buffer)
	--token positions are relative to (line1, p1), not (line1, 1). shift line positions to accomodate that.
	minp = minp - p1 + 1
	maxp = maxp - p1 + 1
	local i
	return function()
		local p
		i, p = next_token_pos(t, i)
		if not i then return end
		--if p is outside the current line, advance the line until it's on it again
		while p > maxp do
			line = line + 1
			minp, maxp = maxp + 1, maxp + linesize(line, buffer)
		end
		return i, line, p - minp + 1
	end
end

--project tokens originated from text at (line1, p1) back into the text,
--returning (i, line1, p1, line2, p2, style) for each token.
local function project_tokens(t, line1, p1, buffer)
	local next_pos = project_pos(t, line1, p1, buffer)
	local i, line, p = next_pos()
	return function()
		if not i then return end
		local i2, line2, p2 = next_pos()
		if not i2 then return end
		local i1, line1, p1 = i, line, p
		i, line, p = i2, line2, p2
		return i1, line1, p1, line2, p2, t[i1 + 1]
	end
end

--project tokens originated from text at (line1, p1) back into the text,
--splitting multi-line tokens, and returning (i, line, p1, p2, style) for each line.
local function project_lines(t, line1, p1, buffer)
	local next_token = project_tokens(t, line1, p1, buffer)

	local i, line1, p1, line2, p2, style = next_token()
	local line = line1

	local function advance_token(ri, rline, rp1, rp2, rstyle)
		i, line1, p1, line2, p2, style = next_token()
		line = line1
		return ri, rline, rp1, rp2, rstyle
	end

	local function advance_line(ri, rline, rp1, rp2, rstyle)
		line = line + 1
		return ri, rline, rp1, rp2, rstyle
	end

	return function()
		if not i then return end
		if line1 == line2 then
			return advance_token(i, line, p1, p2, style)
		elseif line == line1 then
			return advance_line(i, line, p1, linesize(line, buffer) + 1, style)
		elseif line == line2 then
			return advance_token(i, line, 1, p2, style)
		else
			return advance_line(i, line, 1, linesize(line, buffer) + 1, style)
		end
	end
end

--[[
--find the last token positioned before or at the beginning of a line.
local function token_for(line, t, line1, p1, buffer)
	assert(line >= line1)
	if line == line1 then
		return 0, line1, p1
	end
	for i, line1, p1, line2, p2 in project_tokens(t, line1, p1, buffer) do
		if line2 >= line then
			return i, line1, p1
		end
	end
end
]]

--find the last whitespace token positioned before or at the beginning of a line.
local function start_token_for(line, t, line1, p1, buffer, lang0)
	local i0, line0, p0 = 0, line1, p1
	for i, line1, p1, line2, p2, style in project_tokens(t, line1, p1, buffer) do
		local lang = style:match'^(.-)_whitespace$'
		if lang then
			i0, line0, p0 = i, line1, p1
		end
		if line2 >= line then
			break
		end
	end
	return i0, line0, p0, lang0
end

--replace the tokens in t from i onwards with new tokens.
--the new tokens must represent the lexed text at that position.
local function replace_tokens(t, i, newt)
	local p0 = t[i] - 1
	for i1, p1, p2, style in tokens(newt) do
		t[i + i1 + 0] = p1 + p0
		t[i + i1 + 1] = style
		t[i + i1 + 2] = p2
	end
	--instead of deleting garbage entries, we keep them, and explicitly mark the list end.
	t.len = i + len(newt)
end

local function replace_start_tokens(st, t, line1, p1, buffer)
	local i0, line0, p0 = 0, line1, p1
	for i, line, p1, p2, style in project_lines(t, line1, p1, buffer) do
		local lang = style:match'^(.-)_whitespace$'
		if lang then
			i0, line0, p0 = i, line1, p1
		end
		st[line + 1] = {i0, line0, p0, lang}
	end
end

--given a list of tokens representing the lexed text from the beginning up to `last_line`,
--re-lex the text incrementally up to `max_line`.
local function relex(maxline, t, last_line, buffer, lang0, start_tokens)

	local line1 = last_line + 1
	local line2 = math.min(maxline, #buffer.lines)

	if line1 > line2 then
		return t, line2, start_tokens --nothing to do
	end

	t = t or {[0] = 1}

	local line0 = line1
	local i, p1, lang

	if start_tokens and start_tokens[line1] then
		i, line1, p1, lang = unpack(start_tokens[line1])
		print('cache', line0, '', i, line1, p1, lang)
	else
		i, line1, p1, lang = start_token_for(line1, t, 1, 1, buffer, lang0)
		print('comp', line0, '', i, line1, p1, lang)
	end

	local text = select_text(buffer, line1, p1, line2)
	local newt = lex_text(text, lang)

	replace_tokens(t, i, newt)

	--start_tokens = start_tokens or {}
	--replace_start_tokens(start_tokens, newt, line1, p1, buffer)

	return t, line2--, start_tokens
end

--highlighter object

local hl = {}

function hl:__call(hl)
	self = object(self, hl)
	self.last_line = 0
	return self
end

function hl:invalidate(line)
	self.last_line = math.min(self.last_line, line - 1)
	self.editor:invalidate()
end

function hl:relex(maxline)
	self.tokens, self.last_line = relex(maxline, self.tokens, self.last_line, self.buffer, self.lang)
end

function hl:lines()
	return project_lines(self.tokens, 1, 1, self.buffer)
end

local hl = {
	relex = relex,
	tokens = project_lines,
}

--view: measuring, layouting, drawing and hit testing ------------------------

--features: proportional fonts, auto-wrapping, line margins, scrolling.

--[[

...................................
:client :m1 :m2 :                 :
:rect   :   :   :                 :
:       :___:___:______________   :
:       |(*)|   |clip       | |   :
:       |   |   |rect       | |   :
:       |   |   |           |#|   :
:       |   |   |           |#|   :
:       |   |   |           |#|   :
:       |   |   |           |#|   :
:       |   |   |           | |   :
:       |___|___|___________|_|   :
:       :   :   |_____####__|     :
:       :   :   :                 :
:       :   :   :                 :
...................................

view rect (*):     x, y, w, h (contains the clipped margins and the scrollbox)
scrollbox rect:    x + margins_w, y, w - margins_w, h
clip rect:         clip_x, clip_y, clip_w, clip_h (from drawing the scrollbox)
client rect:       clip_x + scroll_x, clip_y + scroll_y, client_size()
margin1 rect:      x, client_y, m1:get_width(), client_h
margin1 clip rect: m1_x, clip_y, m1_w, clip_h

]]

local view = object()

--tab expansion
view.tabsize = 3
view.tabstop_margin = 1 --min. space in pixels between tab-separated chunks

--font metrics
view.line_h = nil   --to be set when setting the font
view.ascender = nil --to be set when setting the font

--cursor metrics
view.cursor_xoffset = -1     --cursor x offset from a char's left corner
view.cursor_xoffset_col1 = 0 --cursor x offset for the first column
view.cursor_thickness = 2

--scrolling
view.x = 0
view.y = 0
view.scroll_x = 0 --client rect position relative to the clip rect
view.scroll_y = 0
view.cursor_margins = {
	top = 16,
	left = 0,
	right = view.cursor_xoffset + view.cursor_thickness,
	bottom = 16}

--drawing
view.highlight_cursor_lines = true
view.lang = nil --optional lexer to use for syntax highlighting
view.tabstops = false --draw tabstop guidelines

--reflowing
view.line_width = 72

--lifetime

function view:__call(view)
	self = object(self, view)
	self:init()
	return self
end

function view:init()
	--objects to draw
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}
	self.margins = {} --{margin1, ...}
	--state
	self.last_valid_line = 0 --for incremental lexing
end

--adding objects to draw

function view:add_selection(sel) self.selections[sel] = true end
function view:add_cursor(cur) self.cursors[cur] = true end
function view:add_margin(margin, pos)
	table.insert(self.margins, pos or #self.margins + 1, margin)
end

--state management

function view:invalidate(line)
	if line then
		self.last_valid_line = math.min(self.last_valid_line, line - 1)
	end
	self.editor:invalidate()
end

local function update_state(dst, src)
	dst.scroll_x = src.scroll_x
	dst.scroll_y = src.scroll_y
end

function view:save_state(state)
	update_state(state, self)
end

function view:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--utils

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

local function point_in_rect(x, y, x1, y1, w1, h1)
	return x >= x1 and x <= x1 + w1 and y >= y1 and y <= y1 + h1
end

--tabstop metrics ------------------------------------------------------------

--pixel width of n space characters
function view:space_width(n)
	return self:char_advance_x(' ', 1) * n
end

--pixel width of a full tabstop
function view:tabstop_width()
	return self:space_width(self.tabsize)
end

--x coord of the first tabstop to the right of x0
function view:next_tabstop_x(x0)
	local w = self:tabstop_width()
	return math.ceil((x0 + self.tabstop_margin) / w) * w
end

--x coord of the first tabstop to the left of x0
function view:prev_tabstop_x(x0)
	local w = self:tabstop_width()
	return math.floor((x0 - self.tabstop_margin) / w) * w
end

--text positioning -----------------------------------------------------------

--x-advance of the grapheme cluster at s[i]
function view:char_advance_x(s, i) error'stub' end

--x coord of the grapheme cluster following the one at s[i] which is at x
function view:next_x(x, s, i)
	if str.istab(s, i) then
		return self:next_tabstop_x(x)
	else
		return x + self:char_advance_x(s, i)
	end
end

--x coord of the grapheme cluster at line,i
function view:char_x(line, i)
	assert(i >= 1)
	assert(line >= 1)
	local x = 0
	for i1, s in self.buffer:chars(line) do
		if i == i1 then break end
		x = self:next_x(x, s, i1)
	end
	return x
end

function view:string_width(s, i, j)
	local x = 0
	for i in str.chars(s, i) do
		if j and i > j then break end
		x = self:next_x(x, s, i)
	end
	return x
end

function view:line_y(line)
	assert(line >= 1)
	return self.line_h * (line - 1)
end

function view:char_y(line, i)
	return self:line_y(line)
end

function view:char_coords(line, i)
	local y = self:char_y(line, i)
	local x = self:char_x(line, i)
	return x, y
end

--text hit testing -----------------------------------------------------------

function view:line_at(y)
	return math.max(1, math.floor(y / self.line_h) + 1)
end

function view:char_at_line(line, x, closest)
	local xi, x0, i0 = 0, 0, 1
	for i, s in self.buffer:chars(line) do
		if xi > x then
			if closest then --char starting closest to x
				if x - x0 < xi - x then
					return i0
				else
					return i
				end
			else
				return i0 --char hitting x
			end
		end
		x0 = xi
		xi = self:next_x(xi, s, i)
		i0 = i
	end
	if xi > x then --check eol's x too
		if closest then
			if x - x0 < xi - x and i0 then
				return i0
			end
		else
			return i0 --char hitting x
		end
	end
	return self.buffer:eol(line)
end

function view:char_at(x, y, closest)
	local line = self:line_at(y)
	return line, self:char_at_line(line, x, closest)
end

--cursor positioning & shape -------------------------------------------------

function view:cursor_y(cursor)
	return self:char_y(cursor.line, cursor.i)
end

function view:cursor_xw(cursor)
	if cursor.line > #self.buffer.lines then
		local x = self:space_width(cursor.i - 1)
		local w = self:space_width(1)
		return x, w
	end
	local x = self:char_x(cursor.line, cursor.i)
	local eol = self.buffer:eol(cursor.line)
	local extra_spaces = cursor.i - eol
	if extra_spaces > 0 then
		x = x + self:space_width(extra_spaces)
	end
	local w
	if extra_spaces >= 0 then
		w = self:space_width(1)
	else
		local _, i2 = cursor:next_pos(false, cursor.jump_tabstops)
		local x2 = self:char_coords(cursor.line, i2)
		w = x2 - x
	end
	return x, w
end

function view:cursor_coords(cursor)
	local y = self:cursor_y(cursor)
	local x, w = self:cursor_xw(cursor)
	return x, y, w
end

function view:_cursor_rect_insert_mode(cursor)
	local x, y = self:cursor_coords(cursor)
	local w = cursor.thickness or self.cursor_thickness
	local h = self.line_h
	x = x + (cursor.i == 1 and self.cursor_xoffset_col1 or self.cursor_xoffset)
	return x, y, w, h
end

function view:_cursor_rect_overwrite_mode(cursor)
	local x, y, w = self:cursor_coords(cursor)
	local h = cursor.thickness or self.cursor_thickness
	y = y + self.ascender + 1
	return x, y, w, h
end

function view:cursor_rect(cursor)
	if cursor.insert_mode then
		return self:_cursor_rect_insert_mode(cursor)
	else
		return self:_cursor_rect_overwrite_mode(cursor)
	end
end

--cursor hit testing ---------------------------------------------------------

function view:_space_chars(w)
	return math.floor(w / self:space_width(1) + 0.5)
end

function view:cursor_char_at_line(line, x, restrict_eof)
	if line > #self.buffer.lines then --outside buffer
		if not restrict_eof then
			return self:_space_chars(x) + 1
		else
			line = #self.buffer.lines
		end
	end
	local i = self:char_at_line(line, x, true)
	if i == self.buffer:eol(line) then --possibly outside line
		local w = x - self:char_x(line, i) --outside width
		if w > 0 then
			i = i + self:_space_chars(w)
		end
	end
	return i
end

function view:cursor_char_at(x, y, restrict_eof)
	local line = self:line_at(y)
	return line, self:cursor_char_at_line(line, x, restrict_eof)
end

--selection positioning & shape ----------------------------------------------

--rectangle surrounding a block of text
function view:char_rect(line, i1, i2)
	local x1, y = self:char_coords(line, i1)
	local x2, y = self:char_coords(line, i2)
	return x1, y, x2 - x1, self.line_h
end

function view:selection_line_rect(sel, line)
	local i1, i2 = sel:chars(line)
	local x, y, w, h = self:char_rect(line, i1, i2)
	if not sel.block and line < (sel:isforward() and sel.line2 or sel.line1) then
		w = w + self:space_width(0.5) --show eol as half space
	end
	return x, y, w, h, i1, i2
end

--selection hit testing ------------------------------------------------------

function view:selection_hit_test(sel, x, y)
	if not sel.visible or sel:isempty() or not point_in_rect(x, y, self:clip_rect()) then
		return false
	end
	x, y = self:screen_to_client(x, y)
	local line1, line2 = sel:line_range()
	for line = line1, line2 do
		if point_in_rect(x, y, self:selection_line_rect(sel, line)) then
			return true
		end
	end
	return false
end

--text size ------------------------------------------------------------------

function view:line_width(line)
	return self:char_x(line, 1/0)
end

function view:max_line_width()
	local w = 0
	for line = 1, #self.buffer.lines do
		w = math.max(w, self:line_width(line))
	end
	return w
end

--size of the text space (i.e. client rectangle) as limited by the available
--text and any outside-of-text cursors.
function view:client_size()
	local maxline = #self.buffer.lines
	local maxw = self:max_line_width()
	--unrestricted cursors can enlarge the client area
	for cur in pairs(self.cursors) do
		maxline = math.max(maxline, cur.line)
		if not cur.restrict_eol then
			local x, w = self:cursor_xw(cur)
			maxw = math.max(maxw, x + w)
		end
	end
	return maxw, self:line_y(maxline + 1)
end

--margin metrics -------------------------------------------------------------

--width of all margins combined
function view:margins_width()
	local w = 0
	for _,m in ipairs(self.margins) do
		w = w + m:get_width()
	end
	return w
end

--x coord of a margin in screen space
function view:margin_x(target_margin)
	local x = self.x
	for _,margin in ipairs(self.margins) do
		if margin == target_margin then
			return x
		end
		x = x + margin:get_width()
	end
end

--clipping and scrolling -----------------------------------------------------

function view:screen_to_client(x, y)
	x = x - self.clip_x - self.scroll_x
	y = y - self.clip_y - self.scroll_y
	return x, y
end

function view:client_to_screen(x, y)
	x = x + self.clip_x + self.scroll_x
	y = y + self.clip_y + self.scroll_y
	return x, y
end

--clip rect of the client area in screen space.
function view:clip_rect()
	return self.clip_x, self.clip_y, self.clip_w, self.clip_h
end

--clip rect of a margin area in screen space
function view:margin_clip_rect(margin)
	local clip_x = self:margin_x(margin)
	local clip_w = margin:get_width()
	return clip_x, self.clip_y, clip_w, self.clip_h
end

--clip rect of a line in screen space
function view:line_clip_rect(line)
	local y = self:line_y(line)
	local _, y = self:client_to_screen(0, y)
	return self.clip_x, y, self.clip_w, self.line_h
end

--clipping in text space

--which lines are partially or entirely visibile
function view:visible_lines()
	local line1 = math.floor(-self.scroll_y / self.line_h) + 1
	local line2 = math.ceil((-self.scroll_y + self.clip_h) / self.line_h)
	line1 = self.buffer:clamp_pos(line1, 1)
	line2 = self.buffer:clamp_pos(line2, 1)
	return line1, line2
end

--point translation from screen space to client (text) space and back

function view:screen_to_margin_client(margin, x, y)
	x = x - self:margin_x(margin)
	y = y - self.clip_y - self.scroll_y
	return x, y
end

function view:margin_client_to_screen(margin, x, y)
	x = x + self:margin_x(margin)
	y = y + self.clip_y + self.scroll_y
	return x, y
end

--hit testing

function view:margin_hit_test(margin, x, y)
	if not point_in_rect(x, y, self:margin_clip_rect(margin)) then
		return false
	end
	x, y = self:screen_to_margin_client(margin, x, y)
	return true, self:char_at(x, y)
end

function view:client_hit_test(x, y)
	return point_in_rect(x, y, self:clip_rect())
end

--scrolling, i.e. adjusting the position of the client rectangle relative to
--the clipping rectangle.

--how many lines are in the clipping rect
function view:pagesize()
	return math.floor(self.clip_h / self.line_h + 0.5)
end

--event: adjust scrollbars.
function view:scroll_changed(scroll_x, scroll_y) end

function view:scroll_by(x, y)
	self.scroll_x = self.scroll_x + x
	self.scroll_y = self.scroll_y + y
	self:scroll_changed(self.scroll_x, self.scroll_y)
	self:invalidate()
end

function view:scroll_up()
	self:scroll_by(0, self.line_h)
end

function view:scroll_down()
	self:scroll_by(0, -self.line_h)
end

--scroll to make a specific rectangle visible
function view:make_rect_visible(x, y, w, h)
	self.scroll_x = -clamp(-self.scroll_x, x + w - self.clip_w, x)
	self.scroll_y = -clamp(-self.scroll_y, y + h - self.clip_h, y)
	self:scroll_changed(self.scroll_x, self.scroll_y)
end

--scroll to make the char under cursor visible
function view:cursor_make_visible(cur)
	local x, y, w, h = self:char_rect(cur.line, cur.i, cur.i)
	--enlarge the char rectangle with the cursor margins
	x = x - self.cursor_margins.left
	y = y - self.cursor_margins.top
	w = w + self.cursor_margins.right  + self.cursor_margins.left
	h = h + self.cursor_margins.bottom + self.cursor_margins.top
	self:make_rect_visible(x, y, w, h)
end

--drawing --------------------------------------------------------------------

--drawing stubs: all drawing is based on these functions

function view:draw_char(x, y, s, i, color) error'stub' end
function view:draw_rect(x, y, w, h, color) error'stub' end
function view:begin_clip(x, y, w, h) error'stub' end
function view:end_clip() error'stub' end

function view:draw_string(cx, cy, s, color, i, j)
	cy = cy + self.ascender
	local x = 0
	for i in str.chars(s, i) do
		if j and i >= j then
			break
		end
		if not str.iswhitespace(s, i) then
			self:draw_char(cx + x, cy, s, i, color)
		end
		x = self:next_x(x, s, i)
	end
end

function view:draw_string_aligned(cx, cy, s, color, i, j, align, cw)
	if align == 'right' then
		local w = self:string_width(s, i, j)
		self:draw_string(cx + cw - w, cy, s, color, i, j)
	else
		self:draw_string(cx, cy, s, color, i, j)
	end
end

function view:draw_buffer(cx, cy, line1, i1, line2, i2, color)

	--clamp the text rectangle to the visible rectangle
	local minline, maxline = self:visible_lines()
	line1 = clamp(line1, minline, maxline+1)
	line2 = clamp(line2, minline-1, maxline)

	cy = cy + self.ascender
	local _i1, _i2 = i1, i2
	for line = line1, line2 do
		i1, i2 = _i1, _i2
		if line ~= line1 and line ~= line2 then
			i1, i2 = 1, 1/0
		end
		local y = self:line_y(line)
		local x = 0
		for i, s in self.buffer:chars(line) do
			if i >= i1 and i <= i2 then
				if not str.iswhitespace(s, i) then
					self:draw_char(cx + x, cy + y, s, i, color)
				end
			end
			x = self:next_x(x, s, i)
		end
	end
end

function view:draw_buffer_highlighted(cx, cy)

	local minline, maxline = self:visible_lines()

	self.tokens, self.last_valid_line, self.start_tokens =
		hl.relex(maxline, self.tokens, self.last_valid_line, self.buffer,
					self.lang, self.start_tokens)

	local last_line, last_p1, last_vcol

	for i, line, p1, p2, style in hl.tokens(self.tokens, 1, 1, self.buffer) do

		if line > maxline then
			break
		end

		if line >= minline then
			if not style:match'whitespace$' then

				if line ~= last_line then
					last_p1, last_vcol = nil
				end

				local s = self.buffer:select(line)
				local vcol = visual_col_bi(s, p1, self.tabsize, last_p1, last_vcol)
				local x, y = self:char_coords(line, vcol)
				self:draw_string(cx + x, cy + y, s, style, p1, p2)

				last_line, last_p1, last_vcol = line, p1, vcol
			end
		end
	end
end

function view:draw_visible_text(cx, cy)
	if self.lang then
		self:draw_buffer_highlighted(cx, cy)
	else
		local color = self.buffer.text_color or 'text'
		self:draw_buffer(cx, cy, 1, 1, 1/0, 1/0, color)
	end
end

function view:draw_selection(sel, cx, cy)
	if sel:isempty() then return end
	local bg_color = sel.background_color or 'selection_background'
	local text_color = sel.text_color or 'selection_text'
	local line1, line2 = sel:line_range()
	for line = line1, line2 do
		local x, y, w, h, i1, i2 = self:selection_line_rect(sel, line)
		self:draw_rect(cx + x, cy + y, w, h, bg_color)
		self:draw_buffer(cx, cy, line, i1, line, i2 - 1, text_color)
	end
end

function view:draw_cursor(cursor, cx, cy)
	local x, y, w, h = self:cursor_rect(cursor)
	local color = cursor.color or 'cursor'
	self:draw_rect(cx + x, cy + y, w, h, color)
end

function view:draw_margin_line(margin, line, cx, cy, cw, ch, highlighted)
	local x, y = self:char_coords(line, 1)
	margin:draw_line(line, cx + x, cy + y, cw, ch, highlighted)
end

function view:draw_margin(margin)
	local clip_x, clip_y, clip_w, clip_h = self:margin_clip_rect(margin)
	self:begin_clip(clip_x, clip_y, clip_w, clip_h)
	--background
	local color = margin.background_color or 'margin_background'
	self:draw_rect(clip_x, clip_y, clip_w, clip_h, color)
	--contents
	local cx, cy = self:margin_client_to_screen(margin, 0, 0)
	local cw = margin:get_width()
	local ch = self.line_h
	local minline, maxline = self:visible_lines()
	for line = minline, maxline do
		self:draw_margin_line(margin, line, cx, cy, cw, ch)
	end
	--highlighted lines
	if self.highlight_cursor_lines then
		for cursor in pairs(self.cursors) do
			self:draw_margin_line(margin, cursor.line, cx, cy, cw, ch, true)
		end
	end
	self:end_clip()
end

function view:draw_line_highlight(line, color)
	local x, y, w, h = self:line_clip_rect(line)
	color = color or self.buffer.line_highlight_color or 'line_highlight'
	self:draw_rect(x, y, w, h, color)
end

function view:draw_background()
	local color = self.buffer.background_color or 'background'
	self:draw_rect(self.clip_x, self.clip_y, self.clip_w, self.clip_h, color)
end

function view:draw_tabstops()
	local color = self.buffer.tabstop_color or 'tabstop'
	local x0 = 0
	while x0 < self.clip_w do
		x0 = self:next_tabstop_x(x0)
		self:draw_rect(self.clip_x + x0, 0, 1, 1000, 'tabstop')
	end
end

function view:draw_client()
	self:begin_clip(self:clip_rect())
	self:draw_background()
	for cur in pairs(self.cursors) do
		self:draw_line_highlight(cur.line, cur.line_highlight_color)
	end
	if self.tabstops then
		self:draw_tabstops()
	end
	local cx, cy = self:client_to_screen(0, 0)
	self:draw_visible_text(cx, cy)
	for sel in pairs(self.selections) do
		if sel.visible then
			self:draw_selection(sel, cx, cy)
		end
	end
	for cur in pairs(self.cursors) do
		if cur.visible and cur.on then
			self:draw_cursor(cur, cx, cy)
		end
	end
	self:end_clip()
end

function view:draw()

	local margins_w = self:margins_width()
	self.clip_x = self.x + margins_w
	self.clip_y = self.y
	self.clip_w = self.w - margins_w
	self.clip_h = self.h

	for i,margin in ipairs(self.margins) do
		self:draw_margin(margin)
	end
	self:draw_client()
end

--margin base object ---------------------------------------------------------

local margin = object()

margin.w = 50
margin.margin_left = 4
margin.margin_right = 4
margin.min_digits = 4

--view overrides
margin.text_color = nil
margin.background_color = nil
margin.highlighted_text_color = nil
margin.highlighted_background_color = nil

function margin:__call(margin)
	self = object(self, margin)
	self.view:add_margin(self)
	return self
end

function margin:get_width()
	return self.w
end

function margin:draw_line(line, x, y, w) end --stub

function margin:hit_test(x, y)
	return self.view:margin_hit_test(self, x, y)
end

--line numbers margin --------------------------------------------------------

local ln_margin = object(margin)

local function digits(n) --number of base-10 digits of a number
	return math.floor(math.log10(n) + 1)
end

function ln_margin:get_width()
	return math.max(self.min_digits, digits(#self.buffer.lines))
		* self.view:char_advance_x('0', 1)
		+ self.margin_left
		+ self.margin_right
end

function ln_margin:draw_line(line, cx, cy, cw, ch, highlighted)

	if highlighted then
		local color =
			self.highlighted_background_color
			or 'line_number_highlighted_background'
		self.view:draw_rect(cx, cy, cw, ch, color)
	end

	local color = self.line_number_separator_color or 'line_number_separator'
	self.view:draw_rect(cx + cw - 1, cy, 1, ch, color)

	local color = highlighted
		and (self.highlighted_text_color or 'line_number_highlighted_text')
		or (self.text_color or 'line_number_text')

	local s = tostring(line)
	self.view:draw_string_aligned(cx + self.margin_left, cy, s, color,
		nil, nil, 'right', cw - self.margin_right - self.margin_left)
end

--blame margin ---------------------------------------------------------------

--TODO: synchronize the blame list with buffer:insert_line() / buffer:remove_line() / buffer:setline() operations
--TODO: request blame info again after each file save

local blame_margin = object(margin)

blame_margin.blame_command = 'hg blame -u "%s"'

function blame_margin:get_blame_info(filename)
	self.blame_info = {}
	self.w = 0

	local cmd = string.format(self.blame_command, filename)
	local f = io.popen(cmd)
	local s = f:read('*a')
	for _,line in self:_lines(s) do
		local user = line:match('([^%:]+)%:') or ''
		self.w = math.max(self.w, self.view:string_width(user))
		table.insert(self.blame_info, user)
	end
	f:close()
end

function blame_margin:draw_line(line, cx, cy, cw, ch, highlighted)
	if self.view.buffer.changed.blame_info then
		self.blame_info = nil
	end
	if not self.blame_info and self.view.buffer.filename then
		self:get_blame_info(self.view.buffer.filename)
		self.view.buffer.changed.blame_info = false
	end
	if not self.blame_info then return end
	local color = self.text_color or 'blame_text'
	local s = self.blame_info[line] or ''
	self.view:draw_text(cx, cy, s, color)
end

--editor object: putting it all together (aka the controller) ----------------

local editor = object()
--subclasses
editor.buffer_class = buffer
editor.line_selection_class = selection
editor.block_selection_class = block_selection
editor.cursor_class = cursor
editor.line_numbers_margin_class = ln_margin
editor.blame_margin_class = blame_margin
editor.view_class = view
--margins
editor.line_numbers = true
editor.blame = false
--keyboard state
editor.next_reflow_mode = {left = 'justify', justify = 'left'}
editor.default_reflow_mode = 'left'

function editor:__call(editor)
	self = object(self, editor)

	--core objects
	self.buffer = self:create_buffer(self.buffer)
	self.view = self:create_view(self.view)
	if self.text then
		self.buffer:load(self.text)
	end

	--main cursor & selection objects
	self.cursor = self:create_cursor(self.cursor)
	self.line_selection = self:create_line_selection(self.line_selection)
	self.block_selection = self:create_block_selection(self.block_selection)
	self.selection = self.line_selection --replaced by block_selection when selecting in block mode

	--selection changed flags
	self.block_selection.changed.reflow_mode = false
	self.line_selection.changed.reflow_mode = false

	--margins
	if self.blame then
		self.blame_margin =
			self:create_blame_margin(self.blame_margin)
	end
	if self.line_numbers then
		self.line_numbers_margin =
			self:create_line_numbers_margin(self.line_numbers_margin)
	end

	return self
end

--object constructors

function editor:create_buffer(buffer)
	return self.buffer_class(update({
		editor = self,
	}, buffer))
end

function editor:create_view(view)
	return self.view_class(update({
		editor = self,
		buffer = self.buffer,
	}, view))
end

function editor:create_cursor(cursor)
	return self.cursor_class(update({
		editor = self,
		buffer = self.buffer,
		view = self.view,
		visible = true,
		on = true,
	}, cursor))
end

function editor:create_line_selection(selection)
	return self.line_selection_class(update({
		editor = self,
		buffer = self.buffer,
		view = self.view,
		visible = true,
	}, selection))
end

function editor:create_block_selection(selection)
	return self.block_selection_class(update({
		editor = self,
		buffer = self.buffer,
		view = self.view,
		visible = false,
	}, selection))
end

function editor:create_line_numbers_margin(margin)
	return self.line_numbers_margin_class(update({
		editor = self,
		buffer = self.buffer,
		view = self.view,
	}, margin))
end

function editor:create_blame_margin(margin)
	return self.blame_margin_class(update({
		editor = self,
		buffer = self.buffer,
		view = self.view,
	}, margin))
end

--undo/redo integration

function editor:save_state(state)
	state.cursor = state.cursor or {}
	state.selection = state.selection or {}
	state.view = state.view or {}
	self.cursor:save_state(state.cursor)
	state.block_selection = self.selection.block
	self.selection:save_state(state.selection)
	self.view:save_state(state.view)
end

function editor:load_state(state)
	if self.selection.block ~= state.block_selection then
		self.selection.visible = false
		self.selection:invalidate()
		self.selection = state.block_selection and self.block_selection or self.line_selection
		self.selection.visible = true
		self.selection:invalidate()
	end
	self.selection:load_state(state.selection)
	self.cursor:load_state(state.cursor)
	self.view:load_state(state.view)
end

--undo/redo commands

function editor:undo() self.buffer:undo() end
function editor:redo() self.buffer:redo() end

--navigation & selection commands

function editor:_before_move_cursor(mode)
	self.buffer:start_undo_group'move'
	if mode == 'select' or mode == 'select_block' then
		if self.selection.block ~= (mode == 'select_block') then
			self.selection.visible = false
			local old_sel = self.selection
			if mode == 'select' then
				self.selection = self.line_selection
			else
				self.selection = self.block_selection
			end
			self.selection:set_to_selection(old_sel)
			self.selection.visible = true
		end
	else
		self.cursor.restrict_eol = nil
	end

	if mode == 'select' or mode == 'select_block' or mode == 'unrestricted' then
		local old_restrict_eol = self.cursor.restrict_eol
		self.cursor.restrict_eol = nil
		self.cursor.restrict_eol =
			self.cursor.restrict_eol
			and not self.selection.block
			and mode ~= 'unrestricted'
		if not old_restrict_eol and self.cursor.restrict_eol then
			self.cursor:move(self.cursor.line, self.cursor.i)
		end
	end
end

function editor:_after_move_cursor(mode)
	if mode == 'select' or mode == 'select_block' then
		self.selection:extend_to_cursor(self.cursor)
	else
		self.selection:reset_to_cursor(self.cursor)
	end
	self.cursor:make_visible()
end

function editor:move_cursor_to_coords(x, y, mode)
	self:_before_move_cursor(mode)
	self.cursor:move_to_coords(x, y)
	self:_after_move_cursor(mode)
end

function editor:move_cursor(direction, mode)
	self:_before_move_cursor(mode)
	local method = assert(self.cursor['move_'..direction], direction)
	method(self.cursor)
	self:_after_move_cursor(mode)
end

function editor:move_prev_pos()  self:move_cursor('prev_pos') end
function editor:move_next_pos() self:move_cursor('next_pos') end
function editor:move_prev_pos_unrestricted()  self:move_cursor('prev_pos',  'unrestricted') end
function editor:move_next_pos_unrestricted() self:move_cursor('next_pos', 'unrestricted') end
function editor:move_up()    self:move_cursor('up') end
function editor:move_down()  self:move_cursor('down') end
function editor:move_prev_word_break()  self:move_cursor('prev_word_break') end
function editor:move_next_word_break() self:move_cursor('next_word_break') end
function editor:move_home()  self:move_cursor('home') end
function editor:move_end()   self:move_cursor('end') end
function editor:move_bol()   self:move_cursor('bol') end
function editor:move_eol()   self:move_cursor('eol') end
function editor:move_up_page()   self:move_cursor('up_page') end
function editor:move_down_page() self:move_cursor('down_page') end

function editor:select_prev_pos()  self:move_cursor('prev_pos', 'select') end
function editor:select_next_pos() self:move_cursor('next_pos', 'select') end
function editor:select_up()    self:move_cursor('up', 'select') end
function editor:select_down()  self:move_cursor('down', 'select') end
function editor:select_prev_word_break()  self:move_cursor('prev_word_break', 'select') end
function editor:select_next_word_break() self:move_cursor('next_word_break', 'select') end
function editor:select_home()  self:move_cursor('home', 'select') end
function editor:select_end()   self:move_cursor('end', 'select') end
function editor:select_bol()   self:move_cursor('bol', 'select') end
function editor:select_eol()   self:move_cursor('eol', 'select') end
function editor:select_up_page()   self:move_cursor('up_page', 'select') end
function editor:select_down_page() self:move_cursor('down_page', 'select') end

function editor:select_block_prev_pos()  self:move_cursor('prev_pos', 'select_block') end
function editor:select_block_next_pos() self:move_cursor('next_pos', 'select_block') end
function editor:select_block_up()    self:move_cursor('up', 'select_block') end
function editor:select_block_down()  self:move_cursor('down', 'select_block') end
function editor:select_block_prev_word_break()  self:move_cursor('prev_word_break', 'select_block') end
function editor:select_block_next_word_break() self:move_cursor('next_word_break', 'select_block') end
function editor:select_block_home()  self:move_cursor('home', 'select_block') end
function editor:select_block_end()   self:move_cursor('end', 'select_block') end
function editor:select_block_bol()   self:move_cursor('bol', 'select_block') end
function editor:select_block_eol()   self:move_cursor('eol', 'select_block') end
function editor:select_block_up_page()   self:move_cursor('up_page', 'select_block') end
function editor:select_block_down_page() self:move_cursor('down_page', 'select_block') end

function editor:select_all()
	self:move_cursor('home')
	self:move_cursor('end', 'select')
end

function editor:reset_selection_to_cursor()
	self.selection:reset_to_cursor(self.cursor)
end

function editor:select_word_at_cursor()
	local i1, i2 = self.cursor:word_bounds()
	if not i1 then return end
	self.selection:set(self.cursor.line, i1, self.cursor.line, i2)
	self.cursor:move_to_selection(self.selection)
end

function editor:select_line_at_cursor()
	self:move_cursor('bol')
	self:move_cursor('eol', 'select')
end

--editing commands

function editor:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
	self.cursor:invalidate()
end

function editor:remove_selection()
	if self.selection:isempty() then return end
	self.buffer:start_undo_group'remove_selection'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
end

function editor:insert_char(char)
	self:remove_selection()
	self.buffer:start_undo_group'insert_char'
	self.cursor:insert_char(char)
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:delete_pos(prev)
	if self.selection:isempty() then
		self.buffer:start_undo_group'delete_position'
		if prev then
			if not (self.cursor.line == 1 and self.cursor.i == 1) then
				self.cursor:delete_prev_pos()
			end
		else
			self.cursor:delete_pos(true)
		end
		self.selection:reset_to_cursor(self.cursor)
	else
		self:remove_selection()
	end
	self.cursor:make_visible()
end

function editor:delete_prev_pos()
	self:delete_pos(true)
end

function editor:newline()
	self:remove_selection()
	self.buffer:start_undo_group'insert_newline'
	self.cursor:insert_newline()
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:indent()
	if self.selection:isempty() then
		self.buffer:start_undo_group'insert_tab'
		self.cursor:insert_tab()
		self.selection:reset_to_cursor(self.cursor)
	else
		self.buffer:start_undo_group'indent_selection'
		self.selection:indent(self.cursor.insert_tabs ~= 'never')
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:outdent()
	if self.selection:isempty() then
		self.buffer:start_undo_group'outdent_line'
		self.cursor:outdent_line()
		self.selection:reset_to_cursor(self.cursor)
	else
		self.buffer:start_undo_group'outdent_selection'
		self.selection:outdent()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_up()
	if self.selection:isempty() then
		self.buffer:start_undo_group'move_line_up'
		self.cursor:move_line_up()
		self.selection:reset_to_cursor(self.cursor)
	elseif self.selection.move_up then
		self.buffer:start_undo_group'move_selection_up'
		self.selection:move_up()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_down()
	if self.selection:isempty() then
		self.buffer:start_undo_group'move_line_down'
		self.cursor:move_line_down()
		self.selection:reset_to_cursor(self.cursor)
	elseif self.selection.move_up then
		self.buffer:start_undo_group'move_selection_down'
		self.selection:move_down()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:reflow()
	if self.selection:isempty() then return end

	local reflow_mode = self.last_reflow_mode
		and self.next_reflow_mode[self.last_reflow_mode]
		or self.default_reflow_mode
	if self.selection.changed.reflow_mode then
		reflow_mode = self.default_reflow_mode
	end
	self.last_reflow_mode = reflow_mode

	self.buffer:start_undo_group'reflow_selection'
	self.selection:reflow(self.view.line_width, self.tabsize, reflow_mode, 'greedy')
	self.cursor:move_to_selection(self.selection)
end

--clipboard commands

--global clipboard over all editor instances on the same Lua state
local clipboard_contents = ''

function editor:set_clipboard(s)
	clipboard_contents = s
end

function editor:get_clipboard()
	return clipboard_contents
end

function editor:cut()
	if self.selection:isempty() then return end
	local s = self.selection:contents()
	self:set_clipboard(s)
	self.buffer:start_undo_group'cut'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
	self.cursor:make_visible()
end

function editor:copy()
	if self.selection:isempty() then return end
	self.buffer:start_undo_group'copy'
	self:set_clipboard(self.selection:contents())
end

function editor:paste(mode)
	local s = self:get_clipboard()
	if not s then return end
	self.buffer:start_undo_group'paste'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
	if mode == 'block' then
		self.cursor:insert_block(s)
	else
		self.cursor:insert(s)
	end
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:paste_block()
	self:paste'block'
end

--scrolling

function editor:scroll_down()
	self.view:scroll_down()
end

function editor:scroll_up()
	self.view:scroll_up()
end

--save command

function editor:save(filename)
	self.buffer:start_undo_group'normalize'
	self.buffer:normalize()
	self.cursor:move(self.cursor.line, self.cursor.i) --cursor could get invalid after normalization
	self.buffer:save_to_file(filename)
end

--replace command

function editor:replace(s, with_undo)
	if with_undo then
		self.buffer:start_undo_group'replace'
		self.selection:select_all()
		self.selection:remove()
		self.cursor:move_to_selection(self.selection)
		self.cursor:insert(s)
		self.selection:reset_to_cursor(self.cursor)
	else
		self.cursor:move_home()
		self.selection:reset_to_cursor()
		self.buffer:load(s)
	end
end

--input ----------------------------------------------------------------------


editor.key_bindings = { --flag order is ctrl+alt+shift
	--navigation
	['ctrl+up']     = 'scroll_up',
	['ctrl+down']   = 'scroll_down',
	['left']        = 'move_prev_pos',
	['right']       = 'move_next_pos',
	['alt+left']    = 'move_prev_pos_unrestricted',
	['alt+right']   = 'move_next_pos_unrestricted',
	['up']          = 'move_up',
	['down']        = 'move_down',
	['ctrl+left']   = 'move_prev_word_break',
	['ctrl+right']  = 'move_next_word_break',
	['home']        = 'move_bol',
	['end']         = 'move_eol',
	['ctrl+home']   = 'move_home',
	['ctrl+end']    = 'move_end',
	['pageup']      = 'move_up_page',
	['pagedown']    = 'move_down_page',
	--navigation + selection
	['shift+left']       = 'select_prev_pos',
	['shift+right']      = 'select_next_pos',
	['shift+up']         = 'select_up',
	['shift+down']       = 'select_down',
	['ctrl+shift+left']  = 'select_prev_word_break',
	['ctrl+shift+right'] = 'select_next_word_break',
	['shift+home']       = 'select_bol',
	['shift+end']        = 'select_eol',
	['ctrl+shift+home']  = 'select_home',
	['ctrl+shift+end']   = 'select_end',
	['shift+pageup']     = 'select_up_page',
	['shift+pagedown']   = 'select_down_page',
	--navigation + block selection
	['alt+shift+left']       = 'select_block_prev_pos',
	['alt+shift+right']      = 'select_block_next_pos',
	['alt+shift+up']         = 'select_block_up',
	['alt+shift+down']       = 'select_block_down',
	['ctrl+alt+shift+left']  = 'select_block_prev_word_break',
	['ctrl+alt+shift+right'] = 'select_block_next_word_break',
	['alt+shift+home']       = 'select_block_bol',
	['alt+shift+end']        = 'select_block_eol',
	['ctrl+alt+shift+home']  = 'select_block_home',
	['ctrl+alt+shift+end']   = 'select_block_end',
	['alt+shift+pageup']     = 'select_block_up_page',
	['alt+shift+pagedown']   = 'select_block_down_page',
	--additional navigation
	['alt+up']      = 'move_up_page',
	['alt+down']    = 'move_down_page',
	--bookmarks (TODO)
	['ctrl+f2']     = 'toggle_bookmark',
	['f2']          = 'move_next_bookmark',
	['shift+f2']    = 'move_prev_bookmark',
	--additional selection
	['ctrl+A']      = 'select_all',
	--editing
	['insert']          = 'toggle_insert_mode',
	['backspace']       = 'delete_prev_pos',
	['shift+backspace'] = 'delete_prev_pos',
	['delete']          = 'delete_pos',
	['enter']           = 'newline',
	['tab']             = 'indent',
	['shift+tab']       = 'outdent',
	['ctrl+shift+up']   = 'move_lines_up',
	['ctrl+shift+down'] = 'move_lines_down',
	['ctrl+Z']          = 'undo',
	['ctrl+Y']          = 'redo',
	--reflowing
	['ctrl+R']          = 'reflow',
	--copy/pasting
	['ctrl+X']            = 'cut',
	['ctrl+C']            = 'copy',
	['ctrl+V']            = 'paste',
	['ctrl+alt+V']        = 'paste_block',
	['shift+delete']      = 'cut',
	['ctrl+insert']       = 'copy',
	['shift+insert']      = 'paste',
	['shift+alt+insert']  = 'paste_block',
	--saving
	['ctrl+S'] = 'save',
}

function editor:perform_shortcut(shortcut, ctrl, alt, shift)
	local command = self.key_bindings[shortcut]
	if not command then return end
	if not self[command] then
		error(string.format('command not found: %s for %s', command, shortcut))
	end
	self[command](self, ctrl, alt, shift)
end

function editor:hit_test(x, y)
	if self.selection:hit_test(x, y) then
		return 'selection'
	elseif self.view:client_hit_test(x, y) then
		return 'client'
	elseif self.line_numbers_margin:hit_test(x, y) then
		return 'line_numbers_margin'
	end
end

--RMGUI integration ----------------------------------------------------------

function editor:capture_mouse(capture) end

function editor:key(key) error'stub' end

function editor:keychar(char)
	local ctrl = self:key'ctrl'
	local alt = self:key'alt'
	local is_input_char =
		not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
	if is_input_char then
		self:insert_char(char)
	end
end

function editor:keypress(key)
	local ctrl = self:key'ctrl'
	local alt = self:key'alt'
	local shift = self:key'shift'
	local shortcut =
		(ctrl  and 'ctrl+'  or '') ..
		(alt   and 'alt+'   or '') ..
		(shift and 'shift+' or '') .. key
	self:perform_shortcut(shortcut)
end

function editor:mousedown()
	self:capture_mouse(true)
	self.active = true
end

function editor:mouseup()
	self:capture_mouse(false)
	self.active = false
end

function editor:click(mx, my)
	self:move_cursor_to_coords(mx, my)
end

function editor:doubleclick(mx, my)
	if self:hit_test(mx, my) == 'client' then
		self:select_word_at_cursor()
	end
end

function editor:tripleclick(mx, my)
	local area = self:hit_test(mx, my)
	if area == 'selection' or area == 'client' then
		self:select_line_at_cursor()
	end
end

function editor:mousemove(mx, my)
	if self.active then
		if self.moving_selection then
			if self.moving_at_pos then
				--TODO: finish moving sub-line selection with the mouse
			elseif not self.moving_adjusted and
				(math.abs(mx - self.moving_mousex) >= 6 or
				 math.abs(my - self.moving_mousey) >= 6)
			then
				self.selection:set_to_line_range()
				self.selection:reverse()
				self.cursor:move_to_selection(self.selection)
				self.moving_adjusted = true
			end
			if self.moving_adjusted then
				--TODO: finish moving multiline selection with the mouse
			end
		else
			local mode = self:key'alt' and 'select_block' or 'select'
			self:move_cursor_to_coords(mx, my, mode)
		end
	end
end

function editor:focus()
	self.cursor.visible = true
	if not self.buffer.multiline then
		self:select_all()
	end
	self.cursor:invalidate()
end

function editor:unfocus()
	self.cursor.visible = false
	self.cursor:invalidate()
	if not self.buffer.multiline then
		self:reset_selection_to_cursor()
	end
end

function editor:invalidate() end --stub

--IMGUI integration ----------------------------------------------------------

--draw a scrollbox widget with the clipping rect (x, y, w, h) and the client
--rect (cx, cy, cw, ch). return the new cx, cy, adjusted from user input
--and other scrollbox constraints, followed by the clipping rect.
--the client rect is relative to the clipping rect of the scrollbox (which
--can be different than its outside rect). this stub implementation is
--equivalent to a scrollbox that takes no user input, has no margins, and has
--invisible scrollbars.
function view:imgui_draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	return cx, cy, x, y, w, h
end

function view:imgui_draw()

	local client_w, client_h = self:client_size()
	local margins_w = self:margins_width()

	self.scroll_x, self.scroll_y,
	self.clip_x, self.clip_y, self.clip_w, self.clip_h =
		self:draw_scrollbox(
			self.x + margins_w, self.y,
			self.w - margins_w, self.h,
			self.scroll_x, self.scroll_y,
			client_w, client_h)

	for i,margin in ipairs(self.margins) do
		self:draw_margin(margin)
	end
	self:draw_client()
end

function editor:imgui_input(focused, active, key, char, ctrl, shift, alt,
	mousex, mousey, lbutton, rbutton, wheel_delta,
	doubleclicked, tripleclicked, quadrupleclicked, waiting_for_triple_click)

	--scrollbox has not been rendered yet, input cannot work
	if not self.view.clip_x then return end

	local client_hit = self.view:client_hit_test(mousex, mousey)
	local selection_hit = self.selection:hit_test(mousex, mousey)
	local ln_margin_hit = self.line_numbers_margin:hit_test(mousex, mousey)

	if client_hit and not selection_hit then
		self.player.cursor = 'text'
	end

	if focused then

		local is_input_char = char and not ctrl and not alt and (#char > 1 or char:byte(1) > 31)
		if is_input_char then
			self:insert_char(char)
		elseif key then
			local shortcut =
				(ctrl  and 'ctrl+'  or '') ..
				(alt   and 'alt+'   or '') ..
				(shift and 'shift+' or '') .. key
			self:perform_shortcut(shortcut)
		end

	end

	if doubleclicked and client_hit then
		self:select_word_at_cursor()
		self.word_selected = true
	else
		if tripleclicked and client_hit then
			self:select_line_at_cursor()
		elseif not active and lbutton and selection_hit and not waiting_for_triple_click then
			self.moving_selection = true
			self.moving_at_pos = self.selection.line2 == self.selection.line1
			self.moving_mousex = mousex
			self.moving_mousey = mousey
			self.moving_adjusted = false
			self:setactive(true)
		elseif not active and lbutton and (client_hit or ln_margin_hit)
			and not waiting_for_triple_click
		then
			self:move_cursor_to_coords(mousex, mousey)
			self:setactive(true)
		elseif active == self.id then
			if lbutton then
				if self.moving_selection then
					if self.moving_at_pos then
						--TODO: finish moving sub-line selection with the mouse
					elseif not self.moving_adjusted and
						(math.abs(mousex - self.moving_mousex) >= 6 or
						 math.abs(mousey - self.moving_mousey) >= 6)
					then
						self.selection:set_to_line_range()
						self.selection:reverse()
						self.cursor:move_to_selection(self.selection)
						self.moving_adjusted = true
					end
					if self.moving_adjusted then
						--TODO: finish moving multiline selection with the mouse
					end
				else
					local mode = alt and 'select_block' or 'select'
					self:move_cursor_to_coords(mousex, mousey, mode)
				end
			else
				if self.moving_selection and not self.moving_adjusted then
					self:move_cursor_to_coords(mousex, mousey)
				end
				self.moving_selection = nil
				self:setactive(false)
			end
		end
		self.word_selected = false
	end

end

--codedit module -------------------------------------------------------------

return {
	str = str,
	object = object,
	buffer = buffer,
	line_selection = selection,
	block_selection = block_selection,
	cursor = cursor,
	line_numbers_margin = ln_margin,
	blame_margin = blame_margin,
	view = view,
	editor = editor,
}
