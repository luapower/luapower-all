
--Scrollbar and Scrollbox Widgets.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local box2d = require'box2d'
local glue = require'glue'

local noop = glue.noop
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

function scrollbar:clamp_and_snap_offset(offset)
	local max_offset = self.content_length - self.view_length
	offset = clamp(offset, 0, math.max(max_offset, 0))
	return snap_offset(offset, self.step)
end

function scrollbar:set_offset(offset)
	local old_offset = self._offset
	offset = self:clamp_and_snap_offset(offset)
	self._offset = offset
	self:settag(':empty', self:empty(), true)
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
	offset = self:clamp_and_snap_offset(offset)
		--^we want to animate the clamped length!
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

function scrollbar:before_sync_layout_children()
	local g = self.grip
	g.x, g.y, g.w, g.h = self:grip_rect()

	local visible = self:check_visible()
	if visible ~= 'hit_test' then
		self:settag(':near', visible, true)
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

	--NOTE: the view is created last so it is freed first, so that the
	--content can still access the scrollbox on its dying breath!
	self.view = self:view_class({
		tags = 'scrollbox_view',
		clip_content = 'background', --we want to pad the content, but not clip it
		sync_layout = noop, --prevent auto-sync'ing content's layout
	}, self.view)

	if not self.content or not self.content.islayer then
		self.content = self.content_class(self.ui, {
			tags = 'scrollbox_content',
			parent = self.view,
		}, self.content)
	elseif self.content then
		self.content.parent = self.view
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

scrollbox:forward_properties('view', 'view_', {
	padding=1,
	padding_left=1,
	padding_right=1,
	padding_top=1,
	padding_bottom=1,
})

--stretch content to the view size to avoid scrolling on that dimension.
scrollbox.auto_h = false
scrollbox.auto_w = false

function scrollbox:sync_layout_children()

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

	--for `auto_w`, lay out the content with `min_w` set to view's cw, and then
	--get its size. if the content overflows vertically, another layout pass
	--is necessary, this time with a smaller `min_w`, making room for the
	--needed vertical scrollbar, under the assumption that the content will
	--still overflow vertically under the smaller `min_w`. the same logic
	--applies symmetrically for `auto_h`.
	local cw0 = self.auto_w and w - ((vs_overlap or vs.autohide_empty) and 0 or sw)
	local ch0 = self.auto_h and h - ((hs_overlap or hs.autohide_empty) and 0 or sh)

	if cw0 and ch0 then
		self.ui:warn'both auto_w and auto_h specified. auto_h ignored.'
		ch0 = nil
	end

	::reflow::

	if cw0 or ch0 then
		content:sync_layout_separate_axes(cw0 and 'xy' or 'yx', cw0, ch0)
	else
		content:sync_layout()
	end

	local cw, ch = content:size()

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

	--if the view's `cw` is smaller than the preliminary `w` on which content
	--reflowing was based on for `auto_w`, then do it again with the real `cw`.
	--the same applies for `ch` for `auto_h`.
	if cw0 and view.cw < cw0 then
		cw0 = view.cw
		goto reflow
	elseif ch0 and view.ch < ch0 then
		ch0 = view.ch
		goto reflow
	end

	--reset the scrollbars state.
	hs:reset(cw, view.cw, hs.offset)
	vs:reset(ch, view.ch, vs.offset)

	--scroll the content layer.
	content.x = -hs.offset * content.w / cw -- content.pw1
	content.y = -vs.offset * content.h / ch -- content.ph1

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

	for _,layer in ipairs(self) do
		if layer ~= content then
			layer:sync_layout() --recurse
		end
	end
end

--scroll API

--x, y is in content's content space.
function scrollbox:scroll_to_view(x, y, w, h)
	x, y = self.content:from_content(x, y)
	self.hscrollbar:scroll_to_view(x, w)
	self.vscrollbar:scroll_to_view(y, h)
end

--x, y, w, h is in own content space.
function scrollbox:make_visible(x, y, w, h)
	x, y = self:to_other(self.content, x, y)
	self:scroll_to_view(x, y, w, h)
end

--multi-line editbox ---------------------------------------------------------

local textarea = scrollbox:subclass'textarea'
ui.textarea = textarea

textarea.tags = 'standalone'

textarea.auto_w = true
textarea.view_padding_left = 0
textarea.view_padding_right = 6

local editbox = ui.layer:subclass'textarea_content'
textarea.content_class = editbox

editbox.layout = 'textbox'
editbox.text_align_x = 'auto'
editbox.text_align_y = 'top'
editbox.focusable = true
editbox.text_selectable = true
editbox.text_editable = true
editbox.clip_content = false

function textarea:get_value() return self.editbox.value end
function textarea:set_value(val) self.editbox.value = val end
textarea:instance_only'value'

textarea:init_ignore{value=1}

function textarea:after_init(ui, t)
	self.editbox = self.content
	self.value = t.value
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.w = 240

	ui:style('scrollbox', {
		--border_width = 1,
		--border_color = '#f00',
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

	local s = [[
Lorem ipsum dolor sit amet, quod oblique vivendum ex sed. Impedit nominavi maluisset sea ut. Utroque apeirian maluisset cum ut. Nihil appellantur at his, fugit noluisse eu vel, mazim mandamus ex quo.

Mei malis eruditi ne. Movet volumus instructior ea nec. Vel cu minimum molestie atomorum, pro iudico facilisi et, sea elitr partiendo at. An has fugit assum accumsan.]]

	--[==[

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

	--auto_w
	ui:scrollbox{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		auto_w = true,
		content = {
			layout = 'textbox',
			text_align_x = 'left',
			text_align_y = 'top',
			text = s,
		},
	}
	xy()

	]==]

	ui:textarea{
		parent = win,
		x = x, y = y, w = 180, h = 180,
		value = s,
	}
	xy()

end) end
