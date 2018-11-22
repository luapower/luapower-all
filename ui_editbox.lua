--go @ luajit ui_editbox.lua

--Edit Box widget based on tr.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local tr = require'tr'
local glue = require'glue'

local push = table.insert
local pop = table.remove
clamp = glue.clamp
snap = glue.snap

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox
editbox.iswidget = true

--features

editbox.password = false
editbox.maxlen = 4096

--metrics & colors

editbox.text_align_x = 'left'
editbox.align_y = 'center'
editbox.padding = 4
editbox.min_ch = 16
editbox.w = 180
editbox.h = 24
editbox.border_color = '#000'
--own properties
editbox.caret_color = '#fff'
editbox.caret_opacity = 1
editbox.selection_color = '#66f6'

editbox.tags = 'standalone'

ui:style('editbox standalone, editbox_scrollbox standalone', {
	border_width = 1,
	border_color = '#333',
})

--keep the same padding for the multiline editbox.
ui:style('editbox_scrollbox > editbox', {padding = 0})
ui:style('editbox_scrollbox', {padding = 1})
ui:style('editbox_scrollbox > scrollbox_view', {padding = 3})

--TODO: :child_hot
ui:style('editbox :hot, editbox_scrollbox :child_hot', {
	border_color = '#999',
})

ui:style('editbox standalone :focused, editbox_scrollbox standalone :child_focused', {
	border_color = '#fff',
	shadow_blur = 2,
	shadow_color = '#666',
	background_color = '#040404', --to cover the shadow
})

ui:style('editbox :insert_mode', {
	caret_color = '#fff8',
})

ui:style('editbox !:window_active', {
	caret_opacity = 0,
	selection_color = '#66f3',
})

--animation

--caret blinking
ui:style('editbox :focused !:insert_mode :window_active', {
	caret_opacity = 0,
	transition_caret_opacity = true,
	transition_delay_caret_opacity = function(self)
		return self.ui.caret_blink_time
	end,
	transition_times_caret_opacity = 1/0, --blink indefinitely
	transition_blend_caret_opacity = 'restart',
})

ui:style([[
	editbox standalone, editbox_scrollbox standalone,
	editbox standalone :hot, editbox_scrollbox standalone :hot
]], {
	transition_border_color = true,
	transition_duration_border_color = .5,
})

--insert_mode property

editbox.insert_mode = false

editbox:stored_property'insert_mode'
editbox:instance_only'insert_mode'

function editbox:after_set_insert_mode(value)
	self:settag(':insert_mode', value)
end

--text property, computed on-demand.

--tell ui:sync_text_shape() to stop checking the `text` property to decide
--if the text needs reshaping. reshaping is done by selection:replace() now.
--this is to skip utf8-encoding the entire text on every key stroke.
editbox.text_editabe = true

--NOTE: the editbox text property is never `false` like in a normal layer.
editbox._text = ''

function editbox:get_text()
	if not self._text then
		self._text = self.selection.segments.text_runs:string()
	end
	return self._text
end

function editbox:set_text(s)
	if not self.selection then return end
	s = self:filter_text(s or '')
	self:clear_undo_stack()
	self.selection:select_all()
	self:replace_selection(s, nil, false)
end

editbox:instance_only'text'

--text length in codepoints.
function editbox:get_text_len()
	if not self.selection then return 0 end
	return self.selection.segments.text_runs.len
end

--value property when used as a grid cell.
function editbox:get_value()
	return self.text
end

--filtering & truncating the input text.

--filter text by replacing newlines and ASCII control chars with spaces.
function editbox:filter_text(s)
	if not self.multiline then
		return
			s:gsub(tr.PS, ' ')
			 :gsub(tr.LS, ' ')
			 :gsub('[%z\1-\31\127]', '')
	else
		return s:gsub('[%z\1-\8\11\12\14-\31\127]', '') --allow \t \n \r
	end
end

--init

editbox:init_ignore{text=1, multiline=1}

