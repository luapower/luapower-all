--math for 2D elliptic arcs defined as:
--  (center_x, center_y, radius_x, radius_y, start_angle, sweep_angle, [rotation], [x2, y2]).
--angles are expressed in degrees, not radians.
--sweep angle is capped between -360..360deg.
--x2, y2 is an optional override of arc's second end point to use when numerical exactness of the endpoint is required.
--mt is an affine transform that applies to the resulted segments.
--segment_max_sweep is for limiting the arc portion that each bezier segment can cover and is computed automatically.

if not ... then require'path_arc_demo' end

local reflect_point = require'path_point'.reflect_point
local rotate_point  = require'path_point'.rotate_point
local hypot = require'path_point'.hypot
local line_to_bezier3 = require'path_line'.to_bezier3
local bezier3 = require'path_bezier3'
local point_around = require'path_point'.point_around
local point_angle = require'path_point'.point_angle
local distance2 = require'path_point'.distance2
local bezier3_length = require'path_bezier3'.length
local bezier3_bounding_box = require'path_bezier3'.bounding_box

local abs, min, max, sqrt, ceil, sin, cos, radians =
	math.abs, math.min, math.max, math.sqrt, math.ceil, math.sin, math.cos, math.rad

local angle_epsilon = 1e-10

--observed sweep: an arc's sweep can be larger than 360deg but we can only render the first -360..360deg of it.
local function observed_sweep(sweep_angle)
	return max(min(sweep_angle, 360), -360)
end

--observed sweep between two arbitrary angles, sweeping from a1 to a2 in a specified direction.
local function sweep_between(a1, a2, clockwise)
	a1 = a1 % 360
	a2 = a2 % 360
	clockwise = clockwise ~= false
	local sweep = a2 - a1
	if sweep < 0 and clockwise then
		sweep = sweep + 360
	elseif sweep > 0 and not clockwise then
		sweep = sweep - 360
	end
	return sweep
end

--angle time on an arc (or outside the arc if outside 0..1 range) for a specified angle.
local function sweep_time(hit_angle, start_angle, sweep_angle)
	sweep_angle = observed_sweep(sweep_angle)
	return sweep_between(start_angle, hit_angle, sweep_angle >= 0) / sweep_angle
end

--check if an angle is inside the sweeped arc.
local function is_sweeped(hit_angle, start_angle, sweep_angle)
	local t = sweep_time(hit_angle, start_angle, sweep_angle)
	return t >= 0 and t <= 1
end

--evaluate ellipse at angle a.
local function point_at(a, cx, cy, rx, ry, rotation, mt)
	rx, ry = abs(rx), abs(ry)
	a = radians(a)
	rotation = rotation or 0
	local x = cx + cos(a) * rx
	local y = cy + sin(a) * ry
	if rotation ~= 0 then
		x, y = rotate_point(x, y, cx, cy, rotation)
	end
	if mt then
		x, y = mt(x, y)
	end
	return x, y
end

