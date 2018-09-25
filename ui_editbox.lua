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

editbox.w = 180
editbox.h = 24
editbox.padding = 4
editbox.focusable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.clip_content = true
editbox.text_align = 'left'
editbox.caret_color = '#fff'
editbox.selection_color = '#66f8'
editbox.nowrap = true
editbox.insert_mode = false
editbox.cursor_text = 'text'
editbox.cursor_selection = 'arrow'
editbox.password = false
editbox.maxlen = 4096
editbox.tags = 'standalone'

ui:style('editbox', {
	caret_color = '#fff0',
	transition_caret_color = true,
	transition_delay_caret_color = function(self)
		return self.ui.caret_blink_time
	end,
	transition_blend_caret_color = 'restart', --(re)start from default color
	transition_repeat_caret_color = 1/0, --blink indefinitely
})

ui:style('editbox standalone', {
	border_color = '#333',
	border_width = 1,
	transition_border_color = true,
	transition_duration_border_color = .5,
})

ui:style('editbox standalone :hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration_border_color = .5,
})

ui:style('editbox standalone :focused', {
	border_color = '#fff',
	shadow_blur = 2,
	shadow_color = '#666',
	background_color = '#040404', --to cover the shadow
})

ui:style('editbox :insert_mode', {
	caret_color = '#fff8',
})

--insert_mode property

editbox:stored_property'insert_mode'
editbox:track_changes'insert_mode'
editbox:instance_only'insert_mode'

function editbox:after_set_insert_mode(value)
	self:settag(':insert_mode', value)
end

--utf8 text property, computed on-demand.

editbox._text = ''

--tell ui:sync_text() that we're managing text reshaping ourselves.
--reshaping is done by selection:replace().
editbox._text_valid = true

function editbox:get_text()
	if not self._text then
		self._text = self.selection.segments.text_runs:string()
	end
	return self._text
end

function editbox:set_text(s)
	s = s or '' --an editbox can never have its text property as false!
	self:clear_undo_stack()
	self.selection:select_all()
	self:replace_selection(s, nil, false)
end

editbox:instance_only'text'

function editbox:text_visible()
	return true --always sync, even for the empty string.
end

--filtering & truncating the input text.

--filter text by replacing newlines and ASCII control chars with spaces.
--TODO: make `tr.multiline` option so that we don't have to do this.
function editbox:filter_text(s)
	return s:gsub(tr.PS, ' '):gsub(tr.LS, ' '):gsub('[%z\1-\31]', ' ')
end

--validation for single utf8 chars.
function editbox:check_char(s)
	return
		self.selection.segments.text_runs.len < self.maxlen
		and s:byte(1, 1) >= 32 and s ~= tr.PS and s ~= tr.LS
end

--init

editbox:init_ignore{text=1}

function editbox:after_init(ui, t)
	self._scroll_x = 0
	--create a selection so we can add the text through the selection which
	--obeys maxlen and triggers changed event.
	self.selection = self:sync_text():selection()
	self.text = t.text

	function self.selection.cursor1.changed()
		self:blink_caret()
	end
	function self.selection.cursor2.changed()
		self:blink_caret()
	end
end

--sync'ing

function editbox:override_sync_text(inherited)
	local segs = inherited(self)

	--extra padding needed to make the rightmost cursor visible when the text
	--is right-aligned.
	local caret_padding = self.text_align == 'right' and 1 or 0

	--scroll text.
	local new_x = -self._scroll_x
	local scrolled = segs.lines.x ~= new_x
	segs.lines.x = new_x - caret_padding

	--clip text segments to the content rectangle.
	if false and not self.password then
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
	if self.selection:empty() then return end
	cr:rgba(self.ui:rgba(self.selection_color))
	cr:new_path()
	self.selection:rectangles(draw_sel_rect, cr, self)
end

function editbox:draw_caret(cr)
	if not self.focused then return end
	if not self.caret_visible then return end
	local x, y, w, h, dir = self:caret_rect()
	cr:rgba(self.ui:rgba(self.caret_color))
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

function editbox:blink_caret()
	self.caret_visible = true
	self:transition'caret_color'
end

function editbox:after_draw_content(cr)
	self:draw_selection(cr)
	self:draw_caret(cr)
end

--scrolling

