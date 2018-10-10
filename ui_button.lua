
--Button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local lerp = glue.lerp

local button = ui.layer:subclass'button'
ui.button = button
button.iswidget = true

button.focusable = true
button.w = 90
button.h = 24
button.background_color = '#444'
button.border_color = '#888'
button.padding_left = 8
button.padding_right = 8
button._default = false
button._cancel = false
button.tags = 'standalone'

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('button :default', {
	background_color = '#092',
})

ui:style('button :hot', {
	background_color = '#999',
	border_color = '#999',
	text_color = '#000',
})

ui:style('button :default :hot', {
	background_color = '#3e3',
})

ui:style('button :disabled', {
	background_color = '#222',
	border_color = '#444',
	text_color = '#666',
	transition_duration = 0,
})

ui:style('button :active :over', {
	background_color = '#fff',
	text_color = '#000',
	shadow_blur = 2,
	shadow_color = '#666',
	transition_duration = 0.2,
})

ui:style('button :default :active :over', {
	background_color = '#9f7',
})

ui:style('button :focused', {
	border_color = '#fff',
	border_width = 1,
	shadow_blur = 3,
	shadow_color = '#666',
})

button:init_priority{
	text=-2, key=-1, --because text can contain a key
}

ui:style('button profile=text', {
	background_type = false,
	border_width = 0,
	text_color = '#999',
})

ui:style('button profile=text :hot', {
	text_color = '#ccc',
})

ui:style('button profile=text :focused', {
	shadow_blur = 2,
	shadow_color = '#111',
	text_color = '#ccc',
})

ui:style('button profile=text :active :over', {
	text_color = '#fff',
	shadow_blur = 2,
	shadow_color = '#111',
})

function button:get_profile()
	return self._profile
end

function button:set_profile(profile)
	if self._profile then self:settag('profile='..self._profile, false) end
	self._profile = profile
	if self._profile then self:settag('profile='..self._profile, true) end
end

function button:press()
	if self:fire'pressed' ~= nil then
		return
	end
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
	self:settag(':over', self.active and self:hit_test(mx, my, 'activate') == self)
end

function button:mouseup()
	if self.active_by_key then return end
	self.active = false
	if self.tags[':over'] then
		self:press()
	end
end

function button:activate_by_key(key)
	if self.active_by_key then return end
	self.active = true
	self.active_by_key = key
	self:settag(':over', true)
	return true
end

function button:keydown(key)
	if self.active_by_key then return end
	if key == 'enter' or key == 'space' then
		return self:activate_by_key(key)
	end
end

function button:keyup(key)
	if not self.active_by_key then return end
	local press = key == self.active_by_key
	if press or key == 'esc' then
		self:settag(':over', false)
		if press then
			self:press()
		end
		self.active = false
		self.active_by_key = false
		return true
	end
end

--default & cancel properties/tags

function button:get_default()
	return self._default
end

function button:set_default(default)
	default = default and true or false
	self._default = default
	self:settag(':default', default)
end

function button:get_cancel()
	return self._cancel
end

function button:set_cancel(cancel)
	cancel = cancel and true or false
	self._cancel = cancel
	self:settag(':cancel', cancel)
end

function button:after_set_window(win)
	if not win then return end
	win:on({'keydown', self}, function(win, key)
		if self.key and self.ui:key(self.key) then
			return self:activate_by_key(key)
		elseif self.default and key == 'enter' then
			return self:activate_by_key(key)
		elseif self.cancel and key == 'esc' then
			return self:activate_by_key(key)
		end
	end)

	--if the button is not focusable, we need to catch keyups globally too
	win:on({'keyup', self}, function(win, key)
		return self:keyup(key)
	end)
end

--drawing

function button:before_draw_text(cr)
	if not self.text_visible then return end
	if not self.underline_pos then return end
	do return end --TODO: use the future hi-level text API to draw the underline
	--measure
	local x, y, w, h = self:text_bounding_box() --sets font
	local line_w = self.window:text_size(self.underline_text, self.text_multiline)
	local s = self.text:sub(1, self.underline_pos - 1)
	local line_pos = self.window:text_size(s, self.text_multiline)
	--draw
	cr:rgba(self.ui:rgba(self.text_color))
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
	self:settag(':checked', checked)
	self:fire(checked and 'was_checked' or 'was_unchecked')
	self:fire('checked_changed', checked)
