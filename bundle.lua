
-- Bundle Lua API, currently containing the blob loader.
-- Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local exedir = require'package.exedir'
local BBIN_PREFIX = 'Bbin_'

local bundle = {}

--reading embedded blobs

local function getsym(sym)
	return ffi.C[sym]
end
local function blob_data(file)
	local sym = BBIN_PREFIX..file:gsub('[\\%-/%.]', '_')
	pcall(ffi.cdef, 'void '..sym..'()')
	local ok, p = pcall(getsym, sym)
	if not ok then return nil end
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

local function canopen_blob(file)
	return blob_data(file) and true or false
end

local function fs_open_blob(file)
	local fs = require'fs'
	local buf, sz = blob_data(file)
	if not buf then return nil end
	return fs.open_buffer(buf, sz)
end

function bundle.open_dir_listing(dir, s)
	local path = require'path'
	local entries = s and assert(loadstring(s))()
	local d = {}
	local closed, name, ftype
	local i = 1
	function d:next()
		if closed then
			return nil
		end
		if not entries then
			closed = true
			return false, 'not_found'
		end
		name = entries[i]
		if not name then
			closed = true
			return nil
		end
		i = i + 1
		name, ftype = name:match'^(.-)([/]?)$'
		if ftype == '/' then
			ftype = 'dir'
		else
			ftype = 'file'
		end
		return name, d
	end
	function d:close() closed = true; return true; end
	function d:closed() return closed end
	function d:name() return name end
	function d:dir() return dir end
	function d:path() return path.combine(dir, name) end
	function d:attr(attr)
		if attr == 'type' then
			return ftype
		elseif not attr then
			return {type = ftype}
		else
			return nil
		end
	end
	function d:is(ftype1) return ftype == ftype1 end
	return d.next, d
end

local function fs_dir_blob(dir)
	local fs = require'fs'
	return bundle.open_dir_listing(dir, load_blob(dir))
end

--reading the filesystem

local function load_file(file)
	file = exedir..'/'..file
	local f = io.open(file, 'rb')
	if not f then return nil end
	local s = f:read'*a'
	f:close()
	return s
end

local function mmap_file(file)
	local s = load_file(file)
	if not s then return end
	--TODO: use fs.mmap() here
	return {data = ffi.cast('const void*', s), size = #s,
		close = function() local _ = s; end}
end

local function canopen_file(file)
	local f = io.open(file, 'r')
	if f then f:close() end
	return f and true or false
end

function fs_open_file(file)
	local fs = require'fs'
	return (fs.open(file))
end

function fs_dir_file(dir)
	local fs = require'fs'
	if not fs.is(dir, 'dir') then return nil end
	return fs.dir(dir)
end

--user API

function bundle.canopen(file)
	return canopen_file(file) or canopen_blob(file)
end

function bundle.load(file)
	return load_file(file) or load_blob(file)
end

function bundle.mmap(file)
	return mmap_file(file) or mmap_blob(file)
end

function bundle.fs_open(file)
	return fs_open_file(file) or fs_open_blob(file)
end

function bundle.fs_dir(dir)
	local d, next = fs_dir_file(dir)
	if d then return d, next end
	return fs_dir_blob(dir)
end

local ok, ver = pcall(require, 'bundle_appversion')
bundle.appversion = ok and ver or nil

return bundle
