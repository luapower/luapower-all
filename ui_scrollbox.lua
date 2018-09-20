
--Scrollbar and Scrollbox Widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local box2d = require'box2d'
local glue = require'glue'

local clamp = glue.clamp
local lerp = glue.lerp

local scrollbar = ui.layer:subclass'scrollbar'
ui.scrollbar = scrollbar

local grip = ui.layer:subclass'scrollbar_grip'
scrollbar.grip_class = grip

--default geometry

scrollbar.w = 10
scrollbar.h = 10
grip.min_w = 20
scrollbar.corner_radius = 5
grip.corner_radius = 5

--default colors

scrollbar.background_color = '#222'
grip.background_color = '#ccc'

--default initial state

scrollbar.content_length = 0
scrollbar.view_length = 0
scrollbar.offset = 0  --in 0..content_length range

--default behavior

scrollbar.vertical = true --scrollbar is rotated 90deg to make it vertical
scrollbar.step = false --no snapping
scrollbar.autohide = true --hide when mouse is not near the scrollbar
scrollbar.autohide_empty = true --hide when content is smaller than the view
scrollbar.autohide_distance = 20 --distance around the scrollbar
scrollbar.click_scroll_length = 300
	--^how much to scroll when clicking on the track (area around the grip)

--fade animation

scrollbar.opacity = 0

ui:style('scrollbar', {
	--fade out
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
	transition_blend_opacity = 'wait',
})

ui:style('scrollbar :near', {
	--fade in
	opacity = .5,
	transition_opacity = true,
	transition_delay_opacity = 0,
	transition_duration_opacity = .5,
	transition_blend_opacity = 'replace',
})

ui:style('scrollbar :active', {
	opacity = .5,
})

--smooth scrolling

ui:style('scrollbar', {
	transition_offset = true,
	transition_duration_offset = .2,
})

--vertical property and tags

scrollbar:stored_property'vertical'

function scrollbar:after_set_vertical(vertical)
	self:settag('vertical', vertical)
	self:settag('horizontal', not vertical)
end

scrollbar:instance_only'vertical'

--grip geometry

local function snap_offset(i, step)
	return step and i - i % step or i
end

local function grip_offset(x, bar_w, grip_w, content_length, view_length, step)
	local offset = x / (bar_w - grip_w) * (content_length - view_length)
	local offset = snap_offset(offset, step)
	return offset ~= offset and 0 or offset
end

local function grip_segment(content_length, view_length, offset, bar_w, min_w)
	local w = clamp(bar_w * view_length / content_length, min_w, bar_w)
	local x = offset * (bar_w - w) / (content_length - view_length)
	local x = clamp(x, 0, bar_w - w)
	return x, w
end

function scrollbar:grip_rect()
	local x, w = grip_segment(
		self.content_length, self.view_length, self.offset,
		self.cw, self.grip.min_w
	)
	local y, h = 0, self.ch
	return x, y, w, h
end

function scrollbar:grip_offset()
	return grip_offset(self.grip.x, self.cw, self.grip.w,
		self.content_length, self.view_length, self.step)
end

function scrollbar:create_grip()
	local grip = self.grip_class(self.ui, {
		parent = self,
	}, self.grip)

	function grip.drag(grip, dx, dy)
		grip.x = clamp(0, grip.x + dx, self.cw - grip.w)
		self:transition('offset', self:grip_offset(), 0)
	end

	return grip
end

--scroll state

local function clamp_offset(offset, content_length, view_length, step)
	offset = clamp(offset, 0, math.max(content_length - view_length, 0))
	return snap_offset(offset, step)
end

function scrollbar:_clamp_offset()
	self._offset = clamp_offset(self._offset, self.content_length,
		self.view_length, self.step)
end

scrollbar:stored_property'content_length'
scrollbar:stored_property'view_length'
scrollbar:stored_property'offset'

