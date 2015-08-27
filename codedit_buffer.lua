--codedit buffer object: text navigation and manipulation.
local glue = require'glue'
local str = require'codedit_str'
require'codedit_reflow'
local tabs = require'codedit_tabs'

local buffer = {
	line_terminator = nil, --line terminator to use when retrieving lines as a string. nil means autodetect.
	default_line_terminator = '\n', --line terminator to use when autodetection fails.
	--view overrides
	background_color = nil,
	text_color = nil,
	line_highlight_color = nil,
}

function buffer:new(editor, view, text)
	self = glue.inherit({
		editor = editor,  --for save_state & load_state (see codedit_undo)
		view = view,      --for tabsize
	}, self)

	text = text or ''

	self.line_terminator =
		self.line_terminator or
		self:detect_line_terminator(text) or
		self.default_line_terminator

	self.lines = {''} --can't have zero lines
	self.changed = {} --{<flag> = true/false}; you can add any flags, they will all be set when the buffer changes.
	self:insert_string(1, 1, text) --insert text without undo stack
	self.changed.file = false --"file" is the default changed flag to decide when to save.

	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil

	return self
end

--message passing

function buffer:invalidate(line)
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
	self.view:invalidate(line)
end

--text analysis

--class method that returns the most common line terminator in a string, or nil for failure
function buffer:detect_line_terminator(s)
	local rn = str.count(s, '\r\n') --win lines
	local r  = str.count(s, '\r') --mac lines
	local n  = str.count(s, '\n') --unix lines (default)
	if rn > n and rn > r then
		return '\r\n'
	elseif r > n then
		return '\r'
	end
end

--detect indent type and tab size of current buffer
function buffer:detect_indent()
	local tabs, spaces = 0, 0
	for line = 1, self:last_line() do
		local tabs1, spaces1 = str.indent_counts(self:getline(line))
		tabs = tabs + tabs1
		spaces = spaces + spaces1
	end
	--TODO: finish this
end

--finding buffer boundaries

function buffer:last_line()
	return #self.lines
end

--selecting text at the line level

function buffer:getline(line)
	return self.lines[line]
end

function buffer:contents(lines)
	return table.concat(lines or self.lines, self.line_terminator)
end

--editing text at the line level (low level interface; valid lines only)

function buffer:insert_line(line, s)
	table.insert(self.lines, line, s)
	self:undo_command('remove_line', line)
	self:invalidate(line)
end

function buffer:remove_line(line)
	local s = table.remove(self.lines, line)
	self:undo_command('insert_line', line, s)
	self:invalidate(line)
	return s
end

function buffer:setline(line, s)
	self:undo_command('setline', line, self:getline(line))
	self.lines[line] = s
	self:invalidate(line)
end

--switch two lines with one another
function buffer:move_line(line1, line2)
	local s1 = self:getline(line1)
	local s2 = self:getline(line2)
	if not s1 or not s2 then return end
	self:setline(line1, s2)
	self:setline(line2, s1)
end

--finding line boundaries

--last column on a valid line
function buffer:last_col(line)
	return str.len(self:getline(line))
end

--the position after the last char in the text
function buffer:end_pos()
	return self:last_line(), self:last_col(self:last_line()) + 1
end

--char-by-char linear navigation based on line boundaries

--position after some char, unclamped
function buffer:next_char_pos(line, col, restrict_eol)
	if not restrict_eol or (self:getline(line) and col < self:last_col(line) + 1) then
		return line, col + 1
	else
		return line + 1, 1
	end
end

--position before some char, unclamped
function buffer:prev_char_pos(line, col)
	if col > 1 then
		return line, col - 1
	elseif self:getline(line - 1) then
		return line - 1, self:last_col(line - 1) + 1
	else
		return line - 1, 1
	end
end

--position that is a number of chars after or before some char, unclamped
function buffer:near_char_pos(line, col, chars, restrict_eol)
	local advance = chars > 0 and self.next_char_pos or self.prev_char_pos
	chars = math.abs(chars)
	while chars > 0 do
		line, col = advance(self, line, col, restrict_eol)
		chars = chars - 1
	end
	return line, col
end

