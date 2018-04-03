
--slider widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local clamp = glue.clamp

ui.slider = ui.layer:subclass'slider'

ui.slider.isslider = true

ui.slider.border = ui.layer:subclass'slider_border'
ui.slider.border.h = 10
ui.slider.border.corner_radius = 10
ui.slider.border.border_width = 1
ui.slider.border.border_color = '#fff'

ui.slider.fill = ui.layer:subclass'slider_fill'
ui.slider.fill.h = 10
ui.slider.fill.background_color = '#fff'

ui.slider.pin = ui.layer:subclass'slider_pin'
ui.slider.pin.w = 16
ui.slider.pin.h = 16
ui.slider.pin.corner_radius = 8
ui.slider.pin.border_width = 1
ui.slider.pin.border_color = '#fff'
ui.slider.pin.background_color = '#000'
ui.slider.pin.drag_threshold = 0

function ui.slider.pin:after_init()

end

function ui.slider.pin:mousedown(button)
	if button == 'left' then
		self.active = true
	end
end

function ui.slider.pin:mouseup(button)
	if button == 'left' then
		self.active = false
	end
end

function ui.slider.pin:start_drag()
	return self
end

function ui.slider.pin:drag(dx, dy)
	self.x = self.x + dx
	self.parent.position = self.parent:position_at_x(self.x)
	self:invalidate()
end

ui.slider.h = 20
ui.slider._position = 0
ui.slider.size = 0

function ui.slider:slider_x()
	return (self.position / self.size) * self.w
end

function ui.slider:position_at_x(x)
	return clamp((x / self.w) * self.size, 0, self.size)
end

function ui.slider:get_position()
	return self._position
end

function ui.slider:set_position(pos)
	self._position = pos
	if self.updating then return end
	local sx = self:slider_x()
	self.pin.x = sx
	self.fill.w = sx
	self:invalidate()
end

function ui.slider:after_init()
	local sx = self:slider_x()
	self.border = self.border(self.ui, {
		id = self:_subtag'border',
		x = 0, y = (self.h - self.border.h) / 2, w = self.w, parent = self,
	})
	self.fill = self.fill(self.ui, {
		id = self:_subtag'fill',
		x = 0, y = 0, w = sx, h = self.border.h,
		parent = self.border,
	})
	self.pin = self.pin(self.ui, {
		id = self:_subtag'pin',
		x = sx, y = (self.h - self.pin.h) / 2, parent = self,
	})
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:style('slider_fill', {
		background_type = 'gradient',
		background_colors = {'#f00', 1, '#00f'},
		background_extend = 'reflect',
		background_x1 = 0,
		background_y1 = 0,
		background_x2 = 5,
		background_y2 = 5,
	})

	ui:style('slider_pin hot', {
		border_offset = 1,
		transition_border_offset = true,
		transition_duration = .5,
		transition_ease = 'expo out',
	})

	ui:slider{
		x = 100, y = 100, w = 200, parent = win, position = 5, size = 10,
	}

end) end