function scrollbar:after_set_content_length() self:_clamp_offset() end
function scrollbar:after_set_view_length() self:_clamp_offset() end
function scrollbar:after_set_offset() self:_clamp_offset() end

function scrollbar:empty()
	return self.content_length <= self.view_length
end

scrollbar:init_ignore{offset=1, view_length=1, content_length=1}

function scrollbar:after_init(ui, t)

	--init scroll state
	self._offset = t.offset
	self._content_length = t.content_length
	self._view_length = t.view_length
	self:_clamp_offset()

	self.grip = self:create_grip()
end

--scroll API

function scrollbar:scroll_to(offset, duration)
	if self.visible and self.autohide and not self.grip.active
		and (not self.autohide_empty or not self:empty())
	then
		self:settag(':near', true)
		self:sync()
		self:settag(':near', false)
	end
	self:transition('offset', offset, duration)
end

function scrollbar:scroll_to_view(x, w, duration)
	local sx = self.offset
	local sw = self.view_length
	self:scroll_to(clamp(sx, x + w - sw, x), duration)
end

function scrollbar:scroll(delta, duration)
	self:scroll_to(self:end_value'offset' + delta, duration)
end

function scrollbar:scroll_pages(pages, duration)
	self:scroll(self.view_length * (pages or 1), duration)
end

--mouse interaction: grip dragging

grip.mousedown_activate = true

function grip:start_drag()
	return self
end

--mouse interaction: clicking on the track

scrollbar.mousedown_activate = true

--TODO: mousepress or mousehold
function scrollbar:mousedown(mx, my)
	local delta = self.click_scroll_length * (mx < self.grip.x and -1 or 1)
	self:transition('offset', self:end_value'offset' + delta)
end

--mouse interaction: proximity showing (autohide feature)

function scrollbar:_check_visible()
	return self.visible
		and not self.ui.active_widget
		and (not self.autohide_empty or not self:empty())
		and (not self.autohide or self.grip.active or 'hit_test')
end

function scrollbar:hit_test_near(mx, my)
	return box2d.hit(mx, my,
		box2d.offset(self.autohide_distance, self:content_rect()))
end

function scrollbar:_window_mousemove(mx, my)
	local visible = self:_check_visible()
	if visible == 'hit_test' then
		local near = self:hit_test_near(self:from_window(mx, my))
		self:settag(':near', near)
	end
end

function scrollbar:_window_mouseleave()
	local visible = self:_check_visible()
	if visible == 'hit_test' then
		self:settag(':near', false)
	end
end

function scrollbar:after_set_parent()
	if not self.window then return end
	self.window:on({'mousemove', self}, function(win, mx, my)
		self:_window_mousemove(mx, my)
	end)
	self.window:on({'mouseleave', self}, function(win)
		self:_window_mouseleave()
	end)
end

--drawing: rotate matrix for vertical scrollbar

function scrollbar:override_rel_matrix(inherited)
	local mt = inherited(self)
	if self._vertical then
		mt:rotate(math.rad(90)):translate(0, -self.h)
	end
	return mt
end

--drawing: sync grip geometry; sync :near tag.

function scrollbar:after_sync()
	local g = self.grip
	g.x, g.y, g.w, g.h = self:grip_rect()

	local visible = self:_check_visible()
	if visible ~= 'hit_test' then
		self:settag(':near', visible)
	end
end

--scrollbox ------------------------------------------------------------------

local scrollbox = ui.layer:subclass'scrollbox'
ui.scrollbox = scrollbox

scrollbox.vscrollbar_class = scrollbar
scrollbox.hscrollbar_class = scrollbar

--default geometry

scrollbox.scrollbar_margin_left = 6
scrollbox.scrollbar_margin_right = 6
scrollbox.scrollbar_margin_top = 6
scrollbox.scrollbar_margin_bottom = 6

--default behavior

scrollbox.vscrollable = true
scrollbox.hscrollable = true
scrollbox.vscroll = 'always' --true/'always', 'near', 'auto', false/'never'
scrollbox.hscroll = 'always'
scrollbox.wheel_scroll_length = 50 --pixels per scroll wheel notch
scrollbox.autohide = true --single option for both scrollbars

