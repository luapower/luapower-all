
--portable filesystem API for LuaJIT / POSIX API
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
setfenv(1, require'fs_common')

local C = ffi.C

--POSIX does not define an ABI and platfoms have different cdefs thus we have
--to limit support to the platforms and architectures we actually tested for.
assert(linux or osx, 'platform not Linux or OSX')
assert(x64 or ffi.arch == 'x86', 'arch not x86 or x64')

--ffi tools ------------------------------------------------------------------

check = check_errno
assert_check = assert_check_errno

local cbuf = mkbuf'char'

--common types and consts ----------------------------------------------------

cdef[[
typedef unsigned int mode_t;
typedef size_t time_t;
typedef int64_t off64_t;
]]

--open/close -----------------------------------------------------------------

cdef[[
int open(const char *pathname, int flags, mode_t mode);
int close(int fd);
]]

local o_flags = linux and {
	--Linux & OSX (Linux bitmasks)
	rdonly    = 0x00000000, --access: read only
	wronly    = 0x00000001, --access: write only
	rdwr      = 0x00000002, --access: read + write
	accmode   = 0x00000003, --access: no read, no write, only ioctl()
	append    = 0x00000400, --append mode (seek to eof before each write())
	trunc     = 0x00000200, --truncate the file on opening
	creat     = 0x00000040, --create if file does not exist
	excl      = 0x00000080, --create or fail (needs 'creat')
	nofollow  = 0x00020000, --fail if file is a symlink
	directory = 0x00010000, --open only if the file is a directory or fail
	nonblock  = 0x00000800, --non-blocking (no effect on regular files)
	async     = 0x00002000, --enable signal-driven I/O (not for regular files)
	sync      = 0x00101000, --enable synchronized _file_ integrity completion
	fsync     = 0x00101000, --'sync'
	dsync     = 0x00001000, --enable synchronized _data_ integrity completion
	noctty    = 0x00000100, --for tty files: prevent becoming ctty
	cloexec   = 0x00080000, --set close-on-exec
	--Linux only
	direct    = 0x00004000, --direct disk access hint (user does caching)
	noatime   = 0x00040000, --don't update atime
	rsync     = 0x00101000, --'sync'
	path      = 0x00200000, --open only for fs-level operation
   tmpfile   = 0x00410000, --create an unnamed temp file (Linux 3.11+)
} or {
	--Linux & OSX (OSX bitmasks)
	rdonly    = 0x00000000, --access: read only
	wronly    = 0x00000001, --access: write only
	rdwr      = 0x00000002, --access: read + write
	accmode   = 0x00000003, --access: no read, no write, only ioctl()
	append    = 0x00000008, --append mode (seek to eof before each write())
	trunc     = 0x00000400, --truncate the file on opening
	creat     = 0x00000200, --create if file does not exist
	excl      = 0x00000800, --create or fail (needs 'creat')
	nofollow  = 0x00000100, --fail if file is a symlink
	directory = 0x00100000, --open only if the file is a directory or fail
	nonblock  = 0x00000004, --non-blocking (no effect on regular files)
	async     = 0x00000040, --enable signal-driven I/O (not for regular files)
	sync      = 0x00000080, --enable synchronized _file_ integrity completion
	fsync     = 0x00000080, --'sync'
	dsync     = 0x00400000, --enable synchronized _data_ integrity completion
	noctty    = 0x00020000, --for tty files: prevent becoming ctty
	cloexec   = 0x01000000, --set close-on-exec
	--OSX only
	shlock    = 0x00000010, --get a shared lock
	exlock    = 0x00000020, --get an exclusive lock
	evtonly   = 0x00008000, --open for events only as to not prevent unmount
	symlink   = 0x00200000, --open the symlink itself
}

local str_opt = {
	r = {flags = 'rdonly'},
	w = {flags = 'creat wronly trunc'},
	['r+'] = {flags = 'rdwr'},
	['w+'] = {flags = 'creat rdwr'},
}

