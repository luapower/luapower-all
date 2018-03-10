
--math for 2D rectangles defined as (x, y, w, h).
--Written by Cosmin Apreutesei. Public Domain.

--a "1D segment" is defined as (x1, x2); a "side" is defined as (x1, x2, y)
--so it's a segment + an altitude. the corners are (x1, y1, x2, y2), where
--(x1, y1) is the top-left corner and (x2, y2) is the bottom-right corner.

local min, max, abs = math.min, math.max, math.abs

--representation forms

local function corners(x, y, w, h)
	return x, y, x + w, y + h
end

local function rect(x1, y1, x2, y2)
	return x1, y1, x2 - x1, y2 - y1
end

--normalization

local function normalize_seg(x1, x2) --make a 1D vector positive
	return min(x1, x2), max(x1, x2)
end

function normalize(x, y, w, h) --make a box have positive size
	local x1, x2 = normalize_seg(x, x+w)
	local y1, y2 = normalize_seg(y, y+h)
	return x1, x2-x1, y1, y2-y1
end

--layouting

local function align(w, h, halign, valign, bx, by, bw, bh) --align a box in another box
	local x =
		halign == 'center' and (2 * bx + bw - w) / 2 or
		halign == 'left' and bx or
		halign == 'right' and bx + bw - w
	local y =
		valign == 'center' and (2 * by + bh - h) / 2 or
		valign == 'top' and by or
		valign == 'bottom' and by + bh - h
	return x, y, w, h
end

--slice a box horizontally at a certain height and return the i'th box.
--if sh is negative, slicing is done from the bottom side.
local function vsplit(i, sh, x, y, w, h)
	if sh < 0 then
		sh = h + sh
		i = 3 - i
	end
	if i == 1 then
		return x, y, w, sh
	else
		return x, y + sh, w, h - sh
	end
end

--slice a box vertically at a certain width and return the i'th box.
--if sw is negative, slicing is done from the right side.
local function hsplit(i, sw, x, y, w, h)
	if sw < 0 then
		sw = w + sw
		i = 3 - i
	end
	if i == 1 then
		return x, y, sw, h
	else
		return x + sw, y, w - sw, h
	end
end

--slice a box in n equal slices, vertically or horizontally, and return the i'th box.
local function nsplit(i, n, direction, x, y, w, h) --direction = 'v' or 'h'
	assert(direction == 'v' or direction == 'h', 'invalid direction')
	if direction == 'v' then
		return x, y + (i - 1) * h / n, w, h / n
	else
		return x + (i - 1) * w / n, y, w / n, h
	end
end

local function translate(x0, y0, x, y, w, h) --move a box
	return x + x0, y + y0, w, h
end

local function offset(d, x, y, w, h) --offset a rectangle by d (outward if d is positive)
	return x - d, y - d, w + 2*d, h + 2*d
end

local function fit(w, h, bw, bh) --deals only with sizes; use align() to position the box
	if w / h > bw / bh then
		return bw, bw * h / w
	else
		return bh * w / h, bh
	end
end

--hit testing

local function hit(x0, y0, x, y, w, h) --check if a point (x0, y0) is inside rect (x, y, w, h)
	return x0 >= x and x0 <= x + w and y0 >= y and y0 <= y + h
end

local function hit_edges(x0, y0, d, x, y, w, h) --returns hit, left, top, right, bottom
	if hit(x0, y0, offset(d, x, y, 0, 0)) then
		return true, true, true, false, false
	elseif hit(x0, y0, offset(d, x + w, y, 0, 0)) then
		return true, false, true, true, false
	elseif hit(x0, y0, offset(d, x, y + h, 0, 0)) then
		return true, true, false, false, true
	elseif hit(x0, y0, offset(d, x + w, y + h, 0, 0)) then
		return true, false, false, true, true
	elseif hit(x0, y0, offset(d, x, y, w, 0)) then
		return true, false, true, false, false
	elseif hit(x0, y0, offset(d, x, y + h, w, 0)) then
		return true, false, false, false, true
	elseif hit(x0, y0, offset(d, x, y, 0, h)) then
		return true, true, false, false, false
	elseif hit(x0, y0, offset(d, x + w, y, 0, h)) then
		return true, false, false, true, false
	end
	return false, false, false, false, false
