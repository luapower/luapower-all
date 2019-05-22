
--Fast bgra8 and g8 box blurs for Terra.
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'low')

require'bitmaplib'

includepath'$L/csrc/boxblur'
include'boxblur.h'
linklibrary'boxblur'

local pixelsize = bitmap.pixelsize
local aligned_stride = bitmap.aligned_stride

BlurRepaintFunc = {&opaque, &Bitmap} -> {}

struct Blur {
	--config
	w: int;
	h: int;
	format: enum; --BITMAP_*
	--buffers
	max_w: int;
	max_h: int;
	max_radius: int;
	bmp1  : Bitmap; bmp1_parent: Bitmap;
	bmp2  : Bitmap; bmp2_parent: Bitmap;
	blurx : Bitmap; blurx_parent: Bitmap;
	sumx  : &int16; sumx_size: int;
	--state
	src    : &Bitmap;
	dst    : &Bitmap;
	radius : uint8;
	passes : uint8;
	valid  : bool;
}

terra Blur:init(format: enum)
	fill(self)
	self.format = format
end

terra Blur:free()
	self.bmp1_parent:free()
	self.bmp2_parent:free()
	self.blurx_parent:free()
	free(self.sumx)
	self:init(self.format)
end

terra Blur:_realloc()
	--compute side paddings needed for both src and dst bitmaps.
	--both get padding because src gets swapped with dst on multiple passes.
	var w = self.max_w
	var h = self.max_h
	var r = self.max_radius
	var w1 = r
	var h1 = 2 * r
	var w2 = r + 16 / pixelsize(self.format)
	var h2 = r
	var bw = w + w1 + w2
	var bh = h + h1 + h2
	var stride = aligned_stride(bw, 16)

	self.bmp1_parent:realloc(bw, bh, self.format, stride)
	self.bmp2_parent:realloc(bw, bh, self.format, stride)
	self.bmp1 = self.bmp1_parent:sub(w1, h1, self.w, self.h)
	self.bmp2 = self.bmp2_parent:sub(w1, h1, self.w, self.h)
	self.src = &self.bmp1
	self.dst = &self.bmp2

	self.sumx_size = stride + 8
	self.sumx = realloc(self.sumx, self.sumx_size)

	self.blurx_parent:realloc(
		w * 2, --16bit samples so double the width.
		h + 4 * r + 1,
		self.format, stride * 2)
	self.blurx = self.blurx_parent:sub(0, 3 * r + 1, maxint, maxint)

	if self.sumx == nil
		or self.bmp1_parent.pixels == nil
		or self.bmp2_parent.pixels == nil
		or self.blurx_parent.pixels == nil
	then
		self:free()
		return
	end

	self.valid = false
end

local terra grow(x: num, new_x: num, factor: num)
	if x == 0 then return new_x end
	while x < new_x do x = x * factor end
	return x
end

terra Blur:setsize(w: int, h: int, radius: uint8)
	if w ~= self.w or h ~= self.h or radius > self.max_radius then
		self.max_radius = clamp(grow(self.max_radius, max(8, radius), 2), 0, 255)
		self.max_w = grow(self.max_w, w, sqrt(2))
		self.max_h = grow(self.max_h, h, sqrt(2))
		self.w = w
		self.h = h
		self:_realloc()
	end
end

terra Blur:_blur(src: &Bitmap, dst: &Bitmap)
	var g8 = self.format == BITMAP_G8
	var blur = iif(g8, boxblur_g8, boxblur_8888)
	self.blurx_parent:clear()
	--clear sumx because blur needs to read some 0es from it.
	fill(self.sumx, self.sumx_size)
	blur(
		src.pixels,
		dst.pixels,
		src.w,
		src.h,
		src.stride,
		dst.stride,
		self.radius,
		self.passes,
		[&int16](self.blurx.pixels),
		self.sumx)
end

terra Blur:_extend(src: &Bitmap)
	boxblur_extend(
		src.pixels,
		src.w,
		src.h,
		src.stride,
		pixelsize(self.format) * 8,
		self.radius)
end

Blur.methods.invalidate = overload'invalidate'

Blur.methods.invalidate:adddefinition(
	terra(self: &Blur)
		self.valid = false
	end
)

Blur.methods.invalidate:adddefinition(
	terra(self: &Blur, w: int, h: int, radius: uint8, passes: uint8)
		passes = clamp(passes, 0, 10)
		if self.valid and radius == self.radius and passes == self.passes
			and w == self.w and h == self.h
		then
			--nothing changed
		else
			self:setsize(w, h, radius)
			if radius == 0 or passes == 0 then --no blur
				if self.radius > 0 then --src blurred
					self.valid = false
				end
			elseif passes == 1 then
				if self.passes > 1 then --src blurred
					self.valid = false
				end
			else
				self.valid = false
			end
			self.radius = radius
			self.passes = passes
		end
		return iif(not self.valid, self.src, nil)
	end
)

terra Blur:blur()
	if not self.valid then
		if self.radius == 0 or self.passes == 0 then --no blur
			self.src:paint(self.dst, 0, 0)
		elseif self.passes == 1 then
			self:_extend(self.src)
			self:_blur(self.src, self.dst)
		else
			var src, dst = self.dst, self.src
			for i=1,self.passes do
				src, dst = dst, src
				self:_extend(src)
				self:_blur(src, dst)
			end
			self.src, self.dst = src, dst
		end
	end
	return self.dst
end

terra Blur:free_and_deallocate()
	free(self)
end

function Blur:build()
	local public = publish'boxblurlib'
	public(Bitmap, {
		--
	})
	public(bitmap.new, 'bitmap')
	public:getenums(_M, '^BITMAP_')
	public(Blur, {
		free_and_deallocate='free',
		invalidate = {'invalidate', 'invalidate_rect'},
		blur=1,
	}, true)

	local terra blur(format: enum)
		var b = alloc(Blur)
		b:init(format)
		return b
	end
	public(blur)
	public:build{
		linkto = {'boxblur'},
	}
end

if not ... then
	pf'Compiling...'
	Blur:build()
	pfn'OK'
end

return _M
