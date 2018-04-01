
--ui scrollbar and scrollbox widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local clamp = glue.clamp

ui.scrollbar = ui.layer:subclass'scrollbar'

ui.scrollbar:_addtags'scrollbar'

ui.scrollbar._vertical = true
ui.scrollbar._offset = 0
ui.scrollbar._size = 0
ui.scrollbar.step = false --no snapping
ui.scrollbar.min_width = 0
ui.scrollbar.w = 20
ui.scrollbar.h = 20
ui.scrollbar.autohide = true
ui.scrollbar.background_color = '#222'
--ui.scrollbar.opacity = 0

ui.scrollbar.grabbar = ui.layer --class for the grabbar

--[[
ui:style('scrollbar', {
	transition_background_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
})

ui:style('scrollbar near', {
	opacity = 1,
	transition_opacity = true,
	transition_duration_opacity = .5,
	transition_delay_opacity = 0,
})

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

local function snap_offset(i, step)
	return step and i - i % step or i
end

local function bar_offset(bx, w, bw, size, step)
	return snap_offset(bx / (w - bw) * (size - w), step)
end

local function clamp_offset(i, size, w, step)
	return snap_offset(clamp(i, 0, math.max(size - w, 0)), step)
end

local function bar_segment(w, size, i, minw)
	local bw = clamp(w^2 / size, minw, w)
	local bx = i * (w - bw) / (size - w)
	local bx = clamp(bx, 0, w - bw)
	return bx, bw
end

function ui.scrollbar:grabbar_rect()
	local bx, bw = bar_segment(self.cw, self.size, self.offset, self.min_width)
	local by, bh = 0, self.ch
	return bx, by, bw, bh
end

function ui.scrollbar:grabbar_offset()
	return bar_offset(self.grabbar.x, self.cw, self.grabbar.w, self.size, self.step)
end

function ui.scrollbar:_clamp_offset()
	self._offset = clamp_offset(self._offset, self.size, self.cw, self.step)
end

function ui.scrollbar:_update_grabbar()
	local g = self.grabbar
	g.x, g.y, g.w, g.h = self:grabbar_rect()
	self:invalidate()
end

function ui.scrollbar:get_offset()
	return self._offset
end

function ui.scrollbar:set_offset(offset)
	self._offset = offset
	if self.updating then return end
	self:_clamp_offset()
	self:_update_grabbar()
end

function ui.scrollbar:get_size()
	return self._size
end

function ui.scrollbar:set_size(size)
	self._size = size
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

	function self.grabbar:after_mousedown(button)
		if button == 'left' then
			self.active = true
		end
	end

	function self.grabbar:after_mouseup(button)
		if button == 'left' then
			self.active = false
		end
	end

	function self.grabbar:start_drag()
		return self
	end

	function self.grabbar.drag(grabbar, dx, dy)
		grabbar.x = clamp(0, grabbar.x + dx, self.cw - grabbar.w)
		self._offset = self:grabbar_offset()
		self:fire('changed', self._offset)
		grabbar:invalidate()
	end

	self:_init_autohide()
end

function ui.scrollbar:before_free()
	self.window:off{nil, self}
end

--autohide

function ui.scrollbar:_init_autohide()
	self.window:on({'mousemove', self}, function(win, mx, my)
		local mx, my = self:from_window(mx, my)
		self:_autohide_mousemove(mx, my)
	end)

	self.window:on({'mouseleave', self}, function(win)
		self:_autohide_mouseleave()
	end)

	if not self.autohide then
		self:settags'near'
	end
end

function ui.scrollbar:hit_test_near(mx, my)
	return true --stub
end

function ui.scrollbar:_autohide_mousemove(mx, my)
	local near = not self.autohide or self:hit_test_near(mx, my)
	if near and not self._to1 then
		self._to1 = true
		self._to0 = false
		self:settags'near'
	elseif not near and not self._to0 then
		self._to0 = true
		self._to1 = false
		self:settags'-near'
	end
end

function ui.scrollbar:_autohide_mouseleave()
	if self.autohide and not self._to0 then
		self._to0 = true
		self._to1 = false
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

ui.scrollbox.vscroll = 'always'
ui.scrollbox.hscroll = 'always'
ui.scrollbox.scroll_width = 20
ui.scrollbox.page_size = 120

--classes of sub-components
ui.scrollbox.vscrollbar = ui.scrollbar
ui.scrollbox.hscrollbar = ui.scrollbar
ui.scrollbox.content_layer = ui.layer

function ui.scrollbox:after_init(ui, t)

	self.vscrollbar = self.vscrollbar(self.ui, {
		id = self:_subtag'vertical_scrollbar', parent = self, vertical = true,
		h = 0, size = 500, z_order = 100,
	})

	self.hscrollbar = self.hscrollbar(self.ui, {
		id = self:_subtag'horizontal_scrollbar', parent = self, vertical = false,
		w = 0, size = 500, z_order = 100,
	})

	function self.vscrollbar:hit_test_near(x, y)
		return true
	end

	function self.hscrollbar:hit_test_near(x, y)
		return true
	end

	local dw = self.vscrollbar.w
	local dh = self.hscrollbar.h
	local cw = self.w - (self.vscrollbar.autohide and 0 or dw)
	local ch = self.h - (self.hscrollbar.autohide and 0 or dh)

	self.vscrollbar.x = cw - (self.vscrollbar.autohide and dw or 0)
	self.vscrollbar.h = ch
	self.hscrollbar.y = ch - (self.vscrollbar.autohide and dh or 0)
	self.hscrollbar.w = cw

	self.content = self.content_layer(self.ui, {
		id = self:_subtag'content', parent = self,
		x = 0, y = 0, w = cw, h = ch,
	})

end

function ui.scrollbox:before_draw_content()
	local cr = self.window.cr
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

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
		x = 100, y = 100, w = 200, --h = 20,
		size = 1000,
		autohide = false,
		vertical = false,
	}

	local s2 = ui:scrollbar{
		parent = win,
		id = 's2',
		x = 300, y = 100, w = 200, --h = 20,
		size = 1000,
		autohide = false,
		vertical = true,
	}

	pp(s2.tags)

	function s1:changed(offset)
		print(offset)
	end

	--[[
	local s2 = ui:scrollbar{
		parent = win,
		id = 's2',
		x = 250, y = 10, w = 20, h = 200,
		size = 500, vertical = true,
	}

	ui:style('scrollbar', {
		border_width = 5,
		border_color = '#f00',
		--padding_right = 20,
	})
	]]

	--local sb = ui:scrollbox{parent = win, x = 400, y = 50, w = 200, h = 200, background_color = '#333'}

end) end
