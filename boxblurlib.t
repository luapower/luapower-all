
--Fast bgra8 and g8 box blurs for Terra.
--Written by Cosmin Apreutesei. Public Domain.

local boxblurlib = {__index = require'bitmaplib'}
setfenv(1, setmetatable(boxblurlib, boxblurlib))

includepath'$L/csrc/boxblur'
include'boxblur.h'
linklibrary'boxblur'

RepaintFunc = {&Bitmap} -> {}

struct Blur {
	--config
	w: int;
	h: int;
	format: enum; --BITMAP_FORMAT_*
	repaint: RepaintFunc;
	--buffers
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

terra Blur:_alloc()
	--compute side paddings needed for both source and dest. bitmaps.
	--we set max padding since we're swapping src with dst for multiple passes.
	var w = self.w
	var h = self.h
	var max_radius = [int](self.max_radius)
	var w1 = max_radius
	var h1 = 2 * max_radius
	var w2 = max_radius + 16 / pixelsize(self.format)
	var h2 = max_radius
	var bw = w + w1 + w2
	var bh = w + w1 + w2

	self.bmp1_parent = bitmap(bw, bh, self.format, aligned_stride(bw, 16))
	self.bmp2_parent = bitmap(bw, bh, self.format, aligned_stride(bw, 16))
	self.blurx_parent = bitmap(
		w * 2, --16bit samples so double the width.
		h + 4 * max_radius + 1,
		self.format, aligned_stride(self.src.stride * 2, 16))

	self.sumx_size = self.src.stride + 8
	self.sumx = alloc(int16, self.sumx_size)

	if self.sumx == nil
		or self.bmp1_parent.pixels == nil
		or self.bmp2_parent.pixels == nil
		or self.blurx_parent.pixels == nil
	then
		self:free()
		return
	end

	self.bmp1 = self.bmp1_parent:sub(w1, h1, w, h)
	self.bmp2 = self.bmp2_parent:sub(w1, h1, w, h)
	self.blurx = self.blurx_parent:sub(0, 3 * max_radius + 1, maxint, maxint)
	self.src = &self.bmp1
	self.dst = &self.bmp2
	self.valid = false
end

terra Blur:free()
	self.bmp1_parent:free()
	self.bmp2_parent:free()
	self.blurx_parent:free()
	free(self.sumx); self.sumx = nil
	self.max_radius = -1
	self.src = nil
	self.dst = nil
end

terra Blur:grow(radius: uint8)
	if radius > self.max_radius then
		self:free()
		while self.max_radius < radius do
			self.max_radius = max(8, self.max_radius) * 2
		end
		self:_alloc()
	end
end

terra boxblurlib.boxblur(w: int, h: int, format: enum, repaint: RepaintFunc)
	var self: Blur; fill(&self)
	self.w = w
	self.h = h
	self.format = format
	self.repaint = repaint
	self.max_radius = -1
	return self
end

terra Blur:_blur(src: &Bitmap, dst: &Bitmap)
	var g8 = self.format == BITMAP_FORMAT_G8
	var blur = iif(g8, boxblur_g8, boxblur_8888)
	self.blurx.parent:clear()
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

terra Blur:invalidate()
	self.valid = false
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

terra Blur:_repaint()
	if self.valid then return end
	self.repaint(self.src)
	self.valid = true
end

terra Blur:blur(radius: uint8, passes: uint8)
	self:grow(radius)
	passes = clamp(passes, 0, 10)
	if self.valid and radius == self.radius and passes == self.passes then
		--nothing changed
	elseif radius == 0 or passes == 0 then --no blur
		if self.radius > 0 then --src blurred, repaint
			self.valid = false
			self:_repaint()
		end
		self.radius = 0
		self.passes = 0
		self.src:paint(self.dst, 0, 0)
	elseif passes == 1 then
		if self.passes > 1 then --src blurred, repaint
			self.valid = false
		end
		self:_repaint()
		self.radius = radius
		self.passes = 1
		self:_extend(self.src)
		self:_blur(self.src, self.dst)
	else
		self.valid = false
		self:_repaint()
		self.radius = radius
		self.passes = passes
		var src, dst = self.dst, self.src
		for i=1,passes do
			src, dst = dst, src
			self:_extend(src)
			self:_blur(src, dst)
		end
		self.src, self.dst = src, dst
	end
	return self.dst
end

return boxblurlib
