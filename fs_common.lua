
--portable filesystem API for LuaJIT / common code
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local path = require'path'

local min, max, floor, ceil, ln =
	math.min, math.max, math.floor, math.ceil, math.log

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

local uint64_ct   = ffi.typeof'uint64_t'
local void_ptr_ct = ffi.typeof'void*'
local uintptr_ct  = ffi.typeof'uintptr_t'

local u8p = glue.u8p
local readall = glue.readall

memoize = glue.memoize
assert = glue.assert
buffer = glue.buffer
update = glue.update

--error reporting ------------------------------------------------------------

cdef'char *strerror(int errnum);'

local errors = {
	[2] = 'not_found', --ENOENT, _open_osfhandle(), _fdopen(), open(), mkdir(),
	                   --rmdir(), opendir(), rename(), unlink()
	[5] = 'io_error', --EIO, readlink(), read()
	[13] = 'access_denied', --EACCESS, mkdir() etc.
	[17] = 'already_exists', --EEXIST, open(), mkdir()
	[20] = 'not_found', --ENOTDIR, opendir()
	[21] = 'is_dir', --EISDIR, unlink()
	[linux and 39 or osx and 66 or ''] = 'not_empty', --ENOTEMPTY, rmdir()
	[28] = 'disk_full', --ENOSPC: fallocate()
	[linux and 95 or ''] = 'not_supported', --EOPNOTSUPP: fallocate()
	[linux and 32 or ''] = 'eof', --EPIPE: write()
}

function check_errno(ret, errno, xtra_errors)
	if ret then return ret end
	errno = errno or ffi.errno()
	local err = errors[errno] or (xtra_errors and xtra_errors[errno])
	if not err then
		local s = C.strerror(errno)
		err = s ~= nil and ffi.string(s) or 'Error '..errno
	end
	return ret, err
end

--flags arg parsing ----------------------------------------------------------

--turn a table of boolean options into a bit mask.
local function table_flags(t, masks, strict)
	local bits = 0
	local mask = 0
	for k,v in pairs(t) do
		local flag
		if type(k) == 'string' and v then --flags as table keys: {flag->true}
			flag = k
		elseif type(k) == 'number'
			and floor(k) == k
			and type(v) == 'string'
		then --flags as array: {flag1,...}
			flag = v
		end
		local bitmask = masks[flag]
		if strict then
			assert(bitmask, 'invalid flag: "%s"', tostring(flag))
		end
		if bitmask then
			mask = bit.bor(mask, bitmask)
			if flag then
				bits = bit.bor(bits, bitmask)
			end
		end
	end
	return bits, mask
end

--turn 'opt1 +opt2 -opt3' -> {opt1=true, opt2=true, opt3=false}
local function string_flags(s, masks, strict)
	local t = {}
	for s in s:gmatch'[^ ,]+' do
		local m,s = s:match'^([%+%-]?)(.*)$'
		t[s] = m ~= '-'
	end
	return table_flags(t, masks, strict)
end

--set one or more bits of a value without affecting other bits.
function setbits(bits, mask, over)
	return over and bit.bor(bits, bit.band(over, bit.bnot(mask))) or bits
end

--cache tuple(options_string, masks_table) -> bits, mask
local cache = {}
local function getcache(s, masks)
	cache[masks] = cache[masks] or {}
	local t = cache[masks][s]
	if not t then return end
	return t[1], t[2]
end
local function setcache(s, masks, bits, mask)
	cache[masks][s] = {bits, mask}
end

function flags(arg, masks, cur_bits, strict)
	if type(arg) == 'string' then
		local bits, mask = getcache(arg, masks)
		if not bits then
			bits, mask = string_flags(arg, masks, strict)
			setcache(arg, masks, bits, mask)
		end
		return setbits(bits, mask, cur_bits)
	elseif type(arg) == 'table' then
		local bits, mask = table_flags(arg, masks, strict)
		return setbits(bits, mask, cur_bits)
	elseif type(arg) == 'number' then
		return arg
	elseif arg == nil then
		return 0
	else
		assert(false, 'flags expected but "%s" given', type(arg))
	end
end

--file objects ---------------------------------------------------------------

function fs.isfile(f)
	return type(f) == 'table' and rawget(f, '__index') == file
end

