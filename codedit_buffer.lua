
--multi-line text navigation and editing
--Written by Cosmin Apreutesei. Public Domain.

--features: save/load, undo/redo, mixed line terminators.

if not ... then require'codedit_demo'; return end

local str = require'codedit_str'
require'codedit_reflow'
local tabs = require'codedit_tabs'

--instantiation --------------------------------------------------------------

local buffer = {
	line_terminator = '\n', --line terminator to use when inserting text
}

function buffer:new()
	self = setmetatable({}, {__index = self})
	self:_init()
	return self
end

--the convention for storing lines is that each line preserves its own line
--terminator at its end, except the last line which doesn't have one, never.
--the empty string is thus stored as a single line containing itself.

function buffer:_init(lines)
	self.lines = lines or {}
	if #self.lines == 0 then
		self.lines[1] = '' --can't have zero lines
	end
	self:_init_undo()
	self:_init_changed()
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
	--set changed flags
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
end

function buffer:on(event, handler)
	local t = self.event_handlers
	t[event] = t[event] or {}
	table.insert(t[event], handler)
end

function buffer:trigger(event, ...)
	local t = self.event_handlers
	t = t and t[event]
	if not t then return end
	for i,f in ipairs(t) do
		f(...)
	end
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
		for j,i in str.lines(s) do
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
	self:_init(lines)
end

function buffer:_load_string(s)
	local lines = {}
	for j,i in str.lines(s) do
		lines[#lines+1] = s:sub(i,j-1)
	end
	self:_init(lines)
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
	--TODO: self.editor:save_state(self.undo_group)
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
	--TODO: self.editor:load_state(group)
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
	self:trigger('line_inserted', line)
end

function buffer:remove_line(line)
	self:_rem(line)
	if #self.lines == line-1 then
		--removed the last line: remove the line term from the prev. line
		self:_upd(line-1, self:select(line-1))
	end
	self:invalidate()
	self:trigger('line_removed', line)
end

function buffer:setline(line, s)
	if line == #self.lines then
		s = str.remove_term(s)
	else
		s = str.add_term(s, self.line_terminator)
	end
	self:_upd(line, s)
	self:invalidate()
	self:trigger('line_changed', line)
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
	for j, i in str.lines(s) do
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

return buffer
