
--caret-based navigation and editing
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'codedit_demo'; return end

local glue = require'glue'
local str = require'codedit_str'
local tabs = require'codedit_tabs'

--instantiation --------------------------------------------------------------

local cursor = {
	--navigation options
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = true, --don't allow caret past end-of-file
	land_bof = true, --go at bof if cursor goes up past it
	land_eof = true, --go at eof if cursor goes down past it (needs restrict_eof)
	word_chars = '^[a-zA-Z]', --for jumping between words
	jump_tabstops = 'always', --'always', 'indent', 'never'
		--where to move the cursor between tabstops instead of individual spaces.
	delete_tabstops = 'always', --'always', 'indent', 'never'
	--editing state
	insert_mode = true, --insert or overwrite when typing characters
	--editing options
	auto_indent = true,
		--pressing enter copies the indentation of the current line over to the following line
	insert_tabs = 'indent', --'never', 'indent', 'always'
		--where to insert a tab instead of enough spaces that make up a tab.
	insert_align_list = false, --TODO: insert whitespace up to the next word on the above line
	insert_align_args = false, --TODO: insert whitespace up to after '(' on the above line
	--view overrides
	thickness = nil,
	color = nil,
	line_highlight_color = nil,
}

function cursor:new(buffer, view, visible)
	self = glue.inherit({
		buffer = buffer,
		view = view,
	}, self)
	self.visible = visible
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
		local ns_i = str.prev_nonspace_char(s, self.i)
		local ps_i = ns_i and str.next_char(s, ns_i) --after prev. nonspace
		ps_i = math.max(ps_i or 1, ts_i) --closest
		if ps_i < self.i then
			return self.line, ps_i
		end
	end

	return self.line, str.prev_char(s, self.i)
end

--move to the previous position in the text.
function cursor:move_prev_pos()
	self:move(self:prev_pos(self.jump_tabstops))
end

function cursor:next_pos(restrict_eol, jump_tabstops)

	local lastline = #self.buffer.lines
	if self.line > lastline then --outside buffer
		if self.restrict_eof then
			return self.buffer:end_pos()
		elseif self.restrict_eol then
			return self.line + 1, 1
		else
			return self.line, self.i + 1
		end
	elseif self.i >= self.buffer:eol(self.line) then
		if self.restrict_eol then
			if self.restrict_eof and self.line >= lastline then
				return self.buffer:end_pos()
			else
				return self.line + 1, 1
			end
		else
			return self.line, self.i + 1
		end
	end

	local s = self.buffer.lines[self.line]

	local jump_tabstops =
		jump_tabstops == 'always'
		or (jump_tabstops == 'indent'
			and self.buffer:indenting(self.line, str.next_char(s, self.i)))

	if jump_tabstops and str.iswhitespace(s, self.i) then
		local x0 = self.view:char_x(self.line, self.i)
		local ts_x = self.view:next_tabstop_x(x0)
		local ts_i = self.view:char_at_line(self.line, ts_x)
		local ns_i =
			str.next_nonspace_char(s, self.i)
			or self.buffer:eol(self.line)
		ns_i = math.min(ts_i, ns_i)
		return self.line, ns_i
	end

	return self.line, str.next_char(s, self.i) or #s + 1
end

--move to the next position in the text.
function cursor:move_next_pos()
	self:move(self:next_pos(self.restrict_eol, self.jump_tabstops))
end

--navigate vertically, using the stored x offset as target offset
function cursor:move_vert(lines)
	local line = self.line + lines
	local i = self.view:cursor_char_at_line(math.max(1, line), self.x)
	self:move(line, i, true)
end

function cursor:move_up()    self:move_vert(-1) end
function cursor:move_down()  self:move_vert(1) end

function cursor:move_home()  self:move(1, 1) end
function cursor:move_bol()   self:move(self.line, 1) end

function cursor:move_end()
	local line, i = self.buffer:end_pos()
	self:move(line, i)
end

function cursor:move_eol()
	local line, i = self.buffer:clamp_pos(self.line, 1/0)
	self:move(line, i)
end

function cursor:move_up_page()
	self:move_vert(-self.view:pagesize())
end

function cursor:move_down_page()
	self:move_vert(self.view:pagesize())
end

function cursor:move_prev_word_break()
	local s = self.buffer.lines[self.line]
	local wb_i = s and str.prev_word_break_char(s, self.i, self.word_chars)
	if wb_i then
		self:move(self.line, wb_i)
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
		self:move_next_pos()
	end
end

function cursor:move_to_selection(sel)
	self:move(sel.line2, sel.i2)
end

function cursor:move_to_coords(x, y)
	x, y = self.view:screen_to_client(x, y)
	local line, i = self.view:cursor_char_at(x, y, self.restrict_eof)
	self:move(line, i)
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

return cursor
