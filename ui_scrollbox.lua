
--Scrollbar and Scrollbox Widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local box2d = require'box2d'
local glue = require'glue'

local clamp = glue.clamp
local lerp = glue.lerp

local scrollbar = ui.layer:subclass'scrollbar'
ui.scrollbar = scrollbar

scrollbar._vertical = true
scrollbar._offset = 0
scrollbar._content_length = 0
scrollbar._view_length = 0
scrollbar.step = false --no snapping
scrollbar.min_width = 20
scrollbar.w = 10
scrollbar.h = 10
scrollbar.background_color = '#222'
scrollbar.corner_radius = 5

scrollbar.autohide = true
scrollbar.autohide_empty = true
scrollbar.autohide_offset = 20 --around-distance to scrollbar
scrollbar.click_scroll_length = 300 --scroll when clicking on the background

local grabbar = ui.layer:subclass'scrollbar_grabbar'
scrollbar.grabbar_class = grabbar

grabbar.background_color = '#ccc'

scrollbar.opacity = 0

ui:style('scrollbar', {
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
	transition_blend_opacity = 'wait',

	transition_offset = true,
	transition_duration_offset = .2,
})

ui:style('scrollbar :near', {
	opacity = .5,
	transition_opacity = true,
	transition_delay_opacity = 0,
	transition_duration_opacity = .5,
	transition_blend_opacity = 'replace',
})

ui:style('scrollbar :active', {
	opacity = .5,
})

local function snap_offset(i, step)
	return step and i - i % step or i
end

local function bar_offset(bx, w, bw, content_length, view_length, step)
	local offset = snap_offset(bx / (w - bw) * (content_length - view_length), step)
	return offset ~= offset and 0 or offset
end

local function clamp_offset(i, content_length, view_length, step)
	return snap_offset(clamp(i, 0, math.max(content_length - view_length, 0)), step)
end

local function bar_segment(w, content_length, view_length, i, minw)
	local bw = clamp(w * view_length / content_length, minw, w)
	local bx = i * (w - bw) / (content_length - view_length)
	local bx = clamp(bx, 0, w - bw)
	return bx, bw
end

function scrollbar:grabbar_rect()
	local bx, bw = bar_segment(self.cw, self.content_length, self.view_length,
		self.offset, self.min_width)
	local by, bh = 0, self.ch
	return bx, by, bw, bh
end

function scrollbar:grabbar_offset()
	return bar_offset(self.grabbar.x, self.cw, self.grabbar.w,
		self.content_length, self.view_length, self.step)
end

function scrollbar:_clamp_offset()
	self._offset = clamp_offset(self._offset, self.content_length,
		self.view_length, self.step)
end

function scrollbar:get_offset()
	return self._offset
end

function scrollbar:get_content_length()
	return self._content_length
end

function scrollbar:get_view_length()
	return self._view_length
end

function scrollbar:empty()
	return self.content_length <= self.view_length
end

function scrollbar:set_offset(offset)
	self._offset = offset
	self:_clamp_offset()
end

function scrollbar:set_content_length(length)
	self._content_length = length
	self:_clamp_offset()
end

function scrollbar:set_view_length(length)
	self._view_length = length
	self:_clamp_offset()
end

function scrollbar:override_rel_matrix(inherited)
	local mt = inherited(self)
	if self._vertical then
		mt:rotate(math.rad(90)):translate(0, -self.h)
	end
	return mt
end

scrollbar:init_ignore{offset=1, view_length=1, content_length=1}

function scrollbar:after_init(ui, t)

	self._offset = t.offset
	self._content_length = t.content_length
	self._view_length = t.view_length
	self:_clamp_offset()

	self.grabbar = self.grabbar_class(self.ui, {
		parent = self,
	}, self.grabbar)

	function self.grabbar.drag(grabbar, dx, dy)
		grabbar.x = clamp(0, grabbar.x + dx, self.cw - grabbar.w)
		self:transition('offset', self:grabbar_offset(), 0)
	end
end

function scrollbar:after_set_parent()
	if not self.window then return end
	--autohide hooks
	self.window:on({'mousemove', self}, function(win, mx, my)
		self:_window_mousemove(mx, my)
	end)
	self.window:on({'mouseleave', self}, function(win)
		self:_window_mouseleave()
	end)
end

grabbar.corner_radius = 5

grabbar.mousedown_activate = true

function grabbar:start_drag()
	return self
end

scrollbar.mousedown_activate = true

--TODO: mousepress or mousehold
function scrollbar:mousedown(mx, my)
	local delta = self.click_scroll_length * (mx < self.grabbar.x and -1 or 1)
	self:transition('offset', self:end_value'offset' + delta)
end

function scrollbar:scroll_to(offset)
	if self.visible and self.autohide and not self.grabbar.active
		and (not self.autohide_empty or not self:empty())
	then
		self:settag(':near', true)
		self:update_styles()
		self:settag(':near', false)
	end
	self:transition('offset', offset)
end

function scrollbar:scroll(delta)
	self:scroll_to(self:end_value'offset' + delta)
end

function scrollbar:scroll_pages(pages)
	self:scroll(self.view_length * (pages or 1))
end

function scrollbar:_check_visible()
	return self.visible
		and (not self.autohide_empty or not self:empty())
		and (not self.autohide or self.grabbar.active or 'hit_test')
