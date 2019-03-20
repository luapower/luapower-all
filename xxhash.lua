
--xxhash binding

local ffi = require'ffi'
local C = ffi.load'xxhash'
local M = {C = C}
require'xxhash_h'

M.version = C.XXH_versionNumber

function M.hash32(data, sz, seed)
	return C.XXH32(data, sz or #data, seed or 0)
end

function M.hash64(data, sz, seed)
	return C.XXH64(data, sz or #data, seed or 0)
end

return M