--clamp a position to the available text
function buffer:clamp_pos(line, col)
	if line < 1 then
		return 1, 1
	elseif line > self:last_line() then
		return self:end_pos()
	else
		return line, math.min(math.max(col, 1), self:last_col(line) + 1)
	end
end

--selecting text at linear char positions

--line slice between two columns on a valid line
function buffer:sub(line, col1, col2)
	return str.sub(self:getline(line), col1, col2)
end

--select the string between two valid, subsequent positions in the text
function buffer:select_string(line1, col1, line2, col2)
	local lines = {}
	if line1 == line2 then
		table.insert(lines, self:sub(line1, col1, col2 - 1))
	else
		table.insert(lines, self:sub(line1, col1))
		for line = line1 + 1, line2 - 1 do
			table.insert(lines, self:getline(line))
		end
		table.insert(lines, self:sub(line2, 1, col2 - 1))
	end
	return lines
end

--editing at linear char positions

--extend the buffer up to (line,col-1) with newlines and spaces so we can edit there.
function buffer:extend(line, col)
	while line > self:last_line() do
		self:insert_line(self:last_line() + 1, '')
	end
	local last_col = self:last_col(line)
	if col > last_col + 1 then
		self:setline(line, self:getline(line) .. string.rep(' ', col - last_col - 1))
	end
end

--insert a multiline string at a specific position in the text, returning the position after the last character.
--if the position is outside the text, the buffer is extended.
function buffer:insert_string(line, col, s)
	self:extend(line, col)
	local s1 = self:sub(line, 1, col - 1)
	local s2 = self:sub(line, col)
	s = s1 .. s .. s2
	local first_line = true
	for _,s in str.lines(s) do
		if first_line then
			self:setline(line, s)
			first_line = false
		else
			line = line + 1
			self:insert_line(line, s)
		end
	end
	return line, self:last_col(line) - #s2 + 1
end

--remove the string between two arbitrary, subsequent positions in the text.
--line2,col2 is the position after the last character to be removed.
function buffer:remove_string(line1, col1, line2, col2)
	line1, col1 = self:clamp_pos(line1, col1)
	line2, col2 = self:clamp_pos(line2, col2)
	local s1 = self:sub(line1, 1, col1 - 1)
	local s2 = self:sub(line2, col2)
	for line = line2, line1 + 1, -1 do
		self:remove_line(line)
	end
	self:setline(line1, s1 .. s2)
end

--tab expansion: finding boundaries in visual space

function buffer:tab_width(vcol)    return tabs.tab_width(vcol, self.view.tabsize) end
function buffer:next_tabstop(vcol) return tabs.next_tabstop(vcol, self.view.tabsize) end
function buffer:prev_tabstop(vcol) return tabs.prev_tabstop(vcol, self.view.tabsize) end

--translating between the char space and the visual (tabs-expanded) space

--real col -> visual col. outside eof visual columns have the same width as real columns.
function buffer:visual_col(line, col)
	local s = self:getline(line)
	if s then
		return tabs.visual_col(s, col, self.view.tabsize)
	else
		return col
	end
end

--visual col -> char col. outside eof visual columns have the same width as real columns.
function buffer:real_col(line, vcol)
	local s = self:getline(line)
	if s then
		return tabs.real_col(s, vcol, self.view.tabsize)
	else
		return vcol
	end
end

--the real col on a line that is vertically aligned (in the visual space) to the same col on a different line.
function buffer:aligned_col(target_line, line, col)
	return self:real_col(target_line, self:visual_col(line, col))
end

--number of columns needed to fit the entire text (for computing the client area for horizontal scrolling)
function buffer:max_visual_col()
	if self.changed.max_visual_col ~= false then
		local vcol = 0
		for line = 1, self:last_line() do
			local vcol1 = self:visual_col(line, self:last_col(line))
			if vcol1 > vcol then
				vcol = vcol1
			end
		end
		self.cached_max_visual_col = vcol
		self.changed.max_visual_col = false
	end
	return self.cached_max_visual_col
end

--finding tabstop boundaries in unclamped char space

function buffer:istab(line, col)
	local s = self:getline(line)
	if not s then return end
	local i = str.byte_index(s, col)
	if not i then return end
	return str.istab(s, i)
end

function buffer:next_tabstop_col(line, col)
	local vcol = self:visual_col(line, col)
	local ts_vcol = self:next_tabstop(vcol)
	return self:real_col(line, ts_vcol)
