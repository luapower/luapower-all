
--portable filesystem API for LuaJIT / Linux & OSX backend
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

--types, consts, utils -------------------------------------------------------

cdef[[
typedef size_t ssize_t; // for older luajit
typedef unsigned int mode_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef size_t time_t;
typedef int64_t off64_t;
]]

if linux then
	cdef'long syscall(int number, ...);' --stat, fstat, lstat
elseif osx then
	cdef'int fcntl(int fd, int cmd, ...);' --fallocate
end

check = check_errno

local cbuf = buffer'char[?]'

local function parse_perms(s, base)
	if type(s) == 'string' then
		local unixperms = require'unixperms'
		return unixperms.parse(s, base)
	else --pass-through
		return s or tonumber(666, 8), false
	end
end

--open/close -----------------------------------------------------------------

cdef[[
int open(const char *pathname, int flags, mode_t mode);
int close(int fd);
]]

local o_bits = {
	--Linux & OSX
	rdonly    = osx and 0x000000 or 0x000000, --access: read only
	wronly    = osx and 0x000001 or 0x000001, --access: write only
	rdwr      = osx and 0x000002 or 0x000002, --access: read + write
	accmode   = osx and 0x000003 or 0x000003, --access: ioctl() only
	append    = osx and 0x000008 or 0x000400, --append mode: write() at eof
	trunc     = osx and 0x000400 or 0x000200, --truncate the file on opening
	creat     = osx and 0x000200 or 0x000040, --create if not exist
	excl      = osx and 0x000800 or 0x000080, --create or fail (needs 'creat')
	nofollow  = osx and 0x000100 or 0x020000, --fail if file is a symlink
	directory = osx and 0x100000 or 0x010000, --open if directory or fail
	nonblock  = osx and 0x000004 or 0x000800, --non-blocking (not for files)
	async     = osx and 0x000040 or 0x002000, --enable signal-driven I/O
	sync      = osx and 0x000080 or 0x101000, --enable _file_ sync
	fsync     = osx and 0x000080 or 0x101000, --'sync'
	dsync     = osx and 0x400000 or 0x001000, --enable _data_ sync
	noctty    = osx and 0x020000 or 0x000100, --prevent becoming ctty
	cloexec   = osx and     2^24 or 0x080000, --set close-on-exec
	--Linux only
	direct    = linux and 0x004000, --don't cache writes
	noatime   = linux and 0x040000, --don't update atime
	rsync     = linux and 0x101000, --'sync'
	path      = linux and 0x200000, --open only for fd-level ops
   tmpfile   = linux and 0x410000, --create anon temp file (Linux 3.11+)
	--OSX only
	shlock    = osx and 0x000010, --get a shared lock
	exlock    = osx and 0x000020, --get an exclusive lock
	evtonly   = osx and 0x008000, --open for events only (allows unmount)
	symlink   = osx and 0x200000, --open the symlink itself
}

local str_opt = {
	r = {flags = 'rdonly'},
	w = {flags = 'creat wronly trunc'},
	['r+'] = {flags = 'rdwr'},
	['w+'] = {flags = 'creat rdwr'},
}

--expose this because the frontend will set its metatype on it at the end.
cdef[[
struct file_t {
	int fd;
};
]]
file_ct = ffi.typeof'struct file_t'

function fs.open(path, opt)
	opt = opt or 'r'
	if type(opt) == 'string' then
		opt = assert(str_opt[opt], 'invalid mode %s', opt)
	end
	local flags = flags(opt.flags or 'rdonly', o_bits)
	local mode = parse_perms(opt.perms)
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

function fs.wrap_fd(fd)
	return file_ct(fd)
end

cdef[[
int fileno(struct FILE *stream);
]]

function fs.fileno(file)
	local fd = C.fileno(file)
	return check(fd ~= -1 and fd or nil)
end

function fs.wrap_file(file)
	local fd = C.fileno(file)
	if fd == -1 then return check() end
	return fs.wrap_fd(fd)
