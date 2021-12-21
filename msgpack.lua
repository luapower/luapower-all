
--MessagePack v5 for LuaJIT.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'msgpack_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'

local floor = math.floor
local bor, band, shr = bit.bor, bit.band, bit.rshift

local u32  = ffi.typeof'uint32_t'
local i64  = ffi.typeof'int64_t'
local u64  = ffi.typeof'uint64_t'

local u8a  = glue.u8a
local i8p  = glue.i8p
local u8p  = glue.u8p
local i16p = glue.i16p
local u16p = glue.u16p
local i32p = glue.i32p
local u32p = glue.u32p
local i64p = glue.i64p
local u64p = glue.u64p
local f32p = glue.f32p
local f64p = glue.f64p

local noop     = glue.noop
local repl     = glue.repl
local update   = glue.update
local dynarray = glue.dynarray

local t_buf = ffi.new'uint8_t[8]'

local mp = {decoder = {}}

function mp:decode_unknown() return nil end --stub
mp.decode_i64 = tonumber --stub
mp.decode_u64 = tonumber --stub
mp.error = error --stub

function mp.new(self)
	assert(self ~= mp)
	return update(self or {}, mp)
end

local rcopy, rev2, rev4, rev8 = noop, noop, noop
if ffi.abi'le' then
	function rcopy(dst, src, len)
		for i = 0, len-1 do
			dst[i] = src[len-1-i]
		end
	end
	function rev2(p, i)
		local a, b = p[i], p[i+1]
		p[i], p[i+1] = b, a
	end
	function rev4(p, i)
		local a, b, c, d = p[i], p[i+1], p[i+2], p[i+3]
		p[i], p[i+1], p[i+2], p[i+3] = d, c, b, a
	end
	function rev8(p, i)
		local a, b, c, d, e, f, g, h = p[i], p[i+1], p[i+2], p[i+3], p[i+4], p[i+5], p[i+6], p[i+7]
		p[i], p[i+1], p[i+2], p[i+3], p[i+4], p[i+5], p[i+6], p[i+7] = h, g, f, e, d, c, b, a
	end
end

--decoding -------------------------------------------------------------------

local function num(self, p, n, i, ct, len, tonumber)
	if i + len > n then self.error'short read' end
	rcopy(t_buf, p + i, len)
	local v = ffi.cast(ct, t_buf)[0]
	return i + len, tonumber and tonumber(v) or v
end

local function str(self, p, n, i, len)
	if i + len > n then self.error'short read' end
	return i + len, ffi.string(p + i, len)
end

local function ext(self, p, n, i, len)
	local i, typ = num(self, p, n, i, i8p, 1)
	if i + len > n then self.error'short read' end
	local decode = self.decoder[typ] or self.decode_unknown
	return i + len, decode(self, p, i, len, typ)
end

local obj --fw. decl.

local function arr(self, d, p, n, i, len)
	local t = {}
	for j = 1, len do
		local v
		i, v = obj(self, d+1, p, n, i)
		if v == nil then v = self.nil_element end
		t[j] = v
	end
	return i, t
end

local function map(self, d, p, n, i, len)
	local t = {}
	for j = 1, len do
		local k, v
		i, k = obj(self, d+1, p, n, i)
		i, v = obj(self, d+1, p, n, i)
		if k == nil then k = self.nil_key end
		if k == 1/0 then k = self.nan_key end
		if k ~= nil and k == k then
			t[k] = v
		end
	end
	return i, t
end