end

function checkbox:toggle()
	self.checked = not self.checked
end

local cbutton = ui.button:subclass'checkbox_button'
checkbox.button_class = cbutton

cbutton.font = 'Ionicons,16'
cbutton.text_checked = '\u{f2bc}'
cbutton.padding_left = 0
cbutton.padding_right = 0

ui:style('checkbox_button :hot', {
	text_color = '#fff',
	background_color = '#555',
})

ui:style('checkbox_button :active :over', {
	background_color = '#888',
})

function cbutton:after_sync()
	self.h = self.checkbox.ch
	self.w = self.h
	self.x = self.checkbox.align == 'left' and 0 or self.checkbox.cw - self.h
	self.text = self.checkbox.checked and self.text_checked
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

function cbutton:checkbox_press()
	self.checkbox:toggle()
end

function cbutton:before_press()
	self:checkbox_press()
end

function checkbox:create_button()
	return self.button_class(self.ui, {
		parent = self,
		checkbox = self,
		iswidget = false,
	}, self.button)
end

local clabel = ui.layer:subclass'checkbox_label'
checkbox.label_class = clabel

function clabel:hit_test(mx, my, reason) end --cbutton does it for us

function clabel:after_sync()
	self.h = self.checkbox.ch
	self.w = self.checkbox.cw - self.checkbox.button.w
	local align = self.checkbox.align
	self.x = align == 'left' and self.checkbox.cw - self.w or 0
	self.text_align = align
	self.padding_left = align == 'left' and self.h / 2 or 0
	self.padding_right = align == 'right' and self.h / 2 or 0
end

function checkbox:create_label()
	return self.label_class(self.ui, {
		parent = self,
		checkbox = self,
		iswidget = false,
	}, self.label)
end

