--Stack Blur Algorithm by Mario Klingemann http://incubator.quasimondo.com
local ffi = require'ffi'

local min, max, abs = math.min, math.max, math.abs
local shr, shl, band, bor = bit.rshift, bit.lshift, bit.band, bit.bor

local mul_table = ffi.new('int32_t[257]', {
	512,512,456,512,328,456,335,512,405,328,271,456,388,335,292,512,
	454,405,364,328,298,271,496,456,420,388,360,335,312,292,273,512,
	482,454,428,405,383,364,345,328,312,298,284,271,259,496,475,456,
	437,420,404,388,374,360,347,335,323,312,302,292,282,273,265,512,
	497,482,468,454,441,428,417,405,394,383,373,364,354,345,337,328,
	320,312,305,298,291,284,278,271,265,259,507,496,485,475,465,456,
	446,437,428,420,412,404,396,388,381,374,367,360,354,347,341,335,
	329,323,318,312,307,302,297,292,287,282,278,273,269,265,261,512,
	505,497,489,482,475,468,461,454,447,441,435,428,422,417,411,405,
	399,394,389,383,378,373,368,364,359,354,350,345,341,337,332,328,
	324,320,316,312,309,305,301,298,294,291,287,284,281,278,274,271,
	268,265,262,259,257,507,501,496,491,485,480,475,470,465,460,456,
	451,446,442,437,433,428,424,420,416,412,408,404,400,396,392,388,
	385,381,377,374,370,367,363,360,357,354,350,347,344,341,338,335,
	332,329,326,323,320,318,315,312,310,307,304,302,299,297,294,292,
	289,287,285,282,280,278,275,273,271,269,267,265,263,261,259
})

local shg_table = ffi.new('int32_t[257]', {
	  9, 11, 12, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17,
	17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19,
	19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20,
	20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21,
	21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
	21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22,
	22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
	22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23,
	23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
	23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
	23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
	23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
	24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
	24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
	24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
	24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24
})

