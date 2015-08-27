
-- Bundle Lua API, currently containing only the blob loader.
-- Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local BBIN_PREFIX = 'Bbin_'

--portable way to get exe's directory, based on arg[0].
--the resulted directory is relative to the current directory.
local dir = arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
dir = dir == '' and '.' or dir

local function getfile(file)
	file = dir..'/'..file
	local f, err = io.open(file, 'rb')
	if not f then return end
	local s = f:read'*a'
	f:close()
	return s
end

local function getblob(file)
	local sym = BBIN_PREFIX..file:gsub('[\\%-/%.]', '_')
	pcall(ffi.cdef, 'void '..sym..'()')
	local p = ffi.cast('const uint32_t*', ffi.C[sym])
	return ffi.string(p+1, p[0])
end

local function load(file)
	return getfile(file) or getblob(file)
end

return {
	load = load,
}
