
--fs.dir() and fs.open() interfaces over mmapped tar-like files.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local fs = require'fs'
local bundle = require'bundle'

local rat = {}

function rat:build(dir, write)
	--TODO:
end

function rat:build_tofile(dir, file)
	local f, err, errcode = fs.open(file, 'w')
	if not f then
		return nil, err, errcode
	end
	local function write(buf, sz)
		return f:write(buf, sz)
	end
	local ok, err, errcode = rat:build(write)
	f:close()
	return ok, err, errcode
end

local mountpoint = {}

function rat:mount(buf, sz)
	local mountpoint = {
		data = ffi.cast('char*', buf),
		size = sz,
		_buffer = buf, --anchor it
		__index = mountpoint,
	}
	local self = setmetatable(mountpoint, mountpoint)
	self:init()
	return self
end

function mountpoint:find_entry(path)
	--TODO:
	local ftype, offset, size
	return ftype, offset, size
end

function mountpoint:init()
	--TODO:
end

function mountpoint:dir(dir)
	local ftype, offset, size = self:find_entry(dir)
	local entries
	local s = ftype == 'dir' and ffi.string(self.data + offset, size)
	return bundle.open_dir_listing(dir, s)
end

function mountpoint:open(path, mode)
	local ftype, offset, size = self:find_entry(path)
	if not ftype then return nil, 'not_found' end
	if ftype ~= 'file' then return nil, 'access_denied' end
	return fs.open_buffer(self.data + offset, size)
end

return rat
