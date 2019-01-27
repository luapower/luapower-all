--go@ luajit -jp=fi1m1 ui_dropdown.lua
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'

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
	self.picker:fire'opened'
	self:fire'opened'
end

function dropdown:_closed()
	self.button.text = self.button.open_text
	self.picker:fire'closed'
	self:fire'closed'
end

--keyboard interaction

function dropdown:lostfocus()
	self:close()
end

function dropdown:keydown(key)
	return self.picker:fire('keydown', key)
end

function dropdown:keyup(key)
	if key == 'esc' and self.isopen then
		self:close()
		return true
	end
	return self.picker:fire('keyup', key)
end

function dropdown:keypress(key)
	if key == 'enter' and not self.isopen then
		self:open()
		return true
	end
	return self.picker:fire('keypress', key)
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
	--TODO: bug: parent window does not repaint synchronously after child is closed.
	self.ui:runafter(0, function()
		self.dropdown:_closed()
	end)
end

function popup:override_parent_window_mousedown_autohide(inherited, ...)
	if self.dropdown.button.hot or self.dropdown.hot then
		--prevent autohide to avoid re-opening the popup by the dropdown.
		return
	end
	inherited(self, ...)
end

--list picker widget ---------------------------------------------------------

local list = ui.scrollbox:subclass'dropdown_list'
ui.dropdown_list = list

list.auto_w = true
list.vscrollbar = {autohide_empty = false}

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

--init

function list:create_item(i, t)
	local value = type(t) == 'string' and i or t.value
	local text = type(t) == 'string' and t or t.text or value
	local t = type(t) == 'table' and t or nil
	local item = self.item_class({
		parent = self.content,
		text = text,
		index = i,
		item_value = value,
		picker = self,
		dropdown = self.dropdown,
		select = self.item_select,
		unselect = self.item_unselect,
	}, t)
	item:inherit()
	self.by_value[value] = i
	item:on('mousedown', self.item_mousedown)
	return item
end
local time = require'time'
function list:set_options(t)
	if not t then return end
	self.by_value = {} --{value -> item_index}
	local t0 = time.clock()
	for i,t in ipairs(t) do
		self:create_item(i, t)
	end
	print((time.clock() - t0) * 1000)
end

list:init_ignore{options=1}

function list:after_init(t)
	local ct = self.content
	ct.layout = 'flexbox'
	ct.flex_flow = 'y'
	ct.dropdown = self.dropdown
	ct.picker = self
	function ct:mouseup()
		self.active = false
		local item = self.picker.selected_item
		if item then
			self.dropdown.value = item.item_value
			self.dropdown:close()
		end
	end
	function ct:mousemove(mx, my)
		local item = self:hit_test_children(mx, my, 'activate')
		if item and item.item_value then
			item:select()
		end
	end
	self.options = t.options
end

--sync'ing

function dropdown:before_sync_layout_children()
	if self.picker.w ~= self.w then
		self.picker.w = self.w
		self.popup:sync()
		self.picker.ch = math.min(self.picker.content.h, self.w * 1.5)
		self.popup:client_size(self.picker:size())
		self.popup:invalidate()
	end
end

--item selection

function list.item_select(self) --self is the item!
	local sel_item = self.picker.selected_item
	if sel_item == self then return end
	if sel_item then
		sel_item:unselect()
	end
	self:make_visible()
	self:settag(':selected', true)
	self.picker.selected_item = self
end

function list.item_unselect(self) --self is the item!
	self.picker.selected_item = false
	self:settag(':selected', false)
end

--mouse interaction

function list.item_mousedown(self) --self is the item!
	self.parent.active = true
end

--keyboard interaction

function list:next_page_item(from_item, pages)
	local ct = self.content
	local last_index = pages > 0 and #ct or 1
	local step = pages > 0 and 1 or -1
	local h = self.view.ch
	local y = 0
	local from_index = from_item and from_item.index or last_index
	for i = from_index, last_index, step do
		y = y + ct[i].h
		if y > h then
			return ct[i]
		end
	end
	return ct[last_index]
end

function list:keypress(key)
	if key == 'up' or key == 'down'
		or key == 'pageup' or key == 'pagedown'
		or key == 'home' or key == 'end'
		or key == 'enter'
	then
		local hot_item = self.ui.hot_widget
		local item = self.selected_item
			or (hot_item and hot_item.picker and hot_item.index and hot_item)
		local ct = self.content
		if key == 'down' then
			if not item then
				item = ct[1]
			else
				item = ct[item.index + 1]
			end
		elseif key == 'up' then
			item = item and ct[item.index - 1] or ct[1]
		elseif key:find'page' then
			item = self:next_page_item(item, key == 'pagedown' and 1 or -1)
		elseif key == 'home' then
			item = ct[1]
		elseif key == 'end' then
			item = ct[#ct]
		end
		if item then
			item:select()
			if key == 'enter' or not self.dropdown.isopen then
				self.dropdown.value = item.item_value
				self.dropdown:close()
			end
			return true
		end
	end
end

--dropdown interface

function list:pick_value(value)
	local index = self.by_value[value]
	if not index then return end
	local item = self.content[index]
	item:select()
	return true, index
end

function list:picked_value_text()
	local item = self.selected_item
	return item and item.text
end

function list:opened()
	if self.selected_item then
		self.selected_item:make_visible()
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

--data binding ---------------------------------------------------------------

--allow setting and typing values outside of the picker's range.
dropdown.allow_any_value = false

dropdown:init_ignore{value=1}

function dropdown:after_init(t)
	self.value = t.value
end

function dropdown:value_changed(val)
	self.text = self.picker:picked_value_text() or self:value_text(val)
end

function dropdown:validate_value(val, old_val)
	local picked, picked_val = self.picker:pick_value(val)
	if picked then
		return picked_val
	elseif self.allow_any_value then
		return val
	else
		return old_val
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.x = 500
	win.w = 300
	win.h = 900

	--[[
	local dropdown1 = ui:dropdown{
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
		value = 20,
		--value = 'Some invalid value',
		allow_any_value = true,
	}
	]]

	local t = {}
	for i = 1, 1000 do
		t[i] = 'Row' --'Row '..i
	end
	local dropdown2 = ui:dropdown{
		parent = win,
		picker = {options = t},
		value = 2,
	}

	function win:after_sync()
		self:invalidate()
	end

end) end
