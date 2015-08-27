--MurmurHash3_x86_32 from http://code.google.com/p/smhasher/source/browse/trunk/MurmurHash3.cpp
local ffi = require'ffi'
local bit = require'bit'

local C1 = 0xcc9e2d51
local C2 = 0x1b873593
local rotl, xor, band, shl, shr = bit.rol, bit.bxor, bit.band, bit.lshift, bit.rshift

local function mmul(x1, x2) --multiplication with modulo2 semantics
	return tonumber(ffi.cast('uint32_t', ffi.cast('uint32_t', x1) * ffi.cast('uint32_t', x2)))
end

local function hash(data, len, seed)
	seed = seed or 0
	if type(data) == 'string' then
		data, len = ffi.cast('const uint8_t*', data), math.min(len or #data, #data)
	end

	local nblocks = math.floor(len / 4)
	local h1 = seed

	local blocks = ffi.cast('uint32_t*', data)
	for i=0,nblocks-1 do
		h1 = mmul(rotl(xor(h1, mmul(rotl(mmul(blocks[i], C1), 15), C2)), 13), 5) + 0xe6546b64
	end

	local tail = data + (nblocks * 4)
	local k1 = 0
	local sw = band(len, 3)
	if sw == 3 then k1 = xor(k1, shl(tail[2], 16)) end
	if sw >= 2 then k1 = xor(k1, shl(tail[1],  8)) end
	if sw >= 1 then k1 = xor(k1, tail[0]) end

	h1 = xor(xor(h1, mmul(rotl(mmul(k1, C1), 15), C2)), len)
	h1 = mmul(xor(h1, shr(h1, 16)), 0x85ebca6b)
	h1 = mmul(xor(h1, shr(h1, 13)), 0xc2b2ae35)
	h1 = xor(h1, shr(h1, 16))

	return h1
end

if not ... then require'murmurhash3_test' end

return hash
