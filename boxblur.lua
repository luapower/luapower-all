
--Fast box blur algorithm for bgra8 and g8 pixel formats.
--Written by Cosmin Apreutesei. Public Domain.
--The algorithm is in csrc/boxblur/boxblur.c, this is just the ffi binding.

if not ... then require'boxblur_demo'; return end

local ffi = require'ffi'
local C = ffi.load'boxblur'
local glue = require'glue'
local bitmap = require'bitmap'
local round = glue.round
local clamp = glue.clamp
local boxblur = {C = C}

ffi.cdef[[

typedef unsigned char u8;
typedef short i16;
typedef int i32;

void boxblur_g8(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	void* blurx, void* sumx);

void boxblur_8888(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	void* blurx, void* sumx);

void boxblur_extend(u8 *src, i32 width, i32 height,
	i32 src_stride, i32 bpp, i32 radius);

]]

local blur_func = {
	[ 8] = C.boxblur_g8;
	[32] = C.boxblur_8888;
}

local blur = {}

function boxblur.new(...)
	local w, h, bottom_up, img, radius, passes, format
	if type((...)) == 'number' then
		w, h, format, radius, passes = ...
		bottom_up = false
	else
		img, radius, passes, format = ...
		w = img.w
		h = img.h
		bottom_up = img.bottom_up
	end
	w = math.ceil(w)
	h = math.ceil(h)

	local format_string = assert(format or img.format, 'format expected')
	local format = bitmap.format(format_string)
	local blur_func = assert(blur_func[format.bpp], 'unsupoorted format')
	radius = round(clamp(radius, 0, 255))

	local self = {__index = blur}
	setmetatable(self, self)

	--compute side paddings needed for both source and dest. bitmaps.
	--we set max padding since we're swapping src with dst for multiple passes.
	local w1 = radius
	local h1 = 2 * radius
	local w2 = radius + 128 / format.bpp
	local h2 = radius

	local src_data = bitmap.new(
		w + w1 + w2,
		h + h1 + h2,
		format_string, bottom_up, 16)

	self.src = bitmap.sub(src_data, w1, h1, w, h)

	local dst_data = bitmap.new(
		w + w1 + w2,
		h + h1 + h2,
		format_string, bottom_up, 16)

	self.dst = bitmap.sub(dst_data, w1, h1, w, h)

	local blurx_data = bitmap.new(
		w * 2,
		h + 4 * radius + 1,
		format_string, false, 16, self.src.stride * 2) --16bit samples

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
	--clear sumx because blur needs to read some 0es from it.
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

function blur:repaint(src) end --stub

function blur:_extend(src)
	C.boxblur_extend(
		src.data,
		src.w,
		src.h,
		src.stride,
		self.format.bpp,
		self.max_radius)
end

function blur:_repaint()
	if self._valid then return end
	if self.img then
		bitmap.paint(self.src, self.img)
	else
		self:repaint(self.src)
	end
	self._valid = true
end

function blur:blur(radius, passes)
	radius = round(clamp(radius or self.max_radius, 0, self.max_radius))
	passes = clamp(passes or self.default_passes or 1, 0, 10)
	if self._valid and radius == self.radius and passes == self.passes then
		--nothing changed
	elseif radius == 0 or passes == 0 then --no blur
		if self.radius and self.radius ~= 0 then --src blurred, repaint
			self._valid = false
			self:_repaint()
		end
		self.radius = 0
		self.passes = 0
		bitmap.paint(self.dst, self.src)
	elseif passes == 1 then
		if self.passes and self.passes > 1 then --src blurred, repaint
			self._valid = false
		end
		self:_repaint()
		self.radius = radius
		self.passes = 1
		self:_extend(self.src)
		self:_blur(self.src, self.dst)
	else
		self._valid = false
		self:_repaint()
		self.radius = radius
		self.passes = passes
		local src, dst = self.dst, self.src
		for i=1,passes do
			src, dst = dst, src
			self:_extend(src)
			self:_blur(src, dst)
		end
		self.src, self.dst = src, dst
	end
	return self.dst
end

return boxblur
