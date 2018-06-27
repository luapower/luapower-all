--math for 2D line segments defined as (x1, y1, x2, y2).

local abs, min, max = math.abs, math.min, math.max

local distance = require'path2d_point'.distance
local distance2 = require'path2d_point'.distance2

local epsilon = 1e-10
local function near(x, y)
	return abs(x - y) <= epsilon * max(1, abs(x), abs(y))
end

--evaluate a line at time t using linear interpolation.
--the time between 0..1 covers the segment interval.
local function point(t, x1, y1, x2, y2)
	return
		x1 + t * (x2 - x1),
		y1 + t * (y2 - y1)
end

--length of line at time t.
local function length(t, x1, y1, x2, y2)
	return t * distance(x1, y1, x2, y2)
end

--bounding box of line in (x,y,w,h) form.
local function bounding_box(x1, y1, x2, y2)
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end
	return x1, y1, x2-x1, y2-y1
end

--split line segment into two line segments at time t (t is capped between 0..1).
local function split(t, x1, y1, x3, y3)
	t = min(max(t,0),1)
	local x2, y2 = point(t, x1, y1, x3, y3)
	return
		x1, y1, x2, y2, --first segment
		x2, y2, x3, y3  --second segment
end

--intersect infinite line with its perpendicular from point (x, y)
--return the intersection point.
local function point_line_intersection(x, y, x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local k = dx^2 + dy^2
	if near(k, 0) then return x1, y1 end --line has no length
	local k = ((x - x1) * dy - (y - y1) * dx) / k
	return
		x - k * dy,
		y + k * dx
end

--return shortest distance-squared from point (x0, y0) to line, plus the
--touch point, and the time in the line where the touch point splits the line.
local function hit(x0, y0, x1, y1, x2, y2)
	local x, y = point_line_intersection(x0, y0, x1, y1, x2, y2)
	local tx = near(x2, x1) and 0 or (x - x1) / (x2 - x1)
	local ty = near(y2, y1) and 0 or (y - y1) / (y2 - y1)
	if tx < 0 or ty < 0 then
		--intersection is outside the segment, closer to the first endpoint
		return distance2(x0, y0, x1, y1), x1, y1, 0
	elseif tx > 1 or ty > 1 then
		--intersection is outside the segment, closer to the second endpoint
		return distance2(x0, y0, x2, y2), x2, y2, 1
	end
	return distance2(x0, y0, x, y), x, y, max(tx, ty)
end

--intersect line segment (x1, y1, x2, y2) with line segment (x3, y3, x4, y4).
--returns the time on the first line and the time on the second line where
--intersection occurs. if the intersection occurs outside the segments
--themselves, then t1 and t2 are outside the 0..1 range. if the lines are
--parallel then t1 and t2 are +/-inf. if they coincidental, t1 and t2 are nan.
local function line_line_intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	local d = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
	return
		((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / d,
		((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / d
end

--transform to a quad bezier that advances linearly i.e. the point on the line at t
--best matches the point on the curve at t.
local function to_bezier2(x1, y1, x2, y2)
	return
		x1, y1,
		(x1 + x2) / 2,
		(y1 + y2) / 2,
		x2, y2
end

--transform to a cubic bezier that advances linearly i.e. the point on the line at t
--best matches the point on the curve at t.
local function to_bezier3(x1, y1, x2, y2)
	return
		x1, y1,
		(2 * x1 + x2) / 3,
		(2 * y1 + y2) / 3,
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		x2, y2
end

--parallel line segment at a distance on the right side of a segment.
--use a negative distance for the left side, or reflect the returned points against their respective initial points
local function offset(d, x1, y1, x2, y2)
	local dx, dy = -(y2-y1), x2-x1 --normal vector of the same length as original segment
	local k = d / distance(x1, y1, x2, y2) --normal vector scale factor
	return --normal vector scaled and translated to (x1,y1) and (x2,y2)
		x1 + dx * k, y1 + dy * k,
		x2 + dx * k, y2 + dy * k
end

if not ... then require'path2d_line_demo' end

return {
	point_line_intersection = point_line_intersection,
	line_line_intersection = line_line_intersection,
	to_bezier2 = to_bezier2,
	to_bezier3 = to_bezier3,
	offset = offset,
	--path API
	bounding_box = bounding_box,
	point = point,
	length = length,
	split = split,
	hit = hit,
}

