
--ui tab and tablist widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local lerp = glue.lerp
local indexof = glue.indexof
local clamp = glue.clamp

--tab ------------------------------------------------------------------------

ui.tab = ui.layer:subclass'tab'

ui.tab.istab = true

ui.tab._tab_index = 1/0 --add to the tablist tail

function ui.tab:get_tab_index()
	return self._tab_index
end

function ui.tab:get_active_tab()
	return self.parent and self == self.parent.active_tab
end

function ui.tab:set_tab_index(tab_index)
	self._tab_index = tab_index
	if not self.updating and self.parent then
		self._tab_index = self.parent:_move_tab(self, tab_index)
	end
end

function ui.tab:after_end_update()
	self.tab_index = self.tab_index
end

function ui.tab:after_set_active(active)
	if active then
		if self.parent.active_tab then
			self.parent.active_tab:settags'-active_tab'
		end
		self:to_front()
		self:settags'active_tab'
	end
end

--NYI: border width ~= 1, diff. border colors per side, rounded corners,
--border offset, shadows (needs border offset).
function ui.tab:border_path()
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
	local cr = self.window.cr
	cr:move_to(x4 + .5, y4 - .5)
	cr:line_to(x1 + .5, y1 + .5)
	cr:line_to(x2 - .5, y2 + .5)
	cr:line_to(x3 - .5, y3 - .5)
end

function ui.tab:draw_border()
	if not self:border_visible() then return end
	local cr = self.window.cr
	cr:new_path()
	self:border_path()
	cr:rgba(self.ui:color(self.border_color_left))
	cr:line_width(self.border_width_left)
	cr:stroke()
end

--tablist --------------------------------------------------------------------

ui.tablist = ui.layer:subclass'tablist'

ui.tablist.istablist = true
ui.tablist.h = 30
ui.tablist.tab_w = 150
ui.tablist.tabs_padding_left = 10
ui.tablist.tab_spacing = -10
ui.tablist.tab_slant_left = 70 --degrees
ui.tablist.tab_slant_right = 70 --degrees

function ui.tablist:after_init()
	self.tabs = {} --{tab1,...}
end

function ui.layer:_move_tab(tab, index)
	local new_index = clamp(index, 1, #self.tabs)
	local old_index = indexof(tab, self.tabs)
	if old_index ~= new_index then
		local active_tab = self.active_tab
		table.remove(self.tabs, old_index)
		table.insert(self.tabs, new_index, tab)
		self:_update_tabs_pos()
	end
	return new_index
end

function ui.tablist:get_active_tab()
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local tab = self.layers[i]
		if tab.istab then
			return tab
		end
	end
end

function ui.tablist:pos_by_index(index)
	return self.tabs_padding_left + (index - 1) * (self.tab_w + self.tab_spacing)
end

function ui.tablist:index_by_pos(x)
	local x = x - self.tabs_padding_left
	return math.floor(x / (self.tab_w + self.tab_spacing) + 0.5) + 1
end

function ui.tablist:_update_tabs_pos()
	for i,tab in ipairs(self.tabs) do
		if not tab.active then
			tab:transition('x', self:pos_by_index(i), 0.5, 'expo out')
		end
	end
end

function ui.tablist:clamp_tab_pos(x)
	return clamp(x, self.tabs_padding_left, self.w - self.tab_w)
end

function ui.tablist:before_add_layer(tab)
	if not tab.istab then return end
	if self.active_tab then
		self.active_tab:settags'-active_tab'
	end
end

function ui.tablist:after_add_layer(tab)
	if not tab.istab then return end
	if self.active_tab then
		self.active_tab:settags'active_tab'
	end
	local index = clamp(tab.tab_index, 1, #self.tabs)
	table.insert(self.tabs, index, tab)
	tab.h = self.h + 1
	tab.w = self.tab_w
	tab:on('mousedown.tablist', function(tab, button)
		if button == 'left' then
			tab.active = true
		end
	end)
	tab:on('mouseup.tablist', function(tab, button)
		if button == 'left' then
			tab.active = false
			self:_update_tabs_pos()
		end
	end)
	function tab.drag(tab, dx, dy)
		tab.active = true
		tab.tab_index = self:index_by_pos(tab.x + dx)
		tab.x = self:clamp_tab_pos(tab.x + dx)
		tab:invalidate()
	end
	function tab:start_drag()
		return self
	end
	self:_update_tabs_pos()
end

function ui.tablist:after_remove_layer(tab)
	if not tab.istab then return end
	tab:off'.tablist'
	table.remove(self.tabs, indexof(tab, self.tabs))
end

function ui.tablist:draw_tabline_underneath(active_tab)
	if not active_tab:border_visible() then return end
	local cr = self.window.cr
	cr:new_path()
	cr:move_to(self.tabs_padding_left, self.h - .5)
	cr:rel_line_to(self.w - self.tabs_padding_left, 0)
	cr:rgba(self.ui:color(active_tab.border_color_left))
	cr:line_width(1)
	cr:stroke()
end

function ui.tablist:draw_layers()
	if not self.layers then return end
	local active_tab = self.active_tab
	for i = 1, #self.layers do
		local layer = self.layers[i]
		if layer == active_tab then
			self:draw_tabline_underneath(active_tab)
		end
		layer:draw()
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local color = require'color'

	ui:style('tab', {
		border_width = 1,
	})

	ui:style('tab hot', {
		background_color = '#dd8',
		transition_background_color = true,
		transition_duration = 1.5,
		transition_ease = 'expo out',
	})

	ui:style('tab active_tab', {
		background_color = ui.initial,
		border_color = '#0003',
		transition_duration = 0,
	})

	local tl = ui:tablist{
		x = 10, y = 10, w = 800,
		parent = win,
	}

	for i = 1, 5 do
		local bg_color = {i / 5, i / 5, 0, 1}
		local tab = ui:tab{parent = tl, background_color = bg_color}

		local content = ui:layer{parent = win,
			x = tl.x, y = tl.y + tl.h, w = 800, h = (win.h or 0) - tl.h,
			tags = 'content',
			background_color = bg_color,
			corner_radius = 5,
		}

		function tab:after_draw_content()
			self:setfont()
			local bg_color = self.background_color
			local text_color = {color.rgb(unpack(bg_color)):bw(.25):rgba()}
			self.window.cr:rgba(self.ui:color(text_color))
			self.window:textbox(0, 0, self.cw, self.ch, 'Tab '..i, 'center', 'center')
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
	end

end) end