--returns a read(buf, maxsz) -> sz function which reads ahead from file.
function file.buffered_read(f, bufsize)
	local ptr_ct = ffi.typeof'uint8_t*'
	local buf_ct = ffi.typeof'uint8_t[?]'
	local bufsize = bufsize or 4096
	local buf = buf_ct(bufsize)
	local ofs, len = 0, 0
	local eof = false
	return function(dst, sz)
		if not dst then --skip bytes (libjpeg semantics)
			local i, err = f:seek('cur')    ; if not i then return nil, err end
			local j, err = f:seek('cur', sz); if not j then return nil, err end
			return j - i
		end
		local rsz = 0
		while sz > 0 do
			if len == 0 then
				if eof then
					return 0
				end
				ofs = 0
				local len1, err = f:read(buf, bufsize)
				if not len1 then return nil, err end
				len = len1
				if len == 0 then
					eof = true
					return rsz
				end
			end
			--TODO: benchmark: read less instead of copying.
			local n = min(sz, len)
			ffi.copy(ffi.cast(ptr_ct, dst) + rsz, buf + ofs, n)
			ofs = ofs + n
			len = len - n
			rsz = rsz + n
			sz = sz - n
		end
		return rsz
	end
end

--stdio streams --------------------------------------------------------------

cdef[[
typedef struct FILE FILE;
int fclose(FILE*);
]]

stream_ct = ffi.typeof'struct FILE'

function stream.close(fs)
	local ok = C.fclose(fs) == 0
	if not ok then return check_errno(false) end
	return true
end

--i/o ------------------------------------------------------------------------

local whences = {set = 0, cur = 1, ['end'] = 2} --FILE_*
function file:seek(whence, offset)
	if tonumber(whence) and not offset then --middle arg missing
		whence, offset = 'cur', tonumber(whence)
	end
	whence = whence or 'cur'
	offset = tonumber(offset or 0)
	whence = assert(whences[whence], 'invalid whence: "%s"', whence)
	return self:_seek(whence, offset)
end

function file:write(buf, sz, expires)
	sz = sz or #buf
	if sz == 0 then return true end --mask out null writes
	local sz0 = sz
	while true do
		local len, err = self:_write(buf, sz, expires)
		if len == sz then
			break
		elseif not len then --short write
			return nil, err, sz0 - sz
		end
		assert(len > 0)
		if type(buf) == 'string' then --only make pointer on the rare second iteration.
			buf = ffi.cast(u8p, buf)
		end
		buf = buf + len
		sz  = sz  - len
	end
	return true
end

function file:readn(buf, sz, expires)
	local sz0 = sz
	while sz > 0 do
		local len, err = self:read(buf, sz, expires)
		if not len or len == 0 then --short read
			return nil, err, sz0 - sz
		end
		buf = buf + len
		sz  = sz  - len
	end
	return true
end

local u8a = ffi.typeof'uint8_t[?]'
function file:readall(expires)
	if self.type == 'file' then
		local size, err = self:attr'size'; if not size then return nil, err end
		local offset, err = self:seek(); if not offset then return nil, err end
		local sz = size - offset
		if sz == 0 then return nil, 0 end
		local buf = ffi.new(u8a, sz)
		local n, err = self:read(buf, sz)
		if not n then return nil, err end
		if n < sz then return nil, 'partial', buf, n end
		return buf, n
	elseif self.type == 'pipe' then
		return readall(self.read, self, expires)
	else
		assert(false)
	end
end

--filesystem operations ------------------------------------------------------

function fs.mkdir(dir, recursive, ...)
	if recursive then
		dir = path.normalize(dir) --avoid creating `dir` in `dir/..` sequences
		local t = {}
		while true do
			local ok, err, errno = mkdir(dir, ...)
			if ok then break end
			if err ~= 'not_found' then --other problem
				ok = err == 'already_exists' and #t == 0
				return ok, err, errno
			end
			table.insert(t, dir)
			dir = path.dir(dir)
			if not dir then --reached root
				return ok, err
			end
		end
		while #t > 0 do
			local dir = table.remove(t)
			local ok, err, errno = mkdir(dir, ...)
			if not ok then return ok, err, errno end
		end
		return true
	else
		return mkdir(dir, ...)
	end
end

local function remove(path)
	local type = fs.attr(path, 'type', false)
	if type == 'dir' or (win and type == 'symlink'
		and fs.is(path, 'dir'))
	then
		return rmdir(path)
	end
	return rmfile(path)
end

--TODO: for Windows, this simple algorithm is not correct. On NTFS we
--should be moving all files to a temp folder and deleting them from there.
local function rmdir_recursive(dir)
	for file, d in fs.dir(dir) do
		if not file then
			return file, d
		end
		local filepath = path.combine(dir, file)
		local ok, err
		local realtype = d:attr('type', false)
		if realtype == 'dir' then
			ok, err = rmdir_recursive(filepath)
		elseif win and realtype == 'symlink' and fs.is(filepath, 'dir') then
			ok, err = rmdir(filepath)
		else
			ok, err = rmfile(filepath)
		end
		if not ok then
			d:close()
			return ok, err
		end
	end
	return rmdir(dir)
