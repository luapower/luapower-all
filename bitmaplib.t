
--Bitmaps for Terra.
--Written by Cosmin Apreutesei. Public Domain.

local bitmaplib = {__index = require'low'}
setfenv(1, setmetatable(bitmaplib, bitmaplib))
public = publish'bitmaplib'

BITMAP_FORMAT_G8     = 1
BITMAP_FORMAT_ARGB32 = 2

terra pixelsize(format: enum)
	return iif(format == BITMAP_FORMAT_G8, 1, 4)
end

terra aligned_stride(w: int, align: uint8) --assuming align is 2^n
	return (w + align - 1) and not (align - 1)
end

--intersect two positive 1D segments
local terra intersect_segs(ax1: int, ax2: int, bx1: int, bx2: int)
	return max(ax1, bx1), min(ax2, bx2)
end

local terra clip(x1: int, y1: int, w1: int, h1: int, x2: int, y2: int, w2: int, h2: int)
	--intersect on each dimension
	var x1, x2 = intersect_segs(x1, x1+w1, x2, x2+w2)
	var y1, y2 = intersect_segs(y1, y1+h1, y2, y2+h2)
	--clamp size
	var w = max(x2-x1, 0)
	var h = max(y2-y1, 0)
	return x1, y1, w, h
end

struct Bitmap (public) {
	w: int;
	h: int;
	stride: int;
	format: enum; --BITMAP_FORMAT_*
	pixels: &uint8;
	parent: &Bitmap;
}

terra Bitmap:rowsize()
	return self.w * pixelsize(self.format)
end

terra Bitmap:size()
	return self.h * self.stride * pixelsize(self.format)
end

terra Bitmap:init()
	fill(self)
end

terra Bitmap:free()
	if self.parent == nil then
		free(self.pixels)
	end
	self.pixels = nil
	self.parent = nil
end

terra Bitmap:alloc(w: int, h: int, format: enum, stride: int)
	self:free()
	self.w = w
	self.h = h
	self.format = format
	self.stride = stride
	self.pixels = alloc(uint8, self:size())
end

terra Bitmap:clear()
	fill(self.pixels, self:size())
end

--create a bitmap representing a rectangular region of another bitmap.
--no pixels are copied: the bitmap references the same data buffer as the original.
terra Bitmap:sub(x: int, y: int, w: int, h: int)
	x, y, w, h = clip(x, y, w, h, 0, 0, self.w, self.h)
	var offset = y * self.stride + x * pixelsize(self.format)
	return Bitmap {
		w = w, h = h,
		stride = self.stride,
		format = self.format,
		pixels = self.pixels + offset,
		parent = self,
	}
end

terra Bitmap:paint(dst: &Bitmap, dstx: int, dsty: int)
	var src = self
	assert(src.format == dst.format)

	--find the clip rectangle and make sub-bitmaps
	var src_sub: Bitmap
	var dst_sub: Bitmap
	if not (dstx == 0 and dsty == 0 and src.w == dst.w and src.h == dst.h) then
		var x, y, w, h = clip(dstx, dsty, dst.w-dstx, dst.h-dsty, dstx, dsty, src.w, src.h)
		if w == 0 or h == 0 then return end
		src_sub = src:sub(0, 0, w, h); src = &src_sub
		dst_sub = dst:sub(x, y, w, h); dst = &dst_sub
	end
	assert(src.h == dst.h)
	assert(src.w == dst.w)

	--try to copy the bitmap whole
	if src.format == dst.format and src.stride == dst.stride then
		if src.pixels ~= dst.pixels then
			assert(dst:size() >= src:size())
			copy(dst.pixels, src.pixels, src:size())
		end
		return
	end

	--check that dest. pixels would not be written ahead of source pixels
	assert(src.pixels ~= dst.pixels or dst.stride <= src.stride)

	--copy the bitmap row-by-row
	var dj = 0
	for sj = 0, src.h * src.stride, src.stride do
		copy(dst.pixels + dj, src.pixels + sj, src:rowsize())
		dj = dj + dst.stride
	end
end

terra bitmap(w: int, h: int, format: enum, stride: int)
	var bmp: Bitmap; bmp:init(); bmp:alloc(w, h, format, stride); return bmp
end

public:getenums(bitmaplib)

return bitmaplib
