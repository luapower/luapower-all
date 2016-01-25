--finding the nearest-point on a quad bezier curve using closed form (3rd degree equation) solution.
--solution from http://blog.gludion.com/2009/08/distance-to-quadratic-bezier-curve.html adapted by Cosmin Apreutesei.

local bezier2 = require'path2d_bezier2'
local solve_equation3 = require'eq'.solve3
local distance2 = require'path2d_point'.distance2
local point = bezier2.point

local function test_solution(mind, minx, miny, mint, t, x0, y0, x1, y1, x2, y2, x3, y3)
	if t and t >= 0 and t <= 1 then
		local x, y = point(t, x1, y1, x2, y2, x3, y3)
		local d = distance2(x0, y0, x, y)
		if d < mind then
			mind, minx, miny, mint = d, x, y, t
		end
	end
	return mind, minx, miny, mint
end

--shortest distance-squared from point (x0, y0) to a quad bezier curve, plus the touch point,
--and the parametric value t on the curve where the touch point splits the curve.
function bezier2.hit(x0, y0, x1, y1, x2, y2, x3, y3)
	local Ax, Ay = x2 - x1, y2 - y1                  --A = P2-P1
	local Bx, By = x3 - x2 - Ax, y3 - y2 - Ay        --B = P3-P2-A, also P3-2*P2+P1
	local Mx, My = x1 - x0, y1 - y0                  --M = P1-P0
	local a = Bx^2 + By^2                            --a = B^2
	local b = 3 * (Ax * Bx + Ay * By)                --b = 3*AxB
	local c = 2 * (Ax^2 + Ay^2) + Mx * Bx + My * By  --c = 2*A^2+MxB
	local d = Mx * Ax + My * Ay                      --d = MxA
	local t1, t2, t3 = solve_equation3(a, b, c, d)   --solve a*t^3 + b*t^2 + c*t + d = 0

	local mind, minx, miny, mint = 1/0 --shortest distance, touch point, and the parametric value for the touch point.

	--test all solutions for shortest distance
	mind, minx, miny, mint = test_solution(mind, minx, miny, mint, t1, x0, y0, x1, y1, x2, y2, x3, y3)
	mind, minx, miny, mint = test_solution(mind, minx, miny, mint, t2, x0, y0, x1, y1, x2, y2, x3, y3)
	mind, minx, miny, mint = test_solution(mind, minx, miny, mint, t3, x0, y0, x1, y1, x2, y2, x3, y3)

	--also test distances to beginning and end of the curve, where t = 0 and 1 respectively.
	local d = distance2(x0, y0, x1, y1)
	if d < mind then
		mind, minx, miny, mint = d, x1, y1, 0
	end
	local d = distance2(x0, y0, x3, y3)
	if d < mind then
		mind, minx, miny, mint = d, x3, y3, 1
	end

	return mind, minx, miny, mint
end

if not ... then require'path2d_hit_demo' end

