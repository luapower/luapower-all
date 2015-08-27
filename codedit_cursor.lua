--codedit cursor object: caret-based navigation and editing.
local glue = require'glue'
local str = require'codedit_str'
local tabs = require'codedit_tabs'

local cursor = {
	--navigation options
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = true, --don't allow caret past end-of-file
	land_bof = true, --go at bof if cursor goes up past it
	land_eof = true, --go at eof if cursor goes down past it
	word_chars = '^[a-zA-Z]', --for jumping between words
	move_tabfuls = 'indent', --'indent', 'never'; where to move the cursor between tabfuls instead of individual spaces.
	--editing state
	insert_mode = true, --insert or overwrite when typing characters
	--editing options
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
	insert_tabs = 'indent', --never, indent, always: where to insert a tab instead of enough spaces that make up a tab.
	insert_align_list = true, --insert whitespace up to the next word on the above line
	insert_align_args = true, --insert whitespace up to after '(' on the above line
	--view overrides
	thickness = nil,
	color = nil,
	line_highlight_color = nil,
}

--lifetime

function cursor:new(buffer, view, visible)
	self = glue.inherit({
		buffer = buffer,
		view = view,
	}, self)
	self.visible = visible
	self.line = 1
	self.col = 1 --current real col
	self.vcol = 1 --wanted visual col, when navigating up/down
	self.changed = {}
	if self.view then
		self.view:add_cursor(self)
	end
	return self
end

--state management

function cursor:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
end

local function update_state(dst, src)
	dst.line = src.line
	dst.col = src.col
	dst.vcol = src.vcol
end

function cursor:save_state(state)
	update_state(state, self)
end

function cursor:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--navigation

--move to a specific position, restricting the final position according to navigation policies
function cursor:move(line, col, keep_vcol)
	col = math.max(1, col)
	if line < 1 then
		line = 1
		if self.land_bof then
			col = 1
		end
	elseif self.restrict_eof and line > self.buffer:last_line() then
		line = self.buffer:last_line()
		if self.land_eof then
			col = self.buffer:last_col(line) + 1
		end
	end
	if self.restrict_eol then
		if self.buffer:getline(line) then
			col = math.min(col, self.buffer:last_col(line) + 1)
		else
			col = 1
		end
	end
	self.line, self.col = line, col
	if not keep_vcol then
		--store the visual col of the cursor to be used as the wanted landing col by move_vert()
		self.vcol = self.buffer:visual_col(self.line, self.col)
	end
	self:invalidate()
end

function cursor:prev_pos()
	if self.move_tabfuls == 'always' or
		(self.move_tabfuls == 'indent' and
		 self.buffer:indenting(self.line, self.col))
	then
		local tf_col = self.buffer:prev_tabful_col(self.line, self.col)
		if tf_col then
			return self.line, tf_col
		end
	end
	return self.buffer:prev_char_pos(self.line, self.col)
end

function cursor:move_prev_pos()
	local line, col = self:prev_pos()
	self:move(line, col)
end

function cursor:next_pos(restrict_eol)
	if restrict_eol == nil then
		restrict_eol = self.restrict_eol
	end
	if self.move_tabfuls == 'always' or
		(self.move_tabfuls == 'indent' and
		 self.buffer:indenting(self.line, self.col + 1))
	then
		local tf_col = self.buffer:next_tabful_col(self.line, self.col, restrict_eol)
		if tf_col then
			return self.line, tf_col
		end
	end
	local line, col = self.buffer:next_char_pos(self.line, self.col, restrict_eol)
	--the following combination of options and state would move the cursor to col 1 on the last line,
	--which makes sense for vertical movement, but not for linear movement.
	if self.restrict_eof and not self.land_eof and line > self.buffer:last_line() then
		return self.line, self.col
	end
	return line, col
end

function cursor:move_next_pos()
	local line, col = self:next_pos()
	self:move(line, col)
end

--navigate vertically, using the stored visual column as target column
function cursor:move_vert(lines)
	local line = self.line + lines
	local col = self.buffer:real_col(line, self.vcol)
	self:move(line, col, true)
end

function cursor:move_up()    self:move_vert(-1) end
function cursor:move_down()  self:move_vert(1) end

function cursor:move_home()  self:move(1, 1) end
function cursor:move_bol()   self:move(self.line, 1) end

function cursor:move_end()
	local line, col = self.buffer:clamp_pos(1/0, 1/0)
	self:move(line, col)
end

