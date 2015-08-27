--codedit block selection object: selecting vertically aligned text between two arbitrary cursor positions.
--line1,line2 are the horizontal boundaries and col1,col2 are the vertical boundaries of the rectangle.
local selection = require'codedit_selection'

local block_selection = {block = true}

--inherited

block_selection.new = selection.new
block_selection.free = selection.free
block_selection.save_state = selection.save_state
block_selection.load_state = selection.load_state
block_selection.isempty = selection.isempty
block_selection.isforward = selection.isforward
block_selection.endpoints = selection.endpoints

--column range of one selection line
function block_selection:cols(line)
	return self.buffer:block_cols(line, self:endpoints())
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
	line = math.min(math.max(line, 1), self.buffer:last_line())
	self.line1, self.col1 = line, col
	self.line2, self.col2 = self.line1, self.col1
	self:invalidate()
end

function block_selection:extend(line, col)
	line = math.min(math.max(line, 1), self.buffer:last_line())
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


if not ... then require'codedit_demo' end

return block_selection
