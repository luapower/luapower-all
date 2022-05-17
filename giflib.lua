
--giflib ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'giflib_demo'; return end

local ffi = require'ffi'
local bit = require'bit'
require'giflib_h'
local C = ffi.load'gif'

--given a row stride, return the next larger stride that is a multiple of 4.
local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local function DGifOpen(...)
	return C.DGifOpen(...)
end
jit.off(DGifOpen) --calls back into Lua through a ffi call.

local function DGifSlurp(ft)
	return C.DGifSlurp(ft)
end
jit.off(DGifSlurp) --calls back into Lua through a ffi call.

local function open(opt)

	if type(opt) == 'function' then
		opt = {read = opt}
	end
	local read = assert(opt.read, 'read expected')

	local read_cb, ft

	local function free()
		if read_cb then read_cb:free(); read_cb = nil end
		if ft then C.DGifCloseFile(ft); ft = nil end
	end

	local function gif_read(_, buf, len)
		::again::
		local sz = read(buf, len)
		if not sz or sz == 0 then return 0 end
		if sz < len then --partial read
			len = len - sz
			buf = buf + sz
			goto again
		end
		return sz
	end
	--[[local]] read_cb = ffi.cast('GifInputFunc', gif_read)
	local err = ffi.new'int[1]'
	--[[local]] ft = DGifOpen(nil, read_cb, err)
	if ft == nil then
		free()
		return nil, ffi.string(C.GifErrorString(err[0]))
	end

	local gif = {free = free}
	gif.w = ft.SWidth
	gif.h = ft.SHeight
	local c = ft.SColorMap.Colors[ft.SBackGroundColor]
	gif.bg_color = {c.Red/255, c.Green/255, c.Blue/255}
	gif.image_count = ft.ImageCount

	function gif:load(opt)

		if DGifSlurp(ft) == 0 then
			return nil, ffi.string(C.GifErrorString(ft.Error))
		end

		local frames = {}
		local gcb = ffi.new'GraphicsControlBlock'
		for i = 0, ft.ImageCount-1 do
			local si = ft.SavedImages[i]

			--find delay and transparent color index, if any.
			local delay, tcolor_i
			if C.DGifSavedExtensionToGCB(ft, i, gcb) == 1 then
				delay = gcb.DelayTime / 100 --make it in seconds
				tcolor_i = gcb.TransparentColor
			end
			local w, h = si.ImageDesc.Width, si.ImageDesc.Height
			local colormap = si.ImageDesc.ColorMap ~= nil
				and si.ImageDesc.ColorMap or ft.SColorMap

			--convert image to top-down 8bpc rgba.
			local stride = w * 4
			if opt and opt.accept and opt.accept.stride_aligned then
				stride = pad_stride(stride)
			end
			local bottom_up = opt and opt.accept and opt.accept.bottom_up
			local size = stride * h
			local data = ffi.new('uint8_t[?]', size)
			local assert = assert
			local transparent = opt and not opt.opaque
			for y = 0, h-1 do
				for x = 0, w-1 do
					local i = si.RasterBits[y * w + x]
					local di = (bottom_up and h - y - 1 or y) * stride + x * 4
					assert(i < colormap.ColorCount)
					if i == tcolor_i and transparent then
						data[di+0] = 0
						data[di+1] = 0
						data[di+2] = 0
						data[di+3] = 0
					else
						data[di+0] = colormap.Colors[i].Blue
						data[di+1] = colormap.Colors[i].Green
						data[di+2] = colormap.Colors[i].Red
						data[di+3] = 0xff
					end
				end
			end

			frames[i+1] = {
				data = data,
				size = size,
				format = 'bgra8',
				stride = stride,
				bottom_up = bottom_up,
				w = w,
				h = h,
				x = si.ImageDesc.Left,
				y = si.ImageDesc.Top,
				delay = delay,
			}
		end

		return frames
	end

	return gif
end

return {
	open = open,
	C = C,
}
