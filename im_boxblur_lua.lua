--Box Blur Algorithm by Mario Klingemann http://incubator.quasimondo.com
local ffi = require'ffi'

local min, max = math.min, math.max
local shr, shl, band, bor = bit.rshift, bit.lshift, bit.band, bit.bor

local function get_argb(pix, i)
	return
		shr(band(pix[i], 0xff000000), 24),
		shr(band(pix[i], 0x00ff0000), 16),
		shr(band(pix[i], 0x0000ff00), 8),
			band(pix[i], 0x000000ff)
end

local function argb(a, r, g, b)
	return bor(shl(a, 24), shl(r, 16), shl(g, 8), b)
end

--cache per-blur-diameter division tables in a weak table
local dv_tables = setmetatable({}, {
	__mode = 'k',
	__index = function(t,div)
		local dv = {}
		ffi.new('uint8_t[?]', 256 * div)
		for i=0,256*div-1 do dv[i] = i/div end
		t[div] = dv
		return dv
	end
})

local function boxblur_8888(data, w, h, radius, times)
	if radius < 1 or radius > 256 then return end
	times = times or 2
	local wh = w * h
	local div = 2*radius+1
	local r = ffi.new('uint8_t[?]', wh)
	local g = ffi.new('uint8_t[?]', wh)
	local b = ffi.new('uint8_t[?]', wh)
	local a = ffi.new('uint8_t[?]', wh)
	local vmin = ffi.new('int32_t[?]', max(w, h))
	local vmax = ffi.new('int32_t[?]', max(w, h))
	local pix = ffi.cast('int32_t*', data)
	local dv = dv_tables[div]

	for _ = 1,times do
		local yw, yi = 0, 0

		for x=0,w-1 do
			vmin[x] = min(x+radius+1, w-1)
			vmax[x] = max(x-radius, 0)
		end

		for y=0,h-1 do
			local asum, rsum, gsum, bsum = 0, 0, 0, 0
			for i=-radius,radius do
				local aa, rr, gg, bb = get_argb(pix, yi+min(w-1, max(i, 0)))
				asum = asum + aa
				rsum = rsum + rr
				gsum = gsum + gg
				bsum = bsum + bb
			end

			for x=0,w-1 do
				a[yi] = dv[asum]
				r[yi] = dv[rsum]
				g[yi] = dv[gsum]
				b[yi] = dv[bsum]
				local a1,r1,g1,b1 = get_argb(pix, yw+vmin[x])
				local a2,r2,g2,b2 = get_argb(pix, yw+vmax[x])
				asum = asum + a1-a2
				rsum = rsum + r1-r2
				gsum = gsum + g1-g2
				bsum = bsum + b1-b2
				yi = yi + 1
			end
			yw = yw+w
		end

		for y=0,h-1 do
			vmin[y] = min(y+radius+1, h-1) * w
			vmax[y] = max(y-radius, 0) * w
		end

		for x=0,w-1 do
			local asum, rsum, gsum, bsum = 0, 0, 0, 0
			local yp = -radius * w
			for i=-radius,radius do
				yi = max(0, yp) + x
				rsum = rsum + r[yi]
				gsum = gsum + g[yi]
				bsum = bsum + b[yi]
				asum = asum + a[yi]
				yp = yp + w
			end
			yi = x
			for y=0,h-1 do
				pix[yi] = argb(dv[asum], dv[rsum], dv[gsum], dv[bsum])
				local p1 = x+vmin[y]
				local p2 = x+vmax[y]
				asum = asum + a[p1]-a[p2]
				rsum = rsum + r[p1]-r[p2]
				gsum = gsum + g[p1]-g[p2]
				bsum = bsum + b[p1]-b[p2]
				yi = yi + w
			end
		end
	end
end

if not ... then require'im_blur_demo' end

return {
	blur_8888 = boxblur_8888,
}