function editbox:after_init(ui, t)
	--create a selection and then set the text through the selection which
	--obeys maxlen and triggers a changed event.
	self.multiline = t.multiline
	self.selection = self:sync_text_shape():selection() or false
	self.text = t.text

	if self.selection then
		--reset the caret blinking whenever the cursor is being acted upon,
		--regardles of whether it changes position or not.
		local c1, c2 = self.selection:cursors()
		local set = c1.set
		function c1.set(...)
			self:blink_caret()
			return set(...)
		end
		local set = c2.set
		function c2.set(...)
			self:blink_caret()
			return set(...)
		end

		--scroll to view the caret and fire the `caret_moved` event.
		function self.selection.cursor1.changed()
			self:scroll_to_view_caret()
			self:fire'caret_moved'
		end
	end
end

--multiline mode: wrap the editbox in a scrollbox.

editbox:stored_property'multiline'
editbox:instance_only'multiline'

function editbox:get_multiline()
	return self._multiline and not self.password
end

ui:style('editbox multiline', {
	text_align_x = 'left',
	text_align_y = 'top',
})

editbox.scrollbox_class = ui.scrollbox

function editbox:create_scrollbox()
	return self.scrollbox_class(self.parent, {
		tags = 'editbox_scrollbox',
		content = self,
		editbox = self,
		auto_w = true,
		min_cw = self.min_cw,
		min_ch = self.min_ch,
		x = self.x,
		y = self.y,
		w = self.w,
		h = self.h,
	}, self.scrollbox)
end

--enlarge the text bounding box to include space for the caret at the end
--of line and for the full caret height for at least one line.
function editbox:override_text_bounding_box(inherited, ...)
	local x, y, w, h = inherited(self, ...)
	local _, _, cw, ch = self:caret_rect()
	--w = w + cw
	--h = math.max(h, ch) --TODO: use line height instead!
	return x, y, w, h
end

function editbox:after_set_multiline(multiline)
	if multiline then
		self.scrollbox = self:create_scrollbox()
		self:settag('multiline', true)
		if self.tags.standalone then
			self:settag('standalone', false)
			self.scrollbox:settag('standalone', true)
		end
		self.clip_content = false --enable real (strict) bounding box
		self.layout = 'textbox'
	else
		self.layout = false
		self.nowrap = true
		self.clip_content = true
		if self.scrollbox then
			self:settag('multiline', false)
			if self.scrollbox.tags.standalone then
				self:settag('standalone', true)
			end
			self.parent = self.scrollbox.parent
			self.scrollbox:free()
			self.scrollbox = false
		end
	end
end

function editbox:scroll_to_view_caret()
	if not self.scrollbox then return end
	self.scrollbox:scroll_to_view(self:caret_scroll_rect())
end

--sync'ing

function editbox:text_visible()
	return true --always sync, even for the empty string.
end

function editbox:get_caret_w()
	return (self.selection.cursor1:size())
end

function editbox:caret_rect()
	local x, y = self:text_to_mask(self.selection.cursor1:pos())
	local w, h, dir = self.selection.cursor1:size()
	if self.password then
		w = self:password_char_advance_x() * (w > 0 and 1 or -1)
	end
	if not self.insert_mode then
		w = w > 0 and 1 or -1
	end
	return snap(x), snap(y), w, h, dir
end

function editbox:caret_scroll_rect()
	local x, y, w, h = self:caret_rect()
	--enlarge the caret rect to contain the line spacing.
	local c1 = self.selection.cursor1
	local line = c1:line()
	local y = y + line.ascent - line.spacing_ascent
	local h = line.spacing_ascent - line.spacing_descent
	return x, y, w, h
end

function editbox:override_sync_text_align(inherited)
	if self.password then
		self.text_align_x = 'left' --only left-alignment supported!
	end
	local segs = inherited(self)
	if not self.selection then
		return segs
	end
	if self.password then
		self:sync_password_mask(segs)
	end

	--move the text behind the editbox such that the caret remains visible.
	if not self.multiline then
		local line_w
		if self.password then
			local t = segs.lines.pw_cursor_xs
			line_w = #t * self:password_char_advance_x()
		else
			line_w = segs.lines[1].advance_x
		end
		local x, _, w = self:caret_rect()
		local view_w = self.cw - w
		local sx = segs.lines.x
		if line_w > view_w then
			local ax = segs.lines[1].x --alignment x.
			local sx = sx + ax --text offset relative to the editbox.
			x = x - sx
			--scroll to make the cursor visible.
			sx = clamp(sx, -x, -x + view_w)
			--scroll to keep the text within the editbox bounds.
			sx = clamp(sx, math.min(view_w - line_w, 0), 0)
			--apply the scroll offset.
			segs.lines.x = sx - ax
		else
			--make the cursor visible when the text is right-aligned.
			local adjustment = self.text_align_x == 'right' and -w or 0
			--reset the x-offset in order to use the default alignment from `tr`.
			segs.lines.x = 0 + adjustment
		end
	end
	return segs
