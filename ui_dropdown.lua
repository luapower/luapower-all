
--Drop-down widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local dropdown = ui.editbox:subclass'dropdown'
ui.dropdown = dropdown

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
	self.popup:sync()
	self.popup:client_size(self.picker:size())
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

button.font = 'IonIcons,16'
button.open_text = '\u{f280}'
button.close_text = '\u{f286}'
button.text_color = '#aaa'
button.text = button.open_text

ui:style('dropdown_button :hot', {
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

function dropdown:_opened()
	self.button.text = self.button.close_text
	self:fire'popup_opened'
end

function dropdown:_closed()
	self.button.text = self.button.open_text
	self:fire'popup_closed'
end

button.activable = true

function button:click()
	self.dropdown:toggle()
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

function popup:before_shown()
	self.x, self.y = self.dropdown:to_content(0, self.dropdown.h)
end

function popup:after_shown()
	self.dropdown:_opened()
end

function popup:after_hidden()
	self.dropdown:_closed()
end

function popup:override_parent_window_mousedown_autohide(inherited, ...)
	if self.dropdown.button.hot then
		--prevent autohide to avoid re-opening the popup by the dropdown.
		return
	end
	inherited(self, ...)
end

--default value picker -------------------------------------------------------

local list = ui.layer:subclass'dropdown_list'
ui.dropdown_list = list

list.w = 200
list.h = 300
list.background_color = '#f00'

function list:sync_dropdown()
	--sync styles first because we use self's paddings.
	self:sync_styles()

	local w = self.dropdown.w
	local noscroll_ch = self.rows_h
	local max_ch = w * 1.4
	local ch = math.min(noscroll_ch, max_ch)
	self.w, self.ch = w, ch

	self:sync_layout() --sync so that vscrollbar is synced so that scroll works.
	self:move'@focus scroll/instant'

	return self.w, self.h
end

--picker widget --------------------------------------------------------------

dropdown.picker_class = list
dropdown.picker_classname = false --by-name override

function dropdown:create_picker()
	local class = self.picker_class or self.ui[self.picker_classname]
	local picker = class(self.ui, {
		parent = self.popup,
		dropdown = self,
	}, self.picker)
	return picker
end


--[==[

--value property/state

--allow setting and typing values outside of the picker's range.
dropdown.allow_any_value = false

--display value for free-edited values where the picker is not involved.
function dropdown:display_value(val)
	if type(val) == 'nil' or type(val) == 'boolean' then
		return string.format('<%s>', tostring(val))
	end
	return tostring(val)
end

function dropdown:set_value(val)
	if not self.picker:pick_value(val, true) then
		if self.allow_any_value then
			self:value_picked(val, nil, true)
		end
	end
end

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
	if self._mousedown_autohidden then
		self._mousedown_autohidden = false
		return
	end
	if self.isopen then
		self:close()
	else
		self:open()
	end
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
		options = {'Apples', 'Oranges', 'Bannanas'},
		--picker = {rows = {'Row 1', 'Row 2', 'Row 3', {}}},
		value = 'some invalid value',
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
