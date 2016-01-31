--pmurhash binding, see csrc/pmurhash
local ffi = require'ffi'
local pmurhash = ffi.load'pmurhash'

if not ... then require'murmurhash3_test'; return end

--note: we declare the result as int32_t instead of uint32_t for compatibility with Lua implementation
ffi.cdef[[
int32_t PMurHash32(uint32_t seed, const uint8_t* key, int len);
]]

local function hash(data, sz, seed)
	return pmurhash.PMurHash32(seed or 0, data, sz or #data)
end

return hash
