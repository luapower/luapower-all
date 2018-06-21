
--ui button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local button = ui.layer:subclass'button'
ui.button = button

button.focusable = true
button.w = 100
button.h = 26
button.background_color = '#444'
button.border_color = '#888'
button.border_width = 1
button.padding_left = 8
button.padding_right = 8
button._default = false
button._cancel = false

button.uses_enter_key = true

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('button default', {
	background_color = '#092',
})

ui:style('button hot', {
	background_color = '#999',
	border_color = '#999',
	text_color = '#000',
})

ui:style('button default hot', {
	background_color = '#3e3',
})

ui:style('button disabled', {
	background_color = '#222',
	border_color = '#444',
	text_color = '#666',
	transition_duration = 0,
})

ui:style('button active over', {
	background_color = '#fff',
	text_color = '#000',
	transition_duration = 0.2,
})

ui:style('button default active over', {
	background_color = '#9f7',
})

ui:style('button focused', {
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

button:init_priority{text=1, key=2}

function button:press()
	self:fire'pressed'
	if self.default then
		self.window:close'default'
	elseif self.cancel then
		self.window:close'cancel'
	end
end

function button:get_text()
	return self._text
end

function button:set_text(s)
	if s == '' or not s then s = false end
	if self._text == s then return end
	if not s then
		self._text = false
		self.underline_pos = false
		self.underline_text = false
	else
		s = s:gsub('&&', '\0') --TODO: hack
		local pos, key = s:match'()&(.)'
		self._text = s:gsub('&', ''):gsub('%z', '&')
		if key then
			self.key = key:upper()
			self.underline_pos = pos
			self.underline_text = key
		end
	end
end

function button:get_key()
	return self._key
end

function button:set_key(key)
	self._key = key
	self.underline_pos = false
end

function button:mousedown()
	if self.active_by_key then return end
	self.active = true
end

function button:mousemove(mx, my)
	if self.active_by_key then return end
	local mx, my = self:to_parent(mx, my)
	self:settag('over', self:hit_test(mx, my, 'activate') == self)
end

function button:mouseup()
	if self.active_by_key then return end
	self.active = false
	if self.tags.over then
		self:press()
	end
end

function button:keydown(key)
	if key == 'enter' or key == 'space' then
		self.active = true
		self.active_by_key = true
		self:settag('over', true)
	end
end

function button:keyup(key)
	if not self.active_by_key then return end
	if key == 'enter' or key == 'space' or key == 'esc' then
		self.active = false
		self.active_by_key = false
		self:settag('over', false)
		if key == 'enter' or key == 'space' then
			self:press()
		end
	end
end

--default & cancel properties/tags

function button:get_default()
	return self._default
end

function button:set_default(default)
	default = default and true or false
	self._default = default
	self:settag('default', default)
end

function button:get_cancel()
	return self._cancel
end

function button:set_cancel(cancel)
	cancel = cancel and true or false
	self._cancel = cancel
	self:settag('cancel', cancel)
end

function button:allow_key(key)
	local win = self.window
	return not win or not win.focused_widget
		or not win.focused_widget:uses_key(key)
end

function button:after_set_window(win)
	if not win then return end
	local action
	win:on({'keydown', self}, function(win, key)
		if key == self.key and self:allow_key(key) then
			action = true
			self:keydown'enter'
		elseif self.default and key == 'enter' and self:allow_key'enter' then
			action = true
			self:keydown'enter'
		elseif self.cancel and key == 'esc' and self:allow_key'esc' then
			action = true
			self:keydown'enter'
		end
	end)
	win:on({'keyup', self}, function(win, key)
		if action then
			action = false
			self:keyup'enter'
		end
	end)
end

--drawing

--TODO: use the future hi-level text API to draw the underline
function button:before_draw_text(cr)
	if not self:text_visible() then return end
	if not self.underline_pos then return end
	--measure
	local x, y, w, h = self:text_bounding_box() --sets font
	local line_w = self.window:text_size(self.underline_text, self.text_multiline)
	local s = self.text:sub(1, self.underline_pos - 1)
	local line_pos = self.window:text_size(s, self.text_multiline)
	--draw
	cr:rgba(self.ui:color(self.text_color))
	cr:line_width(1)
	cr:move_to(x + line_pos + 1, math.floor(y + h + 2) + .5)
	cr:rel_line_to(line_w - 2, 0)
	cr:stroke()
end

--checkbox -------------------------------------------------------------------

local checkbox = ui.layer:subclass'checkbox'
ui.checkbox = checkbox

checkbox.h = 18
checkbox.align = 'left'
checkbox._checked = false

function checkbox:get_checked()
	return self._checked
end

function checkbox:set_checked(checked)
	checked = checked and true or false
	if self._checked == checked then return end
	self._checked = checked
	self:settag('checked', checked)
	self:fire(checked and 'was_checked' or 'was_unchecked')
	self:fire('checked_changed', checked)
end

function checkbox:toggle()
	self.checked = not self.checked
end

local cbutton = ui.button:subclass'checkbox_button'
checkbox.button_class = cbutton
cbutton.font_family = 'media/fonts/Font Awesome 5 Free-Solid-900.otf'
cbutton.text_checked = '\xEF\x80\x8C'
cbutton.text_size = 10
cbutton.padding_left = 2
cbutton.padding_right = 0

ui:style('checkbox_button hot', {
	text_color = '#fff',
	background_color = '#555',
})

ui:style('checkbox_button active over', {
	background_color = '#888',
})

function cbutton:sync()
	self.h = self.checkbox.ch
	self.w = self.h
	self.x = self.checkbox.align == 'left' and 0 or self.checkbox.cw - self.h
	self.text = self.checkbox.checked and self.text_checked
end

function cbutton:before_draw()
	self:sync()
end

function cbutton:override_hit_test(inherited, mx, my, reason)
	local widget, area = inherited(self, mx, my, reason)
	if not widget then
		local lbl = self.checkbox.label
		widget, area = lbl.super.super.hit_test(lbl, mx, my, reason)
		if widget then
			return self, 'label'
		end
	end
	return widget, area
end

function cbutton:pressed()
	self.checkbox:toggle()
end

function checkbox:create_button()
	return self.button_class(self.ui, {
		parent = self,
		checkbox = self,
	}, self.button)
end

local clabel = ui.layer:subclass'checkbox_label'
checkbox.label_class = clabel

function clabel:hit_test(mx, my, reason) end --cbutton does it for us

function clabel:sync()
	self.h = self.checkbox.ch
	self.w = self.checkbox.cw - self.checkbox.button.w
	local align = self.checkbox.align
	self.x = align == 'left' and self.checkbox.cw - self.w or 0
	self.text_align = align
	self.padding_left = align == 'left' and self.h / 2 or 0
	self.padding_right = align == 'right' and self.h / 2 or 0
end

function clabel:before_draw()
	self:sync()
end

function checkbox:create_label()
	return self.label_class(self.ui, {
		parent = self,
		checkbox = self,
	}, self.label)
end

function checkbox:after_init()
	self.button = self:create_button()
	self.label = self:create_label()
end

--radio button ---------------------------------------------------------------

local radiobutton = ui.checkbox:subclass'radiobutton'
ui.radiobutton = radiobutton

radiobutton.radio_group = 'default'

radiobutton:init_ignore{checked=1}

function radiobutton:after_init(ui, t)
	if t.checked then
		self.checked = true
	end
end

function radiobutton:override_set_checked(inherited, checked)
	local was_checked = self.checked
	inherited(self, checked)
	if self.checked and not was_checked then
		self.window.layer:each_child(function(rb)
			if rb.isradiobutton
				and rb ~= self
				and rb.radio_group == self.radio_group
				and rb.checked
			then
				rb.checked = false
			end
		end)
	end
end

function radiobutton:check()
	self.checked = true
end

local rbutton = ui.checkbox.button_class:subclass'radiobutton_button'
radiobutton.button_class = rbutton

function rbutton:after_sync()
	self.corner_radius = self.w / 2
	self.padding = 0
end

function rbutton:draw_text() end

rbutton.circle_radius = 0

ui:style('radiobutton_button', {
	transition_circle_radius = true,
	transition_duration = .2,
})

ui:style('radiobutton checked > radiobutton_button', {
	circle_radius = 1,
	transition_duration = .2,
})

function rbutton:before_draw_content(cr)
	local r = glue.lerp(self.circle_radius, 0, 1, 0, self.cw / 4)
	if r <= 0 then return end
	cr:circle(self.cw / 2, self.ch / 2, r)
	cr:rgba(self.ui:color(self.text_color))
	cr:fill()
end

function rbutton:pressed()
	self.checkbox:check()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:button{
		parent = win,
		x = 100, y = 100, w = 100,
		text = '&OK',
		default = true,
		text_align = 'center',
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		parent = win,
		x = 100, y = 150, w = 100,
		text = 'Disabled',
		enabled = false,
		text_align = 'right',
	})

	local b3 = btn(ui, {
		parent = win,
		x = 100, y = 200, w = 100,
		text = '&Cancel',
		cancel = true,
		text_align = 'left',
	})

	function b1:gotfocus() print'b1 got focus' end
	function b1:lostfocus() print'b1 lost focus' end
	function b2:gotfocus() print'b2 got focus' end
	function b2:lostfocus() print'b2 lost focus' end

	function b1:pressed() print'b1 pressed' end
	function b2:pressed() print'b2 pressed' end

	local cb1 = ui:checkbox{
		parent = win,
		x = 300, y = 100, w = 200,
		label =  {text = 'Check me'},
		checked = true,
		--enabled = false,
	}

	local cb2 = ui:checkbox{
		parent = win,
		x = 300, y = 140, w = 200,
		label =  {text = 'Check me too'},
		align = 'right',
		--enabled = false,
	}

	local rb1 = ui:radiobutton{
		parent = win,
		x = 300, y = 180, w = 200,
		label =  {text = 'Radio me'},
		checked = true,
		radio_group = 1,
		--enabled = false,
	}

	local rb2 = ui:radiobutton{
		parent = win,
		x = 300, y = 220, w = 200,
		label =  {text = 'Radio me too'},
		radio_group = 1,
		align = 'right',
		--enabled = false,
	}

end) end
