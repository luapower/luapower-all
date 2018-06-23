
--slider widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local box2d = require'box2d'

local snap = glue.snap
local clamp = glue.clamp
local lerp = glue.lerp

local slider = ui.layer:subclass'slider'
ui.slider = slider

local border  = ui.layer:subclass'slider_border'
local fill    = ui.layer:subclass'slider_fill'
local pin     = ui.layer:subclass'slider_pin'
local tooltip = ui.layer:subclass'slider_tooltip'

slider.border_class     = border
slider.fill_class       = fill
slider.pin_class        = pin
slider.tooltip_class    = tooltip
slider.step_label_class = ui.layer

slider.focusable = true
slider.h = 20

slider._min_position = 0
slider._max_position = 1
slider._position = 0
slider.step = false --no stepping
slider.snap_to_labels = true --...if there are any
slider.step_labels = false --{label = value, ...}
slider.step_line_h = 5
slider.step_line_color = '#fff'

border.activable = false
border.h = 10
border.corner_radius = 5
border.border_width = 1
border.border_color = '#999'
border.background_color = '#000'
border.clip_content = true --clip the fill

ui:style('slider focused > slider_border', {
	border_color = '#fff',
	shadow_blur = 2,
	shadow_color = '#fff',
})

fill.activable = false
fill.h = 10
fill.background_color = '#444'

--[[
ui:style('slider hot > slider_pin, slider focused > slider_pin, slider focused > slider_fill', {
	border_color = '#000',
	background_color = '#fff',
	transition_border_color = true,
	transition_background_color = true,
	transition_duration = .2,
})
]]

pin.w = 18
pin.h = 18
pin.corner_radius = 9
pin.border_width = 1
pin.border_color = '#000'
pin.background_color = '#999'

tooltip.y = -16
tooltip.format = '%g'
tooltip.border_width = 0
tooltip.border_color = '#fff'
tooltip.border_offset = 1
tooltip.opacity = 0

