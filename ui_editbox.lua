--go @ luajit ui_editbox.lua

--Edit Box widget based on tr.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local tr = require'tr'
local glue = require'glue'
local box2d = require'box2d'

local push = table.insert
local pop = table.remove
clamp = glue.clamp
snap = glue.snap

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox
editbox.iswidget = true

--config / behavior

editbox.focusable = true
editbox.text_selectable = true
editbox.text_editable = true
editbox.nowrap = true
editbox.text_multiline = false

--config / geometry

editbox.text_align_x = 'auto'
editbox.align_y = 'center'
editbox.min_ch = 24
editbox.w = 180
editbox.h = 24

--styles

editbox.tags = 'standalone'

ui:style('editbox standalone', {
	border_width_bottom = 1,
	transition_border_color = true,
	transition_duration_border_color = .5,
})

ui:style('editbox standalone :focused', {
	border_color = '#fff',
})

ui:style('editbox standalone :hot', {
	border_color = '#fff',
})

--animation

ui:style('editbox standalone, editbox standalone :hot', {
	transition_border_color = true,
	transition_duration_border_color = .5,
})

--cue layer ------------------------------------------------------------------

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
	local cue_layer = self.cue_layer_class(self.ui, {
		tags = 'cue_layer',
		parent = self,
		editbox = self,
		activable = false,
		nowrap = true,
	}, self.cue_layer)

	function cue_layer:before_sync_layout()
		local ed = self.editbox
		self.visible =
			(not ed.show_cue_when_focused or ed.focused)
			and ed.text_len == 0
		if self.visible then
			self.text_align_x = ed.text_align_x
			self.text_align_y = ed.text_align_y
			self.w = ed.cw
			self.h = ed.ch
		end
	end

	return cue_layer
end

function editbox:after_init(t)
	self.cue_layer = self:create_cue_layer()
	self.cue = t.cue
end

--password masking -----------------------------------------------------------

--Password masking works by drawing fixed-width dots in place of actual
--characters. Because cursor placement and hit-testing must continue
--to work over these markers, we have to translate from "text space" (where
--the original cursor positions are) to "mask space" (where the fixed-width
--visual cursor positons are) in order to draw the cursor and the selection
--rectangles. We also need to translate back to text space for hit-testing.

editbox.password = false

function editbox:override_caret_rect(inherited)
	local x, y, w, h = inherited(self)
	if self.password then
		x, y = self:text_to_mask(x, y)
		w = self.insert_mode and self:password_char_advance_x() or 1
		if self.text_selection.cursor2:rtl() then
			x = x - w
		end
		x = snap(x)
		y = snap(y)
	end
	return x, y, w, h
end

function editbox:override_draw_selection_rect(inherited, x, y, w, h, cr)
	local x1, y1 = self:text_to_mask(x, y)
	local x2, y2 = self:text_to_mask(x + w, y + h)
	inherited(self, x1, y1, x2-x1, y2-y1, cr)
end

--compute the text-space to mask-space mappings on each text sync.
function editbox:sync_password_mask()
	if not self.text_selection then return end
	local segs = self.text_selection.segments
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
	return self.text_selection.segments.text_runs[1].font_size * .75
end

--convert "text space" cursor coordinates to "mask space" coordinates.
--NOTE: input must be an exact cursor position.
function editbox:text_to_mask(x, y)
	if self.password then
		local segs = self.text_selection.segments
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

function editbox:draw_password_mask(cr)
	local w = self:password_char_advance_x()
	local h = self.ch
	local segs = self.text_selection.segments
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
		self:draw_password_mask(cr)
	else
		inherited(self, cr)
	end
end

function editbox:before_sync_text_align()
	if self.password then
		self.text_align_x = 'left'
	end
end

function editbox:after_sync_text_align()
	if self.password then
		self:sync_password_mask()
	end
end

--password eye button --------------------------------------------------------

