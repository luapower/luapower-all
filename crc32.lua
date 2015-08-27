--go @ bin/luajit.exe -jdump *
--CRC-32 implementation, see http://www.geocities.ws/malbrain/
--TODO: the zlib implementation of crc32 is 6x faster, can we do better with Lua?
local ffi = require'ffi'
local bit = require'bit'

local s_crc32 = ffi.new('const uint32_t[16]',
	0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
	0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
   0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
	0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c)

local function crc32(buf, sz, crc)
	crc = crc or 0
	sz = sz or #buf
	buf = ffi.cast('const uint8_t*', buf)
	crc = bit.bnot(crc)
	for i = 0, sz-1 do
		crc = bit.bxor(bit.rshift(crc, 4), s_crc32[bit.bxor(bit.band(crc, 0xF), bit.band(buf[i], 0xF))])
		crc = bit.bxor(bit.rshift(crc, 4), s_crc32[bit.bxor(bit.band(crc, 0xF), bit.rshift(buf[i], 4))])
	end
	return bit.bnot(crc)
end

if not ... then
	assert(crc32'Game\'s the same, just got more fierce.' == 0x2c40120a)
	require'hash_benchmark'
end

return crc32