end

--pipes ----------------------------------------------------------------------

cdef[[
int pipe(int[2]);
int fcntl(int fd, int cmd, ...);
int mkfifo(const char *pathname, mode_t mode);
]]

function fs.pipe(path, mode)
	if type(path) == 'table' then
		path, mode = path.path, path
	end
	mode = parse_perms(mode)
	if path then
		return check(C.mkfifo(path, mode) ~= 0)
	else --unnamed pipe
		local fds = ffi.new'int[2]'
		if C.pipe(fds) ~= 0 then
			return check()
		end
		return
			ffi.gc(fs.wrap_fd(fds[0]), file.close),
			ffi.gc(fs.wrap_fd(fds[1]), file.close)
	end
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

--i/o ------------------------------------------------------------------------

cdef(string.format([[
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int fsync(int fd);
int64_t lseek(int fd, int64_t offset, int whence) asm("lseek%s");
]], linux and '64' or ''))

function file.read(f, buf, sz)
	local szread = C.read(f.fd, buf, sz)
	if szread == -1 then return check() end
	return tonumber(szread)
end

function file.write(f, buf, sz)
	local szwr = C.write(f.fd, buf, sz)
	if szwr == -1 then return check() end
	return tonumber(szwr)
end

function file.flush(f)
	return check(C.fsync(f.fd) == 0)
end

function file._seek(f, whence, offset)
	local offs = C.lseek(f.fd, offset, whence)
	if offs == -1 then return check() end
	return tonumber(offs)
end

--truncate/getsize/setsize ---------------------------------------------------

cdef[[
int ftruncate(int fd, int64_t length);
]]

--NOTE: ftruncate() creates a sparse file (and so would seeking to size-1
--and writing '\0'), so we need fallocate() to reserve disk space. OTOH,
--fallocate() only works on ext4. On all other filesystems

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

	local void = ffi.typeof'void*'
	local store
	function fallocate(fd, size)
		store = store or fstore_ct(F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, 0)
		store.fst_bytesalloc = size
		local ret = C.fcntl(fd, F_PREALLOCATE, ffi.cast(void, store))
		if ret == -1 then --too fragmented, allocate non-contiguous space
			store.fst_flags = F_ALLOCATEALL
			local ret = C.fcntl(fd, F_PREALLOCATE, ffi.cast(void, store))
			if ret == -1 then return check() end
		end
		return true
	end

else

	cdef[[
	int fallocate64(int fd, int mode, off64_t offset, off64_t len);
	int posix_fallocate64(int fd, off64_t offset, off64_t len);
	]]

	function fallocate(fd, size, emulate)
		if emulate then
			return check(C.posix_fallocate64(fd, 0, size) == 0)
		else
			return check(C.fallocate64(fd, 0, 0, size) == 0)
		end
	end

end

local ENOSPC = 28 --no space left on device

function file_setsize(f, size, opt)
	opt = opt or 'fallocate emulate' --emulate Windows behavior
	if opt:find'fallocate' then
		local cursize, err, errno = file_getsize(f)
		if not cursize then return nil, err, errno end
		local ok, err, errno = fallocate(f.fd, size, opt:find'emulate')
		if not ok then
			if errno == ENOSPC then
				--when fallocate() fails because disk is full, a file is still
				--created filling up the entire disk, so shrink back the file
				--to its original size. this is courtesy: we don't check to see
				--if this fails or not, and we return the original error code.
				C.ftruncate(fd, cursize)
			end
			if opt:find'fail' then
				return nil, err, errno
			end
		end
	end
	return check(C.ftruncate(f.fd, size) == 0)
end

function file.truncate(f, opt)
	local size, err, errno = f:seek()
	if not size then return nil, err, errno end
	return file_setsize(f, size, opt)
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
		local buf, sz = cbuf(256)
		if C.getcwd(buf, sz) == nil then
			if ffi.errno() ~= ERANGE then
				return check()
			else
				buf, sz = cbuf(sz * 2)
			end
		end
		return ffi.string(buf)
	end
