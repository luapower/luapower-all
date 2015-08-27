local player = require'cplayer'

local scroll_width = 16
local min_width = 20

local function bar_size(w, size, minw)
	return math.min(math.max(w^2 / size, minw), w)
end

local function bar_offset(x, w, size, i, bw)
	return x + i * (w - bw) / (size - w)
end

local function bar_offset_clamp(bx, x, w, bw)
	return math.min(math.max(bx, x), x + w - bw)
end

local function bar_segment(x, w, size, i, minw)
	local bw = bar_size(w, size, minw)
	local bx = bar_offset(x, w, size, i, bw)
	bx = bar_offset_clamp(bx, x, w, bw)
	return bx, bw
end

local function client_offset_round(i, step)
	return i - i % step
end

local function client_offset(bx, x, w, bw, size, step)
	return client_offset_round((bx - x) / (w - bw) * (size - w), step)
end

local function client_offset_clamp(i, size, w, step)
	return client_offset_round(math.min(math.max(i, 0), math.max(size - w, 0)), step)
end

local function bar_box(x, y, w, h, size, i, vertical, min_width)
	local bx, by, bw, bh
	if vertical then
		by, bh = bar_segment(y, h, size, i, min_width)
		bx, bw = x, w
	else
		bx, bw = bar_segment(x, w, size, i, min_width)
		by, bh = y, h
	end
	return bx, by, bw, bh
end

local function scrollbar(self, t, vertical)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local size = assert(t.size, 'size missing')
	local step = t.step or 1
	local i = client_offset_clamp(t.i or 0, size, vertical and h or w, step)
	local min_width = t.min_width or min_width

	if t.autohide and self.active ~= id and not self:hotbox(x, y, w, h) then
		return i
	end

	local bx, by, bw, bh = bar_box(x, y, w, h, size, i, vertical, min_width)
	local hot = self:hotbox(bx, by, bw, bh)

	if not self.active and self.lbutton and hot then
		self.active = id
		self.ui.grab = vertical and self.mousey - by or self.mousex - bx
	elseif self.active == id then
		if self.lbutton then
			if vertical then
				by = bar_offset_clamp(self.mousey - self.ui.grab, y, h, bh)
				i = client_offset(by, y, h, bh, size, step)
			else
				bx = bar_offset_clamp(self.mousex - self.ui.grab, x, w, bw)
				i = client_offset(bx, x, w, bw, size, step)
			end
		else
			self.active = nil
		end
	end

	--drawing
	self:rect(x, y, w, h, 'faint_bg')
	if bw < w or bh < h then
		self:rect(bx, by, bw, bh, self.active == id and 'selected_bg' or hot and 'hot_bg' or 'normal_bg')
	end

	return i
end

function player:hscrollbar(t)
	return scrollbar(self, t, false)
end

function player:vscrollbar(t)
	return scrollbar(self, t, true)
end

function player:scrollbox(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local cx = t.cx or 0
	local cy = t.cy or 0
	local cw = assert(t.cw, 'cw missing')
	local ch = assert(t.ch, 'ch missing')
	local vscroll = t.vscroll or 'always' --auto, always, never
	local hscroll = t.hscroll or 'always'
	local vscroll_w = t.vscroll_w or scroll_width
	local hscroll_h = t.hscroll_h or scroll_width
	local vscroll_step = t.vscroll_step
	local hscroll_step = t.hscroll_step
	local page_size = t.page_size or 120

	local need_vscroll = vscroll == 'always' or (vscroll == 'auto' and ch > h -
									((hscroll == 'always' or hscroll == 'auto' and cw > w - vscroll_w) and hscroll_h or 0))
	local need_hscroll = hscroll == 'always' or (hscroll == 'auto' and cw > w - (need_vscroll and vscroll_w or 0))

	w = need_vscroll and w - vscroll_w or w
	h = need_hscroll and h - hscroll_h or h

	if self.wheel_delta ~= 0 and not self.active and self:hotbox(x, y, w, h) then
		cy = cy + self.wheel_delta * page_size
	end

	--drawing
	if need_vscroll then
		cy = -self:vscrollbar{id = id .. '_vscrollbar', x = x + w, y = y, w = vscroll_w, h = h,
										size = ch, i = -cy, step = vscroll_step}
	end
	if need_hscroll then
		cx = -self:hscrollbar{id = id .. '_hscrollbar', x = x, y = y + h, w = w, h = hscroll_h,
										size = cw, i = -cx, step = hscroll_step}
	end

	return
		cx, cy,     --client area coordinates, relative to the clipping rectangle
		x, y, w, h  --clipping rectangle, in absolute coordinates
end

if not ... then require'cplayer.widgets_demo' end

