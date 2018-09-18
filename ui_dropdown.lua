
--Drop-down widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local dropdown = ui.layer:subclass'dropdown'
ui.dropdown = dropdown

--default metrics

dropdown.w = 180
dropdown.h = 24
dropdown.text_align = 'left'
dropdown.padding_left = 4
dropdown.padding_right = 0

--value property

function dropdown:get_value()
	return self._value
end

function dropdown:set_value(val)
	self._value = val
	self.editbox.text = self:display_value(val)
end

function dropdown:revert()
	self.value = self._initial_value
end

function dropdown:commit()
	self._initial_value = self.value
end

function dropdown:display_value(val)
	return tostring(val)
end

--open/close state

function dropdown:open()
	self:focus(true)
	self.popup:show()
end

function dropdown:close()
	self.popup:hide()
end

function dropdown:cancel()
	self:close()
	self:revert()
end

function dropdown:toggle()
	if self.popup.visible then
		self:cancel()
	else
		self:open()
	end
end

--editable state

function dropdown:get_editable()
	return self.editbox.focusable
end

function dropdown:set_editable(editable)
	self.editbox.focusable = editable
	self.editbox.activable = editable
	self.focusable = not editable
end

dropdown:instance_only'editable'
dropdown.editable = true

--editbox

local editbox = ui.editbox:subclass'dropdown_editbox'
dropdown.editbox_class = editbox

editbox.tags = '-standalone'

function dropdown:create_editbox()
	return self.editbox_class(self.ui, {
		parent = self,
		dropdown = self,
	}, self.editbox)
end

function editbox:after_sync()
	local b = self.dropdown.button
	b:sync()
	self.w = self.dropdown.cw - (b.visible and b.w or 0)
	self.h = self.dropdown.ch
end

function editbox:gotfocus()
	self.dropdown:settag(':focused', true)
end

function editbox:lostfocus()
	self.dropdown:settag(':focused', false)
	self.dropdown:close()
	self.dropdown:revert()
end

function editbox:override_keypress(inherited, key)
	if key == 'enter' then
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
	}, self.button)
end

button.font = 'IonIcons,16'
button.open_text = '\u{f280}'
button.close_text = '\u{f286}'

function button:before_sync()
	self.h = self.dropdown.ch
	self.w = math.floor(self.h * .9)
	self.x = self.dropdown.cw - self.w
	self.text = self.dropdown.isopen and self.close_text or self.open_text
end

--popup window

local popup = ui.popup:subclass'dropdown_popup'
dropdown.popup_class = popup

function dropdown:create_popup()
	local popup = self.popup_class(self.ui, {
		parent = self,
		visible = false,
		dropdown = self,
	})
	return popup
end

function popup:before_shown()
	local picker = self.dropdown.picker
	picker:sync()
	self.x, self.y = self.dropdown:to_content(0, self.dropdown.h)
	self.cw, self.ch = picker.w, picker.h
end

function popup:override_mousedown_autohide(inherited, ...)
	if self.dropdown.hot then
		--prevent autohide to avoid re-opening the popup by the dropdown.
		return
	end
	inherited(self, ...)
end

function popup:after_hidden()
	self.dropdown:close()
	self.dropdown:revert()
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
	self.value = t.value
	self:commit()
end

function dropdown:before_free()
	if not self.popup.dead then
		self.popup:free()
		self.popup = false
	end
end

--keyboard interaction

function dropdown:lostfocus()
	self:cancel()
end

function dropdown:keypress(key)
	if key == 'enter' then
		self:toggle()
	elseif key == 'esc' then
		self:cancel()
	end
end

--mouse interaction

dropdown.mousedown_activate = true

function dropdown:click()
	if self._mousedown_autohidden then
		self._mousedown_autohidden = false
		return
	end
	self:toggle()
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
	}

end) end