end

function rmfile(path)
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

local EINVAL = 22

function readlink(link_path)
	local buf, sz = cbuf(256)
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
	return os.getenv'TMPDIR' or '/tmp'
end

function fs.appdir(appname)
	local dir = fs.homedir()
	return dir and string.format('%s/.%s', dir, appname)
end

if osx then

	cdef'int _NSGetExecutablePath(char* buf, uint32_t* bufsize);'

	function fs.exepath()
		local buf, sz = cbuf(256)
		local out_sz = ffi.new('uint32_t[1]', sz)
		::again::
		if C._NSGetExecutablePath(buf, out_sz) ~= 0 then
			buf, sz = cbuf(out_sz[0])
			goto again
		end
		return (ffi.string(buf, sz):gsub('//', '/'))
	end

else

	function fs.exepath()
		return readlink'/proc/self/exe'
	end

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
]]
elseif linux then cdef[[
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
int fstat64(int fd, struct stat *buf);
int stat64(const char *path, struct stat *buf);
int lstat64(const char *path, struct stat *buf);
]]
end

local fstat, stat, lstat

local file_types = {
	[0xc000] = 'socket',
	[0xa000] = 'symlink',
	[0x8000] = 'file',
	[0x6000] = 'blockdev',
	[0x2000] = 'chardev',
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

local stat_getters = {
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

local stat_ct = ffi.typeof'struct stat'
local st
local function wrap(stat_func)
	return function(arg, attr)
		st = st or stat_ct()
		local ok = stat_func(arg, st) == 0
		if not ok then return check() end
		if attr then
			local get = stat_getters[attr]
			return get and get(st)
		else
			local t = {}
			for k, get in pairs(stat_getters) do
				t[k] = get(st)
			end
			return t
		end
	end
end
if linux then
	local void = ffi.typeof'void*'
	local int = ffi.typeof'int'
	fstat = wrap(function(f, st)
		return C.syscall(x64 and 5 or 197,
			ffi.cast(int, f.fd), ffi.cast(void, st))
	end)
	stat = wrap(function(path, st)
		return C.syscall(x64 and 4 or 195,
			ffi.cast(void, path), ffi.cast(void, st))
	end)
	lstat = wrap(function(path, st)
		return C.syscall(x64 and 6 or 196,
			ffi.cast(void, path), ffi.cast(void, st))
	end)
elseif osx then
	fstat = wrap(function(f, st) return C.fstat64(f.fd, st) end)
	stat = wrap(C.stat64)
	lstat = wrap(C.lstat64)
end

local utimes, futimes, lutimes

if linux then

	cdef[[
	struct timespec {
		time_t tv_sec;
		long   tv_nsec;
	};
	int futimens(int fd, const struct timespec times[2]);
	int utimensat(int dirfd, const char *path, const struct timespec times[2], int flags);
	]]

	local UTIME_OMIT = bit.lshift(1,30)-2

	local function set_timespec(ts, t)
		if ts then
			t.tv_sec = ts
			t.tv_nsec = (ts - math.floor(ts)) * 1e9
		else
			t.tv_sec = 0
			t.tv_nsec = UTIME_OMIT
		end
	end

	local AT_FDCWD = -100

	local ts_ct = ffi.typeof'struct timespec[2]'
	local ts
	function futimes(f, atime, mtime)
		ts = ts or ts_ct()
		set_timespec(atime, ts[0])
		set_timespec(mtime, ts[1])
		return check(C.futimens(f.fd, ts) == 0)
	end

	function utimes(path, atime, mtime)
		ts = ts or ts_ct()
		set_timespec(atime, ts[0])
		set_timespec(mtime, ts[1])
		return check(C.utimensat(AT_FDCWD, path, ts, 0) == 0)
	end

	local AT_SYMLINK_NOFOLLOW = 0x100

	function lutimes(path, atime, mtime)
		ts = ts or ts_ct()
		set_timespec(atime, ts[0])
		set_timespec(mtime, ts[1])
		return check(C.utimensat(AT_FDCWD, path, ts, AT_SYMLINK_NOFOLLOW) == 0)
	end

elseif osx then

	cdef[[
	struct timeval {
		time_t  tv_sec;
		int32_t tv_usec; // ignored by futimes()
	};
	int futimes(int fd, const struct timeval times[2]);
	int utimes(const char *path, const struct timeval times[2]);
	int lutimes(const char *path, const struct timeval times[2]);
	]]

	local function set_timeval(ts, t)
		t.tv_sec = ts
		t.tv_usec = (ts - math.floor(ts)) * 1e7 --apparently ignored
	end

	--TODO: find a way to change btime too (probably with CF or Cocoa, which
	--means many more LOC and more BS for setting one more integer).
	local tv_ct = ffi.typeof'struct timeval[2]'
	local tv
	local function wrap(utimes_func, stat_func)
		return function(arg, atime, mtime)
			tv = tv or tv_ct()
			if not atime or not mtime then
				local t, err, errno = stat_func(arg)
				if not t then return nil, err, errno end
				atime = atime or t.atime
				mtime = mtime or t.mtime
			end
			set_timeval(atime, tv[0])
			set_timeval(mtime, tv[1])
			return check(utimes_func(arg, tv) == 0)
		end
	end
	futimes = wrap(function(f, tv) return C.futimes(f.fd, tv) end, fstat)
	utimes = wrap(C.utimes, stat)
	lutimes = wrap(C.lutimes, lstat)

end

cdef[[
int fchmod(int fd,           mode_t mode);
int  chmod(const char *path, mode_t mode);
int lchmod(const char *path, mode_t mode);
]]

local function wrap(chmod_func, stat_func)
	return function(arg, perms)
		local cur_perms
		local _, is_rel = parse_perms(perms)
		if is_rel then
			local cur_perms, err, errno = stat_func(arg, 'perms')
			if not cur_perms then return nil, err, errno end
		end
		local mode = parse_perms(perms, cur_perms)
		return chmod_func(f.fd, mode) == 0
	end
end
local fchmod = wrap(function(f, mode) return C.fchmod(f.fd, mode) end, fstat)
local chmod = wrap(C.chmod, stat)
local lchmod = wrap(C.lchmod, lstat)

cdef[[
int fchown(int fd,           uid_t owner, gid_t group);
int  chown(const char *path, uid_t owner, gid_t group);
int lchown(const char *path, uid_t owner, gid_t group);
]]

local function wrap(chown_func)
	return function(arg, uid, gid)
		return chown_func(arg, uid or -1, gid or -1) == 0
	end
end
local fchown = wrap(function(f, uid, gid) return C.fchown(f.fd, uid, gid) end)
local chown = wrap(C.chown)
local lchown = wrap(C.lchown)

file_attr_get = fstat

function fs_attr_get(path, attr, deref)
	local stat = deref and stat or lstat
	return stat(path, attr)
end

local function wrap(chmod_func, chown_func, utimes_func)
	return function(arg, t)
		local ok, err, errno
		if t.perms then
			ok, err, errno = chmod_func(arg, t.perms)
			if not ok then return nil, err, errno end
		end
		if t.uid or t.gid then
			ok, err, errno = chown_func(arg, t.uid, t.gid)
			if not ok then return nil, err, errno end
		end
		if t.atime or t.mtime then
			ok, err, errno = utimes_func(arg, t.atime, t.mtime)
			if not ok then return nil, err, errno end
		end
		return ok --returns nil without err if no attr was set
	end
end

file_attr_set = wrap(fchmod, fchown, futimes)

fs_attr_set_deref = wrap(chmod, chown, utimes)
fs_attr_set_symlink = wrap(lchmod, lchown, lutimes)

function fs_attr_set(path, t, deref)
	local set = deref and fs_attr_set_deref or fs_attr_set_symlink
	return set(path, t)
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
struct dirent *readdir(DIR *dirp) asm("%s");
int closedir(DIR *dirp);
]], linux and 'readdir64' or osx and 'readdir$INODE64'))

