
--bitmap resampling.
--Written by Cosmin Apreutesei. Public domain.

local bitmap = require'bitmap'

bitmap.resize = {}

local min, max, floor, ceil =
	math.min, math.max, math.floor, math.ceil

local function clamp(x, t0, t1)
	return min(max(x, t0), t1)
end

local function check_colortypes(src, dst)
	local c1 = bitmap.colortype(src)
	local c2 = bitmap.colortype(dst)
	assert(c1 == c2, 'colortype mismatch')
	return #c1.channels, c1.max
end

local function args(src, w, h)
	local dst
	if type(w) == 'number' then --src, w, h
		dst = bitmap.new(w, h, src.format)
	else --src, dst
		dst = w
	end

	local channels, maxval = check_colortypes(src, dst)

	local src_getpixel = bitmap.pixel_interface(src)
	local _, dst_setpixel = bitmap.pixel_interface(dst)

	return src, dst, src_getpixel, dst_setpixel, channels, maxval
end

function bitmap.resize.nearest(...)

	local src, dst, src_getpixel, dst_setpixel = args(...)

	local tx = (src.w-1) / dst.w
	local ty = (src.h-1) / dst.h

	for y1 = 0, dst.h-1 do
		for x1 = 0, dst.w-1 do
			local x = ceil(tx * x1)
			local y = ceil(ty * y1)
			dst_setpixel(x1, y1, src_getpixel(x, y))
		end
	end

	return dst
end

function bitmap.resize.bilinear(...)

	local src, dst, src_getpixel, dst_setpixel, channels, maxval = args(...)

	local kernel = {}

	kernel[2] = function(x, y, x1, y1, f1, f2, f3, f4)

		local g1, a1 = src_getpixel(x,   y  )
		local g2, a2 = src_getpixel(x+1, y  )
		local g3, a3 = src_getpixel(x,   y+1)
		local g4, a4 = src_getpixel(x+1, y+1)

		dst_setpixel(x1, y1,
			g1 * f1 + g2 * f2 + g3 * f3 + g4 * f4,
			a1 * f1 + a2 * f2 + a3 * f3 + a4 * f4)
	end

	kernel[4] = function(x, y, x1, y1, f1, f2, f3, f4)

		local r1, g1, b1, a1 = src_getpixel(x,   y  )
		local r2, g2, b2, a2 = src_getpixel(x+1, y  )
		local r3, g3, b3, a3 = src_getpixel(x,   y+1)
		local r4, g4, b4, a4 = src_getpixel(x+1, y+1)

		dst_setpixel(x1, y1,
			clamp(r1 * f1 + r2 * f2 + r3 * f3 + r4 * f4, 0, maxval),
			clamp(g1 * f1 + g2 * f2 + g3 * f3 + g4 * f4, 0, maxval),
			clamp(b1 * f1 + b2 * f2 + b3 * f3 + b4 * f4, 0, maxval),
			clamp(a1 * f1 + a2 * f2 + a3 * f3 + a4 * f4, 0, maxval))
	end

	local kernel = assert(kernel[channels], 'unsupported colortype')

	local maxx = src.w-2
	local maxy = src.h-2

	local tx = src.w / dst.w
	local ty = src.h / dst.h

	for y1 = 0, dst.h-1 do
		for x1 = 0, dst.w-1 do

			local x = floor(tx * x1)
			local y = floor(ty * y1)

			x = clamp(x, 0, maxx)
			y = clamp(y, 0, maxy)

			local dx = tx * x1 - x
			local dy = ty * y1 - y

			local f1 = (1-dx)*(1-dy)
         local f2 = dx*(1-dy)
			local f3 = (1-dx)*dy
			local f4 = dx*dy

			kernel(x, y, x1, y1, f1, f2, f3, f4)
		end
	end

	return dst
end


if not ... then require'bitmap_demo' end