end

--edge snapping / transparent

local function near(x1, x2, d) --two 1D points are closer to one another than d
	return abs(x1 - x2) < d
end

local function closer(x1, x, x2) --x1 is closer to x than x2 is to x
	return abs(x1 - x) < abs(x2 - x)
end

local function overlap_seg(ax1, ax2, bx1, bx2) --two 1D segments overlap
	return not (ax2 < bx1 or bx2 < ax1)
end

local function offset_seg(d, x1, x2) --offset a 1D segment by d (outward if d is positive)
	return x1 - d, x2 + d
end

--if side A (ax1, ax2, ay) should snap to parallel side B (bx1, bx2, by),
--then return side B's y. To snap, sides should be close enough and
--overlapping, and side A should be closer to side B than to side C, if any.
local function snap_side(d, cy, ax1, ax2, ay, bx1, bx2, by)
	return near(by, ay, d) and (not cy or closer(by, ay, cy)) and
				overlap_seg(ax1, ax2, offset_seg(d, bx1, bx2)) and by
end

--snap the sides of a rectangle against a list of overlapping, transparent
--rectangles. return the corners of the snapped rectangle.
local function snap_transparent(d, ax1, ay1, ax2, ay2, rectangles)

	local cx1, cy1, cx2, cy2 --snapped sides

	for i,r in ipairs(rectangles) do
		local bx1, by1, bx2, by2 = corners(r.x, r.y, r.w, r.h)
		cy1 = snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by1) or cy1
		cy1 = snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by2) or cy1
		cy2 = snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by1) or cy2
		cy2 = snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by2) or cy2
		cx1 = snap_side(d, cx1, ay1, ay2, ax1, by1, by2, bx1) or cx1
		cx1 = snap_side(d, cx1, ay1, ay2, ax1, by1, by2, bx2) or cx1
		cx2 = snap_side(d, cx2, ay1, ay2, ax2, by1, by2, bx1) or cx2
		cx2 = snap_side(d, cx2, ay1, ay2, ax2, by1, by2, bx2) or cx2
	end

	return cx1, cy1, cx2, cy2
end

--edge snapping / opaque (same algorithm plus edge occlusion check)

--check if a horizontal side is entirely inside a rectangle.
--rotate the rectangle 90deg (switch xs with ys) to check for vertical sides.
local function side_inside_rect(ax1, ax2, ay, bx1, by1, bx2, by2)
	return ay >= by1 and ay <= by2 and ax1 >= bx1 and ax2 <= bx2
end

--check if a side is entirely inside at least one rectangle from a limited
--list of rectangles. In context this means: check if a potential snap side
--is entirely occluded by any of the rectangles in front of it.
local function side_inside_rects(ax1, ax2, ay, rectangles, stop_index, vert)
	if ax1 > ax2 then
		return true
	end
	for i = 1, stop_index do
		local r = rectangles[i]
		local x1, y1, x2, y2 = corners(r.x, r.y, r.w, r.h)
		if vert then
			y1, x1 = x1, y1
			y2, x2 = x2, y2
		end
		if side_inside_rect(ax1, ax2, ay, x1, y1, x2, y2) then
			return true
		end
	end
end

--intersect two positive 1D segments
local function intersect_segs(ax1, ax2, bx1, bx2)
	return max(ax1, bx1), min(ax2, bx2)
end