end

function fs.remove(dirfile, recursive)
	if recursive then
		--not recursing if the dir is a symlink, unless it has an endsep!
		if not path.endsep(dirfile) then
			local type, err = fs.attr(dirfile, 'type', false)
			if not type then return nil, err end
			if type == 'symlink' then
				if win and fs.is(dirfile, 'dir') then
					return rmdir(dirfile)
				end
				return rmfile(dirfile)
			end
		end
		return rmdir_recursive(dirfile)
	else
		return remove(dirfile)
	end
end

function fs.cwd(path)
	if path then
		return chdir(path)
	else
		return getcwd()
	end
end
fs.cd = fs.cwd

--symlinks -------------------------------------------------------------------

local function readlink_recursive(link, maxdepth)
	if not fs.is(link, 'symlink') then
		return link
	end
	if maxdepth == 0 then
		return nil, 'not_found'
	end
	local target, err = readlink(link)
	if not target then
		return nil, err
	end
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
	return readlink_recursive(link, maxdepth - 1)
end

function fs.readlink(link)
	return readlink_recursive(link, 32)
end

--common paths ---------------------------------------------------------------

function fs.exedir()
	return path.dir(fs.exepath())
end

fs.scriptdir = memoize(function()
	return path.normalize((path.combine(initial_cwd(), glue.bin)))
end)

--file attributes ------------------------------------------------------------

function file.attr(f, attr)
	if type(attr) == 'table' then
		return file_attr_set(f, attr)
	else
		return file_attr_get(f, attr)
	end
end

local function attr_args(attr, deref)
	if type(attr) == 'boolean' then --middle arg missing
		attr, deref = nil, attr
	end
	if deref == nil then
		deref = true --deref by default
	end
	return attr, deref
end

function fs.attr(path, ...)
	local attr, deref = attr_args(...)
	if attr == 'target' then
		--NOTE: posix doesn't need a type check here, but Windows does
		if not win or fs.is(path, 'symlink') then
			return readlink(path)
		else
			return nil --no error for non-symlink files
		end
	end
	if type(attr) == 'table' then
		return fs_attr_set(path, attr, deref)
	else
		return fs_attr_get(path, attr, deref)
	end
end

function fs.is(path, type, deref)
	if type == 'symlink' then
		deref = false
	end
	local ftype, err = fs.attr(path, 'type', deref)
	if not type and not ftype and err == 'not_found' then
		return false
	elseif not type and ftype then
		return true
	elseif not ftype then
		return nil, err
	else
		return ftype == type
	end
end

--directory listing ----------------------------------------------------------

local function dir_check(dir)
	assert(not dir:closed(), 'dir closed')
	assert(dir_ready(dir), 'dir not ready')
end

function fs.dir(dir, dot_dirs)
	dir = dir or '.'
	if dot_dirs then
		return fs_dir(dir)
	else --wrap iterator to skip `.` and `..` entries
		local next, dir = fs_dir(dir)
		local function wrapped_next(dir)
			while true do
				local file, err = next(dir)
				if file == nil then
					return nil
				elseif not file then
					return false, err
				elseif file ~= '.' and file ~= '..' then
					return file, dir
				end
			end
		end
		return wrapped_next, dir
	end
end

function dir.path(dir)
	return path.combine(dir:dir(), dir:name())
end

function dir.name(dir)
	dir_check(dir)
	return dir_name(dir)
end

local function dir_is_symlink(dir)
	return dir_attr_get(dir, 'type', false) == 'symlink'
end

function dir.attr(dir, ...)
	dir_check(dir)
	local attr, deref = attr_args(...)
	if attr == 'target' then
		if dir_is_symlink(dir) then
			return readlink(dir:path())
		else
			return nil --no error for non-symlink files
		end
	end
	if type(attr) == 'table' then
		return fs_attr_set(dir:path(), attr, deref)
	elseif not attr or (deref and dir_is_symlink(dir)) then
		return fs_attr_get(dir:path(), attr, deref)
	else
		local val, found = dir_attr_get(dir, attr)
		if found == false then --attr not found in state
			return fs_attr_get(dir:path(), attr)
		else
			return val
		end
	end
end

function dir.is(dir, type, deref)
	if type == 'symlink' then
		deref = false
	end
	return dir:attr('type', deref) == type
end

--memory mapping -------------------------------------------------------------

do
local m = ffi.new[[
	union {
		struct { uint32_t lo; uint32_t hi; };
		uint64_t x;
	}
]]
function split_uint64(x)
	m.x = x
	return m.hi, m.lo