--[[local]] function obj(self, d, p, n, i)
	if i >= n   then self.error'short read' end
	if d >= 100 then self.error'stack overflow' end
	local c = p[i]
	i = i + 1
	if c <  0x80 then return i, c end
	if c <  0x90 then return map(self, d, p, n, i, band(c, 0x0f)) end
	if c <  0xa0 then return arr(self, d, p, n, i, band(c, 0x0f)) end
	if c <  0xc0 then return str(self, p, n, i, band(c, 0x1f)) end
	if c >  0xdf then return i, ffi.cast(i8p, p)[i-1] end
	if c == 0xc0 then return i, nil end
	if c == 0xc2 then return i, false end
	if c == 0xc3 then return i, true end
	if c == 0xc4 then return str(self, p, n, num(self, p, n, i, u8p , 1)) end
	if c == 0xc5 then return str(self, p, n, num(self, p, n, i, u16p, 2)) end
	if c == 0xc6 then return str(self, p, n, num(self, p, n, i, u32p, 4)) end
	if c == 0xc7 then return ext(self, p, n, num(self, p, n, i, u8p , 1)) end
	if c == 0xc8 then return ext(self, p, n, num(self, p, n, i, u16p, 2)) end
	if c == 0xc9 then return ext(self, p, n, num(self, p, n, i, u32p, 4)) end
	if c == 0xca then return num(self, p, n, i, f32p, 4) end
	if c == 0xcb then return num(self, p, n, i, f64p, 8) end
	if c == 0xcc then if i >= n then self.error'short read' end; return i+1, p[i] end
	if c == 0xcd then return num(self, p, n, i, u16p, 2) end
	if c == 0xce then return num(self, p, n, i, u32p, 4) end
	if c == 0xcf then return num(self, p, n, i, u64p, 8, self.decode_u64) end
	if c == 0xd0 then return num(self, p, n, i, i8p , 1) end
	if c == 0xd1 then return num(self, p, n, i, i16p, 2) end
	if c == 0xd2 then return num(self, p, n, i, i32p, 4) end
	if c == 0xd3 then return num(self, p, n, i, i64p, 8, self.decode_i64) end
	if c == 0xd4 then return ext(self, p, n, i,  1) end
	if c == 0xd5 then return ext(self, p, n, i,  2) end
	if c == 0xd6 then return ext(self, p, n, i,  4) end
	if c == 0xd7 then return ext(self, p, n, i,  8) end
	if c == 0xd8 then return ext(self, p, n, i, 16) end
	if c == 0xd9 then return str(self, p, n, num(self, p, n, i, u8p , 1)) end
	if c == 0xda then return str(self, p, n, num(self, p, n, i, u16p, 2)) end
	if c == 0xdb then return str(self, p, n, num(self, p, n, i, u32p, 4)) end
	if c == 0xdc then return arr(self, d, p, n, num(self, p, n, i, u16p, 2)) end
	if c == 0xdd then return arr(self, d, p, n, num(self, p, n, i, u32p, 4)) end
	if c == 0xde then return map(self, d, p, n, num(self, p, n, i, u16p, 2)) end
	if c == 0xdf then return map(self, d, p, n, num(self, p, n, i, u32p, 4)) end
	self.error'invalid message'
end

function mp:decode_next(p, n, i)
	p = ffi.cast(u8p, p)
	return obj(self, 0, p, n, i or 0)
end

function mp:decode_each(p, n, i)
	i = i or 0
	n = n or #p
	p = ffi.cast(u8p, p)
	return function()
		if i >= n then return nil end
		local v
		i, v = obj(self, 0, p, n, i)
		return i, v
	end
end

--encoding -------------------------------------------------------------------

mp.N = {}
function mp:isarray(v)
	return v[self.N] and true or false
end

function mp.array(...)
	return {[mp.N] = select('#', ...), ...}
end

function mp.toarray(t, n)
	t[mp.N] = n or t[mp.N] or #t
	return t
end

