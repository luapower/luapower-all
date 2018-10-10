
--Scrollbar and Scrollbox Widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local box2d = require'box2d'
local glue = require'glue'

local clamp = glue.clamp
local lerp = glue.lerp

local scrollbar = ui.layer:subclass'scrollbar'
ui.scrollbar = scrollbar
scrollbar.iswidget = true

local grip = ui.layer:subclass'scrollbar_grip'
scrollbar.grip_class = grip

--default geometry

scrollbar.w = 12
scrollbar.h = 12
grip.min_w = 20

ui:style('scrollbar autohide, scrollbar autohide > scrollbar_grip', {
	corner_radius = 100,
})

--default colors

scrollbar.background_color = '#222'
grip.background_color = '#999'

ui:style('scrollbar_grip :hot', {
	background_color = '#bbb',
})

ui:style('scrollbar_grip :active', {
	background_color = '#fff',
})

--default initial state

scrollbar.content_length = 0
scrollbar.view_length = 0
scrollbar.offset = 0  --in 0..content_length range

--default behavior

scrollbar.vertical = true --scrollbar is rotated 90deg to make it vertical
scrollbar.step = false --no snapping
scrollbar.autohide = false --hide when mouse is not near the scrollbar
scrollbar.autohide_empty = true --hide when content is smaller than the view
scrollbar.autohide_distance = 20 --distance around the scrollbar
scrollbar.click_scroll_length = 300
	--^how much to scroll when clicking on the track (area around the grip)

--fade animation

scrollbar.opacity = 0 --prevent fade out on init

ui:style('scrollbar', {
	opacity = 1,
	transition_opacity = false,
})

--fade out
ui:style('scrollbar autohide', {
	opacity = 0,
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
	transition_blend_opacity = 'wait',
})

ui:style('scrollbar :empty', {
	opacity = 0,
	transition_opacity = false,
})

