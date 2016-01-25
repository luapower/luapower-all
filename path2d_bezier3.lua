--math for 2D cubic bezier curves defined as (x1, y1, x2, y2, x3, y3, x4, y4)
--where (x2, y2) and (x3, y3) are the control points and (x1, y1) and (x4, y4) are the end points.

local length_function = require'path2d_bezier_length'
local glue = require'glue' --autoload

local min, max, sqrt = math.min, math.max, math.sqrt

--compute B(t) (see wikipedia).
local function value(t, x1, x2, x3, x4)
	return (1-t)^3 * x1 + 3*(1-t)^2*t * x2 + 3*(1-t)*t^2 * x3 + t^3 * x4
end

--separate coefficients from B(t) for using with *_for() functions.
local function coefficients(x1, x2, x3, x4)
	return x4-x1+3*(x2-x3), 3*x1-6*x2+3*x3, 3*(x2-x1), x1 --the a, b, c, d cubic coefficients
end

--compute B(t) for given coefficients.
local function value_for(t, a, b, c, d)
	return d + t * (c + t * (b + t * a)) --aka a * t^3 + b * t^2 + c * t + d
end

--compute the first derivative, aka the curve's tangent vector at t, for given coefficients.
local function derivative1_for(t, a, b, c)
	return c + t * (2 * b + 3 * a * t)
end

--solve B(t)'=0 (use wolframalpha.com).
local function derivative1_roots(x1, x2, x3, x4)
	local base = -x1*x3 + x1*x4+x2^2 - x2*x3 - x2*x4+x3^2
	local denom = -x1 + 3*x2 - 3*x3 + x4
	if base > 0 and denom ~= 0 then
		local sq = sqrt(base)
		return
			 (sq - x1 + 2*x2 - x3) / denom,
			(-sq - x1 + 2*x2 - x3) / denom
	else
		local denom = 2*(x1 - 2*x2 + x3)
		if denom ~= 0 then
			return (x1 - x2) / denom
		end
	end
end

--compute the minimum and maximum values for B(t).
local function minmax(x1, x2, x3, x4)
	--start off with the assumption that the curve doesn't extend past its endpoints.
	local minx = min(x1, x4)
	local maxx = max(x1, x4)
	--if the curve has local minima and/or maxima then adjust the bounding box.
	local t1, t2 = derivative1_roots(x1, x2, x3, x4)
	if t1 and t1 >= 0 and t1 <= 1 then
		local x = value(t1, x1, x2, x3, x4)
		minx = min(x, minx)
		maxx = max(x, maxx)
	end
	if t2 and t2 >= 0 and t2 <= 1 then
		local x = value(t2, x1, x2, x3, x4)
		minx = min(x, minx)
		maxx = max(x, maxx)
	end
	return minx, maxx
end

--bounding box as (x, y, w, h)
local function bounding_box(x1, y1, x2, y2, x3, y3, x4, y4)
	local minx, maxx = minmax(x1, x2, x3, x4)
	local miny, maxy = minmax(y1, y2, y3, y4)
	return minx, miny, maxx-minx, maxy-miny
end

--return a quadratic bezier that (wildly) approximates a cubic bezier.
--the equation has two solutions, which are averaged out to form the final control point.
local function to_bezier2(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		-.25*x1 + .75*x2 + .75*x3 -.25*x4,
		-.25*y1 + .75*y2 + .75*y3 -.25*y4
end

--return a catmull-rom segment that approximates a cubic bezier.
--math from http://pomax.github.io/bezierinfo/
local function to_catmullrom(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		1, --default tension
		x4 + 6 * (x1 - x2),
		y4 + 6 * (y1 - y2),
		x1, y1,
		x4, y4,
		x1 + 6 * (x4 - x3),
		y1 + 6 * (y4 - y3)
end

--evaluate a cubic bezier at time t using linear interpolation.
--for bit more speed, we could save and reuse the polynomial coefficients betwen computations for x and y.
local function point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	return
		value(t, x1, x2, x3, x4),
		value(t, y1, y2, y3, y4)
end

--approximate length of a cubic bezier using Gauss quadrature.
local length = length_function(coefficients, derivative1_for)

--split a cubic bezier at time t into two curves using De Casteljau interpolation.
local function split(t, x1, y1, x2, y2, x3, y3, x4, y4)
	local mt = 1-t
	local x12 = x1 * mt + x2 * t
	local y12 = y1 * mt + y2 * t
	local x23 = x2 * mt + x3 * t
	local y23 = y2 * mt + y3 * t
	local x34 = x3 * mt + x4 * t
	local y34 = y3 * mt + y4 * t
	local x123 = x12 * mt + x23 * t
	local y123 = y12 * mt + y23 * t
	local x234 = x23 * mt + x34 * t
	local y234 = y23 * mt + y34 * t
	local x1234 = x123 * mt + x234 * t
	local y1234 = y123 * mt + y234 * t
	return
		x1, y1, x12, y12, x123, y123, x1234, y1234, --first curve
		x1234, y1234, x234, y234, x34, y34, x4, y4 --second curve
end

if not ... then require'path2d_bezier3_demo' end

return glue.autoload({
	bounding_box = bounding_box,
	to_bezier2 = to_bezier2,
	to_catmullrom = to_catmullrom,
	--hit & split API
	point = point,
	length = length,
	split = split,
}, {
	hit = 'path2d_bezier3_hit',
	interpolate = 'path2d_bezier3_ai',
})