--expose this because the frontend will set its metatype on it at the end.
file_ct = ffi.typeof[[
	struct {
		int fd;
	}
]]

function fs.open(path, opt)
	opt = opt or 'r'
	if type(opt) == 'string' then
		opt = assert(str_opt[opt], 'invalid option %s', opt)
	end
	local flags = flags(opt.flags or 'rdonly', o_flags)
	local mode = opt.mode or 0x1b6 --0666
	local fd = C.open(path, flags, mode)
	if fd == -1 then return check() end
	return ffi.gc(file_ct(fd), file.close)
end

function file.closed(f)
	return f.fd == -1
end

function file.close(f)
	if f:closed() then return end
	local ok = C.close(f.fd) == 0
	f.fd = -1 --ignore failure
	ffi.gc(f, nil)
	return check(ok)
end

--i/o ------------------------------------------------------------------------

cdef(string.format([[
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int fsync(int fd);
int64_t lseek(int fd, int64_t offset, int whence) asm("lseek%s");
int ftruncate(int fd, int64_t length);
]], linux and '64' or ''))

function file.read(f, buf, sz)
	local szread = C.read(f.fd, buf, sz)
	if szread == -1 then return check() end
	return szread
end

function file.write(f, buf, sz)
	local szwr = C.write(f.fd, buf, sz)
	if szwr == -1 then return check() end
	return szwr
end

function file.flush(f)
	return check(C.fsync(f.fd) == 0)
end

local whences = {
	set = 0, cur = 1, ['end'] = 2,
	data = linux and 3, hole = linux and 4, --Linux 3.1+
}
function seek(f, whence, offset)
	whence = assert(whences[whence], 'invalid whence %s', whence)
	local offs = C.lseek(f.fd, offset, whence)
	if offs == -1 then return check() end
	return offs
end

--truncation -----------------------------------------------------------------

--NOTE: ftruncate() creates a sparse file in ext4 and tmpfs filesystems,
--just like the technique of seeking to size-1 and writing one byte would,
--which is why we use fallocate() to grow a file.

local fallocate

if osx then

	local F_PREALLOCATE    = 42
	local F_ALLOCATECONTIG = 2
	local F_PEOFPOSMODE    = 3
	local F_ALLOCATEALL    = 4

	local fstore_ct = ffi.typeof[[
		struct {
			uint32_t fst_flags;
			int      fst_posmode;
			off64_t  fst_offset;
			off64_t  fst_length;
			off64_t  fst_bytesalloc;
		}
	]]

	ffi.cdef'int fcntl(int fd, int cmd, ...);'

	local void = ffi.typeof'void*'
	local store

	function fallocate(fd, size, cursize)
		if size > cursize then --grow
			store = store or fstore_ct(F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, 0)
			store.fst_bytesalloc = size
			local ret = C.fcntl(fd, F_PREALLOCATE, ffi.cast(void, store))
			if ret == -1 then --too fragmented, allocate non-contiguous space
				store.fst_flags = F_ALLOCATEALL
				local ret = C.fcntl(fd, F_PREALLOCATE, ffi.cast(void, store))
				if ret == -1 then return check() end
			end
		end
		return check(C.ftruncate(fd, size) == 0)
	end

else

	ffi.cdef'int posix_fallocate64(int fd, off64_t offset, off64_t len);'

	local EINVAL = 22 --operation not supported
	local ENOSPC = 28 --no space left on device

	function fallocate(fd, size, cursize)
		assert(size > 0, 'invalid size') --remove a potential cause of EINVAL
		if size > cursize then --grow
			local errno = C.posix_fallocate64(fd, 0, size)
			if errno == EINVAL then
				--this filesystem does not support fallocate() (eg. VFAT),
				--so fallback to ftruncate().
				return check(C.ftruncate(fd, size) == 0)
			elseif errno == ENOSPC then
				--when fallocate() fails because disk is full, a file is still
				--created filling up the entire disk, so shrink back the file
				--to its original size. this is courtesy: we don't check to see
				--if it fails or not and we return the original error code.
				C.ftruncate(fd, cursize)
			end
			return check(errno == 0, errno)
		else
			return check(C.ftruncate(fd, size) == 0)
		end
	end

