--codedit controller: putting it all together
local glue = require'glue'
local buffer = require'codedit_buffer'
require'codedit_blocks'
require'codedit_undo'
require'codedit_normal'
local line_selection = require'codedit_selection'
local block_selection = require'codedit_blocksel'
local cursor = require'codedit_cursor'
local line_numbers_margin = require'codedit_margin_ln'
local blame_margin = require'codedit_margin_blame'
local view = require'codedit_view'

local editor = {
	--subclasses
	buffer = buffer,
	line_selection = line_selection,
	block_selection = block_selection,
	cursor = cursor,
	line_numbers_margin = line_numbers_margin,
	blame_margin = blame_margin,
	view = view,
	--margins
	line_numbers = true,
	blame = false,
	--keyboard state
	next_reflow_mode = {left = 'justify', justify = 'left'},
	default_reflow_mode = 'left',
}

function editor:new(options)
	self = glue.inherit(options or {}, self)

	--core objects
	self.view = self.view:new()
	self.buffer = self.buffer:new(self, self.view, self.text)
	self.view.buffer = self.buffer

	--main cursor & selection objects
	self.cursor = self:create_cursor(true)
	self.line_selection = self:create_line_selection(true)
	self.block_selection = self:create_block_selection(false)
	self.selection = self.line_selection --replaced by block_selection when selecting in block mode

	--selection changed flags
	self.block_selection.changed.reflow_mode = false
	self.line_selection.changed.reflow_mode = false

	--margins
	if self.blame then
		self.blame_margin = self:create_blame_margin()
	end
	if self.line_numbers then
		self.line_numbers_margin = self:create_line_numbers_margin()
	end

	return self
end

--object constructors

function editor:create_cursor(visible)
	return self.cursor:new(self.buffer, self.view, visible)
end

function editor:create_line_selection(visible)
	return self.line_selection:new(self.buffer, self.view, visible)
end

function editor:create_block_selection(visible)
	return self.block_selection:new(self.buffer, self.view, visible)
end

function editor:create_line_numbers_margin()
	return self.line_numbers_margin:new(self.buffer, self.view)
end

function editor:create_blame_margin()
	return self.blame_margin:new(self.buffer, self.view)
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
		self.cursor.restrict_eol = self.cursor.restrict_eol and not self.selection.block and mode ~= 'unrestricted'
		if not old_restrict_eol and self.cursor.restrict_eol then
			self.cursor:move(self.cursor.line, self.cursor.col)
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

function editor:select_word_at_cursor()
	local col1, col2 = self.buffer:word_cols(self.cursor.line, self.cursor.col, self.cursor.word_chars)
	if not col1 then return end
	self.selection:set(self.cursor.line, col1, self.cursor.line, col2)
	self.cursor:move_to_selection(self.selection)
end

function editor:select_line_at_cursor()
	self:move_cursor('bol')
	self:move_cursor('eol', 'select')
end

--editing commands

function editor:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
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
			if not (self.cursor.line == 1 and self.cursor.col == 1) then
				self.cursor:move_prev_pos()
				self.cursor:delete_pos(true)
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

	local reflow_mode = self.last_reflow_mode and self.next_reflow_mode[self.last_reflow_mode] or self.default_reflow_mode
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
		self.cursor:insert_string(s)
	end
	self.selection:reset_to_cursor(self.cursor)
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
	self.cursor:move(self.cursor.line, self.cursor.col) --cursor could get invalid after normalization
	self.buffer:save_to_file(filename)
end


if not ... then require'codedit_demo' end

return editor

