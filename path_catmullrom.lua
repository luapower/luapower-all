--math for 2D catmull-rom segments defined as (k, x1, y1, x2, y2, x3, y3, x4, y4).

--math from http://pomax.github.io/bezierinfo/ (k is the tension, between 0..1)
local function to_bezier3(k, x1, y1, x2, y2, x3, y3, x4, y4)
	return
		x2, y2,
		x2 + (x3 - x1) / 6 * k,
		y2 + (y3 - y1) / 6 * k,
		x3 - (x4 - x2) / 6 * k,
		y3 - (y4 - y2) / 6 * k,
		x3, y3
end

--TODO: include k in the formula
local function value(t, k, x1, x2, x3, x4)
	return ((2 * x2) + (-x1 + x3) * t + (2*x1 - 5*x2 + 4*x3 - x4) * t^2 + (-x1 + 3*x2 - 3*x3 + x4) * t^3) / 2
end

local function point(t, k, x1, y1, x2, y2, x3, y3, x4, y4)
	return
		value(t, k, x1, x2, x3, x4),
		value(t, k, y1, y2, y3, y4)
end

if not ... then require'path_catmullrom_demo' end

return {
	to_bezier3 = to_bezier3,
	point = point,
}