--fade in
ui:style('scrollbar autohide :near', {
	opacity = .5,
	transition_opacity = true,
	transition_delay_opacity = 0,
	transition_duration_opacity = .5,
	transition_blend_opacity = 'replace',
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
	local grip = self:grip_class(self.grip)

	function grip.drag(grip, dx, dy)
		grip.x = clamp(0, grip.x + dx, self.cw - grip.w)
		self:transition('offset', self:grip_offset(), 0)
	end

	return grip
end

--scroll state

scrollbar:stored_property'content_length'
scrollbar:stored_property'view_length'
scrollbar:stored_property'offset'

function scrollbar:clamp_offset(offset)
	local max_offset = self.content_length - self.view_length
	offset = clamp(offset, 0, math.max(max_offset, 0))
	return snap_offset(offset, self.step)
end

function scrollbar:set_offset(offset)
	local old_offset = self._offset
	offset = self:clamp_offset(offset)
	self._offset = offset
	self:settag(':empty', self:empty())
	if offset ~= old_offset then
		self:fire('offset_changed', offset, old_offset)
	end
end

function scrollbar:after_set_content_length() self.offset = self.offset end
function scrollbar:after_set_view_length() self.offset = self.offset end

scrollbar:instance_only'content_length'
scrollbar:instance_only'view_length'
scrollbar:instance_only'offset'

function scrollbar:reset(content_length, view_length, offset)
	self._content_length = content_length
	self._view_length = view_length
	self.offset = offset
end

function scrollbar:empty()
	return self.content_length <= self.view_length
end

scrollbar:init_ignore{content_length=1, view_length=1, offset=1}

function scrollbar:after_init(ui, t)
	self:reset(t.content_length, t.view_length, t.offset)
	self.grip = self:create_grip()
end

--visibility state

function scrollbar:check_visible(...)
	return self.visible
		and (not self.autohide_empty or not self:empty())
		and (not self.autohide or self:check_visible_autohide(...))
end

--scroll API

function scrollbar:scroll_to(offset, duration)
	if self:check_visible() == 'hit_test' then
		self:settag(':near', true)
		self:sync()
		self:settag(':near', false)
	end
	offset = self:clamp_offset(offset) --we want to animate the clamped length!
	self:transition('offset', offset, duration)
end

function scrollbar:scroll_to_view(x, w, duration)
	local sx = self:end_value'offset'
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

--autohide feature

scrollbar:stored_property'autohide'
function scrollbar:after_set_autohide(autohide)
	self:settag('autohide', autohide)
end
scrollbar:instance_only'autohide'

function scrollbar:hit_test_near(mx, my) --mx,my in window space
	if not mx then
		return 'hit_test'
	end
	mx, my = self:from_window(mx, my)
	return box2d.hit(mx, my,
		box2d.offset(self.autohide_distance, self:client_rect()))
end

function scrollbar:check_visible_autohide(mx, my)
	return self.grip.active
		or (not self.ui.active_widget and self:hit_test_near(mx, my))
end

function scrollbar:after_set_parent()
	if not self.window then return end
	self.window:on({'mousemove', self}, function(win, mx, my)
		self:settag(':near', self:check_visible(mx, my))
	end)
	self.window:on({'mouseleave', self}, function(win)
		local visible = self:check_visible()
		if visible == 'hit_test' then visible = false end
		self:settag(':near', visible)
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

	local visible = self:check_visible()
	if visible ~= 'hit_test' then
		self:settag(':near', visible)
	end
end

--scrollbox ------------------------------------------------------------------

local scrollbox = ui.layer:subclass'scrollbox'
ui.scrollbox = scrollbox
scrollbox.iswidget = true

scrollbox.view_class = ui.layer
scrollbox.content_class = ui.layer
scrollbox.vscrollbar_class = scrollbar
scrollbox.hscrollbar_class = scrollbar

function scrollbox:after_init(ui, t)

	self.view = self:view_class({
		clip_content = true,
	}, self.view)

	if not self.content or not self.content.islayer then
		self.content = self.content_class(self.ui, {
			tags = 'content',
			parent = self.view,
			clip_content = true, --for faster bounding box computation
		}, self.content)
	elseif self.content then
		self.content.parent = self.view
	end

	self.vscrollbar = self:vscrollbar_class({
		tags = 'vscrollbar',
		scrollbox = self,
		vertical = true,
		iswidget = false,
	}, self.scrollbar, self.vscrollbar)

	self.hscrollbar = self:hscrollbar_class({
		tags = 'hscrollbar',
		scrollbox = self,
		vertical = false,
		iswidget = false,
	}, self.scrollbar, self.hscrollbar)

	--make autohide scrollbars to show and hide in sync.
	--TODO: remove the brk anti-recursion barrier hack.
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	function vs:override_check_visible_autohide(inherited, mx, my, brk)
		return inherited(self, mx, my)
			or (not brk and hs.autohide and hs:check_visible(mx, my, true))
	end
	function hs:override_check_visible_autohide(inherited, mx, my, brk)
		return inherited(self, mx, my)
			or (not brk and vs.autohide and vs:check_visible(mx, my, true))
	end
end

--mouse interaction: wheel scrolling

scrollbox.vscrollable = true
scrollbox.hscrollable = true
scrollbox.wheel_scroll_length = 50 --pixels per scroll wheel notch

function scrollbox:mousewheel(delta)
	self.vscrollbar:scroll(-delta * self.wheel_scroll_length)
end

--drawing

--stretch content to the view size to avoid scrolling on that dimension.
scrollbox.auto_h = false
scrollbox.auto_w = false

function scrollbox:after_sync()

	local vs = self.vscrollbar
	local hs = self.hscrollbar
	local view = self.view
	local content = self.content
	content.parent = view

	local w, h = self:client_size()

	local vs_margin = vs.margin or 0
	local hs_margin = hs.margin or 0

	local vs_overlap = vs.autohide or vs.overlap or not vs.visible
	local hs_overlap = hs.autohide or hs.overlap or not hs.visible

	local sw = vs.h + vs_margin
	local sh = hs.h + hs_margin

	--for `auto_w`, set up a preliminary maximum-allowed content `w` then
	--measure the actual content size with `bounding_box()`, assuming that
	--the content reflows itself after `w`. if the content reflows such
	--that it overflows vertically, another reflowing is ncessary, this time
	--with a smaller `w` which makes room for the needed vertical scrollbar,
	--under the assumption that the content will still overflow vertically
	--with the smaller `w`. the same logic applies symmetrically for `auto_h`.
	local cw0 = self.auto_w and w - ((vs_overlap or vs.autohide_empty) and 0 or sw)
	local ch0 = self.auto_h and h - ((hs_overlap or hs.autohide_empty) and 0 or sh)

	--auto_w and auto_h are mutually exclusive. auto_w takes priority.
	if cw0 then ch0 = nil end

	::reflow::

	if cw0 or ch0 then
		if cw0 then content.w = cw0; content.h = 0 end
		if ch0 then content.h = ch0; content.w = 0 end
		local _, _, cw, ch = content:text_bounding_box()
		content.cw = cw
		content.ch = ch
	end

	local _, _, cw, ch = content:bounding_box()

	--compute view dimensions by deciding which scrollbar is either hidden
	--or is overlapping the view box so it takes no space of its own.
	local vs_nospace, hs_nospace

	local vs_nospace = vs_overlap
		or (vs.autohide_empty and ch <= h and (ch <= h - sh or 'depends'))

	local hs_nospace = hs_overlap
		or (hs.autohide_empty and cw <= w and (cw <= w - sw or 'depends'))

	if    (vs_nospace == 'depends' and not hs_nospace)
		or (hs_nospace == 'depends' and not vs_nospace)
	then
		vs_nospace = false
		hs_nospace = false
	end

	view.w = w - (vs_nospace and 0 or sw)
	view.h = h - (hs_nospace and 0 or sh)

	print(content.cw, content.w, cw, view.w)

	--if the view's `w` is smaller than the preliminary `w` on which content
	--reflowing was based on for `auto_w`, then do it again with the real `w`.
	--the same applies for `h` for `auto_h`.
	if cw0 and view.w < cw0 then
		cw0 = view.w
		goto reflow
	elseif ch0 and view.h < ch0 then
		ch0 = view.h
		goto reflow
	end

	content.w = cw
	content.h = ch

	--reset the scrollbars state.
	hs:reset(cw, view.w, hs.offset)
	vs:reset(ch, view.h, vs.offset)

	--scroll the content layer.
	content.y = -vs.offset
	content.x = -hs.offset

	--compute scrollbar dimensions.
	vs.w = view.h - 2 * vs_margin --.w is its height!
	hs.w = view.w - 2 * hs_margin

	--check which scrollbars are visible and actually overlapping the view.
	--NOTE: scrollbars state must already be set here since we call `empty()`.
	local hs_overlapping = hs.visible and hs_overlap
		and (not hs.autohide_empty or not hs:empty())

	local vs_overlapping = vs.visible and vs_overlap
		and (not vs.autohide_empty or not vs:empty())

	--shorten the ends of scrollbars so they don't overlap each other.
	vs.w = vs.w - (vs_overlap and hs_overlapping and sh or 0)
	hs.w = hs.w - (hs_overlap and vs_overlapping and sw or 0)

	--compute scrollbar positions.
	vs.x = view.w - (vs_nospace and sw or 0)
	hs.y = view.h - (hs_nospace and sh or 0)
	vs.y = vs_margin
	hs.x = hs_margin
end

--scroll API

function scrollbox:scroll_to_view(x, y, w, h) --x, y is in content's content space.
	x, y = self.content:from_content(x, y)
	self.hscrollbar:scroll_to_view(x, w)
	self.vscrollbar:scroll_to_view(y, h)
end

--clipping API

function scrollbox:view_rect() --view rect in content's content space.
	local x, y = self.view:to_other(self.content, 0, 0)
	return x, y, self.view:client_size()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:style('scrollbox', {
		border_width = 1,
		border_color = '#f00',
	})

	local function mkcontent(w, h)
		return ui:layer{
			w = w or 2000,
			h = h or 32000,
			border_width = 20,
			border_color = '#ff0',
			background_type = 'gradient',
			background_colors = {'#ff0', 0.5, '#00f'},
			background_x2 = 100,
			background_y2 = 100,
			background_extend = 'repeat',
		}
	end

	local x, y = 10, 10
	local function xy()
		x = x + 200
		if x + 190 > win.cw then
			x = 10
			y = y + 200
		end
	end

	--not autohide, custom bar metrics
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(),
		vscrollbar = {h = 20, margin = 20},
		hscrollbar = {h = 30, margin = 10},
	}
	xy()

	--overlap, custom bar metrics
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(),
		vscrollbar = {h = 20, margin = 20},
		hscrollbar = {h = 30, margin = 10},
		scrollbar = {overlap = true},
	}
	xy()

	--not autohide, autohide_empty vertical
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(nil, 165),
	}
	xy()

	--not autohide, autohide_empty horizontal
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(165),
		autohide = true,
	}
	xy()

	--not autohide, autohide_empty horizontal -> vertical
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(185, 175),
		autohide = true,
	}
	xy()

	--not autohide, autohide_empty vertical -> horizontal
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(175, 185),
		autohide = true,
	}
	xy()

	--autohide_empty case
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(180, 180),
	}
	xy()

	--autohide
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(),
		scrollbar = {
			autohide = true,
		},
	}
	xy()

	--autohide, autohide_empty vertical
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(nil, 175),
		scrollbar = {
			autohide = true,
		}
	}
	xy()

	--autohide, autohide_empty horizontal
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(175),
		scrollbar = {
			autohide = true,
		}
	}
	xy()

	--autohide horizontal only
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		content = mkcontent(175),
		hscrollbar = {
			autohide = true,
		}
	}
	xy()

end) end
