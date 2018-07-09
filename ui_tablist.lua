
--ui tab and tablist widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local indexof = glue.indexof
local clamp = glue.clamp

--tab ------------------------------------------------------------------------

local tab = ui.layer:subclass'tab'
ui.tab = tab

--tablist property

tab.tablist = false
tab:stored_property'tablist'
function tab:before_set_tablist()
	if self.tablist then
		self.tablist:_remove_tab(self)
		self.parent = false
	end
end
function tab:after_set_tablist()
	if self.tablist then
		self.parent = self.tablist
		self.tablist:_add_tab(self, self._index)
		self.selected = self._selected
	end
end
tab:nochange_barrier'tablist'

--index property

tab._index = 1/0 --add to the tablist tail

function tab:get_index()
	return self.tablist and self.tablist:tab_index(self) or self._index
end

function tab:set_index(index)
	if self.tablist then
		self.tablist:_move_tab(self, index)
	else
		self._index = index
	end
end

--visible state
--reason: we need to select the previous tab after hiding a tab.

tab._visible = tab.visible

function tab:get_visible(visible)
	return self._visible
end

function tab:set_visible(visible)
	local select_tab
	if not visible and self.tablist and self.selected then
		select_tab = self.tablist:prev_tab(self)
	elseif visible and self.tablist then
		select_tab = self
	end
	self._visible = visible
	if select_tab then
		select_tab:select()
	end
	if self.tablist then
		self.tablist:sync()
	end
end
tab:nochange_barrier'visible'

--close() method
--reason: decoupling visibility from closing, semantically.

function tab:close()
	if not self.closeable then return end
	if self:fire'closing' ~= false then
		self.visible = false
		self:fire'closed'
	end
end

--selected property

tab._selected = false

function tab:get_selected()
	if self.tablist then
		return self.tablist.selected_tab == self
	else
		return self._selected
	end
end

function tab:set_selected(selected)
	if selected then
		self:select()
	else
		self:unselect()
	end
end

function tab:select()
	if not (self.tablist and self.visible and self.enabled) then
		self._selected = true
		return
	end
	local stab = self.tablist.selected_tab
	if stab == self then return end
	if stab then
		stab:unselect()
	end
	self:settag(':selected', true)
	self:to_front()
	self:fire'tab_selected'
	self.parent:fire('tab_selected', self)
	self.tablist._selected_tab = self
end

function tab:unselect()
	if not self.tablist then
		self._selected = false
		return
	end
	local stab = self.tablist.selected_tab
	if stab ~= self then return end
	stab:settag(':selected', false)
	stab:fire'tab_unselected'
	self.tablist:fire('tab_unselected', stab)
	self.tablist._selected_tab = false
end

--init

tab:init_ignore{tablist=1, visible=1, selected=1}

function tab:after_init(ui, t)
	if t.tablist then
		self.tablist = t.tablist
	end
	self.visible = t.visible
	self.selected = t.selected
end

function tab:before_free()
	self.tablist = false
end

--input / mouse / drag & drop

tab.mousedown_activate = true

function tab:activated()
	self:select()
end

function tab:deactivated()
	self.tablist:sync()
end

function tab:start_drag()
	if not self.tablist then return end
	self.origin_tablist = self.tablist
	return self
end

function tab:drag(dx, dy)
	local x = self.x + dx
	local y = self.y + dy
	if self.tablist then
		local vi = self.tablist:visual_index_by_pos(x)
		self.index = self.tablist:tab_index_by_visual_index(vi)
		self:transition('x', self.tablist:clamp_tab_pos(x), 0)
		self:transition('y', 0, 0)
	else
		self:transition('x', x, 0)
		self:transition('y', y, 0)
	end
end

function tab:enter_drop_target(tablist)
	self.tablist = tablist
end

function tab:leave_drop_target(tablist)
	self.tablist = false
	self.parent = tablist.window.view
	self:to_front()
end