function cursor:move_eol()
	local line, col = self.buffer:clamp_pos(self.line, 1/0)
	self:move(line, col)
end

function cursor:move_up_page()
	self:move_vert(-self.view:pagesize())
end

function cursor:move_down_page()
	self:move_vert(self.view:pagesize())
end

function cursor:move_prev_word_break()
	local wb_col = self.buffer:prev_word_break_col(self.line, self.col, self.word_chars)
	if wb_col then
		self:move(self.line, wb_col)
	else
		self:move_prev_pos()
	end
end

function cursor:move_next_word_break()
	local wb_col = self.buffer:next_word_break_col(self.line, self.col, self.word_chars)
	if wb_col then
		self:move(self.line, wb_col)
	else
		self:move_next_pos()
	end
end

function cursor:move_to_selection(sel)
	self:move(sel.line2, sel.col2)
end

function cursor:move_to_coords(x, y)
	x, y = self.view:screen_to_client(x, y)
	local line, vcol = self.view:char_at(x, y)
	local col = self.buffer:real_col(line, vcol)
	self:move(line, col)
end

--editing

--insert a string at cursor and move the cursor to after the string
function cursor:insert_string(s)
	local line, col = self.buffer:insert_string(self.line, self.col, s)
	self:move(line, col)
end

--insert a string block at cursor.
--does not move the cursor, but returns the position after the text.
function cursor:insert_block(s)
	return self.buffer:insert_block(self.line, self.col, s)
end

--insert or overwrite a char at cursor, depending on insert mode
function cursor:insert_char(c)
	if not self.insert_mode then
		self:delete_pos(false)
	end
	self:insert_string(c)
end

--delete the text up to the next cursor position
function cursor:delete_pos(restrict_eol)
	local line2, col2 = self:next_pos(restrict_eol)
	self.buffer:remove_string(self.line, self.col, line2, col2)
end

--add a new line, optionally copying the indent of the current line, and carry the cursor over
function cursor:insert_newline()
	if self.auto_indent then
		self.buffer:extend(self.line, self.col)
		local indent = self.buffer:select_indent(self.line, self.col)
		self:insert_string('\n' .. indent)
	else
		self:insert_string'\n'
	end
end

--insert a tab character, expanding it according to tab expansion policies
function cursor:insert_tab()

	if self.insert_align_list then
		local ls_vcol = self.buffer:next_list_aligned_vcol(self.line, self.col, self.restrict_eol)
		if ls_vcol then
			local line, col = self.buffer:insert_whitespace(self.line, self.col, ls_vcol, self.insert_tabs == 'always')
			self:move(line, col)
			return
		end
	end

	if false and self.insert_align_args then
		local arg_vcol = self.buffer:next_args_aligned_vcol(self.line, self.col, self.restrict_eol)
		if arg_vcol then
			if self.buffer:indenting(self.line, self.col) then
				local indent = self.buffer:select_indent(self.line - 1)
				local indent_vcol = tabs.visual_col(indent, str.len(indent) + 1, self.tabsize)
				local whitespace = self.buffer:gen_whitespace(indent_vcol, arg_vcol, self.insert_tabs == 'always')
				local line, col = self.buffer:insert_string(self.line, 1, indent .. whitespace)
				self:move(line, col)
			else
				local line, col = self.buffer:insert_whitespace(self.line, self.col, arg_vcol, self.insert_tabs == 'always')
				self:move(line, col)
			end
			return
		end
	end

	local use_tabs =
		self.insert_tabs == 'always' or
			(self.insert_tabs == 'indent' and
			 self.buffer:indenting(self.line, self.col))

	local line, col = self.buffer:indent(self.line, self.col, use_tabs)
	self:move(line, col)
end

function cursor:outdent_line()
	if not self.buffer:getline(self.line) then
		self:move(self.line, self.col - 1)
		return
	end
	local old_sz = #self.buffer:getline(self.line)
	self.buffer:outdent_line(self.line)
	local new_sz = #self.buffer:getline(self.line)
	local col = self.col + new_sz - old_sz
	self:move(self.line, col)
end

function cursor:move_line_up()
	self.buffer:move_line(self.line, self.line - 1)
	self:move_up()
end

function cursor:move_line_down()
	self.buffer:move_line(self.line, self.line + 1)
	self:move_down()
end

--scrolling

function cursor:make_visible()
	if not self.visible then return end
	self.view:cursor_make_visible(self)
end


if not ... then require'codedit_demo' end

return cursor
