--[[

	1-D and 2-D bit array type for Terra.
	Written by Cosmin Apreutesei. Public domain.

	A bit array is a packed array of bits.

]]

if not ... then require'terra.bitarray_test'; return end

setfenv(1, require'terra.low')
require'terra.box2d'
local rect = rect(num)

local function view_type(size_t)

	local struct view {
		bits: &uint8;
		offset: size_t; --in bits, relative to &bits
		len: size_t; --in bits
	}

	view.empty = `view{bits = nil, offset = 0, len = 0}

	newcast(view, niltype, view.empty)

	view.metamethods.__apply = macro(function(self, i)
		return `self:get(i)
	end)

	addmethods(view, function()

		local addr = macro(function(self, i)
			return quote
				var i = i + self.offset
				in i >> 3, i and 7
			end
		end)

		terra view:get(i: size_t)
			assert(i >= 0 and i < self.len)
			var B, b = addr(self, i)
			return getbit(self.bits[B], b)
		end

		terra view:set(i: size_t, v: bool)
			assert(i >= 0 and i < self.len)
			var B, b = addr(self, i)
			setbit(self.bits[B], b, v)
		end

		terra view:range(i: size_t, j: size_t)
			assert(i >= 0)
			i = min(i, self.len)
			j = min(max(i, j), self.len)
			return i, j-i
		end

		terra view:sub(i: size_t, j: size_t)
			var start, len = self:range(i, j)
			return view {bits = self.bits, offset = self.offset + start, len = len}
		end

		terra view:first_and_last_bytes(i: size_t, bits: size_t)
			i = clamp(i, 0, self.len)
			bits = clamp(bits, 0, self.len-i)
			var offset = self.offset + i --bit offset in buffer
			var offset1 = offset and 7 --bit offset inside first byte
			var offset2 = 0 --bit offset inside last byte
			var bits1 = min(8 - offset1, bits) --number of bits in first byte in 0..8
			var rbits = max(0, bits - bits1) --remaining bits after first byte
			var bits2 = rbits and 7 --number of bits in last byte in 0..7
			var bytes = rbits >> 3 --number of full bytes, first byte always excepted
			var mask1 = ((1 << bits1) - 1) << offset1 --bit mask of first byte
			var mask2 = ((1 << bits2) - 1) << offset2 --bit mask of last byte
			var byte1 = offset >> 3 --byte offset of first byte
			var byte2 = byte1 + 1 + bytes --byte offset of last byte when bits2 > 0
			if bits2 == 0 then --last byte is empty
				dec(byte2) --consider the last non-empty byte as the last byte
				if byte2 == byte1 then --last byte is first byte
					mask2 = mask1
				else --last byte is a full byte
					mask2 = 0xff
				end
			end
			return byte1, mask1, byte2, mask2
		end

		view.methods.fill = overload'fill'
		view.methods.fill:adddefinition(terra(self: &view, i: size_t, bits: size_t, val: bool)
			var i1, m1, i2, m2 = self:first_and_last_bytes(i, bits)
			var bytes = i2 - i1 - 1
			var v = iif(val, 0xff, 0)
			setbits(self.bits[i1], v, m1)
			if bytes > 0 then
				fill(self.bits + i1 + 1, bytes, v)
			end
			setbits(self.bits[i2], v, m2)
		end)
		view.methods.fill:adddefinition(terra(self: &view, val: bool)
			self:fill(0, self.len, val)
		end)

		terra view:copy(dest: &view)
			var bits = min(self.len, dest.len)
			var overlap = dest.bits + dest.offset >= self.bits + self.offset
				and dest.bits + dest.offset < self.bits + self.offset + self.len
			if (self.offset and 7) == (dest.offset and 7) then --alignments match
				var si1, sm1, si2, sm2 = self:first_and_last_bytes(0, bits)
				var di1, dm1, di2, dm2 = dest:first_and_last_bytes(0, bits)
				assert(sm1 == dm1 and sm2 == dm2 and si2-si1 == di2-di1)
				if not overlap then
					setbits(dest.bits[di1], self.bits[si1], sm1)
				else
					setbits(dest.bits[di2], self.bits[si2], sm2)
				end
				var bytes = si2 - si1 - 1
				if bytes > 0 then
					copy(
						dest.bits + di1 + 1,
						self.bits + si1 + 1,
						bytes)
				end
				if not overlap then
					setbits(dest.bits[di2], self.bits[si2], sm2)
				else
					setbits(dest.bits[di1], self.bits[si1], sm1)
				end
			else --bit-by-bit copy
				if not overlap then
					for i=0,bits do
						dest:set(i, self:get(i))
					end
				else
					for i=bits-1,-1,-1 do
						dest:set(i, self:get(i))
					end
				end
			end
		end

		setinlined(view.methods, function(m)
			return m ~= 'copy' and m ~= 'fill'
		end)

	end)

	return view

