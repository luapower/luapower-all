
--Drop-down widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local dropdown = ui.editbox:subclass'dropdown'
ui.dropdown = dropdown

dropdown.text_editable = false
dropdown.text_selectable = false

function dropdown:after_init(t)
	self.button = self:create_button()
	self.popup = self:create_popup()
	self.picker = self:create_picker()
end

--open/close state -----------------------------------------------------------

function dropdown:get_isopen()
	return self.popup.visible
end

function dropdown:set_isopen(open)
	if open then
		self:open()
	else
		self:close()
	end
end
dropdown:track_changes'isopen'

function dropdown:open()
	self:focus(true)
	self.popup:show()
end

function dropdown:close()
	if not self.popup.dead then
		self.popup:hide()
	end
end

function dropdown:toggle()
	self.isopen = not self.isopen
end

function dropdown:_opened()
	self.button.text = self.button.close_text
	self:fire'opened'
end

function dropdown:_closed()
	self.button.text = self.button.open_text
	self:fire'closed'
end

--keyboard interaction

function dropdown:lostfocus()
	self:close()
end

function dropdown:keypress(key)
	if key == 'enter' and not self.isopen then
		self:open()
		return true
	elseif key == 'esc' then
		self:close()
		return true
	else
		return self.picker:fire('keypress', key)
	end
end

--mouse interaction

dropdown.mousedown_activate = true

function dropdown:click()
	self:toggle()
end

--open/close button ----------------------------------------------------------

local button = ui.layer:subclass'dropdown_button'
dropdown.button_class = button

function dropdown:create_button()
	return self.button_class(self.ui, {
		parent = self,
		dropdown = self,
		iswidget = false,
	}, self.button)
end

button.activable = false

button.font = 'IonIcons,16'
button.open_text = '\u{f280}'
button.close_text = '\u{f286}'
button.text_color = '#aaa'
button.text = button.open_text

ui:style('dropdown :hot > dropdown_button', {
	text_color = '#fff',
})

function dropdown:after_sync_styles()
	self.padding_right = math.floor(self.h * .8)
end

function dropdown:before_sync_layout_children()
	local btn = self.button
	btn.h = self.ch
	btn.x = self.cw
	btn.w = self.pw2
end

--popup window ---------------------------------------------------------------

local popup = ui.popup:subclass'dropdown_popup'
dropdown.popup_class = popup

popup.activable = false

function dropdown:create_popup(ui, t)
	return self.popup_class(self.ui, {
		w = 200, h = 200, --required; sync'ed layer
		parent = self,
		visible = false,
		dropdown = self,
	}, self.popup)
end

function popup:after_init()
	self:frame_rect(0, self.dropdown.h)
end

function popup:shown()
	self.dropdown:_opened()
end

function popup:hidden()
	self.dropdown:_closed()
end

function popup:override_parent_window_mousedown_autohide(inherited, ...)
	if self.dropdown.button.hot or self.dropdown.hot then
		--prevent autohide to avoid re-opening the popup by the dropdown.
		return
	end
	inherited(self, ...)
end

--default value picker -------------------------------------------------------

local list = ui.scrollbox:subclass'dropdown_list'
ui.dropdown_list = list

list.auto_w = true

list.border_color = '#333'
list.padding_left = 1
list.border_width_left = 1
list.border_width_right = 1
list.border_width_bottom = 1

local item = ui.layer:subclass'dropdown_item'
list.item_class = item

item.layout = 'textbox'
item.text_align_x = 'auto'

item.padding_left = 6

ui:style('dropdown_item :hot', {
	background_color = '#222',
})

ui:style('dropdown_item :selected', {
	background_color = '#226',
})

function list:set_options(t)
	if not t then return end
	for i,t in ipairs(t) do
		self.item_class{
			parent = self.content,
			text = t,
			index = i,
			dropdown = self.dropdown,
		}
	end
end

list:init_ignore{options=1}

function list:after_init(t)
	local ct = self.content
	ct.layout = 'flexbox'
	ct.flex_flow = 'y'
	ct.dropdown = self.dropdown
	function ct:mouseup()
		self.active = false
		local item = self.selected_item
		if item then
			self.dropdown:value_picked(item.index, item.text, true)
		end
	end
	function ct:mousemove(mx, my)
		local item = self:hit_test_children(mx, my, 'activate')
		if item and item.index then
			item:select()
		end
	end
	self.options = t.options
end

function dropdown:before_sync_layout_children()
	if self.picker.w ~= self.w then
		self.picker.w = self.w
		self.popup:sync()
		self.picker.ch = math.min(self.picker.content.h, self.w * 1.5)
		self.popup:client_size(self.picker:size())
		self.popup:invalidate()
	end
end

function item:mousedown()
	self.parent.active = true
end

function item:select()
	if self.parent.selected_item then
		self.parent.selected_item:unselect()
	end
	self:make_visible()
	self:settag(':selected', true)
	self.parent.selected_item = self
end

function item:unselect()
	self.parent.selected_item = false
	self:settag(':selected', false)
