
--Bitmaps for Terra.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'terra.bitmap_test'; return end

setfenv(1, require'terra.low'.module())

FORMAT_INVALID = 0
FORMAT_G8      = 1
FORMAT_ARGB32  = 2

terra valid_format(format: enum)
	assert(format == FORMAT_G8 or format == FORMAT_ARGB32)
	return format
end

terra pixelsize(format: enum)
	return iif(valid_format(format) == FORMAT_G8, 1, 4)
end

terra aligned_stride(w: int, align: uint8)
	assert(align == nextpow2(align))
	return ceil(w, align)
end

terra min_aligned_stride(w: int, format: enum)
	var bpp = iif(valid_format(format) == FORMAT_G8, 1, 4)
	return aligned_stride(w * bpp, 4) --always 4 for compat. with cairo
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
	w        : int;
	h        : int;
	pixels   : &uint8;
	capacity : int64;  --in bytes
	stride   : int;    --in bytes
	format   : enum;   --FORMAT_*
}

terra Bitmap:get_pixelsize()
	return pixelsize(self.format)
end

terra Bitmap:get_rowsize()
	return self.w * self.pixelsize
end

terra Bitmap:get_size()
	return self.h * self.stride
end

terra Bitmap:get_empty()
	return self.w == 0 or self.h == 0
end

terra Bitmap:min_aligned_stride(w: int)
	return min_aligned_stride(w, self.format)
end

--initializes a valid 0x0 bitmap of a specific format.
terra Bitmap:init(format: enum)
	fill(self)
	self.format = format
end

terra Bitmap:free()
	if self.capacity == 0 then return end --not owning the pixel buffer
	dealloc(self.pixels)
end

--give 0 to stride and capacity to ensure the smallest allocation.
--give -1 to stride and capacity to ensure minimum reallocs and re-strides
--when resizing for a growing bitmap.
terra Bitmap:_realloc_args(w: int, h: int, format: enum, stride: int, capacity: int)
	assert(w >= 0)
	assert(h >= 0)
	format = valid_format(format)

	if stride == -1 then
		stride = max(nextpow2(min_aligned_stride(w, format)), self.stride)
	elseif stride == 0 then
		stride = min_aligned_stride(w, format)
	end
	assert(stride >= w * pixelsize(format))

	var size = h * stride
	if capacity == -1 then
		capacity = max(nextpow2(size), self.capacity)
	elseif capacity == 0 then
		capacity = size
	end
	assert(capacity >= size)

	return stride, capacity
end

--(re)alloc the bitmap without preserving its pixel values.
--failure to realloc results in an empty bitmap.
terra Bitmap:realloc(w: int, h: int, format: enum, stride: int, capacity: int)
	var stride, capacity = self:_realloc_args(w, h, format, stride, capacity)
	if capacity ~= self.capacity then
		dealloc(self.pixels) --dealloc pixels to avoid copying them by realloc.
		self.pixels = nil
		self.pixels = realloc(self.pixels, capacity)
		if self.pixels ~= nil then
			self.capacity = capacity
		else
			self:init(format)
			return false
		end
	end
	self.w = w
	self.h = h
	self.stride = stride
	self.format = format
	return true
end

--create a bitmap representing a rectangular region of another bitmap.
--no pixels are copied: the bitmap references the same data buffer as the original.
terra Bitmap:sub(x: int, y: int, w: int, h: int)
	x, y, w, h = intersect(x, y, w, h, 0, 0, self.w, self.h)
	var offset = y * self.stride + x * pixelsize(self.format)
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

local row_by_row_func = {&uint8, &uint8, int} -> {}

Bitmap.methods._row_by_row_forward = terra(src: &Bitmap, dst: &Bitmap, func: row_by_row_func)
	if src.stride == 0 then return end
	var w = min(src.w, dst.w)
	var h = min(src.h, dst.h)
	var dj = 0
	for sj = 0, h * src.stride, src.stride do
		func(dst.pixels + dj, src.pixels + sj, w)
		dj = dj + dst.stride
	end
