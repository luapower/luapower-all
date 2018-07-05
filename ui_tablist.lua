
--ui tab and tablist widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local indexof = glue.indexof
local clamp = glue.clamp

--tab ------------------------------------------------------------------------

local tab = ui.layer:subclass'tab'
ui.tab = tab

--tablist & index state

tab._tablist = false

function tab:get_tablist()
	return self._tablist
end

function tab:set_tablist(new_tablist)
	local cur_tablist = self._tablist
	local new_tablist = new_tablist or false
	if cur_tablist == new_tablist then return end
	if cur_tablist then
		self._tablist = false --recursion barrier
		cur_tablist:_remove_tab(self)
	end
	self._tablist = new_tablist or false --recursion barrier
	if new_tablist then
		new_tablist:_add_tab(self, self._index)
	end
end

--convenience binder: just specify the tablist as parent when creating the tab
function tab:after_set_parent(parent)
	self.tablist = parent
end

tab._index = 1/0 --add to the tablist tail

function tab:get_index()
	return self.tablist and self.tablist:index(self) or self._index
end

function tab:set_index(index)
	if not self.tablist then
		self._index = index
	else
		self._index = nil
		self.tablist:_move_tab(self, index)
	end
end

tab:init_ignore{tablist=1, selected=1}

function tab:after_init(ui, t)
	self.tablist = t.tablist or t.parent
	self.selected = t.selected
end

function tab:before_free()
	self.tablist = false
end

--selected state

function tab:get_selected()
	return self.tablist and self.tablist.selected_tab == self
end

function tab:set_selected(selected)
	if selected then
		self:select()
	else
		self:unselect()
	end
end

function tab:select()
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
	local stab = self.tablist.selected_tab
	if stab ~= self then return end
	stab:settag(':selected', false)
	stab:fire'tab_unselected'
	self.tablist:fire('tab_unselected', stab)
end

--input / mouse

tab.mousedown_activate = true

function tab:activated()
	self:select()
end

function tab:deactivated()
	self.tablist:sync()
end

function tab:start_drag() return self end

function tab:drag(dx, dy)
	local x = self.x + dx
	local vi = self.tablist:visual_index_by_pos(x)
	self.index = self.tablist:index_by_visual_index(vi)
	self:transition('x', self.tablist:clamp_tab_pos(x), 0)
end

--input / keyboard

tab.focusable = true

function tab:keypress(key)
	if key == 'enter' or key == 'space' then
		self:select()
	elseif key == 'left' or key == 'right' then
		local next_tab = self.tablist:next_tab(self, key == 'right')
		if next_tab then
			next_tab:focus()
		end
	end
end

--drawing

tab.clip_content = true
tab.border_width = 1
tab.border_color = '#222'
tab.background_color = '#111'
tab.text_align = 'left'
tab.padding_left = 15

ui:style('tab', {
	transition_x = true,
	transition_duration_x = 0.5,
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
	local w, h = self.w, self.h
	local sl = self.tablist.tab_slant_left
	local sr = self.tablist.tab_slant_right
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

--close button

local xbutton = ui.button:subclass'tab_close_button'
tab.close_button_class = xbutton

--TODO

--tablist --------------------------------------------------------------------

local tablist = ui.layer:subclass'tablist'
ui.tablist = tablist

--tabs list

function tablist:index(tab)
	return indexof(tab, self.tabs)
end

function tablist:clamped_index(index, add)
	return clamp(index, 1, math.max(1, #self.tabs + (add and 1 or 0)))
end

function tablist:_add_tab(tab, index)
	tab.parent = self
	local index = self:clamped_index(index, true)
	table.insert(self.tabs, index, tab)
	self:sync()
end

function tablist:_remove_tab(tab)
	tab.parent = false
	table.remove(self.tabs, self:index(tab))
	self:sync()
end

function ui.layer:_move_tab(tab, index)
	local old_index = self:index(tab)
	local new_index = self:clamped_index(index)
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
	tab:select()
end

--visible tabs list

function tablist:visible_tab_count()
	local n = 0
	for i=1,#self.tabs do
		if self.tabs[i].visible then n = n + 1 end
	end
	return n
end

function tablist:next_tab(from_tab, forward, rotate)
	if forward == nil then
		forward = true
	end
	local i0, i1, step = 1, #self.tabs, 1
	if not forward then
		i0, i1, step = i1, i0, -step
	end
	if from_tab then
		i0 = from_tab.index + (forward and 1 or -1)
	end
	for i = i0, i1, step do
		local tab = self.tabs[i]
		if tab.visible then return tab end
	end
	if rotate then
		return self:next_tab(nil, forward)
	end
end

--input / keyboard

tablist.main_tablist = true --responds to tab/ctrl+tab globally

function tablist:after_init()
	self.window:on({'keypress', self}, function(win, key)
		self:_window_keypress(key)
	end)
end

function tablist:_window_keypress(key)
	if self.main_tablist and key == 'tab' and self.ui:key'ctrl' then
		local tab = self:next_tab(self.selected_tab, not self.ui:key'shift', true)
		if tab then
			tab:select()
		end
	end
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

function tablist:index_by_visual_index(vi)
	vi = math.max(1, vi)
	local vi1 = 1
	for i,tab in ipairs(self.tabs) do
		if tab.visible then
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
		if tab.visible then
			if not tab.active then
				tab:transition('x', self:pos_by_visual_index(vi), duration)
				tab:transition('w', tab_w, duration)
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

	local tl = ui:tablist{
		x = 10, y = 10, w = 800,
		parent = win,
	}

	for i = 1, 5 do
		local visible = i == 2 or i == 4 or i == 1

		local content = ui:layer{parent = win,
			x = tl.x, y = tl.y + tl.h, w = 800, h = (win.h or 0) - tl.h,
			tags = 'content',
			background_color = '#222',
			corner_radius = 5,
			visible = visible,
		}

		local tab = ui:tab{
			tags = 'tab'..i,
			index = 1,
			parent = tl,
			style = {
				font_slant = 'normal',
			},
			text = 'Tab '..i,
			text_color = {color.rgb(ui.tab.background_color):bw(.25):rgba()},
			visible = visible,
			selected = visible,
			tab_selected = function(self)
				ui:each('content', function(self) self.visible = false end)
				content:to_front()
				content.visible = self.visible
			end,
		}

	end

	function win:client_rect_changed(cx, cy, cw, ch)
		self:each('content', function(self)
			self.w = cw - 2 * tl.x
			self.h = ch - 2 * tl.y - tl.h
		end)
		self:each('tablist', function(self)
			self.w = cw - 2 * tl.x
			self:sync(0)
		end)
	end

end) end
