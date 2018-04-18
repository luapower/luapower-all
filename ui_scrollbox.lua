
--ui scrollbar and scrollbox widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local box2d = require'box2d'
local glue = require'glue'
local clamp = glue.clamp
local lerp = glue.lerp

ui.scrollbar = ui.layer:subclass'scrollbar'

ui.scrollbar:_addtags'scrollbar'

ui.scrollbar._vertical = true
ui.scrollbar._offset = 0
ui.scrollbar._content_size = 0
ui.scrollbar._view_size = 0
ui.scrollbar.step = false --no snapping
ui.scrollbar.min_width = 20
ui.scrollbar.w = 12
ui.scrollbar.h = 12
ui.scrollbar.background_color = '#222'
ui.scrollbar.corner_radius = 6

ui.scrollbar.autohide = true
ui.scrollbar.autohide_empty = false
ui.scrollbar.autohide_offset = 20 --around-distance to scrollbar
ui.scrollbar.opacity = 0
ui.scrollbar.page_size = 300 --pixels to scroll when clicking on the bg

ui.scrollbar.grabbar = ui.layer:subclass'grabbar'
ui.scrollbar.grabbar.corner_radius = 6

ui:style('scrollbar', {
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
	transition_blend_opacity = 'wait',

	transition_offset = true,
	transition_duration_offset = .2,
})

ui:style('scrollbar near', {
	opacity = .5,
	transition_opacity = true,
	transition_delay_opacity = 0,
	transition_duration_opacity = .5,
	transition_blend_opacity = ui.initial,
})

ui:style('scrollbar active', {
	opacity = .5,
})

local function snap_offset(i, step)
	return step and i - i % step or i
end

local function bar_offset(bx, w, bw, content_size, view_size, step)
	local offset = snap_offset(bx / (w - bw) * (content_size - view_size), step)
	return offset ~= offset and 0 or offset
end

local function clamp_offset(i, content_size, view_size, step)
	return snap_offset(clamp(i, 0, math.max(content_size - view_size, 0)), step)
end

local function bar_segment(w, content_size, view_size, i, minw)
	local bw = clamp(w * view_size / content_size, minw, w)
	local bx = i * (w - bw) / (content_size - view_size)
	local bx = clamp(bx, 0, w - bw)
	return bx, bw
end

function ui.scrollbar:grabbar_rect()
	local bx, bw = bar_segment(self.cw, self.content_size, self.view_size,
		self.offset, self.min_width)
	local by, bh = 0, self.ch
	return bx, by, bw, bh
end

function ui.scrollbar:grabbar_offset()
	return bar_offset(self.grabbar.x, self.cw, self.grabbar.w,
		self.content_size, self.view_size, self.step)
end

function ui.scrollbar:_clamp_offset()
	self._offset = clamp_offset(self._offset, self.content_size,
		self.view_size, self.step)
end

function ui.scrollbar:_update_grabbar()
	self.visible = not (self.autohide_empty and self:empty())
	local g = self.grabbar
	g.x, g.y, g.w, g.h = self:grabbar_rect()
	self:invalidate()
end

function ui.scrollbar:get_offset()
	return self._offset
end

function ui.scrollbar:get_content_size()
	return self._content_size
end

function ui.scrollbar:get_view_size()
	return self._view_size
end

function ui.scrollbar:empty()
	return self.content_size <= self.view_size
end

function ui.scrollbar:set_offset(offset)
	if self._offset == offset then return end
	self._offset = offset
	if self.updating then return end
	self:_clamp_offset()
	self:_update_grabbar()
end

function ui.scrollbar:set_content_size(size)
	if self._content_size == size then return end
	self._content_size = size
	if self.updating then return end
	self:_clamp_offset()
	self:_update_grabbar()
end

function ui.scrollbar:set_view_size(size)
	if self._view_size == size then return end
	self._view_size = size
	if self.updating then return end
	self:_clamp_offset()
	self:_update_grabbar()
end

function ui.scrollbar:override_rel_matrix(inherited)
	local mt = inherited(self)
	if self._vertical then
		mt:rotate(math.rad(90)):translate(0, -self.h)
	end
	return mt
end

function ui.scrollbar:after_init(ui, t)

	self:_clamp_offset()
	local bx, by, bw, bh = self:grabbar_rect()

	self.grabbar = self.grabbar(self.ui, {
		id = self:_subtag'grabbar', tags = 'grabbar', parent = self,
		x = bx, y = by, w = bw, h = bh,
		background_color = '#ccc',
		drag_threshold = 0,
	})

	function self.grabbar.drag(grabbar, dx, dy)
		grabbar.x = clamp(0, grabbar.x + dx, self.cw - grabbar.w)
		self._offset = self:grabbar_offset()
		self:fire('changed', self._offset)
		grabbar:invalidate()
	end

	--autohide hooks
	self.window:on({'mousemove', self}, function(win, mx, my)
		self:_autohide_mousemove(mx, my)
	end)
	self.window:on({'mouseleave', self}, function(win)
		self:_autohide_mouseleave()
	end)

	if not self.autohide then
		self:settags'near'
	end
end

function ui.scrollbar:before_free()
	self.window:off{nil, self}
end

function ui.scrollbar.grabbar:mousedown()
	self.active = true
end

function ui.scrollbar.grabbar:mouseup()
	self.active = false
end

function ui.scrollbar.grabbar:start_drag()
	return self
end

