--math for 2D quadratic bezier curves defined as (x1, y1, x2, y2, x3, y3)
--where (x1, y1) and (x3, y3) are the end points and (x2, y2) is the control point.

local distance = require'path_point'.distance
local length_function = require'path_bezier_length'
local glue = require'glue' --autoload

local min, max, sqrt, log = math.min, math.max, math.sqrt, math.log

--compute B(t) (see wikipedia).
local function value(t, x1, x2, x3)
	return (1-t)^2 * x1 + 2*(1-t)*t * x2 + t^2 * x3
end

--separate coefficients from B(t) for using with *_for() functions.
local function coefficients(x1, x2, x3)
	return x1-2*x2+x3, 2*(x2-x1), x1 --the a, b, c quadratic coefficients
end

--compute B(t) for given coefficients.
local function value_for(t, a, b, c, d)
	return c + t * (b + t * a) --aka a * t^2 + b * t + c
end

--compute the first derivative, aka the curve's tangent vector at t, for given coefficients.
local function derivative1_for(t, a, b)
	return 2*a*t + b --solution is -b/2a for a ~= 0
end

--solve B(t)'=0 (use wolframalpha.com).
local function derivative1_root(x1, x2, x3)
	local denom = x1 - 2*x2 + x3
	if denom == 0 then return end
	return (x1 - x2) / denom
end

--compute the minimum and maximum values for B(t).
local function minmax(x1, x2, x3)
	--start off with the assumption that the curve doesn't extend past its endpoints.
	local minx = min(x1, x3)
	local maxx = max(x1, x3)
	--if the control point is between the endpoints, the curve has no local extremas.
	if x2 >= minx and x2 <= maxx then
		return minx, maxx
	end
	--if the curve has local minima and/or maxima then adjust the bounding box.
	local t = derivative1_root(x1, x2, x3)
	if t and t >= 0 and t <= 1 then
		local x = value(t, x1, x2, x3)
		minx = min(x, minx)
		maxx = max(x, maxx)
	end
	return minx, maxx
end

--bounding box as (x, y, w, h)
local function bounding_box(x1, y1, x2, y2, x3, y3)
	local minx, maxx = minmax(x1, x2, x3)
	local miny, maxy = minmax(y1, y2, y3)
	return minx, miny, maxx-minx, maxy-miny
end

--transform to cubic bezier.
local function to_bezier3(x1, y1, x2, y2, x3, y3)
	return
		x1, y1,
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		(x3 + 2 * x2) / 3,
		(y3 + 2 * y2) / 3,
		x3, y3
end

--return a fair candidate for the control point of a quad bezier given its end points (x1, y1) and (x3, y3),
--and a point (x0, y0) that lies on the curve.
local function _3point_control_point(x1, y1, x0, y0, x3, y3)
	-- find a good candidate for t based on chord lengths
	local c1 = distance(x0, y0, x1, y1)
	local c2 = distance(x0, y0, x3, y3)
	local t = c1 / (c1 + c2)
	-- a point on a quad bezier is at B(t) = (1-t)^2*P1 + 2*t*(1-t)*P2 + t^2*P3
	-- solving for P2 gives P2 = (B(t) - (1-t)^2*P1 - t^2*P3) / (2*t*(1-t)) where B(t) is P0
	return
		(x0 - (1 - t)^2 * x1 - t^2 * x3) / (2*t * (1 - t)),
		(y0 - (1 - t)^2 * y1 - t^2 * y3) / (2*t * (1 - t))
end

--evaluate a quad bezier at parameter t using linear interpolation.
local function point(t, x1, y1, x2, y2, x3, y3)
	return
		value(t, x1, x2, x3),
		value(t, y1, y2, y3)
end

local length = length_function(coefficients, derivative1_for)

--split a quad bezier at parameter t into two curves using De Casteljau interpolation.
local function split(t, x1, y1, x2, y2, x3, y3)
	local mt = 1-t
	local x12 = x1 * mt + x2 * t
	local y12 = y1 * mt + y2 * t
	local x23 = x2 * mt + x3 * t
	local y23 = y2 * mt + y3 * t
	local x123 = x12 * mt + x23 * t
	local y123 = y12 * mt + y23 * t
	return
		x1, y1, x12, y12, x123, y123, --first curve
		x123, y123, x23, y23, x3, y3  --second curve
end

if not ... then require'path_bezier2_demo' end

return glue.autoload({
	bounding_box = bounding_box,
	to_bezier3 = to_bezier3,
	_3point_control_point = _3point_control_point,
	--hit & split API
	point = point,
	length = length,
	split = split,
}, {
	hit = 'path_bezier2_hit',
	interpolate = 'path_bezier2_ai',
})

