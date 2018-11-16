
--Button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local lerp = glue.lerp

local button = ui.layer:subclass'button'
ui.button = button
button.iswidget = true
button.focusable = true

button.layout = 'textbox'
button.min_ch = 20
button.align_y = 'center'
button.padding_left = 8
button.padding_right = 8
button.padding_top = 2
button.padding_bottom = 2

button.background_color = '#444'
button.border_color = '#888'

button.default = false
button.cancel = false
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

ui:style('button !:enabled', {
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

--button style profiles

button.profile = false

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

button:stored_property'profile'
function button:set_profile(new_profile, old_profile)
	if old_profile then self:settag('profile='..old_profile, false) end
	if new_profile then self:settag('profile='..new_profile, true) end
end
button:nochange_barrier'profile' --gives `old_profile` arg

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

button:stored_property'key'
function button:after_set_key(key)
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

button:stored_property'default'
function button:after_set_default(default)
	self:settag(':default', default)
end

button:stored_property'cancel'
function button:after_set_cancel(cancel)
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
	if not self:text_visible() then return end
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

checkbox.layout = 'flexbox'
checkbox.min_ch = 16
checkbox.align_cross = 'top'
checkbox.align_lines = 'center'

--checked property

checkbox:stored_property'checked'
function checkbox:after_set_checked(checked)
	self:settag(':checked', checked)
	self:fire(checked and 'was_checked' or 'was_unchecked')
end
checkbox:track_changes'checked'
checkbox:instance_only'checked'

function checkbox:toggle()
	self.checked = not self.checked
end

--align property

checkbox.align = 'left'

checkbox:stored_property'align'
function checkbox:after_set_align(align)
	if align == 'right' then
		self.button:to_front()
	else
		self.button:to_back()
	end
end
checkbox:instance_only'align'

--check button

local cbutton = ui.button:subclass'checkbox_button'
checkbox.button_class = cbutton

cbutton.font = 'Ionicons,16'
cbutton.text_checked = '\u{f2bc}'

cbutton.fr = 0
cbutton.min_cw = 20
cbutton.padding_top = 0
cbutton.padding_bottom = 0
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

--label

local clabel = ui.layer:subclass'checkbox_label'
checkbox.label_class = clabel

clabel.layout = 'textbox'

function clabel:hit_test(mx, my, reason) end --cbutton does it for us

function clabel:after_sync()
	local align = self.checkbox.align
	self.text_align_x = align
	local padding = self.checkbox.button.h / 2
	self.padding_left = align == 'left' and padding or 0
	self.padding_right = align == 'right' and padding or 0
end

function checkbox:create_label()
	return self.label_class(self.ui, {
		parent = self,
		checkbox = self,
		iswidget = false,
	}, self.label)
end

checkbox:init_ignore{align=1}

function checkbox:after_init(ui, t)
	self.button = self:create_button()
	self.label = self:create_label()
	self.align = t.align
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
	self.checkbox.checked = true
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

choicebutton.layout = 'flexbox'
choicebutton.align_cross = 'center'

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
	for i,btn in ipairs(self) do
		if btn.choicebutton == self and selects(btn) then
			return btn
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

function choicebutton:sync_layout_for_button(b)
	local r = self.button_corner_radius
	b.corner_radius_top_left = b.index == 1 and r or 0
	b.corner_radius_bottom_left = b.index == 1 and r or 0
	b.corner_radius_top_right = b.index == #self.values and r or 0
	b.corner_radius_bottom_right = b.index == #self.values and r or 0
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

	function btn:after_sync()
		self.choicebutton:sync_layout_for_button(self)
	end

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
		x = 100, y = 100, min_cw = 120,
		text = '&OK',
		default = true,
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		id = 'Disabled',
		parent = win,
		x = 100, y = 150,
		text = 'Disabled',
		enabled = false,
		text_align_x = 'right',
	})

	local b3 = btn(ui, {
		id = 'Cancel',
		parent = win,
		x = 100, y = 200,
		text = '&Cancel',
		cancel = true,
		text_align_x = 'left',
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
		x = 300, y = 100, min_cw = 200,
		label =  {text = 'Check me.\nI\'m multiline.'},
		checked = true,
		--enabled = false,
	}

	local cb2 = ui:checkbox{
		id = 'CB2',
		parent = win,
		x = 300, y = 140,
		label =  {text = 'Check me too', nowrap = true},
		align = 'right',
		--enabled = false,
	}

	local rb1 = ui:radiobutton{
		id = 'RB1',
		parent = win,
		x = 300, y = 180,
		label =  {text = 'Radio me', nowrap = true},
		checked = true,
		radio_group = 1,
		--enabled = false,
	}

	local rb2 = ui:radiobutton{
		id = 'RB2',
		parent = win,
		x = 300, y = 220,
		label =  {text = 'Radio me too', nowrap = true},
		radio_group = 1,
		align = 'right',
		--enabled = false,
	}

	local cb1 = ui:choicebutton{
		id = 'CHOICE',
		parent = win,
		x = 100, y = 300, min_cw = 400,
		values = {
			'Choose me',
			'No, me!',
			{text = 'Me, me, me!', value = 'val3'},
		},
		selected = 'val3',
	}
	for i,b in ipairs(cb1) do
		if b.isbutton then
			b.id = 'CHOICE'..i
		end
	end

end) end
