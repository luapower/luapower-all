
-- unidirectional cdata ring buffers that can grow on request.
-- Written by Cosmin Apreutesei. Public Domain.

if not ... then require'ringbuffer_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
local min, max, band, assert = math.min, math.max, bit.band, assert

--select the offset normalization function to use: if the buffer size
--is a power-of-2, we can normalize offsets faster.
local function offset_and(self, offset) return band(offset, (self.size - 1)) end
local function offset_mod(self, offset) return offset % self.size end
local function offset_func(size)
	local pow2_size = band(size, size - 1) == 0
	return pow2_size and offset_and or offset_mod
end

--given a buffer (0, size) and a segment (offset, length) where `length`
--can exceed `size`, return the two segments (offset1, length1) and
--(offset2, length2) that map the input segment to the buffer.
local function segments(offset, length, size)
	local length1 = size - offset
	return offset, min(length, length1), 0, max(0, length - length1)
end

local cbuf = {}

function cbuf:write(src, di, si, n)
	local dst = self.data
	ffi.copy(dst + di, src + si, n)
end

function cbuf:read(dst, di, si, n)
	local src = self.data
	ffi.copy(dst + di, src + si, n)
end

function cbuf:push(len, data)
	local start, length, size = self.start, self.length, self.size
	assert(len > 0, 'invalid length')
	assert(len <= size - length, 'buffer overflow')
	local start1 = self:offset(start + length)
	local i1, n1, i2, n2 = segments(start1, len, size)
	self.length = length + len
	if data then
		self:write(data, i1, 0, n1)
		if n2 ~= 0 then
			data = ffi.cast(self.bctype, data)
			self:write(data, i2, n1, n2)
		end
	end
	return i1, n1, i2, n2
end

function cbuf:pull(len, data)
	local start, length, size = self.start, self.length, self.size
	assert(len > 0, 'invalid length')
	assert(len <= length, 'buffer underflow')
	local start1 = self:offset(start + len)
	local i1, n1, i2, n2 = segments(start, len, size)
	self.start = start1
	self.length = length - len
	if data then
		self:read(data, 0, i1, n1)
		if n2 ~= 0 then
			data = ffi.cast(self.bctype, data)
			self:read(data, n1, i2, n2)
		end
	end
	return i1, n1, i2, n2
end

function cbuf:segments()
	return segments(self.start, self.length, self.size)
end

function cbuf:free_segments()
	local start, length, size = self.start, self.length, self.size
	local start1 = self:offset(start + length)
	return segments(start1, size - length, size)
end

function cbuf:head(ofs) return self:offset(self.start + ofs) end
function cbuf:tail(ofs) return self:offset(self.start + ofs + self.length) end

function cbuf:checksize(len)
	if len <= self.size - self.length then return end
	local newsize = max(self.size * 2, self.length + len)
	local newdata = self:alloc(newsize)
	local i1, n1, i2, n2 = self:segments()
	ffi.copy(newdata,      self.data + i1, n1)
	ffi.copy(newdata + n1, self.data + i2, n2)
	self.data = newdata
	self.size = newsize
	self.start = 0
	self.offset = offset_func(self.size)
end

function cbuf:alloc(size)
	local actype = ffi.typeof('$[?]', self.ctype)
	return ffi.new(actype, size)
end

function cbuf.new(super, self)
	assert(self.size, 'size required')
	self.ctype  = ffi.typeof(self.ctype or 'char')
	self.bctype = ffi.typeof('$*', self.ctype)
	self.start  = self.start or 0
	self.length = self.length or 0
	self.offset = offset_func(self.size)
	self.__index = super
	setmetatable(self, self)
	if self.data then
		self._data = self.data --pin it!
		self.data = ffi.cast(self.bctype, self.data)
	else
		self.data = self:alloc(self.size)
	end
	return self
end

setmetatable(cbuf, cbuf)
cbuf.__call = cbuf.new

return cbuf
