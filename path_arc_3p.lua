--math for 2D circular arcs defined as (x1, y1, xp, yp, x2, y2) where (x1, y1) and (x2, y2) are its end points,
--and (xp, yp) is a third point on the arc. if the 3 points are collinear, then the arc is the line between
--(x1, y1) and (x2, y2), regardless of where (xp, yp) is.

local circle_3p_to_circle = require'path_circle_3p'.to_circle
local point_angle = require'path_point'.point_angle
local sweep_between = require'path_arc'.sweep_between
local arc_split = require'path_arc'.split
local arc_to_arc_3p = require'path_arc'.to_arc_3p

local function to_arc(x1, y1, xp, yp, x2, y2)
	local cx, cy, r = circle_3p_to_circle(x1, y1, xp, yp, x2, y2)
	if not cx then return end
	local start_angle = point_angle(x1, y1, cx, cy)
	local end_angle   = point_angle(x2, y2, cx, cy)
	local ctl_angle   = point_angle(xp, yp, cx, cy)
	local sweep_angle = sweep_between(start_angle, end_angle)
	local ctl_sweep   = sweep_between(start_angle, ctl_angle)
	if ctl_sweep > sweep_angle then
		--control point is outside the positive sweep, must be inside the negative sweep then.
		sweep_angle = sweep_between(start_angle, end_angle, false)
	end
	return cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2
end

local function split(t, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, r, start_angle, sweep_angle = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then return end
	local
		cx1, cy1, r1, r1, start_angle1, sweep_angle1, _,
		cx2, cy2, r2, r2, start_angle2, sweep_angle2 = arc_split(t, cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2)
	local ax1, ay1, axp, ayp, ax2, ay2 = arc_to_arc_3p(cx1, cy1, r1, r1, start_angle1, sweep_angle1)
	local bx1, by1, bxp, byp, bx2, by2 = arc_to_arc_3p(cx2, cy2, r2, r2, start_angle2, sweep_angle2)
	--overide arcs' end points for numerical stability
	ax1, ay1 = x1, y1
	bx2, by2 = x2, y2
	bx1, by1 = ax2, ay2
	return
		ax1, ay1, axp, ayp, ax2, ay2, --first arc
		bx1, by1, bxp, byp, bx2, by2  --second arc
end

if not ... then require'path_arc_3p_demo' end

return {
	to_arc = to_arc,
	split = split,
}

