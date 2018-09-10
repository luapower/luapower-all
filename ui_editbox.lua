
--Edit Box widget based on tr.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox

editbox.w = 200
editbox.h = 30
editbox.padding = 4
editbox.focusable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.clip_content = true
editbox.border_color = '#333'
editbox.border_width = 1
editbox.text_align = 'left'
editbox.text = ''
editbox.caret_color = '#fff'
editbox.caret_color_insert_mode = '#fff8'
editbox.selection_color = '#8888'
editbox.nowrap = true
editbox.insert_mode = false
editbox.cursor = 'text'
editbox.cursor_selection = 'arrow'

function editbox:after_init(ui, t)
	local segs = self:layout_text()
	self._scroll_x = 0
	self.selection = segs:selection()
end

--drawing

function editbox:text_visible()
	return true --ensure that segments are created when text is empty
end

function editbox:cursor_rect()
	self:layout_text()
	local x, y = self.selection.cursor1:pos()
	local w, h, dir = self.selection.cursor1:size()
	if not self.insert_mode then
		w = w > 0 and 1 or -1
	end
	return x, y, w, h, dir
end

function editbox:sync()
	local segs = self:layout_text()
	local new_x = -self._scroll_x
	if segs.lines.x ~= new_x or not segs.lines.editbox_clipped then
		segs.lines.x = new_x
		segs:clip(self:content_rect())
		--mark the lines as clipped: this will dissapear after re-layouting.
		segs.lines.editbox_clipped = true
	end
end

function editbox:before_draw()
	self:sync()
end

local function draw_sel_rect(x, y, w, h, cr)
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end
function editbox:after_draw_content(cr)
	if self.focused and self.selection:empty() then
		local x, y, w, h, dir = self:cursor_rect()
		local color = self.insert_mode
			and self.caret_color_insert_mode
			or self.caret_color
		cr:rgba(self.ui:color(color))
		cr:new_path()
		cr:rectangle(x, y, w, h)
		cr:fill()
	end
	cr:rgba(self.ui:color(self.selection_color))
	self.selection:rectangles(draw_sel_rect, cr)
end

--keyboard

function editbox:scroll_to_caret()
	local segs = self:layout_text()
	local x, y, w, h, dir = self:cursor_rect()
	x = x - segs.lines.x
	self._scroll_x = glue.clamp(self._scroll_x, x - self.cw + w, x)
	self:invalidate()
end

function editbox:keychar(s)
	if s:byte(1, 1) < 32 then return end
	self.selection:insert(s)
	self:scroll_to_caret()
end

function editbox:keypress(key)
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	if key == 'right' or key == 'left' then
		if shift then
			self.selection.cursor1:move('horiz', key == 'right' and 1 or -1)
		else
			local c1, c2 = self.selection:cursors()
			if self.selection:empty() then
				c1:move('horiz', key == 'right' and 1 or -1)
				c2:move_to_cursor(c1)
			else
				if key == 'left' then
					c2:move_to_cursor(c1)
				else
					c1:move_to_cursor(c2)
				end
			end
		end
		self:scroll_to_caret()
		return true
	elseif key == 'up' or key == 'down' then
		self.selection.cursor1:move('vert', key == 'down' and 1 or -1)
		if not shift then
			self.selection.cursor2:move_to_cursor(self.selection.cursor1)
		end
		self:scroll_to_caret()
		return true
	elseif key == 'insert' then
		self.insert_mode = not self.insert_mode
		self:scroll_to_caret()
		return true
	elseif key == 'delete' or key == 'backspace' then
		if self.selection:empty() then
			if key == 'delete' then --remove the char after the cursor
				self.selection.cursor1:move('horiz', 1)
			else --remove the char before the cursor
				self.selection.cursor1:move('horiz', -1)
			end
		end
		self.selection:remove()
		self:invalidate()
		return true
	elseif ctrl and key == 'A' then
		self.selection:select_all()
		self:scroll_to_caret()
		return true
	elseif ctrl and (key == 'C' or key == 'X') then
		self.ui:setclipboard(self.selection:string(), 'text')
		if key == 'X' then
			self.selection:remove()
		end
		return true
	elseif ctrl and key == 'V' then
		local s = self.ui:getclipboard'text' or ''
		return true
	end
end

function editbox:gotfocus()
	if not self.active then
		self.selection:select_all()
		self:scroll_to_caret()
	end
end

function editbox:lostfocus()
	self.selection:reset()
	self:invalidate()
end

--mouse

function editbox:override_hit_test_content(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if not widget then
		if not self.selection:empty() then
			if self.selection:hit_test(x, y) then
				return self, 'selection'
			end
		end
	end
	return widget, area
end

editbox.mousedown_activate = true

function editbox:click(x, y)

end

function editbox:doubleclick(x, y)

end

function editbox:tripleclick(x, y)

end

function editbox:mousedown(x, y)
	self.selection.cursor1:move_to_pos(x, y)
	self.selection:reset()
	self:scroll_to_caret()
end

function editbox:mousemove(x, y)
	if not self.active then return end
	self.selection.cursor1:move_to_pos(x, y)
	self:scroll_to_caret()
end


--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local long_text = ('Hello World! '):rep(2) -- (('Hello World! '):rep(10)..'\n'):rep(30)
	local long_text = 'Hello W'

	ui:add_font_file('media/fonts/FSEX300.ttf', 'fixedsys')

	local ed1 = ui:editbox{
		--font = 'fixedsys,16',
		x = 320,
		y = 10 + 35 * 1,
		w = 200,
		parent = win,
		text = long_text,
	}

	local ed2 = ui:editbox{
		--font = 'fixedsys,16',
		x = 320,
		y = 10 + 35 * 2,
		w = 200,
		parent = win,
		text = long_text,
	}

	local ed3 = ui:editbox{
		--font = 'fixedsys,16',
		x = 320,
		y = 10 + 35 * 3,
		w = 200,
		h = 200,
		parent = win,
		text = long_text,
		multiline = true,
	}

end) end
