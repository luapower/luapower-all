
-- Bundle Lua API, currently containing the blob loader.
-- Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local BBIN_PREFIX = 'Bbin_'

--portable way to get exe's directory, based on arg[0].
--the resulted directory is relative to the current directory.
local dir = arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
dir = dir == '' and '.' or dir

local function getsym(sym)
	return ffi.C[sym]
end
local function blob_data(file)
	local sym = BBIN_PREFIX..file:gsub('[\\%-/%.]', '_')
	pcall(ffi.cdef, 'void '..sym..'()')
	local ok, p = pcall(getsym, sym)
	if not ok then return end
	local p = ffi.cast('const uint32_t*', p)
	return ffi.cast('void*', p+1), p[0]
end

local function load_blob(file)
	local data, size = blob_data(file)
	return data and ffi.string(data, size)
end

local function mmap_blob(file)
	local data, size = blob_data(file)
	return data and {data = data, size = size, close = function() end}
end

local function canopen(file)
	local f = io.open(file, 'r')
	if f then
		f:close()
		return true
	end
	return blob_data(file) and true or false
end

local function load_file(file)
	file = dir..'/'..file
	local f = io.open(file, 'rb')
	if f then
		local s = f:read'*a'
		f:close()
		return s
	end
end

local function load(file)
	return load_file(file) or load_blob(file)
end

local function mmap(file)
	local s = load_file(file)
	if s then
		--TODO: use fs.mmap() here
		return {data = ffi.cast('void*', s), size = #s,
			close = function() local _ = s; end}
	else
		return mmap_blob(file)
	end
end

return {
	canopen = canopen,
	load = load,
	mmap = mmap,
}