function editbox:scroll_to_caret(preserve_screen_x)
	local segs = self:sync_text()
	local x, y, w, h, dir = self:caret_rect()
	x = x - segs.lines.x
	if preserve_screen_x and self._screen_x then
		self._scroll_x = x - self._screen_x
	end
	self._scroll_x = clamp(self._scroll_x, x - self.cw + w, x)
	local line_w
	if segs.lines.pw_cursor_xs then
		line_w = #segs.lines.pw_cursor_xs * self:password_char_advance_x()
	else
		line_w = segs.lines[1].advance_x
	end
	local max_scroll_x = math.max(0, line_w - self.cw + w)
	self._scroll_x = clamp(self._scroll_x, 0, max_scroll_x)
	self._screen_x = x - self._scroll_x
	self:invalidate()
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
	if state then
		push(redo_stack, self:save_state{type = 'undo'})
		self:load_state(state)
	end
end

function editbox:undo()
	self:_undo_redo(self.undo_stack, self.redo_stack)
end

function editbox:redo()
	self:_undo_redo(self.redo_stack, self.undo_stack)
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

--editing

function editbox:replace_selection(s, preserve_screen_x, fire_event)
	local maxlen = self.maxlen - self.selection.segments.text_runs.len
	if not self.selection:replace(s, nil, nil, maxlen) then return end
	self._text = false --invalidate the text property
	self:scroll_to_caret(preserve_screen_x)
	if fire_event ~= false then
		self:fire'text_changed'
	end
end

--keyboard

function editbox:keychar(s)
	if not self:check_char(s) then return end
	self:undo_group'typing'
	self:replace_selection(s)
end

function editbox:keypress(key)

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
		self:undo_group()
		self.selection.cursor1:move('vert', key == 'down' and 1 or -1)
		if not shift then
			self.selection.cursor2:move_to_cursor(self.selection.cursor1)
		end
		self:scroll_to_caret()
		return true
	elseif key_only and key == 'insert' then
		self.insert_mode = not self.insert_mode
		self:scroll_to_caret()
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
		self:replace_selection('', true)
		return true
	elseif ctrl and key == 'A' then
		self:undo_group()
		self.selection:select_all()
		self:scroll_to_caret()
		return true
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
		end
		return true
	elseif (ctrl and key == 'V') or (shift_only and key == 'insert') then
		local s = self.ui:getclipboard'text'
		s = s and self:filter_text(s)
		if s and s ~= '' then
			self:undo_group'paste'
			self:replace_selection(s)
		end
		return true
	elseif ctrl and key == 'Z' then
		self:undo()
		return true
	elseif (ctrl and key == 'Y') or (shift_ctrl and key == 'Z') then
		self:redo()
		return true
	end
end

function editbox:gotfocus()
	if not self.active then
		self.selection:select_all()
		self:scroll_to_caret()
		self.caret_visible = false
	end
end

function editbox:lostfocus()
	self.selection.cursor1:move_to_offset(0)
	self.selection:reset()
	self:scroll_to_caret()
end

--mouse interaction

function editbox:hit_test_selection(x, y)
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
	for _,x in segs:cursor_xs() do
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
		x = snap(x, 1) --prevent blurry carets
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

--cue layer

ui:style('editbox > cue_layer', {
	text_color = '#666',
})

editbox.show_cue_when_focused = false

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
	}, self.cue_layere)
end

function editbox:after_init(ui, t)
	self.cue_layer = self:create_cue_layer()
	self.cue = t.cue
end

function editbox:after_sync()
	self.cue_layer.w = self.cw
	self.cue_layer.h = self.ch
	self.cue_layer.text_align = self.text_align
	local len = self.selection.segments.text_runs.len
	self.cue_layer.visible = len == 0
		and (self.show_cue_when_focused or not self.focused)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:add_font_file('media/fonts/FSEX300.ttf', 'fixedsys')
	local x, y = 10, 10
	local function xy()
		local editbox = win.view.layers[#win.view.layers]
		y = y + editbox.h + 10
		if y + editbox.h + 10 > win.ch then
			x = x + editbox.y + 10
		end
	end

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

	--right align
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		text_align = 'right',
	}
	xy()

	--password
	ui:editbox{
		--font = 'fixedsys,16',
		x = x, y = y, parent = win,
		text = 'Hello World!',
		password = true,
		maxlen = 28,
	}
	xy()

	ui:editbox{
		--font = 'fixedsys,16',
		x = x, y = y, parent = win,
		font = 'Amiri,20',
		text = 'السَّلَامُ عَلَيْكُمْ',
		text_align = 'right',
		text_dir = 'rtl',
	}
	xy()

	ui:editbox{
		x = x, y = y, parent = win,
		text = ('Hello World! '):rep(100000),
		maxlen = 65536 / 10,
	}
	xy()

	ui:editbox{
		x = x, y = y, parent = win,
		--font = 'fixedsys,16',
		h = 200,
		parent = win,
		text = 'Hello World!',
		text_align = 'center',
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
	ed3:sync_text()
	require'jit.p'.stop()
	print(require'time'.clock() - t0)
	--win:close()
	]]

end) end
