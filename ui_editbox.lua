
--Edit Box widget based on tr.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local tr = require'tr'
local glue = require'glue'

clamp = glue.clamp
snap = glue.snap

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox

--TODO: make the caret a layer so it can be styled.
--TODO: make selection rectangles layers so they can be styled.

editbox.w = 200
editbox.h = 30
editbox.padding = 4
editbox.focusable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.clip_content = true
editbox.border_color = '#333'
editbox.border_width = 1
editbox.text_align = 'left'
editbox.caret_color = '#fff'
editbox.selection_color = '#66f8'
editbox.nowrap = true
editbox.insert_mode = false
editbox.cursor_text = 'text'
editbox.cursor_selection = 'arrow'
editbox.password = false

ui:style('editbox', {
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('editbox :hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('editbox :focused', {
	border_color = '#fff',
	background_color = '#040404',
	shadow_blur = 3,
	shadow_color = '#666',
})

ui:style('editbox :insert_mode', {
	caret_color = '#fff8',
})

--sanitize text by replacing newlines and ASCII control chars with spaces.
--TODO: make `tr.multiline` option so that we don't have to do this.
local function sanitize(s)
	return s:gsub(tr.PS, ' '):gsub(tr.LS, ' '):gsub('[%z\1-\31]', ' ')
end

local function check_char(s) --validation but for single utf8 chars.
	if s:byte(1, 1) < 32 then return end
	if s == tr.PS or s == tr.LS then return end
	return s
end

--insert_mode property

editbox:stored_property'insert_mode'
editbox:track_changes'insert_mode'
editbox:instance_only'insert_mode'

function editbox:after_set_insert_mode(value)
	self:settag(':insert_mode', value)
end

--utf8 text property, computed on-demand.

function editbox:get_text()
	if not self._text then
		self._text = self.selection.segments.text_runs:string()
		self._text_tree[1] = self._text --prevent resync by layer:sync_text()
	end
	return self._text
end

function editbox:set_text(s)
	s = s or '' --an editbox can never have its text property as false!
	self.selection:select_all()
	self.selection:replace(s)
	self._text = false --invalidate the text property
	self:scroll_to_caret()
end

editbox:instance_only'text'

function editbox:text_visible()
	return true --always sync, even for the empty string.
end

--init

editbox:init_ignore{text=1}

function editbox:after_init(ui, t)
	self._scroll_x = 0
	self._text = sanitize(t.text or '')
	self.selection = self:sync_text():selection()
end

--sync

function editbox:override_sync_text(inherited)
	local segs = inherited(self)

	--scroll text.
	local new_x = -self._scroll_x
	local scrolled = segs.lines.x ~= new_x
	segs.lines.x = new_x

	--clip text segments to the content rectangle.
	if not self.password then
		if scrolled or not segs.lines.editbox_clipped then
			segs:clip(self:content_rect())
			--mark the lines as clipped: this flag will be gone after re-layouting.
			segs.lines.editbox_clipped = true
		end
	end

	return segs
end

--drawing cursor & selection

function editbox:caret_rect()
	local x, y = self:text_to_mask(self.selection.cursor1:pos())
	local w, h, dir = self.selection.cursor1:size()
	if self.password then
		w = self:password_char_advance_x() * (w > 0 and 1 or -1)
	end
	if not self.insert_mode then
		w = w > 0 and 1 or -1
	end
	return x, y, w, h, dir
end

local function draw_sel_rect(x, y, w, h, cr, self)
	local x2 = x + w
	x, y = self:text_to_mask(x, y)
	x2 = self:text_to_mask(x2)
	w = x2 - x
	cr:rectangle(x, y, w, h)
	cr:fill()
end
function editbox:draw_selection(cr)
	cr:rgba(self.ui:rgba(self.selection_color))
	cr:new_path()
	self.selection:rectangles(draw_sel_rect, cr, self)
end

function editbox:draw_caret(cr)
	local x, y, w, h, dir = self:caret_rect()
	cr:rgba(self.ui:rgba(self.caret_color))
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

function editbox:after_draw_content(cr)
	if not self.selection:empty() then
		self:draw_selection(cr)
	elseif self.focused then
		self:draw_caret(cr)
	end
end

--editing & scrolling

function editbox:scroll_to_caret(preserve_screen_x)
	local segs = self:sync_text()
	local x, y, w, h, dir = self:caret_rect()
	x = x - segs.lines.x
	if preserve_screen_x and self._screen_x then
		self._scroll_x = x - self._screen_x
	end
	self._scroll_x = clamp(self._scroll_x, x - self.cw + w, x)
	self._scroll_x = clamp(self._scroll_x, 0, 1/0)
	self._screen_x = x - self._scroll_x
	self:invalidate()
end

--keyboard

function editbox:keychar(s)
	if not check_char(s) then return end
	self.selection:replace(s)
	self._text = false
	self:scroll_to_caret()
end

function editbox:keypress(key)
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	if key == 'right' or key == 'left' then
		local movement = ctrl and 'word' or 'char'
		local delta = key == 'right' and 1 or -1
		if shift then
			self.selection.cursor1:move(movement, delta)
		else
			local c1, c2 = self.selection:cursors()
			if self.selection:empty() then
				c1:move(movement, delta)
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
				self.selection.cursor1:move('char', 1)
			else --remove the char before the cursor
				self.selection.cursor1:move('char', -1)
			end
		end
		self.selection:remove()
		self._text = false
		self:scroll_to_caret(true)
		return true
	elseif ctrl and key == 'A' then
		self.selection:select_all()
		self:scroll_to_caret()
		return true
	elseif ctrl and (key == 'C' or key == 'X') then
		if not self.selection:empty() then
			self.ui:setclipboard(self.selection:string(), 'text')
			if key == 'X' then
				self.selection:remove()
				self._text = false
				self:scroll_to_caret()
			end
		end
		return true
	elseif ctrl and key == 'V' then
		local s = self.ui:getclipboard'text'
		if s then
			s = sanitize(s)
			self.selection:replace(s)
			self._text = false
			self:scroll_to_caret()
		end
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
	self.selection.cursor1:move_to_offset(0)
	self.selection:reset()
	self:scroll_to_caret()
end

--mouse

function editbox:override_hit_test_content(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if widget then
		return widget, area
	end
	x, y = self:mask_to_text(x, y)
	if self.selection:hit_test(x, y) then
		return self, 'selection'
	elseif self.selection.segments:hit_test(x, y) then
		return self, 'text'
	end
end

editbox.mousedown_activate = true

function editbox:doubleclick(x, y)
	self.selection:select_word()
	self:scroll_to_caret()
end

function editbox:tripleclick(x, y)
	self.selection:select_all()
	self:scroll_to_caret()
end

function editbox:mousedown(x, y)
	self.selection.cursor1:move_to_pos(self:mask_to_text(x, y))
	self.selection:reset()
	self:scroll_to_caret()
end

function editbox:mousemove(x, y)
	if not self.active then return end
	self.selection.cursor1:move_to_pos(self:mask_to_text(x, y))
	self:scroll_to_caret()
end

--password mask drawing & hit testing

--Password masking works by drawing fixed-width dots in place of actual
--characters. Because cursor placement and hit-testing must continue
--to work over these markers, we have to translate from "text space" (where
--the original cursor positions are) to "mask space" (where the fixed-width
--visual cursor positons are) in order to draw the cursor and the selection
--rectangles. We also need to translate back to text space for hit-testing.

--compute the text-space to mask-space mappings on each text sync.
function editbox:sync_password_mask(segs)
	if segs.lines.pw_cursor_is then return end
	segs.lines.pw_cursor_is = {}
	segs.lines.pw_cursor_xs = {}
	local i = 0
	for _, x in segs:cursor_xs() do
		segs.lines.pw_cursor_is[snap(x, 1/256)] = i
		segs.lines.pw_cursor_xs[i] = x
		i = i + 1
	end
end

function editbox:override_sync_text(inherited)
	local segs = inherited(self)
	if self.password then
		self:sync_password_mask(segs)
	end
	return segs
end

function editbox:password_char_advance_x()
	--TODO: maybe use the min(w, h) of the "M" char here?
	return self.text_size * .75
end

--convert "text space" cursor coordinates to "mask space" coordinates.
--NOTE: input must be an exact cursor position.
function editbox:text_to_mask(x, y)
	if self.password then
		local segs = self.selection.segments
		local line_x = segs:line_pos(1)
		local i = segs.lines.pw_cursor_is[snap(x - line_x, 1/256)]
		x = line_x + i * self:password_char_advance_x()
	end
	return x, y
end

--convert "mask space" coordinates to "text space" coordinates.
--NOTE: input can be arbitrary but output is snapped to a cursor position.
function editbox:mask_to_text(x, y)
	if self.password then
		local segs = self:sync_text()
		local line_x = segs:line_pos(1)
		local w = self:password_char_advance_x()
		local i = snap(x - line_x, w) / w
		local i = clamp(i, 0, #segs.lines.pw_cursor_xs)
		x = line_x + segs.lines.pw_cursor_xs[i]
	end
	return x, y
end

function editbox:draw_password_char(cr, i, w, h)
	cr:new_path()
	cr:circle(w / 2, h / 2, math.min(w, h) * .3)
	cr:rgba(self.ui:rgba(self.text_color))
	cr:fill()
end

function editbox:draw_password_mask(cr, segs)
	local w = self:password_char_advance_x()
	local h = self.ch
	local segs = self.selection.segments
	local x = segs:line_pos(1)
	cr:save()
	cr:translate(x, 0)
	for i = 0, #segs.lines.pw_cursor_xs-1 do
		self:draw_password_char(cr, i, w, h)
		cr:translate(w, 0)
	end
	cr:restore()
end

function editbox:override_draw_text(inherited, cr)
	if self.password then
		local segs = self:sync_text()
		self:draw_password_mask(cr, segs)
	else
		inherited(self, cr)
	end
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
		password = true,
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
