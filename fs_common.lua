
--portable filesystem API for LuaJIT / common code
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local path = require'path'

local C = ffi.C

local backend = setmetatable({}, {__index = _G})
setfenv(1, backend)

cdef = ffi.cdef
x64 = ffi.arch == 'x64' or nil
osx = ffi.os == 'OSX' or nil
linux = ffi.os == 'Linux' or nil
win = ffi.abi'win' or nil

--namespaces in which backends can add methods directly.
fs = {} --fs module namespace
file = {} --file object methods
stream = {} --FILE methods
dir = {} --dir listing object methods

--binding tools --------------------------------------------------------------

--assert() with string formatting (this should be a Lua built-in).
function assert(v, err, ...)
	if v then return v end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then
		err = string.format(err,...)
	end
	error(err, 2)
end

--return a function which reuses and returns an ever-increasing buffer.
function mkbuf(ctype, min_sz)
	ctype = ffi.typeof('$[?]', ffi.typeof(ctype))
	min_sz = min_sz or 256
	assert(min_sz > 0)
	local buf, bufsz
	return function(sz)
		sz = sz or bufsz or min_sz
		assert(sz > 0)
		if not bufsz or sz > bufsz then
			buf, bufsz = ctype(sz), sz
		end
		return buf, bufsz
	end
end

--error reporting ------------------------------------------------------------

cdef'char *strerror(int errnum);'

local error_classes = {
	[2] = 'not_found', --ENOENT, _open_osfhandle(), _fdopen(), open(), mkdir(),
	                   --rmdir(), opendir(), rename(), unlink()
	[5] = 'io_error', --EIO, readlink()
	[17] = 'already_exists', --EEXIST, open(), mkdir()
	[20] = 'not_found', --ENOTDIR, opendir()
	[21] = 'access_denied', --EISDIR, unlink()
	[linux and 39 or osx and 66 or win and 41] = 'not_empty',
		--ENOTEMPTY, rmdir()

	[12] = 'out_of_mem', --TODO: ENOMEM: mmap
	[22] = 'file_too_short', --TODO: EINVAL: mmap
	[27] = 'disk_full', --TODO: EFBIG
	[28] = 'disk_full', --TODO: ENOSP
	[osx and 69 or 122] = 'disk_full', --TODO: EDQUOT
}

function check_errno(ret, errno)
	if ret then return ret end
	errno = errno or ffi.errno()
	local err = error_classes[errno]
	if not err then
		local s = C.strerror(errno)
		err = s ~= nil and ffi.string(s) or 'Error '..errno
	end
	return ret, err, errno
end

function assert_checker(check)
	return function(...)
		return _G.assert(...)
	end
end

assert_check_errno = assert_checker(check_errno)

--flags arg parsing ----------------------------------------------------------

local function memoize2(func)
	cache = {}
	return function(k1, k2)
		local cache2 = cache[k1]
		if cache2 == nil then
			cache2 = {}
			cache[k1] = cache2
		end
		local v = cache2[k2]
		if v == nil then
			v = func(k1, k2)
			cache2[k2] = v
		end
		return v
	end
end

local function table_flags(t, masks, cur_bits)
	local mask = 0
	for k,v in pairs(t) do
		local flag
		if type(k) == 'string' and v then --flags as table keys: {flag->true}
			flag = k
		elseif
			type(k) == 'number'
			and math.floor(k) == k
			and type(v) == 'string'
		then --flags as array: {flag1,...}
			flag = v
		end
		if flag then
			local m = assert(masks[flag], 'invalid flag %s', flag)
			mask = bit.bor(mask, m)
		end
	end
	return mask
end