end
view_type = memoize(view_type)

local view_type = function(size_t)
	if type(size_t) == 'table' then
		size_t = size_t.size_t
	end
	size_t = size_t or int
	return view_type(size_t)
end

bitarrview = macro(
	function(size_t)
		local view_type = view_type(size_t and size_t:astype())
		return `view_type(nil)
	end, view_type
)

--2D bitarray view (aka monochrome bitmap).

local function view_type(size_t)

	local struct view {
		bits: &uint8;
		offset: size_t; --in bits, relative to &bits
		stride: size_t; --in bits
		w: size_t; --in bits
		h: size_t; --in bits
	}

	view.empty = `view{bits = nil, offset = 0, stride = 0, w = 0, h = 0}

	newcast(view, niltype, view.empty)

	addmethods(view, function()

		local offset = macro(function(self, x, y)
			return `self.offset + y * self.stride + x
		end)

		local addr = macro(function(self, x, y)
			return quote
				var i = offset(self, x, y)
				in i >> 3, i and 7
			end
		end)

		terra view:get(x: size_t, y: size_t)
			x = clamp(x, 0, self.w-1)
			y = clamp(y, 0, self.h-1)
			var B, b = addr(self, x, y)
			return getbit(self.bits[B], b)
		end

		terra view:set(x: size_t, y: size_t, v: bool)
			x = clamp(x, 0, self.w-1)
			y = clamp(y, 0, self.h-1)
			var B, b = addr(self, x, y)
			setbit(self.bits[B], b, v)
		end

		--create a view representing a rectangular region inside this view.
		--the new view references the same buffer, nothing is copied.
		terra view:sub(x: size_t, y: size_t, w: size_t, h: size_t)
			x, y, w, h = rect.intersect(x, y, w, h, 0, 0, self.w, self.h)
			return view {bits = self.bits, offset = offset(self, x, y),
				stride = self.stride, w = w, h = h}
		end

		--create a 1-D view of a line.
		terra view:line(y: size_t)
			var line = bitarrview(size_t)
			line.bits = self.bits
			line.offset = self.offset + y * self.stride
			line.len = self.w
			return line
		end

		--create a 1-D view of the entire 2-D view.
		terra view:asline()
			var a = bitarrview(size_t)
			a.bits = self.bits
			a.offset = self.offset
			a.len = self.h * self.stride
			return a
		end

		terra view:fill(val: bool)
			if self.stride == self.w then --contiguous buffer, fill whole
				self:asline():fill(val)
			else --fill line-by-line
				var line = self:line(0)
				for i = 0, self.h do
					line:fill(0, line.len, val)
					inc(line.offset, self.stride)
				end
			end
		end

		terra view:copy(dest: &view)
			var sub: view
			if dest.w < self.w or dest.h < self.h then --self needs cropping
				sub = self:sub(0, 0, dest.w, dest.h)
				self = &sub
			end
			if self.stride == dest.stride
				and ((self.stride and 7) == 0)
				and ((self.offset and 7) == 0)
				and ((dest.offset and 7) == 0)
			then --strides match and rows are byte-aligned: copy whole.
				copy(
					dest.bits + (dest.offset << 3),
					self.bits + (self.offset << 3),
					self.h * (self.stride << 3))
			else --copy line-by-line
				var overlap = dest.bits + dest.offset >= self.bits + self.offset
					and dest.bits + dest.offset < self.bits + self.offset + self.h * self.stride
				if not overlap then
					var sline = self:line(0)
					var dline = dest:line(0)
					for i=0,self.h do
						sline:copy(&dline)
						inc(sline.offset, self.stride)
						inc(dline.offset, dest.stride)
					end
				else
					var sline = self:line(self.h-1)
					var dline = dest:line(self.h-1)
					for i=self.h-1,-1,-1 do
						sline:copy(&dline)
						dec(sline.offset, self.stride)
						dec(dline.offset, dest.stride)
					end
				end
			end
		end

		setinlined(view.methods)

	end)

	return view

end
view_type = memoize(view_type)

local view_type = function(size_t)
	if type(size_t) == 'table' then
		size_t = size_t.size_t
	end
	size_t = size_t or int
	return view_type(size_t)
end

bitarrview2d = macro(
	function(size_t)
		local view_type = view_type(size_t and size_t:astype())
		return `view_type(nil)
	end, view_type
)

--TODO: dynamically allocated 2D bitarray.
bitarr2d = macro(function()

end)