--TODO: mousepress or mousehold
function ui.scrollbar:mousedown(mx, my)
	self.active = true
	local delta = self.page_size * (mx < self.grabbar.x and -1 or 1)
	self:transition('offset', self:end_value'offset' + delta)
end

function ui.scrollbar:mouseup(mx, my)
	self.active = false
end

function ui.scrollbar:hit_test_near(mx, my)
	return box2d.hit(mx, my,
		box2d.offset(self.autohide_offset, self:content_rect()))
end

function ui.scrollbar:_autohide_mousemove(mx, my)
	local near =
		not self.autohide
		or self.grabbar.active
		or self:hit_test_near(self:from_window(mx, my))
	self:settags(near and 'near' or '-near')
end

function ui.scrollbar:_autohide_mouseleave()
	if self.autohide and not self.grabbar.active then
		self:settags'-near'
	end
end

--`vertical` and `horizontal` tags based on `vertical` property

function ui.scrollbar:get_vertical()
	return self._vertical
end

function ui.scrollbar:set_vertical(vertical)
	self._vertical = vertical
	self:settags(vertical and 'vertical' or '-vertical')
	self:settags(vertical and '-horizontal' or 'horizontal')
end

--scrollbox ------------------------------------------------------------------

ui.scrollbox = ui.layer:subclass'scrollbox'

ui.scrollbox.vscrollable = true
ui.scrollbox.hscrollable = true
ui.scrollbox.background_color = '#0000' --enable hit testing for scrolling
ui.scrollbox.vscroll = 'always' --true/'always', 'near', 'auto', false/'never'
ui.scrollbox.hscroll = 'always'
ui.scrollbox.page_size = 50 --pixels per scroll wheel notch
ui.scrollbox.vscrollbar = ui.scrollbar
ui.scrollbox.hscrollbar = ui.scrollbar
ui.scrollbox.scrollbar_margin = 6
ui.scrollbox.content_class = ui.layer

function ui.scrollbox:after_init(ui, t)

	self.content_container = self.ui:layer{
		parent = self, content_clip = true,
	}

	self.content = self.content_class(self.ui, {
		id = self:_subtag'content', parent = self.content_container,
		content_clip = true, --for faster bounding box computation
	})

	self.vscrollbar = self.vscrollbar(self.ui, {
		id = self:_subtag'vertical_scrollbar',
		parent = self, vertical = true, autohide = self.autohide,
	})

	function self.vscrollbar:override_hit_test_near(inherited, mx, my)
		if inherited(self, mx, my)
			or self.parent.hscrollbar.super.hit_test_near(self.parent.hscrollbar,
				self:to_other(self.parent.hscrollbar, mx, my))
		then
			local pmx, pmy = self.parent:to_parent(self:to_parent(mx, my))
			return self.parent:hit_test(pmx, pmy, 'vscroll') and true
		end
	end

	self.hscrollbar = self.hscrollbar(self.ui, {
		id = self:_subtag'horizontal_scrollbar',
		parent = self, vertical = false, autohide = self.autohide,
	})

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
	self.vscrollbar:settags'near'
	self.vscrollbar:settags'-near'
	self.vscrollbar:transition('offset',
		self.vscrollbar:end_value'offset' - delta * self.page_size)
end

function ui.scrollbox:before_draw_content()
	local cw, ch = self:content_size()
	local sw = self.vscrollbar.h
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	local cc = self.content_container
	local ct = self.content
	local margin = self.scrollbar_margin
	local ctw, cth = select(3, ct:bounding_box())
	local autohide = self.autohide
	cc.w = cw - (autohide and 0 or sw)
	cc.h = ch - (autohide and 0 or sw)
	vs.autohide = autohide
	vs.x = cc.w - (autohide and sw or 0) - margin
	vs.y = margin
	vs.w = cc.h - (hs.visible and sw or 0) - 2*margin
	vs.view_size = cc.h
	vs.content_size = cth
	ct.y = -vs.offset
	hs.autohide = autohide
	hs.y = cc.h - (autohide and sw or 0) - margin
	hs.x = margin
	hs.w = cc.w - (vs.visible and sw or 0) - 2*margin
	hs.view_size = cc.w
	hs.content_size = ctw
	ct.x = -hs.offset
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	--[==[

--[[
ui:style('scrollbar hot', {
	grabbar_background_color = '#ccc',
	transition_grabbar_background_color = true,
})

ui:style('scrollbar active', {
	grabbar_background_color = '#fff',
	transition_grabbar_background_color = true,
	transition_duration = 0.2,
})
]]

	ui:style('scrollbar vertical > grabbar', {
		background_color = '#f00',
	})

	ui:style('scrollbar horizontal > grabbar', {
		background_color = '#0f0',
	})

	ui:style('grabbar hot', {
		background_color = '#ff0',
	})

	local s1 = ui:scrollbar{
		parent = win,
		id = 's1',
		x = 100, y = 100, w = 200,
		size = 1000,
		--autohide = false,
		vertical = false,
	}

	local s2 = ui:scrollbar{
		parent = win,
		id = 's2',
		x = 300, y = 100, w = 200,
		size = 1000,
		--autohide = false,
		vertical = true,
	}

	function s1:changed(offset)
		print(offset)
	end
	]==]

	local sb = ui:scrollbox{
		id = 'sb',
		parent = win,
		x = 0, y = 0, w = 900, h = 500,
		background_color = '#111',
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

	sb:invalidate()

end) end