local string_flags = memoize2(function(s, masks)
	if not s:find'[ ,]' then
		return assert(masks[s], 'invalid flag %s', s)
	end
	local t = {}
	for s in s:gmatch'[^ ,]+' do
		t[#t+1] = s
	end
	return table_flags(t, masks)
end)

function flags(arg, masks)
	if type(arg) == 'string' then
		return string_flags(arg, masks)
	elseif type(arg) == 'table' then
		return table_flags(arg, masks)
	elseif type(arg) == 'number' then
		return arg
	elseif arg == nil then
		return 0
	else
		assert(false, 'flags expected but %s given', type(arg))
	end
end

--i/o ------------------------------------------------------------------------

function file.seek(f, whence, offset)
	if tonumber(whence) and not offset then
		whence, offset = 'cur', tonumber(whence)
	end
	return seek(f, whence or 'cur', offset or 0)
end

function fs.isfile(f)
	return ffi.istype(file_ct, f)
end

--stdio streams --------------------------------------------------------------

cdef[[
typedef struct FILE FILE;
int fclose(FILE*);
]]

stream_ct = ffi.typeof'struct FILE'

function stream.close(fs)
	local ok = C.fclose(fs) == 0
	if not ok then return check_errno() end
	ffi.gc(fs, nil)
	return true
end

--directory listing ----------------------------------------------------------

function fs.dir(dir, dot_dirs)
	dir = dir or '.'
	if dot_dirs then
		return dir_iter(dir)
	else --wrap iterator to skip `.` and `..` entries
		local next, dir = dir_iter(dir)
		local function wrapped_next(dir, last)
			local ret2, ret3
			repeat
				last, ret2, ret3 = next(dir, last)
			until not last or (last ~= '.' and last ~= '..')
			return last, ret2, ret3
		end
		return wrapped_next, dir
	end
end

function dir.path(dir)
	return path.combine(dir:dir(), dir:name())
end

function dir.attr(dir, attr, deref)
	if deref == nil then
		deref = true --deref by default
	end
	if attr == 'target' then
		if dir_attr(dir, 'type', false) == 'symlink' then
			return readlink(dir:path())
		else
			return nil --no error for non-symlink files
		end
	end
	local deref, val, err, errcode = dir_attr(dir, attr, deref)
	if val == nil and err then return nil, err, errcode end
	if deref then
		return fs.attr(dir:path(), attr, true)
	else
		return val
	end
end

function dir.type(dir, deref)
	return dir:attr('type', deref)
end

function dir.is(dir, type, deref)
	if type == 'symlink' then
		deref = false
	end
	return dir:type(deref) == type
end

--file attributes ------------------------------------------------------------

function fs.attr(path, attr, deref)
	if deref == nil then
		deref = true --deref by default
	end
	if attr == 'target' then
		--NOTE: posix doesn't need a type check here, but Windows does
		if not win or fs.is(path, 'symlink') then
			return readlink(path)
		else
			return nil --no error for non-symlink files
		end
	end
	local deref, val, err, errcode = fs_attr(path, attr, deref)
	if val == nil and err then return nil, err, errcode end
	if deref then --backend doesn't support symlink dereferencing
		local path, err, errcode = fs.readlink(path)
		if not path then return nil, err, errcode end
		return fs.attr(path, attr, false)
	else
		return val
	end
end

function fs.type(path, deref)
	return fs.attr(path, 'type', deref)
end

function fs.is(path, type, deref)
	if type == 'symlink' then
		deref = false
	end
	local ftype, err, errcode = fs.type(path, deref)
	if not type and not ftype and err == 'not_found' then
		return false
	elseif not type and ftype then
		return true
	elseif not ftype then
		return nil, err, errcode
	else
		return ftype == type
	end
end

--filesystem operations ------------------------------------------------------

function fs.mkdir(dir, recursive, ...)
	if recursive then
		dir = path.normalize(dir) --avoid creating `dir` in `dir/..` sequences
		local t = {}
		while true do
			local ok, err, errcode = mkdir(dir, ...)
			if ok then break end
			if err ~= 'not_found' then --other problem
				return ok, err, errcode
			end
			table.insert(t, dir)
			dir = path.dir(dir)
			if not dir then --reached root
				return ok, err, errcode
			end
		end
		while #t > 0 do
			local dir = table.remove(t)
			local ok, err, errcode = mkdir(dir, ...)
			if not ok then return ok, err, errcode end
		end
		return true
	else
		return mkdir(dir, ...)
	end
end

function fs.rmdir(dir, recursive)
	if recursive then
		for file, dirobj, errcode in fs.dir(dir) do
			if not file then
				return file, dirobj, errcode
			end
			local filepath = path.combine(dir, file)
			local ok, err, errcode
			if dirobj:is'dir' then
				ok, err, errcode = fs.rmdir(filepath, true)
			else
				ok, err, errcode = fs.remove(filepath)
			end
			if not ok then
				dirobj:close()
				return ok, err, errcode
			end
		end
		return fs.rmdir(dir)
	else
		return rmdir(dir)
	end
end

function fs.pwd(path)
	if path then
		return chdir(path)
	else
		return getcwd()
	end
end

function fs.remove(path, recursive)
	if recursive and fs.is(path, 'dir') then
		return fs.rmdir(path, true)
	else
		return remove(path)
	end
end

--symlinks -------------------------------------------------------------------

local function _readlink(link, maxdepth)
	if not fs.is(link, 'symlink') then
		return link
	end
	if maxdepth == 0 then
		return nil, 'not_found'
	end
	local target, err, errcode = readlink(link)
	if not target then return nil, err, errcode end
	if path.isabs(target) then
		link = target
	else --relative symlinks are relative to their own dir
		local link_dir = path.dir(link)
		if not link_dir then
			return nil, 'not_found'
		elseif link_dir == '.' then
			link_dir = ''
		end
		link = path.combine(link_dir, target)
	end
	return _readlink(link, maxdepth - 1)
end

function fs.readlink(link)
	return _readlink(link, 32)
end


return backend
