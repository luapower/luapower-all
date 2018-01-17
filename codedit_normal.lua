
--codedit normalization (extension module for codedit_buffer).
--Written by Cosmin Apreutesei. Public Domain.

local buffer = require'codedit_buffer'
local str = require'codedit_str'

buffer.eol_spaces = 'remove' --leave, remove.
buffer.eof_lines = 'leave' --leave, remove, ensure, or a number.
buffer.convert_indent = 'tabs' --tabs, spaces, leave: convert indentation to tabs or spaces based on current tabsize

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


if not ... then require'codedit_demo' end
