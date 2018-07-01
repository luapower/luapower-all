
--ui tab and tablist widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local indexof = glue.indexof
local clamp = glue.clamp

--tab ------------------------------------------------------------------------

ui.tab = ui.layer:subclass'tab'

ui.tab._index = 1/0 --add to the tablist tail
ui.tab.close_button = ui.button
ui.tab.focusable = true
ui.tab.clip_content = true

ui:style('tab', {
	transition_x = true,
	transition_duration_x = 0.5,
})

function ui.tab:get_index()
	return self.parent and self.parent:index(self) or self._index
end

function ui.tab:get_front_tab()
	return self.parent and self == self.parent.front_tab
end

function ui.tab:set_index(index)
	if not self.parent then
		self._index = index
	else
		self._index = nil
		self.parent:_move_tab(self, index)
	end
end

function ui.tab:after_set_parent()
	self.index = self._index
end

function ui.tab:after_set_active(active)
	if active then
		if self.parent.front_tab then
			self.parent.front_tab:settag(':front_tab', false)
		end
		self:settag(':front_tab', true)
		self:to_front()
	end
end

function ui.tab:keypress(key)
	if key == 'enter' or key == 'space' then
		self:activate()
		self:focus()
	elseif key == 'left' or key == 'right' then
		local next_tab = self.parent:next_tab(self, key == 'right')
		if next_tab then
			next_tab:activate()
			next_tab:focus()
		end
	end
end

--NYI: border width ~= 1, diff. border colors per side, rounded corners,
--border offset, shadows (needs border offset).
function ui.tab:border_path(cr)
	local w, h = self.w, self.h
	local sl = self.parent.tab_slant_left
	local sr = self.parent.tab_slant_right
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
	cr:move_to(x4 + .5, y4 - .5)
	cr:line_to(x1 + .5, y1 + .5)
	cr:line_to(x2 - .5, y2 + .5)
	cr:line_to(x3 - .5, y3 - .5)
end

function ui.tab:draw_border(cr)
	if not self:border_visible() then return end
	cr:new_path()
	self:border_path(cr)
	cr:rgba(self.ui:color(self.border_color_left))
	cr:line_width(self.border_width_left)
	cr:stroke()
end

--tablist --------------------------------------------------------------------

ui.tablist = ui.layer:subclass'tablist'

ui.tablist.h = 30
ui.tablist.tab_w = 150
ui.tablist.tabs_padding_left = 10
ui.tablist.tab_spacing = -10
ui.tablist.tab_slant_left = 70 --degrees
ui.tablist.tab_slant_right = 70 --degrees
ui.tablist.main_tablist = true --responds to tab/ctrl+tab globally

function ui.tablist:after_init()
	self.tabs = {} --{tab1,...}
	self.window:on({'keypress', self}, function(win, key)
		self:_window_keypress(key)
	end)
end

function ui.tablist:before_free()
	self.window:off({nil, self})
end

function ui.tablist:next_tab(tab, forward, rotate)
	local first_index = forward and 1 or #self.tabs
	if tab == nil then
		tab = self.front_tab
	end
	if tab == false then
		return self.tabs[first_index]
	else
		return self.tabs[tab.index + (forward and 1 or -1)]
			or (rotate and self.tabs[first_index])
	end
end

function ui.tablist:_window_keypress(key)
	if not self.main_tablist then return end
	if #self.tabs == 0 then return end
	if key == 'tab' and self.ui:key'ctrl' then
		local next_tab = self:next_tab(nil, not self.ui:key'shift', true)
		next_tab:activate()
		local widget = self.focused_widget
		if widget and widget.istab and self:index(widget) then
			next_tab:focus()
		end
	end
end

