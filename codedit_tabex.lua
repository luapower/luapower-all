
--word-level navigation ------------------------------------------------------

function buffer:next_word_break_ci(line, ci, word_chars)
	local s = self:line(line)
	return s and str.next_word_break_ci(s, ci, word_chars)
end

function buffer:prev_word_break_ci(line, ci, word_chars)
	local s = self:line(line)
	return s and str.prev_word_break_ci(s, ci, word_chars)
end

--word boundaries surrounding a char position
function buffer:word_cis(line, ci, word_chars)
	if not self:line(line) then return end
	line, ci = self:clamp_pos(line, ci)
	local ci1 = self:prev_word_break_ci(line, ci, word_chars) or 1
	local ci2 = self:next_word_break_ci(line, ci, word_chars)
	ci2 = (ci2 and self:prev_nonspace_ci(line, ci2) or self:eol(line) - 1) + 1
	return ci1, ci2
end

--finding list-aligned boundaries

function buffer:next_double_space_ci(line, ci)
	local s = self:line(line)
	return s and str.next_double_space_ci(s, ci)
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

--[==[
--paragraph-level editing

--reflowing the text between two lines. return the position after the last inserted character.
function buffer:reflow_lines(line1, line2, line_width, tabsize, align, wrap)
	local line1, col1 = self:clamp_pos(line1, 1)
	local line2, col2 = self:clamp_pos(line2, 1/0)
	local lines = self:select(line1, col1, line2, col2)
	local lines = str.reflow(lines, line_width, tabsize, align, wrap)
	self:remove_string(line1, col1, line2, col2)
	return self:insert(line1, col1, self:contents(lines))
end
]==]

--[==[
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
			file1:write(self:line(line))
			file1:write(self.line_terminator)
		end
		file1:write(self:line(self:last_line()))
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
]==]