dir_ct = ffi.typeof[[
	struct {
		DIR *_dirp;
		struct dirent* _dentry;
		int  _errno;
		int  _dirlen;
		char _dir[?];
	}
]]

function dir.close(dir)
	if dir:closed() then return end
	local ok = C.closedir(dir._dirp) == 0
	dir._dirp = nil --ignore failure, prevent double-close
	ffi.gc(dir, nil)
	return check(ok)
end

function dir_ready(dir)
	return dir._dentry ~= nil
end

function dir.closed(dir)
	return dir._dirp == nil
end

function dir_name(dir)
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

function fs_dir(path)
	local dir = dir_ct(#path)
	dir._dirlen = #path
	ffi.copy(dir._dir, path, #path)
	dir._dirp = C.opendir(path)
	if dir._dirp == nil then
		dir._errno = ffi.errno()
	end
	return dir.next, dir
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
	dir      = DT_DIR,
	file     = DT_REG,
	symlink  = DT_LNK,
	blockdev = DT_BLK,
	chardev  = DT_CHR,
	pipe     = DT_FIFO,
	socket   = DT_SOCK,
	unknown  = DT_UNKNOWN,
}

local dt_names = {
	[DT_DIR]  = 'dir',
	[DT_REG]  = 'file',
	[DT_LNK]  = 'symlink',
	[DT_BLK]  = 'blockdev',
	[DT_CHR]  = 'chardev',
	[DT_FIFO] = 'pipe',
	[DT_SOCK] = 'socket',
	[DT_UNKNOWN] = 'unknown',
}

function dir_attr_get(dir, attr)
	if attr == 'type' and dir._dentry.d_type == DT_UNKNOWN then
		--some filesystems (eg. VFAT) require this extra call to get the type.
		local type, err, errcode = lstat(dir:path(), 'type')
		if not type then
			return false, nil, err, errcode
		end
		local dt = dt_types[type]
		dir._dentry.d_type = dt --cache it
	end
	if attr == 'type' then
		return dt_names[dir._dentry.d_type]
	elseif attr == 'inode' then
		return dir._dentry.d_ino
	else
		return nil, false
	end
end

--memory mapping -------------------------------------------------------------

if linux then
	cdef'int __getpagesize();'
elseif osx then
	cdef'int getpagesize();'
end
fs.pagesize = linux and C.__getpagesize or C.getpagesize

cdef[[
int shm_open(const char *name, int oflag, mode_t mode);
int shm_unlink(const char *name);
]]

local librt = C
if linux then
	local ok, rt = pcall(ffi.load, 'rt')
	if ok then librt = rt end
end

local function open(path, write, exec, shm)
	local oflags = write and bit.bor(O_RDWR, O_CREAT) or O_RDONLY
	local perms = oct'444' +
		(write and oct'222' or 0) +
		(exec and oct'111' or 0)
	local open = shm and librt.shm_open or C.open
	local fd = open(path, oflags, perms)
	if fd == -1 then return reterr() end
	return fd
end

cdef(string.format([[
void* mmap(void *addr, size_t length, int prot, int flags,
	int fd, off64_t offset) asm("%s");
int munmap(void *addr, size_t length);
int msync(void *addr, size_t length, int flags);
int mprotect(void *addr, size_t len, int prot);
]], osx and 'mmap' or 'mmap64'))

--mmap() access flags
local PROT_READ  = 1
local PROT_WRITE = 2
local PROT_EXEC  = 4

--mmap() flags
local MAP_SHARED  = 1
local MAP_PRIVATE = 2 --copy-on-write
local MAP_FIXED   = 0x0010
local MAP_ANON    = osx and 0x1000 or 0x0020

--msync() flags
local MS_ASYNC      = 1
local MS_INVALIDATE = 2
local MS_SYNC       = osx and 0x0010 or 4

local function protect_bits(write, exec, copy)
	return bit.bor(
		PROT_READ,
		bit.bor(
			(write or copy) and PROT_WRITE or 0,
			exec and PROT_EXEC or 0))
end

function fs_map(file, write, exec, copy, size, offset, addr, tagname)

	local fd, close
	if type(file) == 'string' then
		local errmsg, errcode
		fd, errmsg, errcode = open(file, write, exec)
		if not fd then return nil, errmsg, errcode end
	elseif tagname then
		tagname = '/'..tagname
		local errmsg, errcode
		fd, errmsg, errcode = open(tagname, write, exec, true)
		if not fd then return nil, errmsg, errcode end
	end
	local f = fs.wrap_fd(fd)

	--emulate Windows behavior for missing size and size mismatches.
	if file then
		if not size then --if size not given, assume entire file
			local filesize, errmsg, errcode = f:attr'size'
			if not filesize then
				if close then close() end
				return nil, errmsg, errcode
			end
			--32bit OSX allows mapping on 0-sized files, dunno why
			if filesize == 0 then
				if close then close() end
				return nil, 'file_too_short'
			end
			size = filesize - offset
		elseif write then --if writable file too short, extend it
			local filesize = f:attr'size'
			if filesize < offset + size then
				local ok, err, errcode = f:seek(offset + size)
				if not ok then
					if close then close() end
					return nil, errmsg, errcode
				end
				local ok, errmsg, errcode = f:truncate()
				if not ok then
					if close then close() end
					return nil, errmsg, errcode
				end
			end
		else --if read/only file too short
			local filesize, errmsg, errcode = mmap.filesize(fd)
			if not filesize then
				if close then close() end
				return nil, errmsg, errcode
			end
			if filesize < offset + size then
				return nil, 'file_too_short'
			end
		end
	elseif write then
		--NOTE: lseek() is not defined for shm_open()'ed fds
		local ok = C.ftruncate(fd, size) == 0
		if not ok then return check() end
	end

	--flush the buffers before mapping to see the current view of the file.
	if file then
		local ret = C.fsync(fd)
		if ret == -1 then
			local err = ffi.errno()
			if close then close() end
			return reterr(err)
		end
	end

	local protect = protect_bits(write, exec, copy)

	local flags = bit.bor(
		copy and MAP_PRIVATE or MAP_SHARED,
		fd and 0 or MAP_ANON,
		addr and MAP_FIXED or 0)

	local addr = C.mmap(addr, size, protect, flags, fd or -1, offset)

	local ok = ffi.cast('intptr_t', addr) ~= -1
	if not ok then
		local err = ffi.errno()
		if close then close() end
		return reterr(err)
	end

	local function flush(self, async, addr, sz)
		if type(async) ~= 'boolean' then --async arg is optional
			async, addr, sz = false, async, addr
		end
		local addr = fs.aligned_addr(addr or self.addr, 'left')
		local flags = bit.bor(async and MS_ASYNC or MS_SYNC, MS_INVALIDATE)
		local ok = C.msync(addr, sz or self.size, flags) ~= 0
		if not ok then return reterr() end
		return true
	end

	local function free()
		C.munmap(addr, size)
		if close then close() end
	end

	local function unlink()
		assert(tagname, 'no tagname given')
		librt.shm_unlink(tagname)
	end

	return {addr = addr, size = size, free = free, flush = flush,
		unlink = unlink, protect = protect}
end

function fs.protect(addr, size, access)
	local write, exec = parse_access(access or 'x')
	local protect = protect_bits(write, exec)
	checkz(C.mprotect(addr, size, protect))
end

function fs.unlink_mapfile(tagname)
	librt.shm_unlink('/'..check_tagname(tagname))
end