end

Bitmap.methods._row_by_row_reverse = terra(src: &Bitmap, dst: &Bitmap, func: row_by_row_func)
	if src.stride == 0 then return end
	var w = min(src.w, dst.w)
	var h = min(src.h, dst.h)
	var dj = (h - 1) * dst.stride
	for sj = (h - 1) * src.stride, -1, -src.stride do
		print(dj, sj)
		func(dst.pixels + dj, src.pixels + sj, w)
		dj = dj - dst.stride
	end
end

Bitmap.methods.row_by_row = terra(src: &Bitmap, dst: &Bitmap, func: row_by_row_func)
	if src.pixels == dst.pixels
		or (src.pixels + src.size <= dst.pixels)
		or (dst.pixels + dst.size <= src.pixels)
		or (src.pixels >= dst.pixels and src.stride >= dst.stride)
	then
		--forward row-by-row copy possible without overwriting the destination.
		src:_row_by_row_forward(dst, func)
		return true
	elseif src.pixels <= dst.pixels and src.stride <= dst.stride then
		--reverse row-by-row copy possible without overwriting the destination.
		src:_row_by_row_reverse(dst, func)
		return true
	else
		--direct write not possible, must copy the source to a temporary buffer.
		return false
	end
end

local struct row_iter{bitmap: &Bitmap}
row_iter.metamethods.__for = function(self, body)
	return quote
		var self = self.bitmap
		if self.stride ~= 0 then
			for i = 0, self.h * self.stride, self.stride do
				[ body(i, `self.pixels + i) ]
			end
		end
	end
end
terra Bitmap:rows()
	return row_iter{bitmap = self}
end

local struct row_backwards_iter{bitmap: &Bitmap}
row_backwards_iter.metamethods.__for = function(self, body)
	return quote
		var self = self.bitmap
		if self.stride ~= 0 then
			for i = (self.h-1) * self.stride, -1, self.stride do
				[ body(i, `self.pixels + i) ]
			end
		end
	end
end
terra Bitmap:rows_backwards()
	return row_backwards_iter{bitmap = self}
end

local terra blend_copy_row_g8(d: &uint8, s: &uint8, w: int)
	copy(d, s, w)
end

local terra blend_copy_row_argb32(d: &uint8, s: &uint8, w: int)
	copy(d, s, w * 4)
end