end

function file.truncate(f, sparse)
	local curpos,e,c = f:seek()
	if not curpos then return nil,e,c end
	if sparse then
		return check(C.ftruncate(f.fd, curpos) == 0)
	else
		local cursize,e,c = f:size()
		if not cursize then return nil,e,c end
		return fallocate(f.fd, curpos, cursize)
	end
end

function file.size(f, size)
	local curpos,e,c = f:seek()
	if not curpos then return nil,e,c end
	local cursize,e,c = f:seek('end')
	if not cursize then return nil,e,c end
	if size then --set size
		local _,e,c = f:seek('set', size)
		if not _ then return nil,e,c end
		if cursize < size then -- grow
			local _,e,c = fallocate(fd, size, cursize)
			if not _ then return nil,e,c end
		elseif cursize > size then --shrink
			local _,e,c = f:truncate()
			if not _ then return nil,e,c end
		end
	else --get size
		size = cursize
	end
	local _,e,c = f:seek('set', curpos)
	if not _ then return nil,e,c end
	return size
end

--stdio streams --------------------------------------------------------------

cdef'FILE *fdopen(int fd, const char *mode);'

function file.stream(f, mode)
	local fs = C.fdopen(f.fd, mode)
	if fs == nil then return check() end
	ffi.gc(f, nil) --fclose() will close the handle
	ffi.gc(fs, stream.close)
	return fs
end

--directory listing ----------------------------------------------------------

if linux then cdef[[
struct dirent { // NOTE: 64bit version
	uint64_t        d_ino;
	int64_t         d_off;
	unsigned short  d_reclen;
	unsigned char   d_type;
	char            d_name[256];
};
]] elseif osx then cdef[[
struct dirent { // NOTE: 64bit version
	uint64_t d_ino;
	uint64_t d_seekoff;
	uint16_t d_reclen;
	uint16_t d_namlen;
	uint8_t  d_type;
	char     d_name[1024];
};
]] end

cdef(string.format([[
typedef struct DIR DIR;
DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp) asm("readdir%s");
int closedir(DIR *dirp);
]], linux and '64' or osx and '$INODE64'))

function dir.close(dir)
	if dir:closed() then return end
	local ok = C.closedir(dir._dirp) == 0
	if ok then dir._dirp = nil end
	return check(ok)
end

function dir.closed(dir)
	return dir._dirp == nil
end

function dir.name(dir)
	if dir:closed() then return nil end
	return ffi.string(dir._dentry.d_name)
end

function dir.dir(dir)
	return ffi.string(dir._dir, dir._dirlen)
end

function dir.next(dir)
	if dir:closed() then
		if dir._errno ~= 0 then
			local errno = dir._errno
			dir._errno = 0
			return check(false, errno)
		end
		return nil
	end
	ffi.errno(0)
	dir._dentry = C.readdir(dir._dirp)
	if dir._dentry ~= nil then
		return dir:name(), dir
	else
		local errno = ffi.errno()
		dir:close()
		if errno == 0 then
			return nil
		end
		return check(false, errno)
	end
end

--dirent.d_type consts
local DT_UNKNOWN = 0
local DT_FIFO    = 1
local DT_CHR     = 2
local DT_DIR     = 4
local DT_BLK     = 6
local DT_REG     = 8
local DT_LNK     = 10
local DT_SOCK    = 12

local dt_types = {
	dir       = DT_DIR,
	file      = DT_REG,
	symlink   = DT_LNK,
	dev_block = DT_BLK,
	dev_char  = DT_CHR,
	pipe      = DT_FIFO,
	socket    = DT_SOCK,
	unknown   = DT_UNKNOWN,
}

