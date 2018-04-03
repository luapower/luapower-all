
--ui menu bar & menu widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

--menu item ------------------------------------------------------------------

ui.menuitem = ui.layer:subclass'menuitem'
ui.menuitem.ismenuitem = true
ui.menuitem.h = 20
ui.menuitem.padding_left = 10
ui.menuitem.align = 'left'
ui.menuitem.border_offset = 1

function ui.menuitem:after_init()
	self:on('mouseenter', function(self, mx, my)
		--self.
	end)
	self:on('mouseleave', function(self)

	end)
	self:on('mousedown', function(self)
		--if button =
	end)
end

--menu bar -------------------------------------------------------------------

ui.menubar = ui.layer:subclass'menubar'

--function ui.menubar:

--menu -----------------------------------------------------------------------

ui.menu = ui.layer:subclass'menu'
ui.menu.h = 0
ui.menu.border_offset = 1

function ui.menu:item_h(mi)
	return (select(4, mi:border_rect(1)))
end

function ui.menu:item_y(mi)
	assert(mi.parent == self)
	local y = 0
	for _,item in ipairs(self.layers) do
		if item.ismenuitem then
			if item == mi then
				return y
			else
				y = y + self:item_h(item) - item.border_width_bottom
			end
		end
	end
end

function ui.menu:after_add_layer(mi)
	if not mi.ismenuitem then return end
	mi.x = 0
	mi.w = self.w
	mi.y = self:item_y(mi)
	local prev_mi = self.layers[#self.layers - 1]
	if prev_mi then
		prev_mi.border_color_bottom = '#0000'
		mi.border_color_top = self.border_color_top
		mi.border_color_bottom = '#0000'
	end
	mi.border_color_bottom = '#0000'
	mi.border_width = self.border_width_top
	self.h = self.h + self:item_h(mi) - mi.border_width_bottom
end

--popup menu -----------------------------------------------------------------

ui.popupmenu = ui.menu:subclass'popupmenu'

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:style('menuitem', {
		background_color = '#000',
		border_color = '#ff0',
	})

	ui:style('menuitem hot', {
		background_color = '#333',
	})

	local menu = ui:menu{
		parent = win,
		x = 10, y = 10, w = 100,
		border_width = 1,
		border_color = '#fff',
		padding = 10,
		border_width = 10,
		--content_clip = false,
	}

	for i=1,5 do
		local mi = ui:menuitem{
			parent = menu,
			text = 'Menu '..i,
			padding = 10,
			h = 50,
		}
	end

end) end
