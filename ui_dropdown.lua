
--Drop-down widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local dropdown = ui.layer:subclass'dropdown'
ui.dropdown = dropdown
dropdown.iswidget = true

--default geometry

dropdown.w = 180
dropdown.h = 24
--these must match grid's metrics.
dropdown.text_align = 'left'
dropdown.padding_left = 2
dropdown.padding_right = 0

--value property/state

--allow setting and typing values outside of the picker's range.
dropdown.allow_any_value = false

function dropdown:get_value()
	return self._value
end

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

--open/close state

function dropdown:get_isopen()
	return self.popup.visible
end

function dropdown:open()
	self:focus(true)
	self.popup:show()
end

function dropdown:close()
	self.popup:hide()
end

--editable property

function dropdown:get_editable()
	return self.editbox.focusable
end

function dropdown:set_editable(editable)
	self.editbox.focusable = editable
	self.editbox.activable = editable
	self.focusable = not editable
end

dropdown:instance_only'editable'
dropdown.editable = false

--editbox

local editbox = ui.editbox:subclass'dropdown_editbox'
dropdown.editbox_class = editbox

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

function editbox:text_changed()
	print(self.text)
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

--popup window

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
	self.cw, self.ch = self.dropdown.picker:sync_dropdown()
end

function popup:override_mousedown_autohide(inherited, ...)
	if self.dropdown.hot then
		--prevent autohide to avoid re-opening the popup by the dropdown.
		return
	end
	inherited(self, ...)
end

--value picker widget

dropdown.picker_classname = 'grid'

function dropdown:create_picker()
	local class = self.picker_class or self.ui[self.picker_classname]
	local picker = class(self.ui, {
		parent = self.popup,
		dropdown = self,
	}, self.picker)
	return picker
end

--init & free

dropdown:init_ignore{editable=1, value=1}

function dropdown:after_init(ui, t)
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
dropdown.border_width = 1

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
	border_color = '#ccc',
	shadow_blur = 2,
	shadow_color = '#666',
	background_color = '#080808', --to cover the shadow
})

ui:style('dropdown_button :hot, dropdown_button :focused', {
	text_color = '#fff',
})

button.text_color = '#999'

ui:style('dropdown :hot > dropdown_button, dropdown_button :focused', {
	text_color = '#fff',
})

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local dropdown1 = ui:dropdown{
		x = 10, y = 10,
		parent = win,
		picker = {rows = {'Row 1', 'Row 2', 'Row 3', {}}},
		value = 'some invalid value',
		allow_any_value = true,
	}

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

end) end