end
function join_uint64(hi, lo)
	m.hi, m.lo = hi, lo
	return m.x
end
end

function fs.aligned_size(size, dir) --dir can be 'l' or 'r' (default: 'r')
	if ffi.istype(uint64_ct, size) then --an uintptr_t on x64
		local pagesize = fs.pagesize()
		local hi, lo = split_uint64(size)
		local lo = fs.aligned_size(lo, dir)
		return join_uint64(hi, lo)
	else
		local pagesize = fs.pagesize()
		if not (dir and dir:find'^l') then --align to the right
			size = size + pagesize - 1
		end
		return bit.band(size, bit.bnot(pagesize - 1))
	end
end

function fs.aligned_addr(addr, dir)
	return ffi.cast(void_ptr_ct,
		fs.aligned_size(ffi.cast(uintptr_ct, addr), dir))
end

function parse_access(s)
	assert(not s:find'[^rwcx]', 'invalid access flags')
	local write = s:find'w' and true or false
	local exec  = s:find'x' and true or false
	local copy  = s:find'c' and true or false
	assert(not (write and copy), 'invalid access flags')
	return write, exec, copy
end

function check_tagname(tagname)
	assert(not tagname:find'[/\\]', 'tagname cannot contain `/` or `\\`')
	return tagname
end

function file.map(f, ...)
	local access, size, offset, addr
	if type(t) == 'table' then
		access, size, offset, addr = t.access, t.size, t.offset, t.addr
	else
		offset, size, addr, access = ...
	end
	return fs.map(f, access or f.access, size, offset, addr)
end

function fs.map(t,...)
	local file, access, size, offset, addr, tagname, perms
	if type(t) == 'table' then
		file, access, size, offset, addr, tagname, perms =
			t.file, t.access, t.size, t.offset, t.addr, t.tagname, t.perms
	else
		file, access, size, offset, addr, tagname, perms = t, ...
	end
	assert(not file or type(file) == 'string' or fs.isfile(file), 'invalid file argument')
	assert(file or size, 'file and/or size expected')
	assert(not size or size > 0, 'size must be > 0')
	local offset = file and offset or 0
	assert(offset >= 0, 'offset must be >= 0')
	assert(offset == fs.aligned_size(offset), 'offset not page-aligned')
	local addr = addr and ffi.cast(void_ptr_ct, addr)
	assert(not addr or addr ~= nil, 'addr can\'t be zero')
	assert(not addr or addr == fs.aligned_addr(addr), 'addr not page-aligned')
	assert(not (file and tagname), 'cannot have both file and tagname')
	assert(not tagname or not tagname:find'\\', 'tagname cannot contain `\\`')
	return fs_map(file, access, size, offset, addr, tagname, perms)
end

--memory streams -------------------------------------------------------------

local vfile = {}

function fs.open_buffer(buf, sz, mode)
	sz = sz or #buf
	mode = mode or 'r'
	assert(mode == 'r' or mode == 'w', 'invalid mode: "%s"', mode)
	local f = {
		buffer = ffi.cast(u8p, buf),
		size = sz,
		offset = 0,
		mode = mode,
		_buffer = buf, --anchor it
		__index = vfile,
	}
	return setmetatable(f, f)
end

function vfile.close(f) f._closed = true; return true end
function vfile.closed(f) return f._closed end

function vfile.flush(f)
	if f._closed then
		return nil, 'access_denied'
	end
	return true
end

function vfile.read(f, buf, sz)
	if f._closed then
		return nil, 'access_denied'
	end
	sz = min(max(0, sz), max(0, f.size - f.offset))
	ffi.copy(buf, f.buffer + f.offset, sz)
	f.offset = f.offset + sz
	return sz
end

function vfile.write(f, buf, sz)
	if f._closed then
		return nil, 'access_denied'
	end
	if f.mode ~= 'w' then
		return nil, 'access_denied'
	end
	sz = min(max(0, sz), max(0, f.size - f.offset))
	ffi.copy(f.buffer + f.offset, buf, sz)
	f.offset = f.offset + sz
	return sz
end

vfile.seek = file.seek

function vfile._seek(f, whence, offset)
	if whence == 1 then --cur
		offset = f.offset + offset
	elseif whence == 2 then --end
		offset = f.size + offset
	end
	offset = max(offset, 0)
	f.offset = offset
	return offset
end

function vfile:truncate(size)
	local pos, err = f:seek(size)
	if not pos then return nil, err end
	f.size = size
	return true
end

vfile.buffered_read = file.buffered_read


return backend