local function stackblur_8888(data, w, h, radius)
	if radius < 1 or radius > 256 then return end

	local pix = ffi.cast('uint32_t*', data)

	local a = ffi.new('uint8_t[?]', w*h)
	local r = ffi.new('uint8_t[?]', w*h)
	local g = ffi.new('uint8_t[?]', w*h)
	local b = ffi.new('uint8_t[?]', w*h)
	local vmin = ffi.new('int32_t[?]', max(w,h))

	local div=2*radius+1
	local stack = ffi.new('uint8_t*[?]', div)
	local stack_buf = ffi.new('uint8_t[?]', div * 4)
	for i=0,div-1 do stack[i] = stack_buf + (i * 4) end

	local mul_sum = mul_table[radius]
	local shg_sum = shg_table[radius]

	for x=0,w-1 do
		vmin[x]=min(x+radius+1,w-1)
	end

	for y=0,h-1 do
		local ainsum, rinsum, ginsum, binsum, aoutsum, routsum, goutsum, boutsum, asum, rsum, gsum, bsum =
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		for i=-radius,radius do
			local p=pix[y*w+min(w-1,max(i,0))]
			local sir = stack[i+radius]
			sir[0] = shr(band(p, 0xff000000), 24)
			sir[1] = shr(band(p, 0x00ff0000), 16)
			sir[2] = shr(band(p, 0x0000ff00), 8)
			sir[3] =     band(p, 0x000000ff)
			local rbs = radius+1-abs(i)
			asum = asum+sir[0]*rbs
			rsum = rsum+sir[1]*rbs
			gsum = gsum+sir[2]*rbs
			bsum = bsum+sir[3]*rbs
			if i > 0 then
				ainsum=ainsum+sir[0]
				rinsum=rinsum+sir[1]
				ginsum=ginsum+sir[2]
				binsum=binsum+sir[3]
			else
				aoutsum=aoutsum+sir[0]
				routsum=routsum+sir[1]
				goutsum=goutsum+sir[2]
				boutsum=boutsum+sir[3]
			end
		end
		local stackpointer = radius

		for x=0,w-1 do
			a[y*w+x]=shr(asum * mul_sum, shg_sum)
			r[y*w+x]=shr(rsum * mul_sum, shg_sum)
			g[y*w+x]=shr(gsum * mul_sum, shg_sum)
			b[y*w+x]=shr(bsum * mul_sum, shg_sum)

			asum=asum-aoutsum
			rsum=rsum-routsum
			gsum=gsum-goutsum
			bsum=bsum-boutsum

			local sir = stack[(stackpointer - radius + div) % div]

			aoutsum=aoutsum-sir[0]
			routsum=routsum-sir[1]
			goutsum=goutsum-sir[2]
			boutsum=boutsum-sir[3]

			local p = pix[y*w+vmin[x]]
			sir[0] = shr(band(p, 0xff000000), 24)
			sir[1] = shr(band(p, 0x00ff0000), 16)
			sir[2] = shr(band(p, 0x0000ff00), 8)
			sir[3] =     band(p, 0x000000ff)

			ainsum=ainsum+sir[0]
			rinsum=rinsum+sir[1]
			ginsum=ginsum+sir[2]
			binsum=binsum+sir[3]

			asum=asum+ainsum
			rsum=rsum+rinsum
			gsum=gsum+ginsum
			bsum=bsum+binsum

			stackpointer = (stackpointer+1) % div
			local sir = stack[stackpointer % div]

			aoutsum=aoutsum+sir[0]
			routsum=routsum+sir[1]
			goutsum=goutsum+sir[2]
			boutsum=boutsum+sir[3]

			ainsum=ainsum-sir[0]
			rinsum=rinsum-sir[1]
			ginsum=ginsum-sir[2]
			binsum=binsum-sir[3]
		end
	end

	for y=0,h-1 do
		vmin[y]=min(y+radius+1,h-1)*w
	end

	for x=0,w-1 do
		local ainsum, rinsum, ginsum, binsum, aoutsum, routsum, goutsum, boutsum, asum, rsum, gsum, bsum =
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		local yp = -radius * w
		for i=-radius,radius do
			local yi = max(0,yp)+x

			local sir = stack[i+radius]

			sir[0]=a[yi]
			sir[1]=r[yi]
			sir[2]=g[yi]
			sir[3]=b[yi]

			do
				local rbs=radius+1-abs(i)
				asum=asum+a[yi]*rbs
				rsum=rsum+r[yi]*rbs
				gsum=gsum+g[yi]*rbs
				bsum=bsum+b[yi]*rbs
			end

			if i>0 then
			  ainsum=ainsum+sir[0]
			  rinsum=rinsum+sir[1]
			  ginsum=ginsum+sir[2]
			  binsum=binsum+sir[3]
			else
			  aoutsum=aoutsum+sir[0]
			  routsum=routsum+sir[1]
			  goutsum=goutsum+sir[2]
			  boutsum=boutsum+sir[3]
			end

			if i<h-1 then
				yp=yp+w
			end
		end

		local stackpointer = radius
		for y=0,h-1 do
			pix[x+y*w] = bor(0xff000000,
				shl(shr(asum * mul_sum, shg_sum), 24),
				shl(shr(rsum * mul_sum, shg_sum), 16),
				shl(shr(gsum * mul_sum, shg_sum), 8),
				    shr(bsum * mul_sum, shg_sum))

			asum=asum-aoutsum
			rsum=rsum-routsum
			gsum=gsum-goutsum
			bsum=bsum-boutsum

			local sir = stack[(stackpointer - radius + div) % div]

			aoutsum=aoutsum-sir[0]
			routsum=routsum-sir[1]
			goutsum=goutsum-sir[2]
			boutsum=boutsum-sir[3]

			local p=x+vmin[y]

			sir[0]=a[p]
			sir[1]=r[p]
			sir[2]=g[p]
			sir[3]=b[p]

			ainsum=ainsum+sir[0]
			rinsum=rinsum+sir[1]
			ginsum=ginsum+sir[2]
			binsum=binsum+sir[3]

			asum=asum+ainsum
			rsum=rsum+rinsum
			gsum=gsum+ginsum
			bsum=bsum+binsum

			stackpointer = (stackpointer+1) % div
			local sir = stack[stackpointer]

			aoutsum=aoutsum+sir[0]
			routsum=routsum+sir[1]
			goutsum=goutsum+sir[2]
			boutsum=boutsum+sir[3]

			ainsum=ainsum-sir[0]
			rinsum=rinsum-sir[1]
			ginsum=ginsum-sir[2]
			binsum=binsum-sir[3]
		end
	end
end

if not ... then require'im_blur_demo' end

return {
	blur_8888 = stackblur_8888,
}
