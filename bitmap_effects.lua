
--bitmap pixel effects.
--Written by Cosmin Apreutesei. Public domain.

local bitmap = require'bitmap'

function bitmap.invert(bmp)
	local colortype = bitmap.colortype(bmp)
	assert(#colortype.channels == 4, 'invalid colortype')
	local maxval = colortype.max
	bitmap.paint(bmp, bmp, function(r, g, b, a)
		r = maxval-r
		g = maxval-g
		b = maxval-b
		a = maxval-a
		return r, g, b, a
	end)
end

function bitmap.grayscale(bmp)
	local colortype = bitmap.colortype(bmp)
	if colortype.channels == 'rgba' then
		bitmap.paint(bmp, bmp, function(r, g, b, a)
			g = bitmap.rgb2g(r, g, b)
			return g, g, g, a
		end)
	elseif colortype.channels == 'ga' then
		--already gray
	else
		error('invalid colortype')
	end
end

--convolution

local function sumkernel(kernel)
	local sum = 0
	for ky = 1, #kernel do
		for kx = 1, #kernel[ky] do
			sum = sum + kernel[ky][kx]
		end
	end
	return sum
end

local function normalize(kernel)
	local sum = sumkernel(kernel)
	local dkernel = {}
	for ky = 1, #kernel do
		dkernel[ky] = {}
		for kx = 1, #kernel[ky] do
			dkernel[ky][kx] = kernel[ky][kx] / sum
		end
	end
	return dkernel
end

function bitmap.convolve(bmp, kernel, edge)
	edge = edge or 'extend'
	local dst = bitmap.new(bmp.w, bmp.h, {
		ctype = 'int16_t', bpp = 16 * 4,
		colortype = 'rgba16',
		read = function(s, i) return s[i], s[i+1], s[i+2], s[i+3] end,
		write = function(d, i, r, g, b, a) d[i], d[i+1], d[i+2], d[i+3] = r, g, b, a end,
	})
	local src_getpixel = bitmap.pixel_interface(bmp)
	local dst_getpixel, dst_setpixel = bitmap.pixel_interface(dst)
	local maxval = 2^bitmap.colortype(bmp).bpc-1
	local halfx = math.ceil(#kernel / 2)
	local halfy = math.ceil(#kernel[1] / 2)
	local x1, x2 = 0, bmp.w - 1
	local y1, y2 = 0, bmp.h - 1
	if edge == 'crop' then
		x1 = x1 + halfx - 1
		x2 = x2 - halfx - 1
		y1 = y1 + halfy - 1
		y2 = y2 - halfy - 1
	end
	for ky = 1, #kernel do
		for kx = 1, #kernel[1] do
			local t = kernel[ky][kx]
			for y = y1, y2 do
				for x = x1, x2 do
					local r, g, b, a = dst_getpixel(x, y)
					local x0 = x - halfx + kx
					local y0 = y - halfy + ky
					if edge == 'wrap' then
						x0 = x0 % bmp.w
						y0 = y0 % bmp.h
					elseif edge == 'extend' then
						x0 = math.min(math.max(x0, 0), bmp.w-1)
						y0 = math.min(math.max(y0, 0), bmp.h-1)
					end
					local r0, g0, b0, a0 = src_getpixel(x0, y0)
					r = r + r0 * t
					g = g + g0 * t
					b = b + b0 * t
					a = a + a0 * t
					dst_setpixel(x, y, r, g, b, a)
				end
			end
		end
	end
	local sum = sumkernel(kernel)
	local final = bitmap.new(dst.w, dst.h, bmp.format)
	bitmap.paint(final, dst, function(r, g, b, a)
		return
			math.min(math.max(r / sum, 0), 0xff),
			math.min(math.max(g / sum, 0), 0xff),
			math.min(math.max(b / sum, 0), 0xff),
			math.min(math.max(a / sum, 0), 0xff)
	end)
	return final
end

function bitmap.sharpen(bmp, amount)
	local sharpen = {
		{0,-1,0},
		{-1,5,-1},
		{0,-1,0}}
	return bitmap.convolve(bmp, sharpen)
end

--mirroring

function bitmap.mirror(bmp)
	local getpixel, setpixel = bitmap.pixel_interface(bmp)
	local function pass(x1, x2, y, ...)
		setpixel(x2, y, getpixel(x1, y))
		setpixel(x1, y, ...)
	end
	local function swappixel(x1, x2, y)
		pass(x1, x2, y, getpixel(x2, y))
	end
	local maxx = math.floor(bmp.w / 2) - 1
	for y = 0, bmp.h-1 do
		for x = 0, maxx do
			swappixel(x, bmp.w-1 - x, y)
		end
	end
end


if not ... then require'bitmap_demo' end
