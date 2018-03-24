
--Fast box blur algorithm for bgra8 and g8 pixel formats.
--Written by Cosmin Apreutesei. Public Domain.
--The algorithm is in csrc/boxblur/boxblur.c, this is just the ffi binding.

if not ... then require'boxblur_demo'; return end

local ffi = require'ffi'
local C = ffi.load'boxblur'
local bitmap = require'bitmap'
local boxblur = {C = C}

ffi.cdef[[

void boxblur_g8(void *src, void *dst,
	int32_t width, int32_t height, int32_t src_stride, int32_t dst_stride,
	int32_t radius, int32_t passes, void* blurx, void* sumx);

void boxblur_8888(void *src, void *dst,
	int32_t width, int32_t height, int32_t src_stride, int32_t dst_stride,
	int32_t radius, int32_t passes, void* blurx, void* sumx);

void boxblur_extend(void *src, int32_t width, int32_t height,
	int32_t src_stride, int32_t bpp, int32_t radius);

]]

local blur_func = {
	[ 8] = C.boxblur_g8;
	[32] = C.boxblur_8888;
}

local blur = {}

function boxblur.new(img, radius, passes, format)

	local format = bitmap.format(format or img)
	local blur_func = assert(blur_func[format.bpp])
	assert(radius >= 0 and radius <= 255)

	local self = {__index = blur}
	setmetatable(self, self)

	--all paddings needed for source and dest. bitmaps together.
	--we combine them since we're swapping src with dst for multiple passes.
	local w1 = radius
	local h1 = 2 * radius
	local w2 = radius + 128 / format.bpp
	local h2 = radius

	local src_data = bitmap.new(
		img.w + w1 + w2,
		img.h + h1 + h2,
		format, img.bottom_up, 16)

	self.src = bitmap.sub(src_data, w1, h1, img.w, img.h)

	local dst_data = bitmap.new(
		img.w + w1 + w2,
		img.h + h1 + h2,
		format, img.bottom_up, 16)

	self.dst = bitmap.sub(dst_data, w1, h1, img.w, img.h)

	local blurx_data = bitmap.new(
		img.w * 2,
		img.h + 4 * radius + 1,
		format, false, 16, self.src.stride * 2)

	self._blurx = bitmap.sub(blurx_data, 0, 3 * radius + 1)

	self._sumx = ffi.new('int16_t[?]', self.src.stride + 8) -- +8 for SSE

	self.img = img
	self.max_radius = radius
	self.default_passes = passes
	self.format = format
	self._blur_func = blur_func
	self._valid = false

	return self
end

function blur:_blur(src, dst)
	bitmap.clear(self._blurx.parent)
	--clear it because blur needs to read 0es that weren't ever written.
	ffi.fill(self._sumx, ffi.sizeof(self._sumx))
	self._blur_func(
		src.data,
		dst.data,
		src.w,
		src.h,
		src.stride,
		dst.stride,
		self.radius,
		self.passes,
		self._blurx.data,
		self._sumx)
end

function blur:invalidate()
	self._valid = false
end

function blur:update()
	bitmap.paint(self.src, self.img)
	C.boxblur_extend(
		self.src.data,
		self.src.w,
		self.src.h,
		self.src.stride,
		self.format.bpp,
		self.max_radius)
	self.radius = nil
	self.passes = nil
end

function blur:blur(radius, passes)
	radius = radius or self.max_radius
	passes = passes or self.default_passes or 1
	assert(radius >= 0 and radius <= self.max_radius)
	assert(passes >= 0 and passes <= 10)
	if self._valid and radius == self.radius and passes == self.passes then
		--nothing changed
	elseif self._valid and radius == 0 or passes == 0 then --no blur
		self.radius = 0
		self.passes = 0
		bitmap.paint(self.dst, self.src)
	elseif passes == 1 then
		if not self._valid then
			self:update()
			self._valid = true
		end
		self.radius = radius
		self.passes = 1
		self:_blur(self.src, self.dst)
	else
		self:update()
		self._valid = true
		self.radius = radius
		self.passes = passes
		local src, dst = self.dst, self.src
		for i=1,passes do
			src, dst = dst, src
			self:_blur(src, dst)
		end
		self.src, self.dst = src, dst
	end
	return self.dst
end

return boxblur
