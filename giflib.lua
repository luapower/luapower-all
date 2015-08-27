
--giflib ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local glue = require'glue'
require'giflib_h'
local C = ffi.load'gif'

local function ptr(p) --convert NULL to nil
	return p ~= nil and p or nil
end

local function string_reader(data)
	local i = 1
	return function(_, buf, sz)
		if sz < 1 or #data < i then error'eof' end
		local s = data:sub(i, i+sz-1)
		ffi.copy(buf, s, #s)
		i = i + #s
		return #s
	end
end

local function cdata_reader(data, size)
	data = ffi.cast('unsigned char*', data)
	return function(_, buf, sz)
		if sz < 1 or size < 1 then error'eof' end
		sz = math.min(size, sz)
		ffi.copy(buf, data, sz)
		data = data + sz
		size = size - sz
		return sz
	end
end

local function open_callback(cb, err)
	return C.DGifOpen(nil, cb, err)
end

local function open_fileno(fileno, err)
	return C.DGifOpenFileHandle(fileno, err)
end

local function open_filename(filename, err)
	return C.DGifOpenFileName(filename, err)
end

local function open(opener, arg)
	local err = ffi.new'int[1]'
	local ft = ptr(opener(arg, err))
	if not ft then error(ffi.string(C.GifErrorString(err[0]))) end
	return ft
end

local function checknz(ft, res)
	if res ~= 0 then return end
	error(ffi.string(C.GifErrorString(ft.Error)))
end

local function close(ft)
	if C.DGifCloseFile(ft) == 0 then
		ffi.C.free(ft)
	end
end

local function load(t)
	return glue.fcall(function(finally)

		--normalize args
		if type(t) == 'string' then
			t = {path = t}
		end

		local transparent = not t.opaque
		--open source
		local ft
		if t.path then
			ft = open(open_filename, t.path)
		elseif t.string then
			local cb = ffi.cast('GifInputFunc', string_reader(t.string))
			finally(function() cb:free() end)
			ft = open(open_callback, cb)
		elseif t.cdata then
			local cb = ffi.cast('GifInputFunc', cdata_reader(t.cdata, t.size))
			finally(function() cb:free() end)
			ft = open(open_callback, cb)
		elseif t.fileno then
			ft = open(open_fileno, t.fileno)
		else
			error'source missing'
		end
		finally(function() close(ft) end)

		--decode gif
		checknz(ft, C.DGifSlurp(ft))

		--collect data
		local gif = {frames = {}}
		gif.w, gif.h = ft.SWidth, ft.SHeight
		local c = ft.SColorMap.Colors[ft.SBackGroundColor]
		gif.bg_color = {c.Red/255, c.Green/255, c.Blue/255}
		local gcb = ffi.new'GraphicsControlBlock'
		for i=0,ft.ImageCount-1 do
			local si = ft.SavedImages[i]

			--find delay and transparent color index, if any
			local delay_ms, tcolor_idx
			if C.DGifSavedExtensionToGCB(ft, i, gcb) == 1 then
				delay_ms = gcb.DelayTime * 10 --make it milliseconds
				tcolor_idx = gcb.TransparentColor
			end
			local w, h = si.ImageDesc.Width, si.ImageDesc.Height
			local colormap = si.ImageDesc.ColorMap ~= nil
				and si.ImageDesc.ColorMap or ft.SColorMap

			--convert image to top-down 8bpc rgba.
			local stride = w * 4
			local size = stride * h
			local data = ffi.new('uint8_t[?]', size)
			local di = 0
			local assert = assert
			for i=0, w * h-1 do
				local idx = si.RasterBits[i]
				assert(idx < colormap.ColorCount)
				if idx == tcolor_idx and transparent then
					data[di+0] = 0
					data[di+1] = 0
					data[di+2] = 0
					data[di+3] = 0
				else
					data[di+0] = colormap.Colors[idx].Blue
					data[di+1] = colormap.Colors[idx].Green
					data[di+2] = colormap.Colors[idx].Red
					data[di+3] = 0xff
				end
				di = di+4
			end

			local img = {
				data = data,
				size = size,
				format = 'bgra8',
				stride = stride,
				w = w,
				h = h,
				x = si.ImageDesc.Left,
				y = si.ImageDesc.Top,
				delay_ms = delay_ms,
			}

			gif.frames[#gif.frames + 1] = img
		end
		return gif
	end)
end

if not ... then require'giflib_demo' end

return {
	load = load,
	C = C,
}