local terra blend_source_g8_argb32(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		@[&vector(uint8, 4)](d+i*4) = s[i]
	end
end

local terra blend_source_argb32_g8(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		--TODO
	end
end

local terra blend_over_g8_argb32(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		--TODO:
		--var da = d[i*4+0]
		--d[i*4+1] = 1 + (1 - sa) * d[i*4+1]
		--d[i*4+2] = 1 + (1 - sa) * d[i*4+2]
		--d[i*4+3] = 1 + (1 - sa) * d[i*4+3]
		--d[i*4+0] = sa + da - sa * da
	end
end

local terra blend_over_argb32_g8(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		--TODO:
	end
end

local terra blend_over_g8_g8(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		--TODO:
	end
end

local terra blend_over_argb32_argb32(d: &uint8, s: &uint8, w: int)
	for i=0,w do
		--TODO:
		--var sa = s[i*4+0]
		--d[i*4+1] = s[i*4+1] + (1 - s[i*4+1]) * d[i*4+1]
		--d[i*4+2] = s[i*4+2] + (1 - s[i*4+2]) * d[i*4+2]
		--d[i*4+3] = s[i*4+3] + (1 - s[i*4+3]) * d[i*4+3]
		--d[i*4+0] = sa + d[i*4+0] - sa * d[i*4+0]
	end
end

BLEND_SOURCE = 0
BLEND_OVER   = 1

terra Bitmap:blend_func(src_format: enum, dst_format: enum, op: enum)
	if op == BLEND_SOURCE then
		if src_format == FORMAT_G8 and dst_format == FORMAT_G8 then
			return blend_copy_row_g8
		elseif src_format == FORMAT_ARGB32 and dst_format == FORMAT_ARGB32 then
			return blend_copy_row_argb32
		elseif src_format == FORMAT_G8 and dst_format == FORMAT_ARGB32 then
			return blend_source_g8_argb32
		elseif src_format == FORMAT_ARGB32 and dst_format == FORMAT_G8 then
			return blend_source_argb32_g8
		end
	elseif op == BLEND_OVER then
		if src_format == FORMAT_G8 and dst_format == FORMAT_ARGB32 then
			return blend_over_g8_argb32
		elseif src_format == FORMAT_ARGB32 and dst_format == FORMAT_G8 then
			return blend_over_argb32_g8
		elseif src_format == FORMAT_ARGB32 and dst_format == FORMAT_ARGB32 then
			return blend_over_argb32_argb32
		elseif src_format == FORMAT_G8 and dst_format == FORMAT_G8 then
			return blend_over_g8_g8
		end
	end
	assert(false)
end

--NOTE: src and dst can be arbitrary subs of the same bitmap.
terra Bitmap:blend(dst: &Bitmap, dstx: int, dsty: int, op: enum)

	--find the clip rectangle and make sub-bitmaps
	var src, dst = self:intersect(dst, dstx, dsty)

	--optimization: try to copy the bitmap whole.
	if op == BLEND_SOURCE then
		if src.format == dst.format then
			if src.pixels == dst.pixels then --nothing to do
				return
			end
			--TODO: test the feasibility limit src.stride <= 2 * src.rowsize
			if src.stride == dst.stride and src.stride <= 2 * src.rowsize then
				assert(dst.size == src.size)
				if src.pixels ~= dst.pixels then
					copy(dst.pixels, src.pixels, src.size)
				end
				return
			end
		end
	end

	var blend_func = self:blend_func(src.format, dst.format, op)
	assert(src:row_by_row(&dst, blend_func))
end

terra Bitmap:copy()
	var dst: Bitmap
	dst:init(self.format)
	if dst:realloc(self.w, self.h, self.format, 0, 0) then
		self:blend(&dst, 0, 0, BLEND_SOURCE)
	end
	return dst
end

terra Bitmap:fill(val: uint8)
	if self.rowsize == self.stride then
		fill(self.pixels, self.size, val)
	else
		for _,pixels in self:rows() do
			fill(pixels, self.rowsize, val)
		end
	end
end

terra Bitmap:clear()
	self:fill(0)
end

--resize the bitmap while preserving its pixel values.
--failure to realloc results in an empty bitmap.
terra Bitmap:resize(w: int, h: int, stride: int, capacity: int64)
	var format = self.format
	var stride, capacity = self:_realloc_args(w, h, format, stride, capacity)
	if capacity ~= self.capacity then
		self.pixels = realloc(self.pixels, capacity)
		if self.pixels ~= nil then
			self.capacity = capacity
		else
			self:init(format)
			return false
		end
	end
	if stride ~= self.stride then --re-stride the rows.
		var blend_func = self:blend_func(format, format, BLEND_SOURCE)
		var dst = @self
		dst.stride = stride
		assert(self:row_by_row(&dst, blend_func))
		self.stride = stride
	end
	self.w = w
	self.h = h
	return true
end

terra Bitmap:pixel_addr(x: int, y: int)
	return
		iif(x >= 0 and x < self.w and y >= 0 and y < self.h,
			self.pixels + y * self.stride + x * self.pixelsize,
			nil)
end

terra new(w: int, h: int, format: enum, stride: int)
	var bmp: Bitmap
	bmp:init(format)
	bmp:realloc(w, h, format, stride, 0)
	return bmp
end

return _M
