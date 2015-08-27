--pmurhash binding, see csrc/pmurhash
local ffi = require'ffi'
local pmurhash = ffi.load'pmurhash'

--note: we declare the result as int32_t instead of uint32_t for compatibility with Lua implementation
ffi.cdef[[
int32_t PMurHash32(uint32_t seed, const uint8_t* key, int len);
]]

local function hash(data, sz, seed)
	seed = seed or 0
	if type(data) == 'string' then
		sz = math.min(sz or #data, #data)
	end
	return pmurhash.PMurHash32(seed, data, sz)
end

if not ... then require'murmurhash3_test' end

return hash