local function snap_opaque_sides(d, cy1, cy2, ax1, ax2, ay1, ay2, bx1, bx2, by1, by2, rectangles, i, vert)

	local cy1_by1 = snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by1)
	local cy1_by2 = snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by2)
	local cy2_by1 = snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by1)
	local cy2_by2 = snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by2)

	--the 1D segment of the 2 potential sides to check for occlusion.
	local dx1, dx2 = intersect_segs(ax1, ax2, offset_seg(d, bx1, bx2))

	if (cy1_by1 or cy2_by1) and not side_inside_rects(dx1, dx2, by1, rectangles, i-1, vert) then
		cy1 = cy1_by1 or cy1
		cy2 = cy2_by1 or cy2
	end
	if (cy1_by2 or cy2_by2) and not side_inside_rects(dx1, dx2, by2, rectangles, i-1, vert) then
		cy1 = cy1_by2 or cy1
		cy2 = cy2_by2 or cy2
	end
	return cy1, cy2
end

--snap the sides of a rectangle against a list of overlapping, opaque rectangles sorted front-to-back.
local function snap_opaque(d, ax1, ay1, ax2, ay2, rectangles)

	local cx1, cy1, cx2, cy2 --snapped sides

	for i,r in ipairs(rectangles) do
		local bx1, by1, bx2, by2 = corners(r.x, r.y, r.w, r.h)
		cy1, cy2 = snap_opaque_sides(d, cy1, cy2, ax1, ax2, ay1, ay2, bx1, bx2, by1, by2, rectangles, i, false)
		cx1, cx2 = snap_opaque_sides(d, cx1, cx2, ay1, ay2, ax1, ax2, by1, by2, bx1, bx2, rectangles, i, true)
	end

	return cx1, cy1, cx2, cy2
end

--edge snapping

local function snap_edges(d, x, y, w, h, rectangles, opaque)
	local snap = opaque and snap_opaque or snap_transparent
	local ax1, ay1, ax2, ay2 = corners(x, y, w, h)
	local cx1, cy1, cx2, cy2 = snap(d, ax1, ay1, ax2, ay2, rectangles)
	return rect(cx1 or ax1, cy1 or ay1, cx2 or ax2, cy2 or ay2)
end

--position snapping

local function snap_seg_pos(ax1, ax2, cx1, cx2)
	if cx1 and cx2 then
		if abs(cx1 - ax1) < abs(cx2 - ax2) then --move to whichever point is closer
			cx2 = cx1 + (ax2 - ax1) --move to cx1
		else
			cx1 = cx2 - (ax2 - ax1) --move to cx2
		end
	elseif cx1 then
		cx2 = cx1 + (ax2 - ax1)
	elseif cx2 then
		cx1 = cx2 - (ax2 - ax1)
	else
		cx1, cx2 = ax1, ax2
	end
	return cx1, cx2
end

local function snap_pos(d, x, y, w, h, rectangles, opaque)
	local snap = opaque and snap_opaque or snap_transparent
	local ax1, ay1, ax2, ay2 = corners(x, y, w, h)
	local cx1, cy1, cx2, cy2 = snap(d, ax1, ay1, ax2, ay2, rectangles)
	cx1, cx2 = snap_seg_pos(ax1, ax2, cx1, cx2)
	cy1, cy2 = snap_seg_pos(ay1, ay2, cy1, cy2)
	return rect(cx1, cy1, cx2, cy2)
end

--snapping info

local function snapped_edges(d, x1, y1, w1, h1, x2, y2, w2, h2)
	local ax1, ay1, ax2, ay2 = corners(x1, y1, w1, h1)
	local bx1, by1, bx2, by2 = corners(x2, y2, w2, h2)
	local left    = overlap_seg(ay1, ay2, by1, by2) and (near(bx1, ax1, d) or near(bx2, ax1, d))
	local top     = overlap_seg(ax1, ax2, bx1, bx2) and (near(by1, ay1, d) or near(by2, ay1, d))
	local right   = overlap_seg(ay1, ay2, by1, by2) and (near(bx1, ax2, d) or near(bx2, ax2, d))
	local bottom  = overlap_seg(ax1, ax2, bx1, bx2) and (near(by1, ay2, d) or near(by2, ay2, d))
	return left or top or right or bottom, left, top, right, bottom
end

--box overlapping test

