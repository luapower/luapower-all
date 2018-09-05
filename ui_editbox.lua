
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

function editbox:text_visible()
	return true --ensure that segments are created when text is empty
end

function editbox:after_init(ui, t)
	local segs = self:layout_text()
	self._scroll_x = 0
	self.cur = segs:cursor()
	self.sel = segs:selection()
end

function editbox:cursor_rect()
	self:layout_text()
	local x, y = self.cur:pos()
	local w, h, dir = self.cur:size()
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

function editbox:after_draw_content(cr)
	if self.focused then
		local x, y, w, h, dir = self:cursor_rect()
		local color = self.insert_mode
			and self.caret_color_insert_mode
			or self.caret_color
		cr:rgba(self.ui:color(color))
		cr:new_path()
		cr:rectangle(x, y, w, h)
		cr:fill()
	end
	self.sel:rectangles(function(x, y, w, h)
		cr:rgba(self.ui:color(self.selection_color))
		cr:new_path()
		cr:rectangle(x, y, w, h)
		cr:fill()
	end)
end

function editbox:scroll_to_caret()
	local segs = self:layout_text()
	local x, y, w, h, dir = self:cursor_rect()
	x = x - segs.lines.x
	self._scroll_x = glue.clamp(self._scroll_x, x - self.cw + w, x)
	self:invalidate()
end

function editbox:keypress(key)
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	if key == 'right' or key == 'left' then
		self.cur:move('horiz', key == 'right' and 1 or -1)
		if not shift then
			self.sel:reset(self.cur.offset)
		else
			self.sel.cursor2:move_to_offset(self.cur.offset)
		end
		self:scroll_to_caret()
	elseif key == 'up' or key == 'down' then
		self.cur:move('vert', key == 'down' and 1 or -1)
		self.sel:reset(self.cur.offset)
		self:scroll_to_caret()
	elseif key == 'insert' then
		self.insert_mode = not self.insert_mode
		self:scroll_to_caret()
	elseif key == 'A' and ctrl then
		self.sel:select_all()
		self.cur:move_to_offset(1/0)
		self:scroll_to_caret()
	end
end

function editbox:gotfocus()
	self.cur:move_to_offset(0)
	self:scroll_to_caret()
end

editbox.mousedown_activate = true

function editbox:mousemove(x, y)
	if not self.active then return end
	self.cur:move_to_pos(x, y, true, true, true, true)
	self:scroll_to_caret()
	self:invalidate()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local long_text = ('Hello World! '):rep(10) -- (('Hello World! '):rep(10)..'\n'):rep(30)

	ui:add_font_file('media/fonts/FSEX300.ttf', 'fixedsys')

	for i=1,3 do
		local ed = ui:editbox{
			font = 'fixedsys,16',
			tags = 'ed'..i,
			x = 320,
			y = 10 + 30 * (i-1),
			w = 200,
			parent = win,
			text = long_text,
		}
	end

end) end
