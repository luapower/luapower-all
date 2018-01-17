--codedit selection object: selecting contiguous text between two line,i pairs.
--line1,i1 is the first selected char and line2,i2 is the char immediately after the last selected char.
local glue = require'glue'

local selection = {
	--view overrides
	background_color = nil,
	text_color = nil,
	line_rect = nil, --line_rect(line) -> x, y, w, h
}

--lifetime

function selection:new(buffer, view, visible)
	self = glue.inherit({
		buffer = buffer,
		view = view,
	}, self)
	self.visible = visible
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
		self.buffer:indent_line(line, use_tab)
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


if not ... then require'codedit_demo' end

return selection
