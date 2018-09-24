
-- Bundle Lua API, currently containing the blob loader.
-- Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local BBIN_PREFIX = 'Bbin_'

local bundle = {}

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

function bundle.canopen(file)
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

function bundle.load(file)
	return load_file(file) or load_blob(file)
end

function bundle.mmap(file)
	local s = load_file(file)
	if s then
		--TODO: use fs.mmap() here
		return {data = ffi.cast('const void*', s), size = #s,
			close = function() local _ = s; end}
	else
		return mmap_blob(file)
	end
end

function bundle.fs_open(file)
	local fs = require'fs'
	local buf, sz = blob_data(file)
	if not buf then
		return fs.open(file)
	else
		return fs.open_buffer(buf, sz)
	end
end

function bundle.fs_dir(dir)
	local fs = require'fs'
	local path = require'path'
	if fs.is(dir, 'dir') then
		return fs.dir(dir)
	else
		local s = load_blob(dir)
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
end

local ok, ver = pcall(require, 'bundle_appversion')
bundle.appversion = ok and ver or nil

return bundle