end

function list:pick_value(val)
	local item = self.content[val]
	if item then
		item:select()
		return true
	end
end

--picker widget --------------------------------------------------------------

dropdown.picker_class = list
dropdown.picker_classname = false --by-name override

function dropdown:create_picker()

	local class =
		self.picker and (self.picker.class or self.picker.classname)
		or self.picker_class
		or self.ui[self.picker_classname]

	local picker = class(self.ui, {
		parent = self.popup,
		dropdown = self,
	}, self.picker)

	return picker
end

function dropdown:value_picked(val, text, close)
	self.text = text or self:display_value(val)
	if close then
		self:close()
	end
end

--allow setting and typing values outside of the picker's range.
dropdown.allow_any_value = false

dropdown:init_ignore{value=1}

function dropdown:after_init(t)
	self.value = t.value
end

function dropdown:value_changing(val)
	return self.picker:pick_value(val) or self.allow_any_value
end

function dropdown:validate_value(val)

--if self.allow_any_value then
--	self:value_picked(val, nil, true)
--end


--[==[

--value property/state

--called by the picker to signal that a value was picked.
function dropdown:value_picked(val, text, close)
	self._value = val
	self.editbox.text = text or self:display_value(val)
	self.editbox:invalidate()
	if close then
		self:close()
	end
end

editbox.tags = '-standalone'

function dropdown:create_editbox()
	return self.editbox_class(self.ui, {
		parent = self,
		dropdown = self,
		iswidget = false,
	}, self.editbox)
end

function editbox:sync_dropdown()
	local b = self.dropdown.button
	self.w = self.dropdown.cw - (b.visible and b.w or 0)
	self.h = self.dropdown.ch
end

function editbox:gotfocus()
	self.dropdown:settag(':focused', true)
end

function editbox:lostfocus()
	self.dropdown:settag(':focused', false)
	self.dropdown:close()
end

--keys that we steal from the editbox and forward to the dropdown.
local fw_keys = {enter=1, esc=1, up=1, down=1}

function editbox:override_keypress(inherited, key)
	if fw_keys[key] then
		return self.dropdown:keypress(key)
	end
	return inherited(self, key)
end

--open/close button

local button = ui.layer:subclass'dropdown_button'
dropdown.button_class = button

button.activable = false

function dropdown:create_button()
	return self.button_class(self.ui, {
		parent = self,
		dropdown = self,
		iswidget = false,
	}, self.button)
end

button.font = 'IonIcons,16'
button.open_text = '\u{f280}'
button.close_text = '\u{f286}'

function button:sync_dropdown()
	self.h = self.dropdown.ch
	self.w = math.floor(self.h * .9)
	self.x = self.dropdown.cw - self.w
	self.text = self.dropdown.isopen and self.close_text or self.open_text
end

--init & free

dropdown:init_ignore{editable=1, value=1}

function dropdown:after_init(t)
	self.editbox = self:create_editbox()
	self.button = self:create_button()
	self.popup = self:create_popup()
	self.picker = self:create_picker()
	self.editable = t.editable
	self.picker:focus() --picks the first value from the picker!
	self.picker:sync_dropdown() --sync to dropdown so that scroll works.
	self.value = t.value
end

function dropdown:before_free()
	if not self.popup.dead then
		self.popup:free()
		self.popup = false
	end
end

--sync'ing

function dropdown:after_sync()
	self.button:sync_dropdown()
	self.editbox:sync_dropdown()
end

--state styles

dropdown.border_color = '#333'
dropdown.border_width_bottom = 1

ui:style('dropdown', {
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('dropdown :hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('dropdown :focused', {
	border_color = '#fff',
})

ui:style('dropdown_button :hot, dropdown_button :focused', {
	text_color = '#fff',
})

button.text_color = '#999'

ui:style('dropdown :hot > dropdown_button, dropdown_button :focused', {
	text_color = '#fff',
})

]==]

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.x = 500
	win.w = 300
	win.h = 900

	local dropdown1 = ui:dropdown{
		x = 10, y = 10,
		parent = win,
		picker = {
			options = {
				'Apples', 'Oranges', 'Bananas',
				'Burgers', 'Cheese', 'Fries',
				'Peppers', 'Onions', 'Olives',
				'Pumpkins', 'Eggplants', 'Cauliflower',
				'Butter', 'Coconut Oil', 'Olive Oil', 'Sunflower Oil',
				'Zucchinis', 'Squash',
				'Lettuce', 'Spinach',
				'I\'m hungry',
			}
		},
		--picker = {rows = {'Row 1', 'Row 2', 'Row 3', {}}},
		--value = 'some invalid value',
		value = 5,
		allow_any_value = true,
	}

	--[[
	local t = {}
	for i = 1, 10000 do
		t[i] = 'Row '..i
	end
	local dropdown2 = ui:dropdown{
		x = 10 + dropdown1.w + 10, y = 10,
		parent = win,
		picker = {rows = t},
		value = 'Row 592',
		editable = true,
	}
	]]

end) end
