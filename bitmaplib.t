
--Bitmaps for Terra.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'bitmaplib_test'; return end

setfenv(1, require'low')

BITMAP_INVALID = 0
BITMAP_G8      = 1
BITMAP_ARGB32  = 2

bitmap = {}

terra bitmap.valid_format(format: enum)
	assert(format == BITMAP_G8 or format == BITMAP_ARGB32)
	return format
end

terra bitmap.pixelsize(format: enum)
	return iif(bitmap.valid_format(format) == BITMAP_G8, 1, 4)
end

terra bitmap.aligned_stride(w: int, align: uint8)
	assert(align == nextpow2(align))
	return ceil(w, align)
end

terra bitmap.min_aligned_stride(w: int, format: enum)
	var bpp = iif(bitmap.valid_format(format) == BITMAP_G8, 1, 4)
	return bitmap.aligned_stride(w * bpp, 4) --always 4 for compat. with cairo
end

--intersect two positive 1D segments
local terra intersect_segs(ax1: int, ax2: int, bx1: int, bx2: int)
	return max(ax1, bx1), min(ax2, bx2)
end

local terra intersect(x1: int, y1: int, w1: int, h1: int, x2: int, y2: int, w2: int, h2: int)
	--intersect on each dimension
	var x1, x2 = intersect_segs(x1, x1+w1, x2, x2+w2)
	var y1, y2 = intersect_segs(y1, y1+h1, y2, y2+h2)
	--clamp size
	var w = max(x2-x1, 0)
	var h = max(y2-y1, 0)
	return x1, y1, w, h
end

struct Bitmap (gettersandsetters) {
	w: int;
	h: int;
	pixels: &uint8;
	stride: int;  --in bytes!
	format: enum; --BITMAP_*
}
bitmap.Bitmap = Bitmap