end

function buffer:prev_tabstop_col(line, col)
	local vcol = self:visual_col(line, col)
	local ts_vcol = self:prev_tabstop(vcol)
	return self:real_col(line, ts_vcol)
end

--selecting text based on tab expansion

--the indent of the line, optionally up to some column
function buffer:select_indent(line, col)
	local ns_col = self:next_nonspace_col(line)
	local indent_col = math.min(col or 1/0, ns_col or 1/0)
	return self:getline(line) and self:sub(line, 1, indent_col - 1)
end

--editing based on tab expansion

--insert a tab or spaces from a position up to the next tabstop.
--return the cursor at the tabstop, where the indented text is.
function buffer:indent(line, col, use_tab)
	if use_tab then
		return self:insert_string(line, col, '\t')
	else
		local vcol = self:visual_col(line, col)
		return self:insert_string(line, col, string.rep(' ', self:tab_width(vcol)))
	end
end

function buffer:indent_line(line, use_tab)
	return self:indent(line, 1, use_tab)
end

--find the max number of tabs and minimum number of spaces that fit between two visual columns
function buffer:tabs_and_spaces(vcol1, vcol2)
	return tabs.tabs_and_spaces(vcol1, vcol2, self.view.tabsize)
end

--generate whitespace (tabs and spaces or just spaces, depending on the use_tabs flag) between two vcols.
function buffer:gen_whitespace(vcol1, vcol2, use_tabs)
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
function buffer:insert_whitespace(line, col, vcol2, use_tabs)
	local vcol1 = self:visual_col(line, col)
	local whitespace = self:gen_whitespace(vcol1, vcol2, use_tabs)
	return self:insert_string(line, col, whitespace)
end

--finding non-space boundaries (jumping whitespace)

function buffer:next_nonspace_col(line, col)
	local s = self:getline(line)
	return s and str.next_nonspace(s, col)
end

function buffer:prev_nonspace_col(line, col)
	local s = self:getline(line)
	return s and str.prev_nonspace(s, col)
end

--check if a line is either invalid, empty or made entirely of whitespace
function buffer:isempty(line)
	return not self:next_nonspace_col(line)
end

--check if a position is before the first non-space char, that is, in the indentation area.
function buffer:indenting(line, col)
	local ns_col = self:next_nonspace_col(line)
	return not ns_col or col <= ns_col
end

--finding tabful boundaries. a tabful is the whitespace between two tabstops.

--the tabful column after of some char, which is either the next tabstop or the first non-space char
--after the prev. char or the char after the last col, whichever comes first, and if after the given char.
function buffer:next_tabful_col(line, col, restrict_eol)
	if restrict_eol then
		if not self:getline(line) then return end
		if col > self:last_col(line) then return end
	end
	local ts_col = self:next_tabstop_col(line, col)
	local ns_col = self:next_nonspace_col(line, col - 1)
	if not ns_col then
		if restrict_eol then
			ns_col = self:last_col(line) + 1
		else
			ns_col = 1/0
		end
	end
	local tf_col = math.min(ts_col, ns_col)
	if restrict_eol then
		tf_col = math.min(tf_col, self:last_col(line) + 1)
	end
	if not (tf_col > col) then
		return
	end
	return tf_col
end

--the tabful column before some char, which is either the prev. tabstop or the char
--after the prev. non-space char, whichever comes last, and if before the given char.
function buffer:prev_tabful_col(line, col)
	if col <= 1 then return end
	local ts_col = self:prev_tabstop_col(line, col)
	local ns_col = self:prev_nonspace_col(line, col)
	if not ns_col then
		return ts_col
	end
	local tf_col = math.max(ts_col, ns_col + 1)
	if not (tf_col < col) then
		return
	end
	return tf_col
end

--editing based on tabfuls

--remove the space up to the next tabstop or non-space char, in other words, remove a tabful.
function buffer:outdent(line, col)
	local tf_col = self:next_tabful_col(line, col, true)
	if tf_col then
		self:remove_string(line, col, line, tf_col)
	end
end

function buffer:outdent_line(line)
	self:outdent(line, 1)
end

--finding word boundaries (word breaking semantics from str module)