end

--drawing cursor & selection

local function draw_sel_rect(x, y, w, h, cr, self)
	local x2 = x + w
	x, y = self:text_to_mask(x, y)
	x2 = self:text_to_mask(x2)
	w = x2 - x
	cr:rectangle(x, y, w, h)
	cr:fill()
end
function editbox:draw_selection(cr)
	if not self.selection then return end
	if self.selection:empty() then return end
	cr:rgba(self.ui:rgba(self.selection_color))
	cr:new_path()
	self.selection:rectangles(draw_sel_rect, cr, self)
end

function editbox:draw_caret(cr)
	if not self.focused then return end
	if not self.caret_visible then return end
	local x, y, w, h, dir = self:caret_rect()
	local r, g, b, a = self.ui:rgba(self.caret_color)
	a = a * self.caret_opacity
	cr:rgba(r, g, b, a)
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

function editbox:blink_caret()
	if not self.focused then return end
	self.caret_visible = true
	self:transition{
		attr = 'caret_opacity',
		val = self:end_value'caret_opacity',
	}
	self:invalidate()
end

function editbox:after_draw_content(cr)
	self:draw_selection(cr)
	self:draw_caret(cr)
end

--undo/redo

function editbox:clear_undo_stack()
	self.undo_stack = false
	self.redo_stack = false
end

function editbox:save_state(state)
	state.cursor1_seg_i = self.selection.cursor1.seg.index
	state.cursor2_seg_i = self.selection.cursor2.seg.index
	state.cursor1_cursor_i = self.selection.cursor1.cursor_i
	state.cursor2_cursor_i = self.selection.cursor2.cursor_i
	state.cursor1_offset = self.selection.cursor1.offset
	state.cursor2_offset = self.selection.cursor2.offset
	state.text = self.text
	return state
end

function editbox:load_state(state)
	self.selection:select_all()
	self:replace_selection(state.text)
	local segs = self.selection.segments
	self.selection.cursor1.seg = assert(segs[state.cursor1_seg_i])
	self.selection.cursor2.seg = assert(segs[state.cursor2_seg_i])
	self.selection.cursor1.cursor_i = state.cursor1_cursor_i
	self.selection.cursor2.cursor_i = state.cursor2_cursor_i
	self.selection.cursor1.offset = state.cursor1_offset
	self.selection.cursor2.offset = state.cursor2_offset
	self:invalidate()
end

function editbox:_undo_redo(undo_stack, redo_stack)
	if not undo_stack then return end
	local state = pop(undo_stack)
	if not state then return end
	push(redo_stack, self:save_state{type = 'undo'})
	self:load_state(state)
	return true
end

function editbox:undo()
	return self:_undo_redo(self.undo_stack, self.redo_stack)
end

function editbox:redo()
	return self:_undo_redo(self.redo_stack, self.undo_stack)
end

