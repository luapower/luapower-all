
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
slider._max_position = false --overrides size
slider._position = 0
slider._progress = false --overrides position
slider.step = false --no stepping
slider.snap_to_labels = true --...if there are any
slider.step_labels = false --{label = value, ...}
slider.show_tooltip = true
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

ui:style('slider focused > slider_fill', {
	background_color = '#ccc',
})

pin.w = 18
pin.h = 18
pin.corner_radius = 9
pin.border_width = 1
pin.border_color = '#000'
pin.background_color = '#999'

ui:style('slider_pin', {
	transition_duration = .2,
	transition_cx = true,
	transition_border_color = true,
	transition_background_color = true,
})

ui:style('slider focused > slider_pin', {
	background_color = '#fff',
})

tooltip.y = -10
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

function pin:progress_at_cx(cx)
	local cx1, cx2 = self:cx_range()
	return lerp(cx, cx1, cx2, 0, 1)
end

function pin:cx_at_progress(progress)
	local cx1, cx2 = self:cx_range()
	return lerp(progress, 0, 1, cx1, cx2)
end

function pin:get_progress()
	return self:progress_at_cx(self.cx)
end

function pin:set_progress(progress)
	local cx = self:cx_at_progress(progress)
	local duration = not self.slider.animating and 0 or nil
	self:transition('cx', cx, duration)
	if self.slider.animating and self.slider.show_tooltip then
		self.slider.tooltip:settag('visible', true)
	end
	self.slider.animating = false
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
	if not p:transitioning'cx' then
		p.progress = self.progress
		if not p.dragging then
			self.tooltip:settag('visible', false)
		end
	end

	f.h = b.h
	f.w = p.cx

	t.x = p.w / 2

	t:transition('text', string.format(t.format, self.position))

	if self.step_labels then
		for _,l in ipairs(self.layers) do
			if l.tags.slider_step_label then
				if l.progress then
					l.x = self.pin:cx_at_progress(l.progress)
				elseif l.position then
					l.x = self.pin:cx_at_progress(l.position / self.size)
				end
				l.y = self.h
				l.w = 200
				l.x = l.x - l.w / 2
				l.h = 20
			end
		end
	end
end

function slider:step_lines_visible()
	return self.step and self.step_line_color
		and self.cw / (self.size / self.step) >= 5
end

function slider:draw_step_lines(cr)
	if not self:step_lines_visible() then return end
	cr:rgba(self.ui:color(self.step_line_color))
	cr:line_width(1)
	cr:new_path()
	for progress = 0, 1, self.step / self.size do
		cr:move_to(self.pin:cx_at_progress(progress), self.h)
		cr:rel_line_to(0, self.step_line_h)
	end
	cr:stroke()
end

function slider:after_draw_content(cr)
	self:draw_step_lines(cr)
end

function slider:before_draw(cr)
	self:sync()
end

--input

pin.mousedown_activate = true
function pin:mousedown()
	self.slider:focus()
end
function pin:start_drag()
	self.slider.tooltip:settag('visible', true)
	return self
end
function pin:end_drag()
	self.slider.tooltip:settag('visible', false)
end
function pin:drag(dx)
	local cx = self.x + dx + self.w / 2
	self.slider.progress = self:progress_at_cx(cx)
end

slider.mousedown_activate = true
function slider:start_drag(_, mx)
	self.animating = true
	self.progress = self.pin:progress_at_cx(mx)
	return self.pin, self.pin.w / 2, 0
end

function slider:keypress(key)
	if key == 'left' or key == 'up' or key == 'pageup'
		or key == 'right' or key == 'down' or key == 'pagedown'
	then
		local pos = self.position
		local dir = (key == 'left' or key:find'up') and -1 or 1
		if self.step_labels and self.snap_to_labels then --label-to-label
			self.animating = true
			self.position = self:nearest_position(nil, dir)
		else
			local delta =
				(self.ui:key'shift' and 0.01 or 1) *
				(self.ui:key'ctrl' and 0.1 or 1) *
				((key == 'up' or key == 'down') and 0.1 or 1) *
				(key:find'page' and 5 or 1) *
				0.1 --constant speed of 10%
			if self.step then --ensure at least one step
				delta = math.max(self.step / self.size, delta)
			end
			self.animating = true
			self.progress = self.progress + delta * dir
		end
	elseif key == 'home' then
		self.animating = true
		self.progress = 0
	elseif key == 'end' then
		self.animating = true
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
	elseif self.step then
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

function slider:get_progress()
	if self:isinstance() then
		local p1, p2 = self:position_range()
		return lerp(self.position, p1, p2, 0, 1)
	else
		return self._progress
	end
end

function slider:set_progress(progress)
	if self:isinstance() then
		self.position = lerp(progress, 0, 1, self:position_range())
	else
		self._progress = progress
	end
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
	if inherited(self, pos) then
		if self:isinstance() then
			self.pin.progress = self.progress
			self:invalidate()
		end
	end
end

slider:init_ignore{min_position=1, max_position=1, size=1, position=1, progress=1}

function slider:after_init()
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
	local t = self._init_vars
	self._min_position = t.min_position
	self._max_position = t.max_position or (self._min_position + t.size)
	if t.progress then
		self._position = lerp(t.progress, 0, 1, self:position_range())
	else
		self._position = t.position
	end
	self._position = self:nearest_position(self._position)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:slider{
		x = 100, y = 100, w = 200, parent = win,
		position = 3, size = 10,
		step_labels = {Low = 0, Medium = 5, High = 10},
		--snap_to_labels = false,
	}

	ui:slider{
		x = 100, y = 200, w = 200, parent = win,
		position = 5, size = 10,
		step = 1.5,
	}

	ui:slider{
		x = 100, y = 300, w = 200, parent = win,
		progress = .3, size = 10,
	}

end) end