function tab:ended_dragging()
	if self.origin_tablist then
		self.tablist = self.origin_tablist
		self.origin_tablist = false
	end
end

--input / mouse / close-on-doubleclick

tab.max_click_chain = 2

function tab:doubleclick()
	self:close()
end

--input / keyboard

tab.focusable = true

function tab:keypress(key)
	if key == 'enter' or key == 'space' then
		self:select()
		return true
	elseif key == 'left' or key == 'right' then
		local next_tab = self.tablist:next_tab(self,
			key == 'right' and 'next_index' or 'prev_index')
		if next_tab then
			next_tab:focus()
		end
		return true
	end
end

--drawing

tab.clip_content = true
tab.border_width = 1
tab.border_color = '#222'
tab.background_color = '#111'
tab.text_align = 'left'
tab.padding_left = 15
tab.padding_right = 12

ui:style('tab', {
	transition_x = true,
	transition_duration_x = .2,
})

ui:style('tab :focused', {
	font_weight = 'bold',
})

ui:style('tab :hot', {
	background_color = '#181818',
	transition_background_color = true,
	transition_duration = .2,
})

ui:style('tab :selected', {
	background_color = '#222',
	border_color = '#333',
	transition_duration = 0,
})

--NYI: border width ~= 1, diff. border colors per side, rounded corners,
--border offset, shadows (needs border offset).
function tab:border_path(cr)
	local tablist = self.tablist or self.origin_tablist
	local w, h = self.w, self.h
	local sl = tablist.tab_slant_left
	local sr = tablist.tab_slant_right
	local wl = h / math.tan(math.rad(sl))
	local wr = h / math.tan(math.rad(sr))
	local x1 = wl
	local x2 = w - wr
	local x3 = w
	local x4 = 0
	local y1 = 0
	local y2 = 0
	local y3 = h
	local y4 = h
	cr:new_path()
	cr:move_to(x4 + .5, y4 - .5)
	cr:line_to(x1 + .5, y1 + .5)
	cr:line_to(x2 - .5, y2 + .5)
	cr:line_to(x3 - .5, y3 - .5)
end

function tab:draw_border(cr)
	if not self:border_visible() then return end
	cr:operator'over'
	cr:new_path()
	self:border_path(cr)
	cr:line_width(self.border_width_left)
	cr:rgba(self.ui:color(self.border_color_left))
	cr:stroke()
end

function tab:before_draw()
	self:sync()
end

--close button

tab.closeable = true --show close button and receive 'closing' event

local xbutton = ui.button:subclass'tab_close_button'
tab.close_button_class = xbutton

xbutton.font_family = 'Ionicons'
xbutton.text = '\xEF\x8B\x80'
xbutton.text_size = 13
xbutton.w = 14
xbutton.h = 14
xbutton.corner_radius = 10
xbutton.corner_radius_kappa = 1
xbutton.padding = 0
xbutton.focusable = false
xbutton.border_width = 0
xbutton.background_color = false
xbutton.text_color = '#999'

ui:style('tab_close_button, tab_close_button :hot, tab_close_button :disabled', {
	background_color = false,
	transition_background_color = false,
})

ui:style('tab_close_button :hot', {
	text_color = '#ddd',
	background_color = '#a00',
})

ui:style('tab_close_button :over', {
	text_color = '#fff',
})

function xbutton:pressed()
	self.tab:close()
end

function tab:create_close_button(button)
	return self.close_button_class(self.ui, {
		parent = self,
		tab = self,
	}, self.close_button, button)
end

function tab:after_init()
	self.close_button = self:create_close_button()
end

function tab:after_sync()
	local xb = self.close_button
	xb.x = self.cw - self.close_button.w
	xb.cy = math.ceil(self.ch / 2)
	xb.visible = self.closeable
end

--tablist --------------------------------------------------------------------

local tablist = ui.layer:subclass'tablist'
ui.tablist = tablist

--tabs list

function tablist:tab_index(tab)
	return indexof(tab, self.tabs)
