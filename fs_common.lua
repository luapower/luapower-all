
--portable filesystem API for LuaJIT / common code
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local path = require'path'

local C = ffi.C
local cdef = ffi.cdef

local backend = setmetatable({}, {__index = _G})
setfenv(1, backend)

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

function str(buf, sz)
	return buf ~= nil and ffi.string(buf, sz) or nil
end

--return a function which reuses an ever-increasing buffer
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

cdef[[
char *strerror(int errnum);
]]

function check_errno(ret, errno)
	if ret then return ret end
	errno = errno or ffi.errno()
	return ret, str(C.strerror(errno)), errno
end

function assert_checker(check)
	return function(ret, errcode)
		if ret then return ret end
		local _, err, errcode = check(errcode)
		if errcode then
			error(string.format('OS Error %s: %s', tostring(errcode), err), 2)
		else
			error(err, 2)
		end
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

local function table_flags(arg, masks)
	local mask = 0
	for k,v in pairs(arg) do
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

local string_flags = memoize2(function(arg, masks)
	if not arg:find'[ ,]' then
		return assert(masks[arg], 'invalid flag %s', arg)
	end
	local t = {}
	for s in arg:gmatch'[^ ,]+' do
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
	return backend.seek(f, whence or 'cur', offset or 0)
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
	dir = dir or fs.pwd()
	if dot_dirs then
		return dir_iter(dir)
	else --wrap iterator to skip `.` and `..` dirs
		local next, dir = dir_iter(dir)
		local function wrapped_next(dir, last)
			repeat
				last = next(dir, last)
			until not (last and (last == '.' or last == '..') and dir:is'dir')
			return last, dir
		end
		return wrapped_next, dir
	end
end

function dir.is(dir, type)
	return dir:type() == type
end

--filesystem operations ------------------------------------------------------

function fs.mkdir(dir, recursive, ...)
	if recursive then
		dir = path.normalize(dir) --avoid creating `dir` in `dir/..` sequences
		local t = {}
		while true do
			local ok, err, errcode = mkdir(dir, ...)
			if ok then break end
			if errcode ~= 'not_found' then --other problem
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
		for file, dirobj in fs.dir(dir) do
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

--symlinks -------------------------------------------------------------------

function fs.symlink(link_path, target_path)
	if not target then
		return get_symlink_target(link_path)
	else
		return set_symlink_target(link_path, target_path)
	end
end

function fs.hardlink(link_path, target_path)
	if not target then
		return get_link_target(link_path)
	else
		return set_link_target(link_path, target_path)
	end
end

function fs.link(link_path, target_path, symlink)
	local f = symlink and fs.symlink or fs.hardlink
	return f(link_path, target_path)
end

--[[
function fs.drive(path)

end

function fs.dev(path)

end

function fs.inode(path)

end

function fs.type(path)
	--file, dir, link, socket, pipe, char device, block device, other
end

function fs.linknum(path)

end

function fs.uid(path, newuid)

end

function fs.gid(path, newgid)

end

function fs.devtype(path)

end

function fs.atime(path, newatime)

end

function fs.mtime(path, newmtime)

end

function fs.ctime(path, newctime)

end

local function getsize(path)

end

local function setsize(path, newsize)

end

function fs.grow(path, newsize)

end

function fs.shrink(path, newsize)

end

function fs.size(path, newsize)
	if newsize then
		return setsize(path, newsize)
	else
		return getsize(path)
	end
end

local function perms_arg(perms, old_perms)
	if type(perms) == 'string' then
		if perms:find'^[0-7]+$' then
			perms = tonumber(perms, 8)
		else
			assert(not perms:find'[^%+%-ugorwx]', 'invalid permissions')
			--TODO: parse perms
		end
	else
		return perms
	end
end

function fs.perms(path, newperms)
	if newperms then
		newperms = perms_arg(newperms, fs.perms(path))
		--
	else
		--
	end
end

function fs.blocks(path)

end

function fs.blksize(path)

end
]]

--paths ----------------------------------------------------------------------

local win = ffi.abi'win'

-- follow symlinks relative to pwd
--encode path given as table:
function fs.path(path, pwd)
		--
end

function fs.splitpath(path, reverse)
	local t = {}
	return
end


function fs.dirname(path)
	return path:gsub('[/\\]?[^/\\]+$', '')
end

function fs.basename(path, suffix)
	--TODO: verify this code
	if suffix and path:sub(-#suffix) == suffix then
		path = path:sub(1, -#suffix)
	end
	return path:match'[^/\\]+$' or ''
end

function fs.extname(path)
	return fs.basename(path):match'.%.([^%.]+)$' or nil
end

function fs.abspath(path, pwd)
	pwd = pwd or fs.pwd()
end

function fs.relpath(path, pwd)
	pwd = pwd or fs.pwd()
end

function fs.realpath(path)
	-- we should check if the path exists on windows
end

function fs.readlink(path)

end


return backend
