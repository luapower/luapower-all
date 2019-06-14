
--Button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local button = ui.layer:subclass'button'
ui.button = button
button.iswidget = true
button.focusable = true

button.layout = 'textbox'
button.min_ch = 20
button.align_x = 'start'
button.align_y = 'center'
button.padding_left = 8
button.padding_right = 8
button.padding_top = 2
button.padding_bottom = 2
button.line_spacing = .9

button.background_color = '#444'
button.border_color = '#888'

button.default = false
button.cancel = false
button.tags = 'standalone'

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration_background_color = .5,
	transition_duration_border_color = .5,
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

function button:override_set_text(inherited, s)
	if not inherited(self, s) then return end
	if s == '' or not s then s = false end
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
			if not self.ui then --window closed
				return true
			end
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
checkbox.item_align_y = 'baseline'
checkbox.align_items_y = 'center'
checkbox.align_y = 'center'

--checked property

checkbox.checked = false
checkbox:stored_property'checked'
function checkbox:after_set_checked(checked)
	self.button.text = self.checked
		and self.button.text_checked
		or self.button.text_unchecked
	self:settag(':checked', checked)
	self:fire(checked and 'was_checked' or 'was_unchecked')
end
function checkbox:override_set_checked(inherited, checked)
	if self:canset_checked(checked) then
		return inherited(self, checked)
	end
end
checkbox:track_changes'checked'

function checkbox:canset_checked(checked)
	return
		self:fire(checked and 'checking' or 'unchecking') ~= false
		and self:fire('value_changing', self:value_for(checked), self.value) ~= false
end

function checkbox:toggle()
	self.checked = not self.checked
end

--value property

checkbox.checked_value = true
checkbox.unchecked_value = false

function checkbox:value_for(checked)
	if checked then
		return self.checked_value
	else
		return self.unchecked_value
	end
end

function checkbox:checked_for(val)
	return val == self.checked_value
end

function checkbox:get_value()
	return self:value_for(self.checked)
end

function checkbox:set_value(val)
	self.checked = self:checked_for(val)
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

--check button

local cbutton = ui.button:subclass'checkbox_button'
checkbox.button_class = cbutton

cbutton.font = 'Ionicons,16'
cbutton.text_checked = '\u{f2bc}'
cbutton.text_unchecked = ''

cbutton.align_y = false
cbutton.fr = 0
cbutton.layout = false
cbutton.min_cw = 16
cbutton.min_ch = 16
cbutton.padding_top = 0
cbutton.padding_bottom = 0
cbutton.padding_left = 0
cbutton.padding_right = 0

ui:style('checkbox_button :hot', {
	text_color = '#fff',
	background_color = '#777',
})

ui:style('checkbox_button :active :over', {
	background_color = '#888',
})

function cbutton:override_hit_test(inherited, mx, my, reason)
	local widget, area = inherited(self, mx, my, reason)
	if not widget then
		self:validate()
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
clabel.line_spacing = .6

function clabel:override_hit_test(inherited, mx, my, reason)
	local widget, area = inherited(self, mx, my, reason)
	if widget then
		return self.checkbox.button, area
	end
end

function clabel:after_sync_styles()
	local align = self.checkbox.align
	self.text_align_x = align
	local padding = self.checkbox.button.min_ch / 2
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

checkbox:init_ignore{align=1, checked=1}

function checkbox:after_init(t)
	self.button = self:create_button()
	self.label = self:create_label()
	self.align = t.align
	self.button:settag('standalone', false)
	self._checked = t --force setting of checked property
	self.checked = t.checked
end

--radio button ---------------------------------------------------------------

local radio = ui.checkbox:subclass'radio'
ui.radio = radio

radio.radio_group = 'default'
radio.item_align_y = 'center'

radio:init_ignore{checked=1}

function radio:override_canset_checked(inherited, checked)
	if not inherited(self, checked) then --refused
		return
	end
	if not checked then
		return true
	end
	--find the first radio button with the same group and uncheck it.
	local unchecked = self.window.view:each_child(function(rb)
		if rb.isradio
			and rb ~= self
			and rb.radio_group == self.radio_group
			and rb.checked
		then
			rb.checked = false
			return not rb.checked --unchecking allowed or refused
		end
	end)
	if unchecked == nil then --none found to uncheck
		unchecked = true
	end
	return unchecked
end

local rbutton = ui.checkbox.button_class:subclass'radio_button'
radio.button_class = rbutton

rbutton.padding_left = 0
rbutton.padding_right = 0

function rbutton:after_sync_styles()
	self.corner_radius = self.w
end

function rbutton:draw_text() end

rbutton.circle_radius = 0

ui:style('radio_button', {
	transition_circle_radius = true,
	transition_duration_circle_radius = .2,
})

ui:style('radio :checked > radio_button', {
	circle_radius = .45,
	transition_duration_circle_radius = .2,
})

function rbutton:before_draw_content(cr)
	local r = glue.lerp(self.circle_radius, 0, 1, 0, self.cw / 2)
	if r <= 0 then return end
	cr:circle(self.cw / 2, self.ch / 2, r)
	cr:rgba(self.ui:rgba(self.text_color))
	cr:fill()
end

function rbutton:checkbox_press()
	self.checkbox.checked = true
end

--radio button list ----------------------------------------------------------

local rblist = ui.layer:subclass'radio_list'
ui.radiolist = rblist