local dt_names = {
	[DT_DIR]  = 'dir',
	[DT_REG]  = 'file',
	[DT_LNK]  = 'symlink',
	[DT_BLK]  = 'dev_block',
	[DT_CHR]  = 'dev_char',
	[DT_FIFO] = 'pipe',
	[DT_SOCK] = 'socket',
	[DT_UNKNOWN] = 'unknown',
}

function dir_attr(dir, attr, deref)
	deref = deref and dir_attr(dir, 'type', false) == 'symlink'
	if attr == 'type' and dir._dentry.d_type == DT_UNKNOWN then
		local type, err, errcode = fs.attr(dir:path(), 'type', false)
		if not type then
			return false, nil, err, errcode
		end
		local dt = dt_types[type]
		dir._dentry.d_type = dt --cache it
	end
	if not deref and attr == 'type' then
		return false, dt_names[dir._dentry.d_type]
	elseif not deref and attr == 'inode' then
		return false, dir._dentry.d_ino
	else --deref is true, or attr that is not in dirent, or get/set attr table
		return false, fs.attr(dir:path(), attr, deref)
	end
end

dir_ct = ffi.typeof[[
	struct {
		DIR *_dirp;
		struct dirent* _dentry;
		int  _errno;
		int  _dirlen;
		char _dir[?];
	}
]]

