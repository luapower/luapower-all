
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
		self:to_front()
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
	cr:move_to(x1, y1)
	cr:line_to(x2, y2)
	cr:line_to(x3, y3)
	cr:line_to(x4, y4)
	cr:close_path()
end

function ui.tab:draw_border()
	if not self:border_visible() then return end
	local cr = self.window.cr
	cr:new_path()
	self:border_path()
	cr:rgba(self.ui:color(self.border_color_left))
	cr:line_width(1)
	cr:stroke()
end

--tablist --------------------------------------------------------------------

ui.tablist = ui.layer:subclass'tablist'

ui.tablist.istablist = true
ui.tablist.h = 30
ui.tablist.tab_w = 150
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
		table.remove(self.tabs, old_index)
		table.insert(self.tabs, new_index, tab)
		self:_update_tabs_pos()
	end
	return new_index
end

function ui.tablist:get_active_tab()
	return self.layers[#self.layers]
end

function ui.tablist:pos_by_index(index)
	return (index - 1) * (self.tab_w + self.tab_spacing)
end

function ui.tablist:index_by_pos(x)
	return math.floor(x / (self.tab_w + self.tab_spacing) + 0.5) + 1
end

function ui.tablist:_update_tabs_pos()
	for i,tab in ipairs(self.tabs) do
		if not tab.active then
			tab:transition('x', self:pos_by_index(i), 0.5, 'expo out')
		end
	end
end

function ui.tablist:after_add_layer(tab)
	if not tab.istab then return end
	local index = clamp(tab.tab_index, 1, #self.tabs)
	table.insert(self.tabs, index, tab)
	tab.h = self.h
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
	function tab:drag(dx, dy)
		tab.active = true
		tab.tab_index = self.parent:index_by_pos(tab.x + dx)
		tab.x = tab.x + dx
		self:invalidate()
	end
	function tab:start_drag()
		return self
	end
	function tab:ended_dragging()
		--self:_update_tabs_pos()
	end
	self:_update_tabs_pos()
end

function ui.tablist:after_remove_layer(tab)
	if not tab.istab then return end
	tab:off'.tablist'
	table.remove(self.tabs, indexof(tab, self.tabs))
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:style('tab', {
		border_color = '#666',
		background_color = '#ccc',
		border_width = 1,
	})

	ui:style('tab hot', {
		background_color = '#fff',
	})

	ui:style('tab active', {
		background_color = '#ff0',
	})

	local tl = ui:tablist{
		x = 50, y = 100, w = 800,
		parent = win,
	}

	for i = 1, 5 do
		ui:tab{parent = tl}
	end

end) end