Bitmap.empty = `Bitmap {
	w = 0;
	h = 0;
	stride = 0;
	format = BITMAP_INVALID;
	pixels = nil;
}

terra Bitmap:get_rowsize()
	return self.w * bitmap.pixelsize(self.format)
end

terra Bitmap:get_size()
	return self.h * self.stride
end

terra Bitmap:init()
	@self = [Bitmap.empty]
end

terra Bitmap:free()
	free(self.pixels)
	self:init()
end

terra Bitmap:realloc(w: int, h: int, format: enum, stride: int)
	format = bitmap.valid_format(format)
	if stride == -1 then
		stride = bitmap.min_aligned_stride(w, format)
	end
	var old_size = self.size
	self.w = w
	self.h = h
	self.format = format
	self.stride = stride
	var new_size = self.size
	if new_size ~= old_size then
		free(self.pixels) --free pixels to avoid copying them
		self.pixels = realloc(self.pixels, new_size)
	end
end

terra Bitmap:clear()
	fill(self.pixels, self.size)
end

--create a bitmap representing a rectangular region of another bitmap.
--no pixels are copied: the bitmap references the same data buffer as the original.
terra Bitmap:sub(x: int, y: int, w: int, h: int)
	x, y, w, h = intersect(x, y, w, h, 0, 0, self.w, self.h)
	var offset = y * self.stride + x * bitmap.pixelsize(self.format)
	return Bitmap {
		w = w, h = h,
		stride = self.stride,
		format = self.format,
		pixels = self.pixels + offset,
	}
end

--intersect self with a bitmap at a position and return the result the
--two sub-bitmaps that perfectly overlap each other.
terra Bitmap:intersect(dst: &Bitmap, px: int, py: int)
	var src = self
	var src_sub: Bitmap
	var dst_sub: Bitmap
	var x, y, w, h = intersect(px, py, src.w, src.h, 0, 0, dst.w, dst.h)
	src_sub = src:sub(x-px, y-py, w, h)
	dst_sub = dst:sub(x, y, w, h)
	return src_sub, dst_sub
end

Bitmap.methods.each_row = macro(function(src, dst, func)
	return quote
		var dj = 0
		for sj = 0, src.h * src.stride, src.stride do
			func(dst.pixels + dj, src.pixels + sj, src.rowsize)
			dj = dj + dst.stride
		end
	end
end)

terra Bitmap:paint(dst: &Bitmap, dstx: int, dsty: int)

	--find the clip rectangle and make sub-bitmaps
	var src, dst = self:intersect(dst, dstx, dsty)

	--try to copy the bitmap whole
	if src.format == dst.format and src.stride == dst.stride then
		if src.pixels ~= dst.pixels then
			assert(dst.size >= src.size)
			copy(dst.pixels, src.pixels, src.size)
		end
		return
	end

	--check that dest. pixels would not be written ahead of source pixels
	assert(src.pixels ~= dst.pixels or dst.stride <= src.stride)

	--copy the bitmap row-by-row
	if src.format == dst.format then
		src:each_row(dst, copy)
	else
		assert(false, 'NYI')
	end
end

terra Bitmap:copy()
	var dst: Bitmap
	dst:init()
	dst:realloc(self.w, self.h, self.format, -1)
	if dst.pixels ~= nil then
		self:paint(&dst, 0, 0)
	end
	return dst
end

BITMAP_COPY = 0
BITMAP_OVER = 1

local blend_copy_g8_rgba32 = macro(function(d, s, n)
	return quote
		for i=0,n do
			@[&vector(uint8, 4)](d+i*4) = s[i]
		end
	end
end)

local blend_copy_rgba32_rgba32 = copy

local blend_over_g8_rgba32 = macro(function(d, s, n)
	return quote
		for i=0,n do
			--TODO:
			--var da = d[i*4+0]
			--d[i*4+1] = 1 + (1 - sa) * d[i*4+1]
			--d[i*4+2] = 1 + (1 - sa) * d[i*4+2]
			--d[i*4+3] = 1 + (1 - sa) * d[i*4+3]
			--d[i*4+0] = sa + da - sa * da
		end
	end
end)

local blend_over_rgba32_rgba32 = macro(function(d, s, n)
	return quote
		for i=0,n/4 do
			--TODO:
			--var sa = s[i*4+0]
			--d[i*4+1] = s[i*4+1] + (1 - s[i*4+1]) * d[i*4+1]
			--d[i*4+2] = s[i*4+2] + (1 - s[i*4+2]) * d[i*4+2]
			--d[i*4+3] = s[i*4+3] + (1 - s[i*4+3]) * d[i*4+3]
			--d[i*4+0] = sa + d[i*4+0] - sa * d[i*4+0]
		end
	end
end)

terra Bitmap:blend(dst: &Bitmap, dstx: int, dsty: int, op: enum)

	--find the clip rectangle and make sub-bitmaps
	var src, dst = self:intersect(dst, dstx, dsty)

	if op == BITMAP_COPY then
		if src.format == BITMAP_G8 and dst.format == BITMAP_ARGB32 then
			src:each_row(dst, blend_copy_g8_rgba32)
		elseif src.format == BITMAP_ARGB32 and dst.format == BITMAP_ARGB32 then
			src:each_row(dst, blend_copy_rgba32_rgba32)
		else
			assert(false)
		end
	elseif op == BITMAP_OVER then
		if src.format == BITMAP_G8 and dst.format == BITMAP_ARGB32 then
			src:each_row(dst, blend_over_g8_rgba32)
		elseif src.format == BITMAP_ARGB32 and dst.format == BITMAP_ARGB32 then
			src:each_row(dst, blend_over_rgba32_rgba32)
		else
			assert(false)
		end
	else
		assert(false)
	end
end

terra bitmap.new(w: int, h: int, format: enum, stride: int)
	var bmp: Bitmap; bmp:init(); bmp:realloc(w, h, format, stride); return bmp
end

bitmap.blend = blend