--evaluate elliptic arc at time t (the time between 0..1 covers the arc over the sweep interval).
local function point(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	return point_at(start_angle + t * observed_sweep(sweep_angle), cx, cy, rx, ry, rotation, mt)
end

--tangent vector on elliptic arc at time t based on http://content.gpwiki.org/index.php/Tangents_To_Circles_And_Ellipses.
--the vector is always oriented towards the sweep of the arc.
local function tangent_vector(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	rotation = rotation or 0
	local a = radians(start_angle + t * sweep_angle)
	--px,py is the point at time t on the origin-centered, unrotated ellipse (0, 0, rx, ry, 0).
	local px = cos(a) * rx
	local py = sin(a) * ry
	--tx,ty is the tip point of the tangent vector at angle a, oriented towards the sweep.
	local sign = sweep_angle >= 0 and 1 or -1
	local tx = px + sign * rx * py / ry
	local ty = py - sign * ry * px / rx
	--now rotate, translate to origin, and transform the points as needed.
	if rotation ~= 0 then
		px, py = rotate_point(px, py, 0, 0, rotation)
		tx, ty = rotate_point(tx, ty, 0, 0, rotation)
	end
	px, py = cx + px, cy + py
	tx, ty = cx + tx, cy + ty
	if t == 1 and x2 then
		px, py = x2, y2
	end
	if mt then
		px, py = mt(px, py)
		tx, ty = mt(tx, ty)
	end
	return px, py, tx, ty
end

local function endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	local x1, y1 = point_at(start_angle, cx, cy, rx, ry, rotation, mt)
	if not x2 then
		x2, y2 = point_at(start_angle + observed_sweep(sweep_angle), cx, cy, rx, ry, rotation, mt)
	elseif mt then
		x2, y2 = mt(x2, y2)
	end
	return x1, y1, x2, y2
end

--determine the length of the major axis of a circle of the given radius after applying an affine transformation.
--look at cairo-matrix.c for the math behind it.
local function transformed_circle_major_axis(mt, r)
	if not mt or mt:has_unity_scale() then return r end
	local a, b, c, d = mt:unpack()
	local i = a^2 + b^2
	local j = c^2 + d^2
	local f = (i + j) / 2
	local g = (i - j) / 2
	local h = a*c + b*d
	return r * sqrt(f + hypot(g, h))
end

--this formula is such that enables a non-oscillating segment-time-to-arc-time at screen resolutions (see demo).
local function best_segment_max_sweep(mt, rx, ry)
	local scale_factor = transformed_circle_major_axis(mt, max(abs(rx), abs(ry))) / 1024
	scale_factor = max(scale_factor, 0.1) --cap scale factor so that we don't create sweeps larger than 90 deg.
	return sqrt(1/scale_factor^0.6) * 30 --faster way to say 1/2^log10(scale) * 30
end

local function segment(cx, cy, rx, ry, start_angle, sweep_angle)
	local a = radians(sweep_angle / 2)
	local x0 = cos(a)
	local y0 = sin(a)
	local tx = (1 - x0) * 4 / 3
	local ty = y0 - tx * x0 / y0
	local px1 =  x0 + tx
	local py1 = -ty
	local px2 =  x0 + tx
	local py2 =  ty
	local px3 =  x0
	local py3 =  y0
	local a = radians(start_angle + sweep_angle / 2)
	local sn = sin(a)
	local cs = cos(a)
	return
		cx + rx * (px1 * cs - py1 * sn), --c1x
		cy + ry * (px1 * sn + py1 * cs), --c1y
		cx + rx * (px2 * cs - py2 * sn), --c2x
		cy + ry * (px2 * sn + py2 * cs), --c2y
		cx + rx * (px3 * cs - py3 * sn), --p2x
		cy + ry * (px3 * sn + py3 * cs)  --p2y
end

local function to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	if abs(sweep_angle) < angle_epsilon then
		local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write('curve', select(3, line_to_bezier3(x1, y1, x2, y2)))
	end

	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	rotation = rotation or 0
	if not x2 then
		x2, y2 = point_at(start_angle + sweep_angle, cx, cy, rx, ry, rotation, mt)
	elseif mt then
		x2, y2 = mt(x2, y2)
	end
	segment_max_sweep = segment_max_sweep or best_segment_max_sweep(mt, rx, ry)

	local segments = ceil(abs(sweep_angle / segment_max_sweep))
	local segment_sweep = sweep_angle / segments
	local end_angle = start_angle + sweep_angle - segment_sweep / 2

	for angle = start_angle, end_angle, segment_sweep do
		local bx2, by2, bx3, by3, bx4, by4 = segment(cx, cy, rx, ry, angle, segment_sweep)
		if rotation ~= 0 then
			bx2, by2 = rotate_point(bx2, by2, cx, cy, rotation)
			bx3, by3 = rotate_point(bx3, by3, cx, cy, rotation)
			bx4, by4 = rotate_point(bx4, by4, cx, cy, rotation)
		end
		if mt then
			bx2, by2 = mt(bx2, by2)
			bx3, by3 = mt(bx3, by3)
			bx4, by4 = mt(bx4, by4)
		end
		if abs(end_angle - angle) < abs(segment_sweep) then --last segment: override endpoint with the specified one
			bx4, by4 = x2, y2
		end
		write('curve', bx2, by2, bx3, by3, bx4, by4)
	end
end

--given the time t on the i'th arc segment of an arc, return the corresponding arc time.
--we assume that time found on the bezier segment approximates well the time on the arc segment.
--the assumption is only accurate if the arc is composed of enough segments, given arc's transformed size.
local function segment_time_to_arc_time(i, t, sweep_angle, segment_max_sweep)
	local sweep_angle = abs(observed_sweep(sweep_angle))
	if sweep_angle < angle_epsilon then
		return t
	end
	local segments = ceil(sweep_angle / segment_max_sweep)
	return (i-1+t) / segments
end

--given the time t on an arc return the corresponding segment number and the time on that segment.
local function arc_time_to_segment_time(t, sweep_angle, segment_max_sweep)
	local sweep_angle = abs(observed_sweep(sweep_angle))
	if sweep_angle < angle_epsilon then
		return 1, t
	end
	local segments = ceil(sweep_angle / segment_max_sweep)
	local d = t * segments
	local i = math.floor(d)
	return i+1, d-i
end

--shortest distance-squared from point (x0, y0) to a circular arc, plus the touch point, and the time in the arc
--where the touch point splits the arc.
local function circular_arc_hit(x0, y0, cx, cy, r, start_angle, sweep_angle, x2, y2)
	r = abs(r)
	sweep_angle = observed_sweep(sweep_angle)
	if x0 == cx and y0 == cy then --projecting from the center
		local x, y = point_around(cx, cy, r, start_angle)
		return r, x, y, 0
	end
	local hit_angle = point_angle(x0, y0, cx, cy)
	local end_angle = start_angle + observed_sweep(sweep_angle)
	local t = sweep_time(hit_angle, start_angle, sweep_angle)
	if t < 0 or t > 1 then --hit point is outside arc's sweep opening, check distance to end points
		local x1, y1, x2, y2 = endpoints(cx, cy, r, r, start_angle, sweep_angle, x2, y2)
		local d1 = distance2(x0, y0, x1, y1)
		local d2 = distance2(x0, y0, x2, y2)
		if d1 <= d2 then
			return d1, x1, y1, 0
		else
			return d2, x2, y2, sweep_time(end_angle, start_angle, sweep_angle)
		end
	end
	local x, y = point_around(cx, cy, r, hit_angle)
	return distance2(x0, y0, x, y), x, y, t
end

--arc hit under affine transform: we construct the arc from a number of bezier segments, hit those and then
--compute the arc time from segment time. segment_max_sweep must be small enough given arc's size.
local function hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	if rx == ry and not mt then
		return circular_arc_hit(x0, y0, cx, cy, rx, start_angle, sweep_angle, x2, y2)
	end
	local i = 0 --segment count
	local mind, minx, miny, mint, mini
	local x1, y1 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	local function write(s, ...)
		i = i + 1
		local d, x, y, t = bezier3.hit(x0, y0, x1, y1, ...)
		x1, y1 = select(5, ...)
		if not mind or d < mind then
			mind, minx, miny, mint, mini = d, x, y, t, i
		end
	end
	segment_max_sweep = segment_max_sweep or best_segment_max_sweep(mt, rx, ry)
	to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	mint = segment_time_to_arc_time(mini, mint, sweep_angle, segment_max_sweep)
	return mind, minx, miny, mint
end

local function split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	t = min(max(t,0),1)
	sweep_angle = observed_sweep(sweep_angle)
	local sweep1 = t * sweep_angle
	local sweep2 = sweep_angle - sweep1
	local split_angle = start_angle + sweep1
	return
		cx, cy, rx, ry, start_angle, sweep1, rotation,        --first arc
		cx, cy, rx, ry, split_angle, sweep2, rotation, x2, y2 --second arc
end

--length of circular arc at time t.
local function circular_arc_length(t, cx, cy, r, start_angle, sweep_angle)
	return abs(t * radians(sweep_angle) * r)
end

local function length(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	if rx == ry and not mt then
		return circular_arc_length(t, cx, cy, rx, start_angle, sweep_angle)
	else
		--decompose and compute the sum of the lengths of the segments
		segment_max_sweep = segment_max_sweep or best_segment_max_sweep(mt, rx, ry)
		local maxseg, segt = arc_time_to_segment_time(t, sweep_angle, segment_max_sweep)
		local x1, y1 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		local cseg, len = 0, 0
		local function write(_, x2, y2, x3, y3, x4, y4)
			cseg = cseg + 1
			if cseg > maxseg or (cseg == maxseg and segt == 0) then return end
			len = len + bezier3_length(cseg < maxseg and 1 or segt, x1, y1, x2, y2, x3, y3, x4, y4)
			x1, y1 = x4, y4
		end
		to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
		return len
	end
end

--bounding box as (x,y,w,h) for a circular arc.
local function circular_arc_bounding_box(cx, cy, r, start_angle, sweep_angle, x2, y2)
	local x1, y1, x2, y2 = endpoints(cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2)
	--assume the bounding box is between endpoints, i.e. that the arc doesn't touch any of its circle's extremities.
	local x1, x2 = min(x1, x2), max(x1, x2)
	local y1, y2 = min(y1, y2), max(y1, y2)
	if is_sweeped(0, start_angle, sweep_angle) then --arc touches its circle's rightmost point
		x2 = cx + r
	end
	if is_sweeped(90, start_angle, sweep_angle) then --arc touches its circle's most bottom point
		y2 = cy + r
	end
	if is_sweeped(180, start_angle, sweep_angle) then --arc touches its circle's leftmost point
		x1 = cx - r
	end
	if is_sweeped(-90, start_angle, sweep_angle) then --arc touches its circle's topmost point
		y1 = cy - r
	end
	return x1, y1, x2-x1, y2-y1
end

--grow a bounding box with another bounding box
local function grow_bbox(bx, by, bw, bh, x, y, w, h)
	local ax1, ay1, ax2, ay2 = x, y, x+w, y+h
	local bx1, by1, bx2, by2 = bx, by, bx+bw, by+bh
	bx1 = min(bx1, ax1, ax2)
	by1 = min(by1, ay1, ay2)
	bx2 = max(bx2, ax1, ax2)
	by2 = max(by2, ay1, ay2)
	return bx1, by1, bx2-bx1, by2-by1
end

local function bounding_box(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	if rx == ry and not mt then --TODO: or mt:straight() ...
		return circular_arc_bounding_box(cx, cy, rx, start_angle, sweep_angle, x2, y2)
	else
		--decompose and compute the bbox of the bboxes of the segments
		local x1, y1 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		local bx, by, bw, bh = 1/0, 1/0, -1/0, -1/0
		local function write(_, x2, y2, x3, y3, x4, y4)
			bx, by, bw, bh = grow_bbox(bx, by, bw, bh, bezier3_bounding_box(x1, y1, x2, y2, x3, y3, x4, y4))
			x1, y1 = x4, y4
		end
		to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
		return bx, by, bw, bh
	end
end

--from http://www.w3.org/TR/SVG/implnote.html#ArcConversionCenterToEndpoint
local function to_svgarc(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	sweep_angle = observed_sweep(sweep_angle)
	local large = abs(sweep_angle) > 180 and 1 or 0
	local sweep = sweep_angle >= 0 and 1 or 0
	return x1, y1, rx, ry, rotation, large, sweep, x2, y2
end

--convert to a 3-point parametric arc (only for circular arcs).
local function to_arc_3p(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if rx ~= ry then return end
	local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	local xp, yp = point_around(cx, cy, rx, start_angle + observed_sweep(sweep_angle) / 2)
	return x1, y1, xp, yp, x2, y2
end

return {
	observed_sweep = observed_sweep,
	sweep_between = sweep_between,
	sweep_time = sweep_time,
	is_sweeped = is_sweeped,
	endpoints = endpoints,
	to_svgarc = to_svgarc,
	to_arc_3p = to_arc_3p,
	best_segment_max_sweep = best_segment_max_sweep,
	point_at = point_at,
	tangent_vector = tangent_vector,
	bounding_box = bounding_box,
	length = length,
	--path API
	to_bezier3 = to_bezier3,
	point = point,
	hit = hit,
	split = split,
}