function scrollbox:after_init(ui, t)

	self.view = self.ui:layer{
		parent = self, clip_content = true,
	}

	if not self.content or not self.content.islayer then
		self.content = self.ui:layer({
			tags = 'content',
			parent = self.view,
			clip_content = true, --for faster bounding box computation
		}, self.content)
	elseif self.content then
		self.content.parent = self.view
	end

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		tags = 'vscrollbar',
		parent = self, vertical = true, autohide = self.autohide,
	}, self.vscrollbar)

	self.hscrollbar = self.hscrollbar_class(self.ui, {
		tags = 'hscrollbar',
		parent = self, vertical = false, autohide = self.autohide,
	}, self.hscrollbar)

	function self.vscrollbar:override_hit_test_near(inherited, mx, my)
		if inherited(self, mx, my)
			or self.parent.hscrollbar.super.hit_test_near(self.parent.hscrollbar,
				self:to_other(self.parent.hscrollbar, mx, my))
		then
			local pmx, pmy = self.parent:to_parent(self:to_parent(mx, my))
			return self.parent:hit_test(pmx, pmy, 'vscroll') and true
		end
	end

	function self.hscrollbar:override_hit_test_near(inherited, mx, my)
		if inherited(self, mx, my)
			or self.parent.vscrollbar.super.hit_test_near(self.parent.vscrollbar,
				self:to_other(self.parent.vscrollbar, mx, my))
		then
			local pmx, pmy = self.parent:to_parent(self:to_parent(mx, my))
			return self.parent:hit_test(pmx, pmy, 'hscroll') and true
		end
	end
end

--mouse interaction: wheel scrolling

function scrollbox:mousewheel(delta)
	self.vscrollbar:scroll(-delta * self.wheel_scroll_length)
end

--drawing

function scrollbox:after_sync()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	local cw, ch = self:content_size()
	local sw = vs.h
	local sh = hs.h
	local cv = self.view
	local ct = self.content
	ct.parent = cv
	local hm1 = hs.autohide and self.scrollbar_margin_left or 0
	local hm2 = hs.autohide and self.scrollbar_margin_right or 0
	local vm1 = vs.autohide and self.scrollbar_margin_top or 0
	local vm2 = vs.autohide and self.scrollbar_margin_bottom or 0
	local ctw, cth = select(3, ct:bounding_box())
	cv.w = cw - (vs.autohide and 0 or sw)
	cv.h = ch - (hs.autohide and 0 or sh)
	vs.visible = self.vscrollable
	vs.x = cv.w - (vs.autohide and sw or 0) - vm1
	vs.y = vm1
	vs.w = cv.h - (hs.visible and sw or 0) - vm1 - vm2
	vs.view_length = cv.h
	vs.content_length = cth
	ct.y = -vs.offset
	hs.visible = self.hscrollable
	hs.y = cv.h - (hs.autohide and sw or 0) - hm1
	hs.x = hm1
	hs.w = cv.w - (vs.visible and sw or 0) - hm1 - hm2
	hs.view_length = cv.w
	hs.content_length = ctw
	ct.x = -hs.offset
end

--scroll API

function scrollbox:scroll_to_view(x, y, w, h)
	self.hscrollbar:scroll_to_view(x, w)
	self.vscrollbar:scroll_to_view(y, h)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local content = ui:layer{
		w = 2000,
		h = 32000,
		border_width = 20,
		border_color = '#ff0',
		background_type = 'gradient',
		background_colors = {'#ff0', 0.5, '#00f'},
		background_x2 = 100,
		background_y2 = 100,
		background_extend = 'repeat',
	}

	local sb = ui:scrollbox{
		tags = 'sb',
		parent = win,
		x = 0, y = 0, w = 900, h = 500,
		background_color = '#111',
		content = content,
		autohide = true,
	}

end) end
