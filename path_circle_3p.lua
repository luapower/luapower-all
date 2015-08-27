--math for 2d circles defined as passing though 3 points (x1, y1, x2, y2, x3, y3).

local distance = require'path_point'.distance

local function to_circle(x1, y1, x2, y2, x3, y3)
	--if the points are on a vertical line, we can't make a circle.
	if x1 == x2 and x2 == x3 then return end
	--if p2 forms a vertical line with any other point, switch it with the third point to avoid an infinite slope.
	if x2 == x1 then
		x2, y2, x3, y3 = x3, y3, x2, y2
	elseif x2 == x3 then
		x2, y2, x1, y1 = x1, y1, x2, y2
	end
	--compute the slopes of p2-p1 and p3-p2.
	local mr = (y2 - y1) / (x2 - x1)
	local mt = (y3 - y2) / (x3 - x2)
	--solve for x the equation for the intersection point between the perpendiculars that pass through
	--the mid points of p2-p1 and p3-p2.
	local cx = (mr * mt * (y3 - y1) + mr * (x2 + x3) - mt * (x1 + x2)) / (2 * (mr - mt))
	--if lines are parallel enough, the center will be further away than what a number can hold giving us inf or -inf.
	--cx can also result in nan if the numerator is also zero (what's the geometric significance of this?)
	if cx ~= cx or cx == 1/0 or cx == -1/0 then return end
	--solve for y one of the ecuations of the perpendiculars (pick the one that avoids an infinite result).
	local cy = mt == 0 and
			-1 / mr * (cx - (x1 + x2) / 2) + (y1 + y2) / 2 or
			-1 / mt * (cx - (x2 + x3) / 2) + (y2 + y3) / 2
	return cx, cy, distance(cx, cy, x1, y1)
end

if not ... then require'path_circle_3p_demo' end

return {
	to_circle = to_circle,
}