function buffer:next_word_break_col(line, col, word_chars)
	local s = self:getline(line)
	return s and str.next_word_break(s, col, word_chars)
end

function buffer:prev_word_break_col(line, col, word_chars)
	local s = self:getline(line)
	return s and str.prev_word_break(s, col, word_chars)
end

--word boundaries surrounding a char position
function buffer:word_cols(line, col, word_chars)
	if not self:getline(line) then return end
	line, col = self:clamp_pos(line, col)
	local col1 = self:prev_word_break_col(line, col, word_chars) or 1
	local col2 = self:next_word_break_col(line, col, word_chars)
	col2 = (col2 and self:prev_nonspace_col(line, col2) or self:last_col(line)) + 1
	return col1, col2
end

--finding list-aligned boundaries

function buffer:next_double_space_col(line, col)
	local s = self:getline(line)
	return s and str.next_double_space(s, col)
end

--the idea is to align the cursor with the text on the above line, like this:
--	 more text        even more text
--  from here     -->_ to here, underneath the next word after a double space
--the conditions are: not indenting and there's a line above, and that line
--has a word after at least two visual spaces starting at vcol.
function buffer:next_list_aligned_vcol(line, col, restrict_eol)
	if line <= 1 or self:indenting(line, col) then return end
	local above_col = self:aligned_col(line - 1, line, col)
	local sp_col = self:next_double_space_col(line - 1, above_col - 1)
	if not sp_col then return end
	local ns_col = self:next_nonspace_col(line - 1, sp_col)
	if not ns_col then return end
	local ns_vcol = self:visual_col(line - 1, ns_col)
	if ns_vcol <= col then return end
	return ns_vcol
end

--finding args-aligned boundaries

--the idea is to align the cursor with the text on the above line, like this:
--	 some_function (some_args, ...)
--  from here   -->_ to here, one char after the parens
--the conditions are: not indenting and there's a line above, and that line
--has a word after at least two visual spaces starting at vcol.

--[[
-- enable if
	-- indenting
	-- indenting to > 1 the above indent
	-- line > 1
	-- above line has '(' after current vcol
-- add spaces up to and including the col of the found '('
-- replace the indent tab surplus of the above indent if using tabs
-- jump through autoalign_args virtual tabs

TODO: finish this
function buffer:next_args_aligned_vcol(line, col, restrict_eol)
	if line <= 1 then return end
	local above_col = self:aligned_col(line - 1, line, col)
	local sp_col = self:next_double_space_col(line - 1, above_col - 1)
	if not sp_col then return end
	local ns_col = self:next_nonspace_col(line - 1, sp_col)
	if not ns_col then return end
	local ns_vcol = self:visual_col(line - 1, ns_col)
	if ns_vcol <= col then return end
	return ns_vcol
end
]]

--finding paragraph boundaries

--

--paragraph-level editing

--reflowing the text between two lines. return the position after the last inserted character.
function buffer:reflow_lines(line1, line2, line_width, tabsize, align, wrap)
	local line1, col1 = self:clamp_pos(line1, 1)
	local line2, col2 = self:clamp_pos(line2, 1/0)
	local lines = self:select_string(line1, col1, line2, col2)
	local lines = str.reflow(lines, line_width, tabsize, align, wrap)
	self:remove_string(line1, col1, line2, col2)
	return self:insert_string(line1, col1, self:contents(lines))
end

--saving to disk safely

function buffer:save_to_file(filename)
	--write the file contents to a temp file and replace the original with it.
	--the way to prevent data loss 24-century style.
	glue.fcall(function(finally)

		local filename1 = assert(os.tmpname())
		finally(function() os.remove(filename1) end)

		local file1 = assert(io.open(filename1, 'wb'))
		finally(function()
			if io.type(file1) ~= 'file' then return end
			file1:close()
		end)

		for line = 1, self:last_line() - 1 do
			file1:write(self:getline(line))
			file1:write(self.line_terminator)
		end
		file1:write(self:getline(self:last_line()))
		file1:close()

		local filename2 = assert(os.tmpname())
		finally(function() os.remove(filename2) end)

		os.rename(filename, filename2)
		local ok,err = os.rename(filename1, filename)
		if not ok then
			os.rename(filename2, filename)
		end
		assert(ok, err)
	end)
end


if not ... then require'codedit_demo' end

return buffer
