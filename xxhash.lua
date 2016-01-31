
--xxhash binding

local ffi = require'ffi'
local C = ffi.load'xxhash'
local M = {C = C}

ffi.cdef[[
unsigned XXH_versionNumber(void);
typedef unsigned int       XXH32_hash_t;
typedef unsigned long long XXH64_hash_t;
XXH32_hash_t XXH32 (const void* input, size_t length, unsigned int seed);
XXH64_hash_t XXH64 (const void* input, size_t length, unsigned long long seed);
]]

M.version = C.XXH_versionNumber

function M.hash32(data, sz, seed)
	return C.XXH32(data, sz or #data, seed or 0)
end

function M.hash64(data, sz, seed)
	return C.XXH64(data, sz or #data, seed or 0)
end

return M