--config
rblist.radio_class = ui.radio
rblist.align_x = 'stretch'
rblist.layout = 'flexbox'
rblist.flex_flow = 'y'

--features
rblist.option_list = false --{{value=, text=}, ...}
rblist.options = false --{value->text}
rblist.none_checked_value = false

--value property

function rblist:get_checked_button()
	return self.radios[self.value]
end

function rblist:set_value(val)
	local rb = self.radios[val]
	if rb then
		rb.checked = true
	else
		if self.checked_button then
			self.checked_button.checked = false
		end
	end
end
rblist:track_changes'value'

--init

rblist:init_ignore{options=1, value=1}

function rblist:create_radio(index, value, text, radio)
	local rb = self:radio_class({
		iswidget = false,
		checked_value = value,
		button = glue.update({
			tabgroup = self.tabgroup or self,
			tabindex = index,
		}),
		label = glue.update({
			text = text,
		}),
		radio_group = self,
	}, self.radio, radio)

	self.radios[value] = rb

	rb:on('checked_changed', function(rb, checked)
		if checked then
			self._value = rb.value
		else
			self._value = self.none_checked_value
		end
	end)
end

function rblist:after_init(t)
	self.radios = {} --{value -> button}
	if t.option_list then
		for i,v in ipairs(t.option_list) do
			local value, text, radio
			if type(v) == 'table' then
				value = v.value
				text = v.text
				radio = v.radio
			else
				value = v
				text = v
			end
			self:create_radio(i, value, text, radio)
		end
	end
	if t.options then
		local i = 1
		for value, text in glue.sortedpairs(t.options) do
			self:create_radio(i, value, text)
			i = i + 1
		end
	end
	if t.value ~= nil then
		self.value = t.value
	else
		self.value = self.none_checked_value
	end
end

--multi-choice button --------------------------------------------------------

local choicebutton = ui.layer:subclass'choicebutton'
ui.choicebutton = choicebutton

choicebutton.layout = 'flexbox'
choicebutton.align_items_y = 'center'

--model

choicebutton.option_list = {} --{{index=, text=, value=, ...}, ...}

function choicebutton:get_value()
	local btn = self.selected_button
	return btn and btn.choicebutton_value
end

function choicebutton:set_value(value)
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
	return self:find_button(function(btn) return btn.choicebutton_value == value end)
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
	self:fire('value_changed', btn.choicebutton_value)
end

--drawing

choicebutton.button_corner_radius = 0

function choicebutton:sync_layout_for_button(b)
	local r = self.button_corner_radius
	b.corner_radius_top_left = b.index == 1 and r or 0
	b.corner_radius_bottom_left = b.index == 1 and r or 0
	b.corner_radius_top_right = b.index == #self.option_list and r or 0
	b.corner_radius_bottom_right = b.index == #self.option_list and r or 0
end

--init

choicebutton.button_class = ui.button

choicebutton:init_ignore{value=1}

function choicebutton:create_button(index, value)

	local btn = self:button_class({
		tags = 'choicebutton_button',
		choicebutton = self,
		parent = self,
		iswidget = false,
		index = index,
		text = type(value) == 'table' and value.text or value,
		choicebutton_value = type(value) == 'table' and value.value or value,
		align_x = 'stretch',
	}, self.button, type(value) == 'table' and value.button or nil)

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

function choicebutton:after_init(t)
	for i,v in ipairs(t.option_list) do
		local btn = self:create_button(type(v) == 'table' and v.index or i, v)
	end
	if t.value ~= nil then
		self:select_button(self:button_by_value(t.value), false)
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.view.grid_wrap = 10
	win.view.grid_flow = 'y'
	win.view.item_align_x = 'left'
	win.view.grid_min_lines = 2

	local b1 = ui:button{
		id = 'OK',
		parent = win,
		min_cw = 120,
		text = '&OK',
		default = true,
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		id = 'Disabled',
		parent = win,
		text = 'Disabled',
		enabled = false,
		text_align_x = 'right',
	})

	local b3 = btn(ui, {
		id = 'Cancel',
		parent = win,
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
		min_cw = 200,
		label =  {text = 'Check me.\nI\'m multiline.'},
		checked = true,
		--enabled = false,
	}

	local cb2 = ui:checkbox{
		id = 'CB2',
		parent = win,
		label =  {text = 'Check me too', nowrap = true},
		align = 'right',
		--enabled = false,
	}

	local rb1 = ui:radio{
		id = 'RB1',
		parent = win,
		label =  {text = 'Radio me', nowrap = true},
		checked = true,
		radio_group = 1,
		--enabled = false,
	}

	local rb2 = ui:radio{
		id = 'RB2',
		parent = win,
		label =  {text = 'Radio me too', nowrap = true},
		radio_group = 1,
		align = 'right',
		--enabled = false,
	}

	ui.radiolist{
		parent = win,
		option_list = {
			'Option 1',
			'Option 2',
			'Option 3',
		},
		value = 'Option 2',
	}

	local cb1 = ui:choicebutton{
		id = 'CHOICE',
		parent = win,
		min_cw = 400,
		option_list = {
			'Choose me',
			'No, me!',
			{text = 'Me, me, me!', value = 'val3'},
		},
		value = 'val3',
	}
	for i,b in ipairs(cb1) do
		if b.isbutton then
			b.id = 'CHOICE'..i
		end
	end

end) end