local function overlapping(x1, y1, w1, h1, x2, y2, w2, h2)
	return
		overlap_seg(x1, x1+w1, x2, x2+w2) and
		overlap_seg(y1, y1+h1, y2, y2+h2)
end

--box intersection

local function clip(x1, y1, w1, h1, x2, y2, w2, h2)
	--intersect on each dimension
	local x1, x2 = intersect_segs(x1, x1+w1, x2, x2+w2)
	local y1, y2 = intersect_segs(y1, y1+h1, y2, y2+h2)
	--clamp size
	local w = max(x2-x1, 0)
	local h = max(y2-y1, 0)
	return x1, y1, w, h
end

--box bounding box

local function bounding_box(x1, y1, w1, h1, x3, y3, w2, h2)
	if w1 == 0 or h1 == 0 then
		return x3, y3, w2, h2
	elseif w2 == 0 or h2 == 0 then
		return x1, y1, w1, h1
	end
	local x2 = x1 + w1
	local y2 = y1 + h1
	local x4 = x3 + w2
	local y4 = y3 + h2
	return rect(
		min(x1, x2, x3, x4),
		min(y1, y2, y3, y4),
		max(x1, x2, x3, x4),
		max(y1, y2, y3, y4))
end


--box class ------------------------------------------------------------------

local box = {}
local box_mt = {__index = box}

local function new(x, y, w, h)
	return setmetatable({x = x, y = y, w = w, h = h}, box_mt)
end

function box:rect()
	return self.x, self.y, self.w, self.h
end

box_mt.__call = box.rect

function box:corners()
	return corners(self())
end

function box:align(halign, valign, parent_box)
	return new(align(r.w, r.h, halign, valign, parent_box()))
end

function box:vsplit(i, sh)
	return new(vsplit(i, sh, self()))
end

function box:hsplit(i, sw)
	return new(hsplit(i, sw, self()))
end

function box:nsplit(i, n, direction)
	return new(nsplit(i, n, direction, self()))
end

function box:translate(x0, y0)
	return new(translate(x0, y0, self()))
end

function box:offset(d) --offset a rectangle by d (outward if d is positive)
	return new(offset(d, self()))
end

function box:fit(parent_box, halign, valign)
	local w, h = fit(r.w, r.h, parent_box.w, parent_box.h)
	local x, y = align(w, h, halign or 'center', valign or 'center', parent_box())
	return new(x, y, w, h)
end

function box:hit(x0, y0)
	return hit(x0, y0, self())
end

function box:hit_edges(x0, y0, d)
	return hit_edges(x0, y0, d, self())
end

function box:snap_edges(d, rectangles)
	local x, y, w, h = self()
	return new(snap_edges(d, x, y, w, h, rectangles))
end

function box:snap_pos(d, rectangles)
	local x, y, w, h = self()
	return new(snap_pos(d, x, y, w, h, rectangles))
end

function box:snapped_edges(d)
	return snapped_edges(d, self())
end

function box:overlapping(box)
	return overlapping(self.x, self.y, self.w, self.h, box:rect())
end

function box:clip(box)
	return new(clip(self.x, self.y, self.w, self.h, box:rect()))
end

function box:join(box)
	self.x, self.y, self.w, self.h =
		bounding_box(self.x, self.y, self.w, self.h, box:rect())
end

local box_module = {
	--representation forms
	corners = corners,
	rect = rect,
	--normalization
	normalize = normalize,
	--layouting
	align = align,
	vsplit = vsplit,
	hsplit = hsplit,
	nsplit = nsplit,
	translate = translate,
	offset = offset,
	fit = fit,
	--hit testing
	hit = hit,
	hit_edges = hit_edges,
	--snapping
	snap_edges = snap_edges,
	snap_pos = snap_pos,
	snapped_edges = snapped_edges,
	--overlapping
	overlapping = overlapping,
	--clipping
	clip = clip,
	--bounding box
	bounding_box = bounding_box,
}

setmetatable(box_module, {__call = function(r, ...) return new(...) end})

return box_module
