
--ui drop-down widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local dropdown = ui.layer:subclass'dropdown'
ui.dropdown = dropdown

dropdown.h = 22
dropdown.focusable = true
dropdown.background_color = '#080808'
dropdown.border_color = '#888'
dropdown.border_width = 1

ui:style('dropdown', {
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('dropdown hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('dropdown focused', {
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

local button = ui.button:subclass'dropdown_button'
dropdown.button_class = button

button.border_color = dropdown.border_color
button.border_width = dropdown.border_width

function dropdown:create_button()
	local button = self.button_class(self.ui, {
		parent = self,
		dropdown = self,
	}, self.button)

	function button:pressed()
		local popup = self.dropdown.popup
		popup.visible = not popup.visible
		self:invalidate()
	end

	return button
end

function button:sync_triangle()
	local cw, ch = self.cw, self.ch
	local w = .4 * cw
	local h = .2 * ch
	local x = (cw - w) / 2
	local y = math.floor((ch - h) / 2 + h / 5)
	self.triangle = {x, y, w, h}
end

function button:draw_triangle()
	local cr = self.window.cr
	local x, y, w, h = unpack(self.triangle)
	cr:move_to(x, y)
	cr:rel_line_to(w, 0)
	cr:rel_line_to(-w/2, h)
	cr:close_path()
	cr:rgba(self.ui:color(self.text_color))
	cr:fill()
end

function button:after_sync()
	self:sync_triangle()
end

function button:before_draw_content()
	self:draw_triangle()
end

local popup = ui.popup--:subclass'dropdown_popup'
dropdown.popup_class = popup

function dropdown:create_popup()
	local x = 0
	local y = self.h
	local w = self.w
	local h = math.floor(w * 1.4)
	local popup = self.ui.popup(self.ui, {
		parent = self,
		x = x, y = y, w = w, h = h,
		visible = false,
	})

	self.ui:on('mousedown', function(mx, my)

	end)

	return popup
end

local list = ui.grid:subclass'dropdown_list'
dropdown.list_class = list

list.header_visible = false
list.col_move = false
list.row_move = false
list.multi_select = false
list.cell_select = false

function dropdown:create_list(popup)
	local list = self.list_class(self.ui, {
		parent = popup,
		cols = {
			{w = 150},
		},
		rows = {
			'1234',
			'%&#$',
			'abcd',
		},
	}, self.list)
	list:to_front()

	return list
end

function dropdown:after_init()
	self.button = self:create_button()
	self.popup = self:create_popup()
	self.list = self:create_list(self.popup)
end

function dropdown:after_sync()
	local b = self.button
	b.h = self.ch
	b.w = math.floor(b.h * .9)
	b.x = self.cw - b.w
	b:sync()

	local l = self.list
	l.w = self.w
	l.h = math.min(l:rows_h(), math.floor(l.w * 1.4))

	local p = self.popup
	p.h = l.h
	p:sync()
end

function dropdown:before_draw()
	self:sync()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local dropdown1 = ui:dropdown{
		x = 10, y = 10,
		w = 200,
		parent = win,
	}

	local dropdown2 = ui:dropdown{
		x = 10, y = 10 + dropdown1.h + 10,
		w = 200,
		parent = win,
	}

end) end
