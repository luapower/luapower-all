
--slider widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local box2d = require'box2d'

local snap = glue.snap
local clamp = glue.clamp

ui.slider = ui.layer:subclass'slider'
ui.slider.border = ui.layer:subclass'slider_border'
ui.slider.fill = ui.layer:subclass'slider_fill'
ui.slider.pin = ui.layer:subclass'slider_pin'
ui.slider.step_label = ui.layer:subclass'slider_step_label'

ui.slider.focusable = true
ui.slider.h = 20
ui.slider._position = 0
ui.slider.size = 1
ui.slider.step = false --no stepping
ui.slider.snap_to_labels = true --...if there are any
ui.slider.step_labels = false --{label = value, ...}
ui.slider.background_color = '#0000'
ui.slider.drag_threshold = 1
ui.slider.step_line_h = 5
ui.slider.step_line_color = '#fff'

ui.slider.border.activable = false
ui.slider.border.h = 10
ui.slider.border.corner_radius = 5
ui.slider.border.border_width = 1
ui.slider.border.border_color = '#999'
ui.slider.border.background_color = '#000'
ui.slider.border.content_clip = true

ui.slider.fill.activable = false
ui.slider.fill.h = 10
ui.slider.fill.background_color = '#444'

ui.slider.pin.activable = false
ui.slider.pin.w = 18
ui.slider.pin.h = 18
ui.slider.pin.corner_radius = 9
ui.slider.pin.border_width = 1
ui.slider.pin.border_color = '#000'
ui.slider.pin.background_color = '#999'

ui.slider.tooltip = ui.layer:subclass'slider_tooltip'
ui.slider.tooltip.y = -16
ui.slider.tooltip.format = '%g'
ui.slider.tooltip.border_width = 0
ui.slider.tooltip.border_color = '#fff'
ui.slider.tooltip.border_offset = 1
ui.slider.tooltip.opacity = 0

ui:style('slider_pin', {
	transition_x = true,
	transition_duration_x = .2,
})

ui:style('slider_pin', {
	transition_border_color = true,
	transition_background_color = true,
	transition_duration = .2,
})

ui:style('slider_fill', {
	transition_w = true,
	transition_duration_w = .2,
})

ui:style('slider hot > slider_pin, slider focused > slider_pin, slider focused > slider_fill', {
	border_color = '#000',
	background_color = '#fff',
	transition_border_color = true,
	transition_background_color = true,
	transition_duration = .2,
})

ui:style('slider_pin dragging', {
	transition_x = false,
	transition_w = false,
})

ui:style('slider focused > slider_border', {
	border_color = '#fff',
	shadow_blur = 2,
	shadow_color = '#fff',
})

ui:style('slider_tooltip', {
	opacity = 0,
	transition_opacity = true,
	transition_duration_opacity = .5,
	transition_delay_opacity = .5,
	transition_blend_opacity = 'replace',
})

ui:style('slider_tooltip visible', {
	opacity = 1,
	transition_opacity = true,
	transition_duration_opacity = .5,
	transition_delay_opacity = 0,
})

function ui.slider.pin:drag(dx, dy)
	local cx = self.x + dx + self.corner_radius_top_left
	self.parent.position = self.parent:position_at_cx(cx)
end

function ui.slider:pin_cx(pos)
	return ((pos or self.position) / self.size) * self.cw
end

function ui.slider:position_at_cx(cx)
	return clamp((cx / self.cw) * self.size, 0, self.size)
end

function ui.slider:_find_position(pos, choose)
	local ref_pos = pos or self.position
	local best_pos
	if self.snap_to_labels and self.step_labels then
		for label, pos in pairs(self.step_labels) do
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	if self.step then
		for pos = ref_pos - self.step, ref_pos + self.step, self.step do
			pos = snap(pos, self.step)
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	return clamp(best_pos or ref_pos, 0, self.size)
end

local function nearest_pos(pos, best_pos, ref_pos)
	return not best_pos or math.abs(pos - ref_pos) < math.abs(best_pos - ref_pos)
end
function ui.slider:snap_position(pos)
	return self:_find_position(pos, nearest_pos)
