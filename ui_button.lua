
--ui button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

local button = ui.layer:subclass'button'
ui.button = button

button.focusable = true
button.w = 100
button.h = 26
button.background_color = '#444'
button.border_color = '#888'
button.border_width = 1
button._default = false
button._cancel = false

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
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
	border_color = '#fff',
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
		self:fire'pressed'
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
			self:fire'pressed'
		end
	end
end

--default & cancel properties/tags -------------------------------------------

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

function button:after_set_window(win)
	if win then
		local action
		win:on({'keydown', self}, function(win, key)
			if self.default and key == 'enter' then
				action = 'default'
				self:keydown'enter'
			elseif self.cancel and key == 'esc' then
				action = 'cancel'
				self:keydown'enter'
			end
		end)
		win:on({'keyup', self}, function(win, key)
			if action then
				self:keyup'enter'
				win:close(action)
			end
		end)
	end
end

--checkbox -------------------------------------------------------------------

local checkbox = ui.layer:subclass'checkbox'
ui.checkbox = checkbox

checkbox.h = 18
checkbox.align = 'left'

local cbutton = ui.button:subclass'checkbox_button'
checkbox.button_class = cbutton
cbutton.font_family = 'media/fonts/Font Awesome 5 Free-Solid-900.otf'
cbutton.text_checked = '\xEF\x80\x8C'
cbutton.text_size = 10
cbutton.padding_left = 2

ui:style('checkbox_button hot', {
	text_color = '#fff',
	transition_duration_text_color = 0,
})

function cbutton:sync()
	self.h = self.checkbox.ch
	self.w = self.h
	self.x = self.checkbox.align == 'left' and 0 or self.checkbox.cw - self.h
	self.text_color = self.checkbox.text_color
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

function checkbox:create_button()
	local btn = self.button_class(self.ui, {
		parent = self,
		checkbox = self,
	}, self.button)

	function btn:pressed()
		self.checkbox.checked = not self.checkbox.checked
	end

	return btn
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

local rbutton = ui.checkbox.button_class:subclass'radiobutton_button'
radiobutton.button_class = rbutton

function rbutton:after_sync()
	self.corner_radius = self.w / 2
	self.padding = 0
end

function rbutton:draw_text() end

function rbutton:before_draw_content(cr)
	if not self.checkbox.checked then return end
	cr:circle(self.cw / 2, self.ch / 2, self.cw / 4)
	cr:rgba(self.ui:color(self.text_color))
	cr:fill()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:button{
		parent = win,
		x = 100, y = 100, w = 100,
		text = 'OK',
		default = true,
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		parent = win,
		x = 100, y = 150, w = 100,
		text = 'Disabled',
		enabled = false,
	})

	local b3 = btn(ui, {
		parent = win,
		x = 100, y = 200, w = 100,
		text = 'Cancel',
		cancel = true,
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