ui:style('editbox_eye_button', {
	text_color = '#aaa',
})
ui:style('editbox_eye_button :hot', {
	text_color = '#fff',
})

function editbox:after_init()
	if self.password then
		local no_eye = '\u{f2e8}'
		local eye = '\u{f2e9}'
		self.eye_button = self.ui:layer({
			parent = self,
			tags = 'editbox_eye_button',
			font = 'Ionicons,16',
			text = no_eye,
			cursor = 'hand',
			click = function(btn)
				self.password = not self.password
				btn.text = self.password and no_eye or eye
				self:invalidate()
			end,
		}, self.eye_button)
		self.padding_right = 20
	end
end

function editbox:before_sync_layout_children()
	if self.password then
		local eye = self.eye_button
		eye.x = self.w - 10
		eye.y = self.h / 2
	end
end

--special text clipping ------------------------------------------------------

--allow fonts with long stems to overflow the text box on the y-axis.
editbox.text_overflow_y = 4

--clip the left & right sides of the box without clipping the top & bottom.
function editbox:text_clip_rect()
	local ph = self.text_overflow_y
	return 0, -ph, self.cw, self.ch + 2 * ph
end

function editbox:override_draw_content(inherited, cr)
	self:draw_children(cr)
	cr:save()
	cr:rectangle(self:text_clip_rect())
	cr:clip()
	self:draw_text_selection(cr)
	self:draw_text(cr)
	self:draw_caret(cr)
	cr:restore()
end

function editbox:override_hit_test_text(inherited, x, y, reason)
	if not box2d.hit(x, y, self:text_clip_rect()) then
		return
	end
	return inherited(self, x, y, reason)
end

function editbox:override_make_visible_caret(inherited)
	local segs = self.text_segments
	if not segs then return end
	local lines = segs.lines
	local y = lines.y
	inherited(self)
	lines.y = y
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.x = 500
	win.w = 300
	win.h = 900

	win.view.layout = 'flexbox'
	win.view.flex_flow = 'y'
	win.view.item_align_y = 'top'

	ui:add_font_file('FSEX300.ttf', 'fixedsys')
	ui:add_font_file('media/fonts/amiri-regular.ttf', 'Amiri')

	local cue = 'Type text here...'
	local s = 'abcd efgh ijkl mnop qrst uvw xyz 0123 4567 8901 2345'

	win.view.accepts_drag_groups = {true}

	--defaults all-around.
	ui:editbox{
		parent = win,
		text = 'Hello World!',
		cue = cue,
		--mousedown_activate = true,
	}

	--maxlen: truncate initial text. prevent editing past maxlen.
	ui:editbox{
		parent = win,
		text = 'Hello World!',
		maxlen = 5,
		cue = cue,
	}

	--right align
	ui:editbox{
		parent = win,
		text = 'Hello World!',
		text_align_x = 'right',
		cue = cue,
	}

	--center align
	ui:editbox{
		parent = win,
		text = 'Hello World!',
		text_align_x = 'center',
		cue = cue,
	}

	--scrolling, left align
	ui:editbox{
		parent = win,
		text = s,
		cue = cue,
	}

	--scrolling, right align
	ui:editbox{
		parent = win,
		text = s,
		text_align_x = 'right',
		cue = cue,
	}

	--scrolling, center align
	ui:editbox{
		parent = win,
		text = s,
		text_align_x = 'center',
		cue = cue,
	}

	--invalid font
	ui:editbox{
		parent = win,
		font = 'Invalid Font,20',
		text = s,
		cue = cue,
	}

	--rtl, align=auto
	ui:editbox{
		parent = win,
		font = 'Amiri,20',
		text = 'السَّلَامُ عَلَيْكُمْ',
		cue = cue,
	}

	--password, scrolling, left align (the only alignment supported)
	ui:editbox{
		parent = win,
		text = 'peekaboo',
		password = true,
	}

end) end