ui:style('slider_tooltip', {
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

--pin position

function pin:position_at_cx(cx)
	local cx1, cx2 = self:cx_range()
	return lerp(cx, cx1, cx2, self.slider:position_range())
end

function pin:cx_at_position(pos)
	local cx1, cx2 = self:cx_range()
	local p1, p2 = self.slider:position_range()
	return lerp(pos, p1, p2, cx1, cx2)
end

function pin:get_position()
	return self:position_at_cx(self.cx)
end

function pin:set_position(pos)
	local cx = self:cx_at_position(pos)
	if cx ~= self.cx then
		self.cx = cx
		self.slider.fill.x2 = cx
		self:invalidate()
	end
end

function pin:cx_range()
	local r = self.slider.border.corner_radius_top_left
	return r, self.slider.cw - r
end

--sync'ing

function slider:create_border()
	return self.border_class(self.ui, {
		slider = self,
		parent = self,
	})
end

function slider:create_fill()
	return self.fill_class(self.ui, {
		slider = self,
		parent = self.border,
	})
end

function slider:create_pin()
	return self.pin_class(self.ui, {
		slider = self,
		parent = self,
	})
end

function slider:create_tooltip()
	return self.tooltip_class(self.ui, {
		slider = self,
		parent = self.pin,
	})
end

function slider:create_step_label(text, position)
	return self.step_label_class(self.ui, {
		tags = 'slider_step_label',
		slider = self,
		parent = self,
		text = text,
		position = position,
	})
end

function slider:sync()
	local b = self.border
	local f = self.fill
	local p = self.pin
	local t = self.tooltip

	b.x = 0
	b.y = (self.h - b.h) / 2
	b.w = self.cw

	p.y = (self.h - p.h) / 2
	p.position = self.position

	f.h = b.h

	t.x = p.w / 2

	t:transition('text', string.format(t.format, self.position))

	if self.step_labels then
		for _,l in ipairs(self.layers) do
			if l.tags.slider_step_label then
				l.x = self.pin:cx_at_position(l.position) - 100
				l.y = self.h
				l.w = 200
				l.h = 20
			end
		end
	end
end

function slider:before_draw(cr)
	self:sync()
end

--input

pin.drag_threshold = 1
pin.mousedown_activate = true
function pin:mousedown()
	self.slider:focus()
end
function pin:start_drag()
	return self
end
function pin:drag(dx)
	self.x = self.x + dx
	self.slider.position = self.position
end

slider.mousedown_activate = true
function slider:start_drag(_, mx)
	self.pin.cx = mx
	return self.pin, self.pin.w / 2, 0
end

function slider:keypress(key)
	if key == 'left' or key == 'up' or key == 'pageup'
		or key == 'right' or key == 'down' or key == 'pagedown'
	then
		local pos = self.position
		local dir = (key == 'left' or key:find'up') and -1 or 1
		if self:smooth() then
			local delta =
				(self.ui:key'shift' and 0.01 or 1) *
				(self.ui:key'ctrl' and 0.1 or 1) *
				(key:find'page' and 4 or 1) *
				0.1
			self.progress = self.progress + delta * dir
		else
			self.position = self:nearest_position(nil, dir)
		end
	elseif key == 'home' then
		self.progress = 0
	elseif key == 'end' then
		self.progress = 1
	end
end

--state

local function next_pos(pos, best_pos, ref_pos)
	return pos > ref_pos and (not best_pos or pos < best_pos)
end
local function prev_pos(pos, best_pos, ref_pos)
	return pos < ref_pos and (not best_pos or pos > best_pos)
end
local function nearest_pos(pos, best_pos, ref_pos)
	return not best_pos or math.abs(pos - ref_pos) < math.abs(best_pos - ref_pos)
end
function ui.slider:nearest_position(ref_pos, rounding)
	ref_pos = ref_pos or self.position
	rounding = rounding or 0
	local choose =
		rounding > 0 and next_pos
		or rounding < 0 and prev_pos
		or nearest_pos
	local best_pos
	if self.snap_to_labels and self.step_labels then
		for label, pos in pairs(self.step_labels) do
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	if self.step then
		if best_pos then
			ref_pos = best_pos
			best_pos = nil
		end
		ref_pos = clamp(ref_pos, self:position_range())
		for pos = ref_pos - self.step, ref_pos + self.step, self.step do
			pos = snap(pos, self.step)
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	return clamp(best_pos or ref_pos, self:position_range())
end

function slider:smooth()
	return not (self.step or self.step_labels)
end

function slider:get_progress()
	local p1, p2 = self:position_range()
	return lerp(self.position, p1, p2, 0, 1)
end

function slider:set_progress(progress)
	self.position = lerp(progress, 0, 1, self:position_range())
end

function slider:position_range()
	return self.min_position, self.max_position
end

function slider:get_min_position() return self._min_position end
function slider:get_max_position() return self._max_position end

function slider:get_size()
	return self.max_position - self.min_position
end

function slider:set_size(size)
	self.max_position = self.min_position + size
end

function slider:set_min_position(pos)
	self._min_position = pos
	self.position = self.position --clamp it
end

function slider:set_max_position(pos)
	self._max_position = pos
	self.position = self.position --clamp it
end

slider:track_changes'position'

function slider:override_set_position(inherited, pos)
	local pos = self:nearest_position(pos)
	inherited(self, pos)
	if self:isinstance() then
		self:invalidate()
	end
end

slider:init_ignore{min_position=1, max_position=1, size=1, position=1}

function slider:after_init(ui, t)
	self.border  = self:create_border()
	self.fill    = self:create_fill()
	self.pin     = self:create_pin()
	self.tooltip = self:create_tooltip()
	if self.step_labels then
		for text, pos in pairs(self.step_labels) do
			if type(text) == 'number' then
				pos, text = text, pos
			end
			self:create_step_label(text, pos)
		end
	end
	self._min_position = t.min_position or self.min_position
	self._max_position = t.max_position
		or t.size and self.min_position + t.size
		or self.max_position
	self._position = self:nearest_position(t.position or self.position)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:slider{
		x = 100, y = 100, w = 200, parent = win,
		size = 10, position = 2,
		step = 1,
		step_labels = {Low = .5, Medium = 5, High = 10},
	}

end) end