function editbox:undo_group(type)
	if not type then
		--cursor moved, force an undo group on the next editing operation.
		self.force_undo_group = true
		return
	end
	local top = self.undo_stack and self.undo_stack[#self.undo_stack]
	if not top or top.type ~= type or self.force_undo_group then
		self.undo_stack = self.undo_stack or {}
		self.redo_stack = self.redo_stack or {}
		push(self.undo_stack, self:save_state{type = type})
		self.force_undo_group = false
	end
end

function editbox:get_edited()
	return self.undo_stack and #self.undo_stack > 0
end

--editing

function editbox:replace_selection(s, preserve_screen_x, fire_event)
	local maxlen = self.maxlen - self.text_len
	if not self.selection:replace(s, nil, nil, maxlen) then return end
	self._text = false --invalidate the text property
	self:invalidate()
	if fire_event ~= false then
		self:fire'text_changed'
	end
	return true
end

--keyboard interaction

editbox.focusable = true

function editbox:keychar(s)
	if not self.selection then return end
	s = self:filter_text(s)
	if s == '' then return end
	self:undo_group'typing'
	self:replace_selection(s)
end

function editbox:keypress(key)
	if not self.selection then return end

	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	local shift_ctrl = shift and ctrl
	local shift_only = shift and not ctrl
	local ctrl_only = ctrl and not shift
	local key_only = not ctrl and not shift

	if key == 'right' or key == 'left' then
		self:undo_group()
		local movement = ctrl and 'word' or 'char'
		local delta = key == 'right' and 1 or -1
		if shift then
			return self.selection.cursor1:move(movement, delta)
		else
			local c1, c2 = self.selection:cursors()
			if self.selection:empty() then
				if c1:move(movement, delta) then
					c2:move_to_cursor(c1)
					return true
				end
			else
				local c1, c2 = c1, c2
				if key == 'left' then
					c1, c2 = c2, c1
				end
				return c1:move_to_cursor(c2)
			end
		end
	elseif
		key == 'up' or key == 'down'
		or key == 'pageup' or key == 'pagedown'
		or key == 'home' or key == 'end'
	then
		local how, by
		if key == 'up' then
			how, by = 'line', -1
		elseif key == 'down' then
			how, by = 'line', 1
		elseif key == 'pageup' then
			how, by = 'page', -1
		elseif key == 'pagedown' then
			how, by = 'page', 1
		elseif key == 'home' then
			how, by = 'line', -1/0
		elseif key == 'end' then
			how, by = 'line', 1/0
		end
		self:undo_group()
		local moved = self.selection.cursor1:move(how, by)
		if not shift then
			self.selection.cursor2:move_to_cursor(self.selection.cursor1)
		end
		return moved
	elseif key_only and key == 'insert' then
		self.insert_mode = not self.insert_mode
		return true
	elseif key_only and (key == 'delete' or key == 'backspace') then
		self:undo_group'delete'
		if self.selection:empty() then
			if key == 'delete' then --remove the char after the cursor
				self.selection.cursor1:move('char', 1)
			else --remove the char before the cursor
				self.selection.cursor1:move('char', -1)
			end
		end
		return self:replace_selection('', true)
	elseif ctrl and key == 'A' then
		self:undo_group()
		return self.selection:select_all()
	elseif
		(ctrl and (key == 'C' or key == 'X'))
		or (shift_only and key == 'delete') --cut
		or (ctrl_only and key == 'insert') --paste
	then
		if not self.selection:empty() then
			self.ui:setclipboard(self.selection:string(), 'text')
			local cut = key == 'X' or key == 'delete'
			if cut then
				self:undo_group'cut'
				self:replace_selection('', true)
			end
			return true
		end
	elseif (ctrl and key == 'V') or (shift_only and key == 'insert') then
		local s = self.ui:getclipboard'text'
		if s then
			s = self:filter_text(s)
			if s ~= '' then
				self:undo_group'paste'
				self:replace_selection(s)
				return true
			end
		end
	elseif ctrl and key == 'Z' then
		return self:undo()
	elseif (ctrl and key == 'Y') or (shift_ctrl and key == 'Z') then
		return self:redo()
	end
end

function editbox:gotfocus()
	if not self.selection then return end
	if not self.active then
		self.selection:select_all()
		self.caret_visible = self.selection:empty()
	else
		self.caret_visible = true
	end
end

function editbox:lostfocus()
	if not self.selection then return end
	self.caret_visible = false
	self.selection.cursor1:move_to_offset(0)
	self.selection:reset()
end

--mouse interaction

editbox.cursor_text = 'text'
editbox.cursor_selection = 'arrow'

function editbox:hit_test_selection(x, y)
	if not self.selection then return end
	x, y = self:mask_to_text(x, y)
	if self.selection:hit_test(x, y) then
		return self, 'selection'
	elseif self.selection.segments:hit_test(x, y) then
		return self, 'text'
	end
end

function editbox:override_hit_test_content(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if widget then
		return widget, area
	end
	if reason == 'activate' and self.activable then
		return self:hit_test_selection(x, y)
	end
end

editbox.mousedown_activate = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events

function editbox:doubleclick(x, y)
	if not self.selection then return end
	self.selection:select_word()
end

function editbox:tripleclick(x, y)
	if not self.selection then return end
	self.selection:select_all()
end

function editbox:mousedown(x, y)
	if not self.selection then return end
	self.selection.cursor1:move_to_pos(self:mask_to_text(x, y))
	self.selection:reset()
end

function editbox:mousemove(x, y)
	if not self.selection then return end
	if not self.active then return end
	self.selection.cursor1:move_to_pos(self:mask_to_text(x, y))
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
	for _,x in segs:cursor_xs() do
		segs.lines.pw_cursor_is[snap(x, 1/256)] = i
		segs.lines.pw_cursor_xs[i] = x
		i = i + 1
	end
end

function editbox:password_char_advance_x()
	--TODO: maybe use the min(w, h) of the "M" char here?
	return self.selection.segments.text_runs[1].font_size * .75
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
		local segs = self:sync_text_shape()
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
		local segs = self:sync_text_shape()
		self:draw_password_mask(cr, segs)
	else
		inherited(self, cr)
	end
end

--cue layer

editbox.show_cue_when_focused = false

ui:style('editbox > cue_layer', {
	text_color = '#666',
})

function editbox:get_cue()
	return self.cue_layer.text
end
function editbox:set_cue(s)
	self.cue_layer.text = s
end
editbox:instance_only'cue'

editbox.cue_layer_class = ui.layer

editbox:init_ignore{cue=1}

function editbox:create_cue_layer()
	return self.cue_layer_class(self.ui, {
		tags = 'cue_layer',
		parent = self,
		editbox = self,
		activable = false,
		nowrap = true,
	}, self.cue_layer)
end

function editbox:after_init(ui, t)
	self.cue_layer = self:create_cue_layer()
	self.cue = t.cue
end

function editbox:after_sync()
	self.cue_layer.text_align_x = self.text_align_x
	self.cue_layer.visible = self.text_len == 0
		and (not self.show_cue_when_focused or self.focused)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.w = 300

	ui:add_font_file('media/fonts/FSEX300.ttf', 'fixedsys')
	local x, y = 10, 10
	local function xy()
		local editbox = win.view[#win.view]
		y = y + editbox.h + 10
		if y + editbox.h + 10 > win.ch then
			x = x + editbox.y + 10
		end
	end

	local s = 'abcd efgh ijkl mnop qrst uvw xyz 0123 4567 8901 2345'

	--defaults all-around.
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
	}
	xy()

	--maxlen: truncate initial text. prevent editing past maxlen.
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		maxlen = 5,
	}
	xy()

	--scrolling, left align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
	}
	xy()

	--scrolling, right align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		text_align_x = 'right',
	}
	xy()

	--scrolling, center align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
	}
	xy()

	local s = '0123 4567 8901 2345'

	--password, scrolling, left align (the only alignment supported)
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		password = true,
		text_align_x = 'right', --overriden!
	}
	xy()

	--rtl
	ui:editbox{
		x = x, y = y, parent = win,
		font = 'Amiri,20',
		text = 'السَّلَامُ عَلَيْكُمْ',
		text_align_x = 'right',
		text_dir = 'rtl',
	}
	xy()

	--multiline
	ui:editbox{
		x = x, y = y, parent = win,
		h = 200,
		parent = win,
		text = ('HelloWorldHelloWorldHelloWorld! '):rep(20),
		multiline = true,
		cue = 'Type text here...',
	}
	xy()

	--[[
	local t0 = require'time'.clock()
	require'jit.p'.start()
	ed3.selection.cursor1:move_to_offset(0)
	ed3.selection.cursor2:move_to_offset(10)
	assert(not ed3.selection:empty())
	ed3:replace_selection('1234')
	ed3:sync_text_shape()
	require'jit.p'.stop()
	print(require'time'.clock() - t0)
	--win:close()
	]]

end) end
