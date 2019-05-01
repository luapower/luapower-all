
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
	repaint: BlurRepaintFunc; context: &opaque;
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

terra Blur:init(format: enum, repaint: BlurRepaintFunc, context: &opaque)
	fill(self)
	self.format = format
	self.repaint = repaint
	self.context = context
end

terra Blur:free()
	self.bmp1_parent:free()
	self.bmp2_parent:free()
	self.blurx_parent:free()
	free(self.sumx)
	self.max_radius = 0
	self.max_w = 0
	self.max_h = 0
	self.w = 0
	self.h = 0
	self.src = nil
	self.dst = nil
	self.valid = false
end

terra Blur:_alloc()
	--compute side paddings needed for both source and dest. bitmaps.
	--we set max padding since we're swapping src with dst for multiple passes.
	var w = self.max_w
	var h = self.max_h
	var r = self.max_radius
	var w1 = r
	var h1 = 2 * r
	var w2 = r + 16 / pixelsize(self.format)
	var h2 = r
	var bw = w + w1 + w2
	var bh = w + w1 + w2

	self.bmp1_parent = bitmap.new(bw, bh, self.format, aligned_stride(bw, 16))
	self.bmp2_parent = bitmap.new(bw, bh, self.format, aligned_stride(bw, 16))
	self.bmp1 = self.bmp1_parent:sub(w1, h1, self.w, self.h)
	self.bmp2 = self.bmp2_parent:sub(w1, h1, self.w, self.h)
	self.src = &self.bmp1
	self.dst = &self.bmp2

	self.sumx_size = self.src.stride + 8
	self.sumx = alloc(int16, self.sumx_size)

	self.blurx_parent = bitmap.new(
		w * 2, --16bit samples so double the width.
		h + 4 * r + 1,
		self.format, aligned_stride(self.src.stride * 2, 16))
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

local terra grow(x: num, newx: num, factor: num)
	if x == 0 then return newx end
	while x < newx do x = x * factor end
	return x
end

terra Blur:grow(w: int, h: int, radius: uint8)
	if w > self.max_w or h > self.max_h or radius > self.max_radius then
		self:free()
		self.max_radius = clamp(grow(self.max_radius, max(8, radius), 2), 0, 255)
		self.max_w = grow(self.max_w, w, sqrt(2))
		self.max_h = grow(self.max_h, h, sqrt(2))
		self.w = w
		self.h = h
		self:_alloc()
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
	self.repaint(self.context, self.src)
	self.valid = true
end

terra Blur:blur(w: int, h: int, radius: uint8, passes: uint8)
	self:grow(w, h, radius)
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

terra Blur:free_and_deallocate()
	free(self)
end

function Blur:build()
	local public = publish'boxblurlib'
	public(Bitmap, {
		--
	})
	public(bitmap.new, 'bitmap')
	public:getenums(low, '^BITMAP_')
	public(Blur, {
		free_and_deallocate='free',
		blur=1,
	}, true)

	local terra blur(format: enum, repaint: BlurRepaintFunc, context: &opaque)
		var b = alloc(Blur); b:init(format, repaint, context)
		return b
	end
	public(blur)
	public:getenums(Blur)
	public:build{
		linkto = {'boxblur'},
	}
end

if not ... then
	pf'Compiling...'
	Blur:build()
	pfn'OK'
end

return low