function ui.layer:clamped_index(index, add)
	return clamp(index, 1, math.max(1, #self.tabs + (add and 1 or 0)))
end

function ui.layer:_move_tab(tab, index)
	local old_index = self:index(tab)
	local new_index = self:clamped_index(index)
	if old_index ~= new_index then
		table.remove(self.tabs, old_index)
		table.insert(self.tabs, new_index, tab)
		self:_update_tabs_pos()
	end
end

function ui.tablist:get_front_tab()
	if not self.layers then return end
	for i = #self.layers, 1, -1 do --frontmost layer that is a tab
		local tab = self.layers[i]
		if tab.istab then
			return tab
		end
	end
end

function ui.tablist:index(tab)
	return indexof(tab, self.tabs)
end

function ui.tablist:real_tab_w()
	local w = self.w - self.tabs_padding_left + self.tab_spacing * #self.tabs
	local sl = self.tab_slant_left
	local sr = self.tab_slant_right
	local wl = self.h / math.tan(math.rad(sl))
	local wr = self.h / math.tan(math.rad(sr))
	local tw = math.min(self.tab_w + self.tab_spacing, math.floor(w / #self.tabs))
	return math.max(tw, wl + wr + 10)
end

function ui.tablist:pos_by_index(index)
	return self.tabs_padding_left +
		(index - 1) * (self:real_tab_w() + self.tab_spacing)
end

function ui.tablist:index_by_pos(x)
	local x = x - self.tabs_padding_left
	return math.floor(x / self:real_tab_w() + 0.5) + 1
end

function ui.tablist:_update_tabs_pos(duration)
	for i,tab in ipairs(self.tabs) do
		if not tab.active then
			tab:transition('x', self:pos_by_index(i), duration)
			tab:transition('w', self:real_tab_w(), duration)
		end
	end
end

function ui.tablist:clamp_tab_pos(x)
	return clamp(x, self.tabs_padding_left, self.w - self.tab_w)
end

function ui.tablist:after_add_layer(tab)
	if not tab.istab then return end
	if self.front_tab then
		self.front_tab:settag(':front_tab', false)
	end
	tab:settag(':front_tab', true)
	local index = self:clamped_index(tab.index, true)
	table.insert(self.tabs, index, tab)
	tab.h = self.h + 1
	tab.w = self:real_tab_w()
	tab:on('mousedown.tablist', function(tab)
		tab.active = true
		tab:focus()
	end)
	tab:on('mouseup.tablist', function(tab)
		tab.active = false
		self:_update_tabs_pos()
	end)
	function tab.drag(tab, dx, dy)
		tab.active = true
		tab.index = self:index_by_pos(tab.x + dx)
		tab:transition('x', self:clamp_tab_pos(tab.x + dx), 0)
	end
	function tab:start_drag()
		return self
	end
	self:_update_tabs_pos(0)
end

function ui.tablist:after_remove_layer(tab)
	if not tab.istab then return end
	tab:off'.tablist'
	table.remove(self.tabs, self:index(tab))
	tab.index = 1/0 --reset to default
end

function ui.tablist:draw_tabline_underneath(cr, front_tab)
	if not front_tab:border_visible() then return end
	cr:new_path()
	cr:move_to(self.tabs_padding_left, self.h - .5)
	cr:rel_line_to(self.w - self.tabs_padding_left, 0)
	cr:rgba(self.ui:color(front_tab.border_color_left))
	cr:line_width(1)
	cr:stroke()
end

function ui.tablist:draw_layers(cr)
	if not self.layers then return end
	local front_tab = self.front_tab
	for i = 1, #self.layers do
		local layer = self.layers[i]
		if layer == front_tab then
			self:draw_tabline_underneath(cr, front_tab)
		end
		layer:draw(cr)
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local color = require'color'

	ui:style('tab', {
		border_width = 1,
	})

	ui:style('tab :hot', {
		background_color = '#dd8',
		transition_background_color = true,
		transition_duration = 1.5,
	})

	ui:style('tab :focused', {
		font_weight = 'bold',
	})

	ui:style('tab :active', {
		font_slant = 'italic',
	})

	ui:style('tab :front_tab', {
		background_color = ui.initial,
		border_color = '#0003',
		transition_duration = 0,
	})

	local tl = ui:tablist{
		x = 10, y = 10, w = 800,
		parent = win,
		tab_slant_left = 70,
		tab_slant_right = 70,
	}

	for i = 1, 5 do
		local bg_color = {i / 5, i / 5, 0, 1}
		local tab = ui:tab{
			tags = 'tab'..i,
			index = 1,
			parent = tl,
			background_color = bg_color,
			padding_left = 15,
			style = {
				font_slant = 'normal',
			},
		}

		local content = ui:layer{parent = win,
			x = tl.x, y = tl.y + tl.h, w = 800, h = (win.h or 0) - tl.h,
			tags = 'content',
			background_color = bg_color,
			corner_radius = 5,
		}

		function tab:after_draw_content(cr)
			self:setfont()
			local bg_color = self.background_color
			local text_color = {color.rgb(bg_color):bw(.25):rgba()}
			cr:rgba(self.ui:color(text_color))
			self.window:textbox(0, 0, self.cw, self.ch, 'Tab '..i, 'left', 'center')
		end
		function tab:activated()
			ui:each('content', function(self) self.visible = false end)
			content.visible = true
		end
	end

	function win:client_rect_changed(cx, cy, cw, ch)
		self:each('content', function(self)
			self.w = cw - 2 * tl.x
			self.h = ch - 2 * tl.y - tl.h
		end)
		self:each('tablist', function(self)
			self.w = cw - 2 * tl.x
			self:_update_tabs_pos(0)
		end)
	end

end) end
