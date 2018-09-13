
--Undo/redo stack for single-user editors.
--Written by Cosmin Apreutesei. Public Domain.

--The undo stack is a stack of undo groups. An undo group is a list of
--functions to be executed in reverse order in order to perform a single undo
--operation. Consecutive undo groups of the same type are merged together.
--The undo commands can be any function with any non-mutable arguments.

local push = table.insert
local pop = table.remove

local undo_stack = {}
setmetatable(undo_stack, undo_stack)

function undo_stack:reset()
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
end

function undo_stack:__call()
	self = {__index = self}
	setmetatable(self, self)
	self:reset()
	return self
end

function undo_stack:save_state(undo_group) end --stub
function undo_stack:load_state(undo_group) end --stub

function undo_stack:undo_group(group_type)
	if self.undo_group then
		if self.undo_group.type == group_type then
			--same type of group, continue using the current group
			return
		end
		self:end_undo_group() --auto-close current group to start a new one
	end
	self.undo_group = {type = group_type}
	self:save_state(self.undo_group)
end

function undo_stack:end_undo_group()
	if not self.undo_group then return end
	if #self.undo_group > 0 then --push group if not empty
		push(self.undo_stack, self.undo_group)
	end
	self.undo_group = nil
end

--add an undo command to the current undo group, if any.
function undo_stack:undo_command(...)
	if not self.undo_group then return end
	push(self.undo_group, {...})
end

local function undo_from(self, group_stack)
	self:end_undo_group()
	local group = pop(group_stack)
	if not group then return end
	self:undo_group(group.type)
	for i = #group, 1, -1 do
		local cmd = group[i]
		cmd[1](unpack(cmd, 2))
	end
	self:end_undo_group()
	self:load_state(group)
end

function undo_stack:undo()
	undo_from(self, self.undo_stack)
	if #self.undo_stack == 0 then return end
	push(self.redo_stack, pop(self.undo_stack))
end

function undo_stack:redo()
	undo_from(self, self.redo_stack)
end

function undo_stack:last_undo_command()
	if not self.undo_group then return end
	local last_cmd = self.undo_group[#self.undo_group]
	if not last_cmd then return end
	return unpack(last_cmd)
end

return undo_stack
