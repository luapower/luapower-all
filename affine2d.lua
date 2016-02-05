
--2D affine transforms.
--Transcribed from cairo by Cosmin Apreutesei. Public Domain.

if not ... then require'affine2d_test'; return end

local min, max, abs, sin, cos, tan, floor =
	math.min, math.max, math.abs, math.sin, math.cos, math.tan, math.floor

local epsilon = 1e-15
local function snap(x)
	return
		(abs(x)   < epsilon and  0) or
		(abs(x-1) < epsilon and  1) or
		(abs(x+1) < epsilon and -1) or x
end

local function new(xx, yx, xy, yy, x0, y0)
	if not xx then
		xx, yx, xy, yy, x0, y0 = 1, 0, 0, 1, 0, 0
	end

	local mt = {}

	function mt:set(xx1, yx1, xy1, yy1, x01, y01)
		xx, yx, xy, yy, x0, y0 = xx1, yx1, xy1, yy1, x01, y01
		return mt
	end

	function mt:reset()
		xx, yx, xy, yy, x0, y0 = 1, 0, 0, 1, 0, 0
		return mt
	end

	function mt:unpack()
		return xx, yx, xy, yy, x0, y0
	end

	function mt:copy()
		return new(xx, yx, xy, yy, x0, y0)
	end

	function mt:transform_point(x, y)
		return xx * x + xy * y + x0,
				 yx * x + yy * y + y0
	end

	function mt:transform_distance(x, y)
		return xx * x + xy * y,
				 yx * x + yy * y
	end

	function mt:multiply(bxx, byx, bxy, byy, bx0, by0) --multiply mt * b and store result in mt
		xx, yx, xy, yy, x0, y0 =
			xx * bxx + yx * bxy,
			xx * byx + yx * byy,
			xy * bxx + yy * bxy,
			xy * byx + yy * byy,
			x0 * bxx + y0 * bxy + bx0,
			x0 * byx + y0 * byy + by0
		return mt
	end

	function mt:transform(bxx, byx, bxy, byy, bx0, by0) --multiply b * mt and store result in mt
		xx, yx, xy, yy, x0, y0 =
			bxx * xx + byx * xy,
			bxx * yx + byx * yy,
			bxy * xx + byy * xy,
			bxy * yx + byy * yy,
			bx0 * xx + by0 * xy + x0,
			bx0 * yx + by0 * yy + y0
		return mt
	end

	function mt:determinant()
		return xx * yy - yx * xy
	end

	local determinant = mt.determinant

	function mt:is_invertible()
		local det = determinant()
		return det ~= 0 and det ~= 1/0 and det ~= -1/0
	end

	function mt:scalar_multiply(t)
		xx = xx * t
		yx = yx * t
		xy = xy * t
		yy = yy * t
		x0 = x0 * t
		y0 = y0 * t
		return mt
	end

	function mt:inverse()
		--scaling/translation-only matrices are easier to invert
		if xy == 0 and yx == 0 then
			local xx, yx, xy, yy, x0, y0 =
					xx, yx, xy, yy, x0, y0
			x0 = -x0
			y0 = -y0
			if xx ~= 1 then
				if xx == 0 then return end
				xx = 1 / xx
				x0 = x0 * xx
			end
			if yy ~= 1 then
				if yy == 0 then return end
				yy = 1 / yy
				y0 = y0 * yy
			end
			return new(xx, yx, xy, yy, x0, y0)
		end
		--inv (A) = 1/det (A) * adj (A)
		local det = determinant()
		if det == 0 or det == 1/0 or det == -1/0 then return end
		--adj (A) = transpose (C:cofactor (A,i,j))
		local a, b, c, d, tx, ty = xx, yx, xy, yy, x0, y0
		return new(d, -b, -c, a, c*ty - d*tx, b*tx - a*ty):scalar_multiply(1 / det)
	end

	function mt:translate(x, y)
		x0 = x0 + x * xx + y * xy
		y0 = y0 + x * yx + y * yy
		return mt
	end

	function mt:scale(sx, sy)
		sy = sy or sx
		xx = sx * xx
		yx = sx * yx
		xy = sy * xy
		yy = sy * yy
		return mt
	end

	function mt:skew(ax, ay)
		ax, ay = tan(ax), tan(ay)
		xx, yx, xy, yy =
			xx + ay * xy,
			yx + ay * yy,
			ax * xx + xy,
			ax * yx + yy
		return mt
	end

	function mt:rotate(a)
		local s, c = snap(sin(a)), snap(cos(a))
		xx, yx, xy, yy =
			 c * xx + s * xy,
			 c * yx + s * yy,
			-s * xx + c * xy,
			-s * yx + c * yy
		return mt
	end

	function mt:rotate_around(cx, cy, a)
		return mt:translate(cx, cy):rotate(a):translate(-cx, -cy)
	end

	function mt:scale_around(cx, cy, sx, sxy)
		return mt:translate(cx, cy):scale(sx, sy):translate(-cx, -cy)
	end

	--check that the matrix is the identity matrix, thus having no effect.
	function mt:is_identity()
		return xx == 1 and yy == 1 and yx == 0 and xy == 0 and x0 == 0 and y0 == 0
	end

	--check that no scaling is done with this transform, only flipping and multiple-of-90deg rotation.
	function mt:has_unity_scale()
		return
			((xy == 0 and yx == 0) and (xx == 1 or xx == -1) and (yy == 1 or yy == -1)) or
			((xx == 0 and yy == 0) and (xy == 1 or xy == -1) and (yx == 1 or yx == -1))
	end

	--check that scaling with this transform is uniform on both axes.
	function mt:has_uniform_scale()
		return abs(xx) == abs(yy) and xy == yx
	end

	--the scale factor is the largest dimension of the bounding box of the transformed unit square.
	function mt:scale_factor()
		local w = max(0, xx, xy, xx + xy) - min(0, xx, xy, xx + xy)
		local h = max(0, yx, yy, yx + yy) - min(0, yx, yy, yx + yy)
		return max(w,h)
	end

	--check that pixels map 1:1 with this transform so that no filtering is necessary
	local has_unity_scale = mt.has_unity_scale
	function mt:is_pixel_exact()
		return has_unity_scale() and floor(x0) == x0 and floor(y0) == y0
	end

	---check that there's no skew and that there's no rotation other than multiple-of-90-deg. rotation.
	function mt:is_straight()
		return (xy == 0 and yx == 0) or (xx == 0 and yy == 0)
	end

	local function __mul(a, b)
		return copy():multiply(b:unpack())
	end

	local function __eq(a, b)
		local a1, b1, c1, d1, e1, f1 = a:unpack()
		local a2, b2, c2, d2, e2, f2 = b:unpack()
		return a1 == a2 and b1 == b2 and c1 == c2 and d1 == d2 and e1 == e2 and f1 == f2
	end

	setmetatable(mt, {
		__mul = __mul,
		__eq = __eq,
		__call = mt.transform_point,
	})

	return mt
end

return new