function mp:encoding_buffer(min_size)
	local mp = self
	local buf = {}
	local arr = dynarray(u8a, min_size)
	local n = 0
	local function b(len)
		n = n + len
		return arr(n), n-len
	end
	local function encode_len(n, u8mark, u16mark, u32mark)
		if n <= 0xff and u8mark then
			local p, i = b(2)
			p[i] = u8mark
			ffi.cast(u8p, p+i+1)[0] = n
		elseif n <= 0xffff then
			local p, i = b(3)
			p[i] = u16mark
			ffi.cast(u16p, p+i+1)[0] = n
			rev2(p, i+1)
		else
			if n > 0xffffffff then mp.error'too many elements' end
			local p, i = b(5)
			p[i] = u32mark
			ffi.cast(u32p, p+i+1)[0] = n
			rev4(p, i+1)
		end
	end
	function buf:encode_array(t, n)
		local n = n or repl(t[mp.N], true, #t) or #t
		if n <= 0x0f then
			local p, i = b(1)
			p[i] = 0x90 + n
		else
			encode_len(n, nil, 0xdc, 0xdd)
		end
		for i = 1, n do
			self:encode(t[i])
		end
		return self
	end
	function buf:encode_map(t, user_pairs)
		local pairs = user_pairs or pairs
		local n = 0
		for k in pairs(t) do
			n = n + 1
		end
		if n <= 0x0f then
			local p, i = b(1)
			p[i] = 0x80 + n
		else
			encode_len(n, nil, 0xde, 0xdf)
		end
		for k,v in pairs(t) do
			self:encode(k)
			self:encode(v)
		end
		return self
	end
	function buf:encode_int(v)
		if type(v) == 'number' then
			if v < 0 then
				if v >= -0x20 then
					local p, i = b(1)
					p[i] = 0x100 + v
				elseif v >= -0x80 then
					local p, i = b(2)
					p[i] = 0xd0
					ffi.cast(i8p, p+i+1)[0] = v
				elseif v >= -0x8000 then
					local p, i = b(3)
					p[i] = 0xd1
					ffi.cast(i16p, p+i+1)[0] = v
					rev2(p, i+1)
				elseif v >= -0x80000000 then
					local p, i = b(5)
					p[i] = 0xd2
					ffi.cast(i32p, p+i+1)[0] = v
					rev4(p, i+1)
				else
					local p, i = b(9)
					p[i] = 0xd3
					ffi.cast(i64p, p+i+1)[0] = v
					rev8(p, i+1)
				end
			elseif v <= 0x7f then
				local p, i = b(1)
				p[i] = v
			elseif v <= 0xff then
				local p, i = b(2)
				p[i] = 0xcc
				p[i+1] = v
			elseif v <= 0xffff then
				local p, i = b(3)
				p[i] = 0xcd
				ffi.cast(u16p, p+i+1)[0] = v
				rev2(p, i+1)
			elseif v <= 0xffffffff then
				local p, i = b(5)
				p[i] = 0xce
				ffi.cast(u32p, p+i+1)[0] = v
				rev4(p, i+1)
			else
				local p, i = b(9)
				p[i] = 0xcf
				ffi.cast(u64p, p+i+1)[0] = v
				rev8(p, i+1)
			end
		elseif ffi.istype(i64, v) then
			local p, i = b(9)
			p[i] = 0xd3
			ffi.cast(i64p, p+i+1)[0] = v
			rev8(p, i+1)
		elseif ffi.istype(u64, v) then
			local p, i = b(9)
			p[i] = 0xcf
			ffi.cast(u64p, p+i+1)[0] = v
			rev8(p, i+1)
		else
			error('number expected, got '..type(v))
		end
		return self
	end
	function buf:encode_float(v)
		local p, i = b(5)
		p[i] = 0xca
		ffi.cast(f32p, p+i+1)[0] = v
		rev4(p, i+1)
		return self
	end
	function buf:encode_double(v)
		local p, i = b(9)
		p[i] = 0xcb
		ffi.cast(f64p, p+i+1)[0] = v
		rev8(p, i+1)
		return self
	end
	function buf:encode_bin(v, n)
		local n = n or #v
		encode_len(n, 0xc4, 0xc5, 0xc6)
		local p, i = b(n)
		ffi.copy(p + i, v, n)
		return self
	end
	function buf:encode_ext(typ, n)
		local n = n or #v
		if n <= 0 then mp.error'zero bytes ext' end
		if n == 1 then
			local p, i = b(2)
			p[i] = 0xd4
			p[i+1] = typ
		elseif n == 2 then
			local p, i = b(2)
			p[i] = 0xd5
			p[i+1] = typ
		elseif n == 4 then
			local p, i = b(2)
			p[i] = 0xd6
			p[i+1] = typ
		elseif n == 8 then
			local p, i = b(2)
			p[i] = 0xd7
			p[i+1] = typ
		elseif n == 16 then
			local p, i = b(2)
			p[i] = 0xd8
			p[i+1] = typ
		else
			encode_len(0xc7, 0xc8, 0xc9)
			local p, i = b(1)
			p[i] = typ
		end
		return self
	end
	function buf:encode_ext_int(ct, x)
		local n = ffi.sizeof(ct)
		local p, i = b(n)
		ffi.cast(ct, p+i)[0] = v
		local rev = n == 1 and noop or n == 2 and rev2
			or n == 4 and rev4 or n == 8 and rev8
		rev(p, i)
		return self
	end
	function buf:encode_timestamp(v)
		local n
		if v >= 0 and v <= 0xffffffff then
			if floor(v) == v then
				self:encode_ext(-1, 4)
				self:encode_ext_int(u32, v)
			else
				self:encode_ext(-1, 8)
				self:encode_ext_int(u32, (v - floor(v)) * 1e9)
				self:encode_ext_int(u32, v)
			end
		else
			self:encode_ext(-1, 4+8)
			self:encode_ext_int(u32, (v - floor(v)) * 1e9)
			self:encode_ext_int(i64, v)
		end
		return self
	end
	function buf:encode(v)
		if v == nil then
			local p, i = b(1)
			p[i] = 0xc0
		elseif v == false then
			local p, i = b(1)
			p[i] = 0xc2
		elseif v == true then
			local p, i = b(1)
			p[i] = 0xc3
		elseif type(v) == 'number' then
			if floor(v) == v and not (v == 0 and 1 / v < 0) then
				self:encode_int(v)
			else
				self:encode_double(v)
			end
		elseif type(v) == 'string' then
			if #v <= 0x1f then
				local p, i = b(1)
				p[i] = 0xa0 + #v
			else
				encode_len(#v, 0xd9, 0xda, 0xdb)
			end
			local p, i = b(#v)
			ffi.copy(p + i, v, #v)
		elseif type(v) == 'table' then
			if mp:isarray(v) then
				self:encode_array(v)
			else
				self:encode_map(v)
			end
		elseif ffi.istype(i64, v) or ffi.istype(u64, v) then
			self:encode_int(v)
		else
			error('invalid type '..type(v))
		end
		return self
	end
	function buf:size()
		return n
	end
	function buf:get()
		return arr(n)
	end
	function buf:tostring()
		return ffi.string(arr(n))
	end
	function buf:reset()
		n = 0
		return self
	end
	return buf
end

return mp