end

function tablist:clamped_tab_index(index, add)
	return clamp(index, 1, math.max(1, #self.tabs + (add and 1 or 0)))
end

function tablist:_add_tab(tab, index)
	index = self:clamped_tab_index(index, true)
	table.insert(self.tabs, index, tab)
	self:sync()
end

function tablist:_remove_tab(tab)
	local select_tab = tab.visible and tab.selected and self:prev_tab(tab)
	tab.selected = false
	table.remove(self.tabs, self:tab_index(tab))
	if select_tab then
		select_tab.selected = true
	end
	self:sync()
end

function ui.layer:_move_tab(tab, index)
	local old_index = self:tab_index(tab)
	local new_index = self:clamped_tab_index(index)
	if old_index ~= new_index then
		table.remove(self.tabs, old_index)
		table.insert(self.tabs, new_index, tab)
		self:sync()
	end
end

function tablist:tab(tab)
	if not tab.istab then
		local class = tab.class or self.ui.tab
		assert(class.istab)
		tab = class(self.ui, self[class], tab, {tablist = self})
	end
	return tab
end

tablist:init_ignore{tabs = 1}

function tablist:after_init(ui, t)
	self.tabs = {} --{tab1,...}
	if t.tabs then
		for _,tab in ipairs(t.tabs) do
			self:tab(tab)
		end
	end
end

--selected tab state

tablist._selected_tab = false

function tablist:get_selected_tab()
	return self._selected_tab
end

function tablist:set_selected_tab(tab)
	assert(tab.tablist == self)
	if tab then
		tab:select()
	elseif self.selected_tab then
		self.selected_tab:unselect()
	end
end

--visible tabs list

function tablist:visible_tab_count()
	local n = 0
	for _,tab in ipairs(self.tabs) do
		if tab.visible and not tab.drag_outside then n = n + 1 end
	end
	return n
end

tablist.last_selected_order = true

--modes: next_index, prev_index, next_layer_index, prev_layer_index.
function tablist:next_tab(from_tab, mode, rotate)
	if mode == nil then
		mode = true
	end
	if type(mode) == 'boolean' then
		if self.last_selected_order then
			mode = not mode
		end
		mode = (mode and 'next' or 'prev')
			.. (self.last_selected_order and '_layer' or '') .. '_index'
	end

	local forward = mode:find'next'
	local tabs = mode:find'layer' and self.layers or self.tabs

	local i0, i1, step = 1, #tabs, 1
	if not forward then
		i0, i1, step = i1, i0, -step
	end
	if from_tab then
		local index_field = tabs == self.layers and 'layer_index' or 'index'
		i0 = from_tab[index_field] + (forward and 1 or -1)
	end
	for i = i0, i1, step do
		local tab = tabs[i]
		if tab.istab and tab.visible and tab.enabled and not tab.dragging then
			return tab
		end
	end
	if rotate then
		return self:next_tab(nil, mode)
	end
end

function tablist:prev_tab(tab)
	local stab = self.selected_tab
	local prev_tab
	if stab == tab then
		local is_first = (stab == self.tabs[self:tab_index_by_visual_index(1)])
		local mode = self.last_selected_order and 'prev_layer_index'
			or (is_first and 'next_index' or 'prev_index')
		prev_tab = self:next_tab(tab, mode)
	end
	return prev_tab
end

--input / keyboard

tablist.main_tablist = true --responds to tab/ctrl+tab globally

function tablist:after_init()
	self.window:on({'keypress', self}, function(win, key)
		if self.main_tablist then
			if key == 'tab' and self.ui:key'ctrl' then
				local shift = self.ui:key'shift'
				local tab = self:next_tab(self.selected_tab, not shift, true)
				if tab then
					tab.selected = true
				end
				return true
			elseif self.selected_tab and key == 'W' and self.ui:key'ctrl' then
				self.selected_tab:close()
				return true
			end
		end
	end)
end

--drag & drop

function tablist:accept_drag_widget(widget, mx, my, area)
	if widget.istab then
		return true
	end
end

function tablist:drop(widget, mx, my, area)
	widget.tablist = self
	widget.origin_tablist = false
end

--drawing & hit-testing

tablist.h = 26
tablist.tab_w = 150
tablist.tab_spacing = -10
tablist.tab_slant_left = 70 --degrees
tablist.tab_slant_right = 70 --degrees
tablist.tabs_padding = 3
tablist.tabs_padding_left = 10

function tablist:clamp_tab_pos(x)
	return clamp(x,
		self.tabs_padding,
		self.w - self.tab_w + self.tabs_padding_left - self.tabs_padding)
end

function tablist:real_tab_w()
	local n = self:visible_tab_count()
	local w = self.w - self.tabs_padding_left + self.tab_spacing * n
	local sl = self.tab_slant_left
	local sr = self.tab_slant_right
	local wl = self.h / math.tan(math.rad(sl))
	local wr = self.h / math.tan(math.rad(sr))
	local tw = math.min(self.tab_w + self.tab_spacing, math.floor(w / n))
	return math.max(tw, wl + wr + 10)
end

function tablist:pos_by_visual_index(index)
	return self.tabs_padding_left +
		(index - 1) * (self:real_tab_w() + self.tab_spacing)
end

function tablist:visual_index_by_pos(x)
	local x = x - self.tabs_padding_left
	return math.floor(x / self:real_tab_w() + 0.5) + 1
end

function tablist:tab_index_by_visual_index(vi)
	vi = math.max(1, vi)
	local vi1 = 1
	for i,tab in ipairs(self.tabs) do
		if tab.visible and not tab.drag_outside then
			if vi1 == vi then
				return i
			end
			vi1 = vi1 + 1
		end
	end
	return #self.tabs
end

function tablist:sync(duration)
	local vi = 1
	local tab_w = self:real_tab_w()
	local tab_h = self.h + 1
	for i,tab in ipairs(self.tabs) do
		tab.h = tab_h
		if tab.visible and not tab.drag_outside then
			if not tab.active then
				tab:transition('x', self:pos_by_visual_index(vi), duration)
				tab:transition('w', tab_w, duration)
				tab:transition('y', 0)
			else
				tab.w = tab_w
			end
			vi = vi + 1
		else
			tab.w = tab_w
		end
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local color = require'color'

	local w = (win.cw - 30) / 2

	local tl1 = ui:tablist{
		x = 10, y = 10, w = w,
		parent = win,
	}

	local tl2 = ui:tablist{
		x = tl1.x2 + 10, y = 10, w = w, parent = win,
	}

	for i = 1, 10 do
		local visible = i ~= 3 and i ~= 8
		local enabled = i ~= 4 and i ~= 7
		local selected = i == 1 or i == 2
		local layer_index = 1
		local closeable = i ~= 5

		local tl = i % 2 == 0 and tl1 or tl2

		local content = ui:layer{
			parent = win,
			x = tl.x, y = tl.y2, w = tl.w, h = (win.ch or 0) - tl.y2 - 10,
			tags = 'content',
			background_color = '#222',
			corner_radius = 5,
			visible = visible and selected,
			tablist = tl,
			text = i,
			text_size = 24,
		}

		local tab = ui:tab{
			tags = 'tab'..i,
			--index = 1,
			layer_index = layer_index,
			tablist = tl,
			style = {
				font_slant = 'normal',
			},
			text = 'Tab '..i,
			text_color = {color.rgb(ui.tab.background_color):bw(.25):rgba()},
			visible = visible,
			selected = selected,
			enabled = enabled,
			closeable = closeable,
			tab_selected = function(tab)
				ui:each('content', function(self)
					if self.ui and self.tablist == tab.tablist then
						self.visible = false
					end
				end)
				if not content.ui then return end
				content.visible = tab.visible
			end,
			closed = function(self)
				self:free()
			end,
		}

	end

end) end