end

local function next_pos(pos, best_pos, ref_pos)
	return pos > ref_pos and (not best_pos or pos < best_pos)
end
function ui.slider:next_position(pos)
	return self:_find_position(pos, next_pos)
end

local function prev_pos(pos, best_pos, ref_pos)
	return pos < ref_pos and (not best_pos or pos > best_pos)
end
function ui.slider:prev_position(pos)
	return self:_find_position(pos, prev_pos)
end

function ui.slider:get_position()
	return self._position
end

function ui.slider:set_position(pos)
	local old_pos = self._position
	pos = pos or old_pos
	self._position = pos
	self._position = self:snap_position(pos)
	local br = self.border.corner_radius_top_left
	if not self.pin.dragging then
		pos = self._position
	end
	local sx = self:pin_cx(pos)
	local pw = select(4, self.pin:border_rect(1))
	self.pin:transition('x', sx - pw / 2)
	self.fill:transition('w', sx + br)
	self.tooltip:transition('text',
		string.format(self.tooltip.format, self._position))
end

function ui.slider:mousedown(mx)
	self.active = true
	self.position = self:position_at_cx(mx)
	self:focus()
	self.tooltip:settags'visible'
end

function ui.slider:mouseup()
	self.active = false
	self.position = self.position
	self.tooltip:settags'-visible'
end

function ui.slider:start_drag()
	return self.pin, self.pin.border_outer_w / 2, 0
end

function ui.slider:keypress(key)
	if key == 'left' or key == 'up' or key == 'pageup' then
		self.position = self:prev_position()
	elseif key == 'right' or key == 'down' or key == 'pagedown' then
		self.position = self:next_position()
	elseif key == 'home' then
		self.position = 0
	elseif key == 'end' then
		self.position = self.size
	end
end

ui.slider:init_ignore{position=1}

function ui.slider:after_init(ui, t)
	self._position = t and t.position
	local br = self.border.corner_radius_top_left
	self.border = self.border(self.ui, {
		id = self:_subtag'border',
		x = -br,
		y = (self.h - self.border.h) / 2,
		w = self.cw + 2 * br,
		parent = self,
	})
	self.fill = self.fill(self.ui, {
		id = self:_subtag'fill',
		h = self.border.h,
		parent = self.border,
	})
	self.pin = self.pin(self.ui, {
		id = self:_subtag'pin',
		y = (self.h - self.pin.h) / 2,
		parent = self,
	})
	if self.step_labels then
		for label, value in pairs(self.step_labels) do
			self.step_label(self.ui, {
				x = self:pin_cx(value) - 100,
				y = self.h,
				w = 200,
				h = 20,
				text = label,
				id = self:_subtag'step_label',
				issteplabel = true,
				parent = self,
			})
		end
	end
	self.tooltip = self.tooltip(self.ui, {
		id = self:_subtag'tooltip',
		x = self.pin.w / 2,
		parent = self.pin,
	})
	self.position = self.position
end

function ui.slider:step_lines_visible()
	return self.step and self.step_line_color and self.size / self.step >= 5
end

function ui.slider:draw_step_lines()
	if not self:step_lines_visible() then return end
	local cr = self.window.cr
	cr:rgba(self.ui:color(self.step_line_color))
	cr:line_width(1)
	cr:new_path()
	for pos = 0, self.size + self.step / 2, self.step do
		cr:move_to(self:pin_cx(math.min(pos, self.size)), self.h)
		cr:rel_line_to(0, self.step_line_h)
	end
	cr:stroke()
end

function ui.slider:after_draw_content()
	self:draw_step_lines()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:slider{
		id = 's1',
		x = 100, y = 100, w = 200, parent = win,
		position = 5, size = 10,
		step_labels = {Low = 0, Medium = 5, High = 10},
		border_color = '#0000',
		snap_to_labels = true,
		border_width = 1,
	}

	ui:slider{
		id = 's2',
		x = 100, y = 200, w = 200, parent = win,
		position = 5, size = 10,
		border_color = '#0000',
		step = 1.5,
		border_width = 1,
	}

end) end