function checkbox:after_init()
	self.button = self:create_button()
	self.label = self:create_label()
	self.button:settag('standalone', false)
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
		self.window.view:each_child(function(rb)
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

rbutton.padding_left = 0
rbutton.padding_right = 0

function rbutton:after_sync()
	self.corner_radius = self.w
end

function rbutton:draw_text() end

rbutton.circle_radius = 0

ui:style('radiobutton_button', {
	transition_circle_radius = true,
	transition_duration = .2,
})

ui:style('radiobutton :checked > radiobutton_button', {
	circle_radius = .45,
	transition_duration = .2,
})

function rbutton:before_draw_content(cr)
	local r = lerp(self.circle_radius, 0, 1, 0, self.cw / 2)
	if r <= 0 then return end
	cr:circle(self.cw / 2, self.ch / 2, r)
	cr:rgba(self.ui:rgba(self.text_color))
	cr:fill()
end

function rbutton:checkbox_press()
	self.checkbox:check()
end

--radio button list ----------------------------------------------------------

local rblist = ui.layer:subclass'radiobutton_list'
ui.radiobuttonlist = rblist

rblist.radiobutton_class = ui.radiobutton

rblist:init_ignore{values=1}

function rblist:create_radiobutton(i, v)
	local t = type(v) == 'table' and v or nil
	local text = t and t.text or v
	local y = i * 36
	self.radiobutton_class(self.ui, {
		y = y,
		w = self.w,
		parent = self,
		iswidget = false,
		button = glue.update({
			tabgroup = self.tabgroup or self,
			tabindex = i,
		}),
		label = glue.update({
			text = text,
		}),
		radio_group = self,
	}, self.radiobutton, t)
end

function rblist:after_init(ui, t)
	for i,v in ipairs(t.values) do
		self:create_radiobutton(i, v)
	end
end

--multi-choice button --------------------------------------------------------

local choicebutton = ui.layer:subclass'choicebutton'
ui.choicebutton = choicebutton

--model

choicebutton.values = {} --{{index=, text=, value=, ...}, ...}

function choicebutton:get_selected()
	local btn = self.selected_button
	return btn and btn.value
end

function choicebutton:set_selected(value)
	self:select_button(self:button_by_value(value))
end

--view

ui:style('button :selected', {
	background_color = '#ccc',
	text_color = '#000',
})

function choicebutton:find_button(selects)
	if self.layers then
		for i,btn in ipairs(self.layers) do
			if btn.choicebutton == self and selects(btn) then
				return btn
			end
		end
	end
end

function choicebutton:button_by_value(value)
	return self:find_button(function(btn) return btn.value == value end)
end

function choicebutton:button_by_index(index)
	return self:find_button(function(btn) return btn.index == index end)
end

function choicebutton:get_selected_button()
	return self:find_button(function(btn) return btn.tags[':selected'] end)
end

function choicebutton:set_selected_button(btn)
	self:select_button(btn)
end

function choicebutton:unselect_button(btn)
	btn:settag(':selected', false)
end

function choicebutton:select_button(btn, focus)
	if not btn then return end
	local sbtn = self.selected_button
	if sbtn == btn then return end
	if sbtn then
		self:unselect_button(sbtn)
	end
	if focus then
		btn:focus()
	end
	btn:settag(':selected', true)
	self:fire('value_selected', btn.value)
end

--drawing

choicebutton.button_corner_radius = 0

function choicebutton:button_xw(index)
	local w = self.cw / #self.values
	local x = (index - 1) * w
	return x, w
end

function choicebutton:sync_button(b)
	b.x, b.w = self:button_xw(b.index)
	self.ch = b.h
	local r = self.button_corner_radius
	b.corner_radius_top_left = b.index == 1 and r or 0
	b.corner_radius_bottom_left = b.index == 1 and r or 0
	b.corner_radius_top_right = b.index == #self.values and r or 0
	b.corner_radius_bottom_right = b.index == #self.values and r or 0
end

function choicebutton:before_draw_content(cr)
	if self.layers then
		for _, layer in ipairs(self.layers) do
			if layer.choicebutton == self then
				self:sync_button(layer)
			end
		end
	end
end

--init

choicebutton.button_class = ui.button

choicebutton:init_ignore{selected=1}

function choicebutton:create_button(index, value)

	local btn = self.button_class(self.ui, {
		tags = 'choicebutton_button',
		choicebutton = self,
		parent = self,
		iswidget = false,
		index = index,
		text = type(value) == 'table' and value.text or value,
		value = type(value) == 'table' and value.value or value,
	}, self.button, type(value) == 'table' and value or nil)

	--input/abstract
	function btn.before_press(btn)
		self:select_button(btn)
	end

	--input/keyboard
	function btn.before_keypress(btn, key)
		if key == 'left' then
			self:select_button(self:button_by_index(btn.index - 1), true)
			return true
		elseif key == 'right' then
			self:select_button(self:button_by_index(btn.index + 1), true)
			return true
		end
	end

	return btn
end

function choicebutton:after_init(ui, t)
	for i,val in ipairs(t.values) do
		local btn = self:create_button(type(val) == 'table' and val.index or i, val)
	end
	if t.selected then
		self:select_button(self:button_by_value(t.selected), false)
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:button{
		id = 'OK',
		parent = win,
		x = 100, y = 100, w = 100,
		text = '&OK',
		default = true,
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		id = 'Disabled',
		parent = win,
		x = 100, y = 150, w = 100,
		text = 'Disabled',
		enabled = false,
		text_align = 'right',
	})

	local b3 = btn(ui, {
		id = 'Cancel',
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
		id = 'CB1',
		parent = win,
		x = 300, y = 100, w = 200,
		label =  {text = 'Check me'},
		checked = true,
		--enabled = false,
	}

	local cb2 = ui:checkbox{
		id = 'CB2',
		parent = win,
		x = 300, y = 140, w = 200,
		label =  {text = 'Check me too'},
		align = 'right',
		--enabled = false,
	}

	local rb1 = ui:radiobutton{
		id = 'RB1',
		parent = win,
		x = 300, y = 180, w = 200,
		label =  {text = 'Radio me'},
		checked = true,
		radio_group = 1,
		--enabled = false,
	}

	local rb2 = ui:radiobutton{
		id = 'RB2',
		parent = win,
		x = 300, y = 220, w = 200,
		label =  {text = 'Radio me too'},
		radio_group = 1,
		align = 'right',
		--enabled = false,
	}

	local cb1 = ui:choicebutton{
		id = 'CHOICE',
		parent = win,
		x = 100, y = 300, w = 400,
		values = {
			'Choose me',
			'No, me!',
			{text = 'Me, me, me!', value = 'val3'},
		},
		selected = 'val3',
	}
	for i,b in ipairs(cb1.layers) do
		if b.isbutton then
			b.id = 'CHOICE'..i
		end
	end

end) end