function dir_iter(path)
	local dir = dir_ct(#path)
	dir._dirlen = #path
	ffi.copy(dir._dir, path)
	dir._dirp = C.opendir(path)
	if dir._dirp == nil then
		dir._errno = ffi.errno()
	end
	return dir.next, dir
end

--file attributes ------------------------------------------------------------

if linux and x64 then cdef[[
struct stat {
	uint64_t st_dev;
	uint64_t st_ino;
	uint64_t st_nlink;
	uint32_t st_mode;
	uint32_t st_uid;
	uint32_t st_gid;
	uint32_t __pad0;
	uint64_t st_rdev;
	int64_t  st_size;
	int64_t  st_blksize;
	int64_t  st_blocks;
	uint64_t st_atime;
	uint64_t st_atime_nsec;
	uint64_t st_mtime;
	uint64_t st_mtime_nsec;
	uint64_t st_ctime;
	uint64_t st_ctime_nsec;
	int64_t  __unused[3];
};
]] elseif linux then cdef[[
struct stat { // NOTE: 64bit version
	uint64_t st_dev;
	uint8_t  __pad0[4];
	uint32_t __st_ino;
	uint32_t st_mode;
	uint32_t st_nlink;
	uint32_t st_uid;
	uint32_t st_gid;
	uint64_t st_rdev;
	uint8_t  __pad3[4];
	int64_t  st_size;
	uint32_t st_blksize;
	uint64_t st_blocks;
	uint32_t st_atime;
	uint32_t st_atime_nsec;
	uint32_t st_mtime;
	uint32_t st_mtime_nsec;
	uint32_t st_ctime;
	uint32_t st_ctime_nsec;
	uint64_t st_ino;
};
]] elseif osx then cdef[[
struct stat { // NOTE: 64bit version
	uint32_t st_dev;
	uint16_t st_mode;
	uint16_t st_nlink;
	uint64_t st_ino;
	uint32_t st_uid;
	uint32_t st_gid;
	uint32_t st_rdev;
	// NOTE: these were `struct timespec`
	time_t   st_atime;
	long     st_atime_nsec;
	time_t   st_mtime;
	long     st_mtime_nsec;
	time_t   st_ctime;
	long     st_ctime_nsec;
	time_t   st_btime; // birth-time i.e. creation time
	long     st_btime_nsec;
	int64_t  st_size;
	int64_t  st_blocks;
	int32_t  st_blksize;
	uint32_t st_flags;
	uint32_t st_gen;
	int32_t  st_lspare;
	int64_t  st_qspare[2];
};
]] end

local stat_ct = ffi.typeof'struct stat'

local fstat, stat, lstat
if linux then
	cdef'long syscall(int number, ...);'
	local void = ffi.typeof'void*'
	local int = ffi.typeof'int'
	function stat(path, buf)
		return C.syscall(x64 and 4 or 195,
			ffi.cast(void, path), ffi.cast(void, buf))
	end
	function lstat(path, buf)
		return C.syscall(x64 and 6 or 196,
			ffi.cast(void, path), ffi.cast(void, buf))
	end
	function fstat(fd, buf)
		return C.syscall(x64 and 5 or 197,
			ffi.cast(int, fd), ffi.cast(void, buf))
	end
else
	cdef[[
	int fstat64(int fd, struct stat *buf);
	int stat64(const char *path, struct stat *buf);
	int lstat64(const char *path, struct stat *buf);
	]]
	stat = C.stat64
	lstat = C.lstat64
	fstat = C.fstat64
end

local file_types = {
	[0xc000] = 'socket',
	[0xa000] = 'symlink',
	[0x8000] = 'file',
	[0x6000] = 'dev_block',
	[0x2000] = 'dev_char',
	[0x4000] = 'dir',
	[0x1000] = 'pipe',
}
local function st_type(mode)
	local type = bit.band(mode, 0xf000)
	return file_types[type]
end

local function st_perms(mode)
	return bit.band(mode, bit.bnot(0xf000))
end

local function st_time(s, ns)
	return tonumber(s) + tonumber(ns) * 1e-9
end

local stat_decoders = {
	type    = function(st) return st_type(st.st_mode) end,
	dev     = function(st) return tonumber(st.st_dev) end,
	inode   = function(st) return st.st_ino end, --unfortunately, 64bit inode
	nlink   = function(st) return tonumber(st.st_nlink) end,
	perms   = function(st) return st_perms(st.st_mode) end,
	uid     = function(st) return st.st_uid end,
	gid     = function(st) return st.st_gid end,
	rdev    = function(st) return tonumber(st.st_rdev) end,
	size    = function(st) return tonumber(st.st_size) end,
	blksize = function(st) return tonumber(st.st_blksize) end,
	blocks  = function(st) return tonumber(st.st_blocks) end,
	atime   = function(st) return st_time(st.st_atime, st.st_atime_nsec) end,
	mtime   = function(st) return st_time(st.st_mtime, st.st_mtime_nsec) end,
	ctime   = function(st) return st_time(st.st_ctime, st.st_ctime_nsec) end,
	btime   = osx and
	          function(st) return st_time(st.st_btime, st.st_btime_nsec) end,
}

local st
function fs_attr(path, attr, deref)
	local decode
	if attr then
		decode = stat_decoders[attr]
		if not decode then return nil end
	end
	st = st or stat_ct()
	local stat = deref and stat or lstat
	local ok = stat(path, st) == 0
	if not ok then return check() end
	if not attr then
		local t = {}
		for k, decode in pairs(stat_decoders) do
			t[k] = decode(st)
		end
		return false, t
	else
		return false, decode(st)
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

function perms(path, newperms)
	if newperms then
		newperms = perms_arg(newperms, perms(path))
		--
	else
		--
	end
end

--file times -----------------------------------------------------------------

if linux then cdef[[
struct timespec {
	time_t tv_sec;
	long   tv_nsec;
};
int futimens(int fd, const struct timespec times[2]);
]] elseif osx then cdef[[
struct timeval {
	time_t  tv_sec;
	int32_t tv_usec;
};
int futimes(int fd, const struct timeval times[2]);
]] end

do

	local UTIME_OMIT = -2

	local function set_timespec(ts, t)
		if ts then
			t.tv_sec = ts
			t.tv_nsec = (ts - math.floor(ts)) * 1e9
		else
			t.tv_sec = 0
			t.tv_nsec = UTIME_OMIT
		end
	end

	local function set_timeval(ts, t)
		if ts then
			t.tv_sec = ts
			t.tv_usec = (ts - math.floor(ts)) * 1e7
		else
			t.tv_sec = 0
			t.tv_usec = UTIME_OMIT
		end
	end

	local times_ct = ffi.typeof(
		linux and 'struct timespec[2]'
		or osx and 'struct timeval[2]')
	local times
	local set_times = linux and set_timespec or osx and set_timeval
	local futimes = linux and C.futimens or osx and C.futimes

	function file.time(f, t)
		times = times or times_ct()
		if t then
			--TODO: ability to change btime on OSX
			set_times(t.atime, times[0])
			set_times(t.mtime, times[1])
			return check(futimes(f.fd, times) == 0)
		else
			st = st or stat_ct()
			local ok = fstat(f.fd, st) == 0
			if not ok then return check() end
			return {
				mtime = st_time(st.st_mtime, st.st_mtime_nsec),
				atime = st_time(st.st_atime, st.st_atime_nsec),
				ctime = st_time(st.st_ctime, st.st_ctime_nsec),
				btime = osx and st_time(st.st_btime, st.st_btime_nsec),
			}
		end
	end

end

--filesystem operations ------------------------------------------------------

cdef[[
int mkdir(const char *pathname, mode_t mode);
int rmdir(const char *pathname);
int chdir(const char *path);
char *getcwd(char *buf, size_t size);
int unlink(const char *pathname);
int rename(const char *oldpath, const char *newpath);
]]

function mkdir(path, perms)
	return check(C.mkdir(path, perms or 0x1ff) == 0)
end

function rmdir(path)
	return check(C.rmdir(path) == 0)
end

function chdir(path)
	return check(C.chdir(path) == 0)
end

local ERANGE = 34

function getcwd()
	while true do
		local buf, sz = cbuf()
		if C.getcwd(buf, sz) == nil then
			if ffi.errno() ~= ERANGE then
				return check()
			else
				buf, sz = cbuf(sz * 2)
			end
		end
		return ffi.string(buf, sz)
	end
end

function remove(path)
	return check(C.unlink(path) == 0)
end

function fs.move(oldpath, newpath)
	return check(C.rename(oldpath, newpath) == 0)
end

--hardlinks & symlinks -------------------------------------------------------

cdef[[
int link(const char *oldpath, const char *newpath);
int symlink(const char *oldpath, const char *newpath);
ssize_t readlink(const char *path, char *buf, size_t bufsize);
]]

function fs.mksymlink(link_path, target_path)
	return check(C.symlink(target_path, link_path) == 0)
end

function fs.mkhardlink(link_path, target_path)
	return check(C.link(target_path, link_path) == 0)
end

local EINVAL = 22 --on all platforms

function readlink(link_path)
	local buf, sz = cbuf()
	::again::
	local len = C.readlink(link_path, buf, sz)
	if len == -1 then
		if ffi.errno() == EINVAL then --make it legit: no symlink, no target
			return nil
		end
		return check()
	end
	if len >= sz then --we don't know if sz was enough
		buf, sz = cbuf(sz * 2)
		goto again
	end
	return ffi.string(buf, len)
end

--common paths ---------------------------------------------------------------

function fs.homedir()
	return os.getenv'HOME'
end

function fs.tmpdir()
	return os.getenv'TMPDIR'
end

function fs.appdir(appname)
	local dir = fs.homedir()
	return dir and string.format('%s/.%s', dir, appname)
end

if osx then

	--cdef'_NSGetExecutablePath(char* buf, uint32_t* bufsize);'
	cdef[[
	int32_t getpid(void);
	int proc_pidpath(int pid, void* buffer, uint32_t buffersize);
	]]

	function fs.exedir()
		local pid = C.getpid()
		if pid == -1 then return check() end
		local proc = ffi.load'proc'
		local buf, sz = cbuf()
		local sz = proc.proc_pidpath(pid, buf, sz)
		if sz <= 0 then return check() end
		return ffi.string(buf, sz)
	end

else

	function fs.exedir()

	end

end
