local player = require'cplayer'
local glue = require'glue'
local stdio = require'stdio'
local ffi = require'ffi'
local bitmap = require'bitmap'

bitmap.dumpinfo()

local function load_bmp(filename)
	local bmp = stdio.readfile(filename)
	assert(ffi.string(bmp, 2) == 'BM')
	local function read(ctype, offset)
		return ffi.cast(ctype, bmp + offset)[0]
	end
	local data = bmp + read('uint32_t*', 0x0A)
	local w = read('int32_t*', 0x12)
	local h = read('int32_t*', 0x16)
	local stride = bitmap.aligned_stride(w * 3)
	local size = stride * h
	assert(size == ffi.sizeof(bmp) - (data - bmp))
	return {w = w, h = h, stride = stride, data = data, size = size,
		format = 'bgr8', bottom_up = true, bmp = bmp}
end

local function available(src_format, values)
	values = glue.index(values)
	local t = {}
	for k in pairs(values) do t[k] = false end
	for d in bitmap.conversions(src_format) do
		t[d] = values[d]
	end
	return t
end

function player:on_render(cr)

	--select file

	local files = {
		'bg.bmp',
		'parrot.bmp',
	   'rgb_3bit.bmp',
	   'rgb_24bit.bmp',
	}
	self.file = self:mbutton{x = 10, y = 10, w = 390, h = 24,
		values = files, selected = self.file or files[1],
		id = 'file',
	}

	--convert to dest. format

	self.format = self.format or 'bgr8'

	local v1 = {
		'rgb8', 'bgr8', 'rgb16', 'bgr16',
		'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'rgbx16', 'bgrx16', 'xrgb16', 'xbgr16',
		'rgba8', 'bgra8', 'argb8', 'abgr8',
		'rgba16', 'bgra16', 'argb16', 'abgr16',
	}
	local e1 = available('bgr8', v1)
	local format1 = self:mbutton{x = 10, y = 40, w = 990, h = 24,
		values = v1, enabled = e1, selected = self.format, default = 'bgr8',
		id = 'format1'}

	local v2 = {
		'rgb565', 'rgb555', 'rgb444', 'rgba4444', 'rgba5551',
		'g1', 'g2', 'g4', 'g8', 'g16',
		'ga8', 'ag8', 'ga16', 'ag16',
		'cmyk8',
		'ycc8',
		'ycck8',
	}
	local e2 = available('bgr8', v2)
	local format2 = self:mbutton{x = 10, y = 70, w = 990, h = 24,
		values = v2, enabled = e2, selected = self.format,
		id = 'format2'}

	self.format = format2 ~= self.format and format2 or format1

	--apply dithering

	self.method = self:mbutton{x = 10, y = 100, w = 190, h = 24,
		values = {'fs', 'ordered', 'none'}, selected = self.method or 'none',
		id = 'method'}

	if self.method == 'fs' then
		local oldrbits = self.rbits

		self.rbits = self:slider{x = 10 , y = 130, w = 190, h = 24,
			i0 = 0, i1 = 8, step = 1, i = self.rbits or 4,
			id = 'rbits', text = 'r bits'}

		if oldrbits ~= self.rbits then
			self.gbits = self.rbits
			self.bbits = self.rbits
			self.abits = self.rbits
		end
		self.gbits = self:slider{x = 10 , y = 160, w = 190, h = 24,
			i0 = 0, i1 = 8, step = 1, i = self.gbits or 4,
			id = 'gbits', text = 'g bits'}
		self.bbits = self:slider{x = 10 , y = 190, w = 190, h = 24,
			i0 = 0, i1 = 8, step = 1, i = self.bbits or 4,
			id = 'bbits', text = 'b bits'}
		self.abits = self:slider{x = 10 , y = 220, w = 190, h = 24,
			i0 = 0, i1 = 8, step = 1, i = self.abits or 4,
			id = 'abits', text = 'a bits'}

	elseif self.method == 'ordered' then
		self.map = self:mbutton{x = 10 , y = 130, w = 190, h = 24,
			values = {2, 3, 4, 8}, selected = self.map or 4,
			id = 'map'}
	end

	--clip the low bits

	self.bits = self:slider{x = 10,
		y = self.method == 'fs' and 250 or self.method == 'ordered' and 160 or 130,
		w = 190, h = 24,
		i0 = 0, i1 = 8, step = 1, i = self.bits or 8,
		id = 'bits', text = 'out bits'}

	--effects

	self.invert = self:togglebutton{x = 10, y = 300, w = 90, h = 24,
		id = 'invert', text = 'invert', selected = self.invert}
	self.grayscale = self:togglebutton{x = 10, y = 330, w = 90, h = 24,
		id = 'grayscale', text = 'grayscale', selected = self.grayscale}
	self.sharpen = self:togglebutton{x = 10, y = 360, w = 90, h = 24,
		id = 'sharpen', text = 'sharpen', selected = self.sharpen}
	if self.sharpen then
		self.sharpen_amount = self:slider{x = 10 , y = 390, w = 90, h = 24,
			i0 = -20, i1 = 20, step = 1, i = self.sharpen_amount or 4,
			id = 'sharpen_amount', text = 'amount'}

	end
	self.resize = self:togglebutton{x = 10, y = 430, w = 190, h = 24,
		id = 'resize', text = 'resize', selected = self.resize}
	if self.resize then
		self.resize_x = self:slider{x = 10, y = 460, w = 190, h = 24,
			i0 = 1, i1 = 4000, step = 1, i = self.resize_x or 1200,
			id = 'resize_x', text = 'x'}
		self.resize_y = self:slider{x = 10, y = 490, w = 190, h = 24,
			i0 = 1, i1 = 4000, step = 1, i = self.resize_y or 1200,
			id = 'resize_y', text = 'y'}
		self.resize_method = self:mbutton{x = 10, y = 520, w = 190, h = 24,
			values = {'nearest', 'bilinear'},
			selected = self.resize_method or 'nearest',
			id = 'resize_method'}
	end

	--finally, perform the conversions and display up the images

	local cx, cy = 210, 100
	local function show(file)

		local bmp = load_bmp(file)

		if bmp.format ~= self.format then
			bmp = bitmap.copy(bmp, self.format, false, true)
		end

		if self.method == 'fs' then
			bitmap.dither.fs(bmp, self.rbits, self.gbits, self.bbits, self.abits)
		elseif self.method == 'ordered' then
			bitmap.dither.ordered(bmp, self.map)
		end

		--low-pass filter
		if self.bits < 8 then
			local c = 0xff-(2^(8-self.bits)-1)
			local m = (0xff / c)
			bitmap.paint(bmp, bmp, function(r,g,b,a)
				return
					bit.band(r,c) * m,
					bit.band(g,c) * m,
					bit.band(b,c) * m,
					bit.band(a,c) * m
			end)
		end

		if self.invert then
			bitmap.invert(bmp)
		end

		if self.grayscale then
			bitmap.grayscale(bmp)
		end

		if self.sharpen then
			bmp = bitmap.sharpen(bmp, self.sharpen_amount)
		end

		if self.resize then
			bmp = bitmap.resize[self.resize_method](bmp, bitmap.new(self.resize_x, self.resize_y, bmp.format))
		end

		self:image{x = cx, y = cy, image = bmp}

		cx = cx + bmp.w + 10
	end

	show(glue.bin..'/media/bmp/'..self.file)
end

player:play()