end

function scrollbar:hit_test_near(mx, my)
	return box2d.hit(mx, my,
		box2d.offset(self.autohide_offset, self:content_rect()))
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

--`vertical` and `horizontal` tags based on `vertical` property

function scrollbar:get_vertical()
	return self._vertical
end

function scrollbar:set_vertical(vertical)
	self._vertical = vertical
	self:settag('vertical', vertical)
	self:settag('horizontal', not vertical)
end

function scrollbar:sync()
	local g = self.grabbar
	g.x, g.y, g.w, g.h = self:grabbar_rect()

	local visible = self:_check_visible()
	if visible ~= 'hit_test' then
		self:settag(':near', visible)
	end
end

function scrollbar:before_draw()
	self:sync()
end

function scrollbar:scroll_to_view(x, w)
	local sx = self.offset
	local sw = self.view_length
	self:scroll_to(clamp(sx, x + w - sw, x))
end

--scrollbox ------------------------------------------------------------------

ui.scrollbox = ui.layer:subclass'scrollbox'

ui.scrollbox.vscrollable = true
ui.scrollbox.hscrollable = true
ui.scrollbox.vscroll = 'always' --true/'always', 'near', 'auto', false/'never'
ui.scrollbox.hscroll = 'always'
ui.scrollbox.wheel_scroll_length = 50 --pixels per scroll wheel notch
ui.scrollbox.vscrollbar_class = scrollbar
ui.scrollbox.hscrollbar_class = scrollbar
ui.scrollbox.scrollbar_margin_left = 6
ui.scrollbox.scrollbar_margin_right = 6
ui.scrollbox.scrollbar_margin_top = 6
ui.scrollbox.scrollbar_margin_bottom = 6
ui.scrollbox.content_class = ui.layer

function ui.scrollbox:after_init(ui, t)

	self.content_container = self.ui:layer{
		parent = self, clip_content = true,
	}

	self.content = self.content_class(self.ui, {
		tags = 'content',
		parent = self.content_container,
		clip_content = true, --for faster bounding box computation
	}, self.content)

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		tags = 'vhscrollbar',
		parent = self, vertical = true, autohide = self.autohide,
	}, self.vscrollbar)

	function self.vscrollbar:override_hit_test_near(inherited, mx, my)
		if inherited(self, mx, my)
			or self.parent.hscrollbar.super.hit_test_near(self.parent.hscrollbar,
				self:to_other(self.parent.hscrollbar, mx, my))
		then
			local pmx, pmy = self.parent:to_parent(self:to_parent(mx, my))
			return self.parent:hit_test(pmx, pmy, 'vscroll') and true
		end
	end

	self.hscrollbar = self.hscrollbar_class(self.ui, {
		tags = 'hscrollbar',
		parent = self, vertical = false, autohide = self.autohide,
	}, self.hscrollbar)

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

function ui.scrollbox:mousewheel(delta)
	self.vscrollbar:scroll(-delta * self.wheel_scroll_length)
end

function ui.scrollbox:sync()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	local cw, ch = self:content_size()
	local sw = vs.h
	local sh = hs.h
	local cc = self.content_container
	local ct = self.content
	local hm1 = hs.autohide and self.scrollbar_margin_left or 0
	local hm2 = hs.autohide and self.scrollbar_margin_right or 0
	local vm1 = vs.autohide and self.scrollbar_margin_top or 0
	local vm2 = vs.autohide and self.scrollbar_margin_bottom or 0
	local ctw, cth = select(3, ct:bounding_box())
	cc.w = cw - (vs.autohide and 0 or sw)
	cc.h = ch - (hs.autohide and 0 or sh)
	vs.visible = self.vscrollable
	vs.x = cc.w - (vs.autohide and sw or 0) - vm1
	vs.y = vm1
	vs.w = cc.h - (hs.visible and sw or 0) - vm1 - vm2
	vs.view_length = cc.h
	vs.content_length = cth
	ct.y = -vs.offset
	hs.visible = self.hscrollable
	hs.y = cc.h - (hs.autohide and sw or 0) - hm1
	hs.x = hm1
	hs.w = cc.w - (vs.visible and sw or 0) - hm1 - hm2
	hs.view_length = cc.w
	hs.content_length = ctw
	ct.x = -hs.offset
end

function ui.scrollbox:before_draw()
	self:sync()
end

function ui.scrollbox:scroll_to_view(x, y, w, h)
	self:sync()
	self.hscrollbar:scroll_to_view(x, w)
	self.vscrollbar:scroll_to_view(y, h)
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local sb = ui:scrollbox{
		tags = 'sb',
		parent = win,
		x = 0, y = 0, w = 900, h = 500,
		background_color = '#111',
		vscrollbar = {view_length = 100, content_length = 1000, offset = 10},
		autohide = true,
	}

	sb.content.w = 2000
	sb.content.h = 32000
	sb.content.border_width = 20
	sb.content.border_color = '#ff0'
	sb.content.background_type = 'gradient'
	sb.content.background_colors = {'#ff0', 0.5, '#00f'}
	sb.content.background_x2 = 100
	sb.content.background_y2 = 100
	sb.content.background_extend = 'repeat'

end) end
