
--portable filesystem API for LuaJIT / POSIX API
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
setfenv(1, require'fs_common')

local C = ffi.C
local x64 = ffi.arch == 'x64'
local cdef = ffi.cdef
local osx = ffi.os == 'OSX'
local linux = ffi.os == 'Linux'

--POSIX does not define an ABI and platfoms have slightly different cdefs
--thus we have to limit support to the platforms we actually tested for.
assert(linux or osx, 'platform not Linux or OSX')

--ffi tools ------------------------------------------------------------------

check = check_errno
assert_check = assert_check_errno

local cbuf = mkbuf'char'

--common types and consts ----------------------------------------------------

cdef[[
typedef unsigned int mode_t;
typedef size_t time_t;
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
	local mode = opt.mode or 666
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
	if not ok then return check() end
	f.fd = -1
	ffi.gc(f, nil)
	return true
end

--i/o ------------------------------------------------------------------------

if linux and x64 then cdef[[
struct stat {
	unsigned long   st_dev;
	unsigned long   st_ino;
	unsigned long   st_nlink;
	unsigned int    st_mode;
	unsigned int    st_uid;
	unsigned int    st_gid;
	unsigned int    __pad0;
	unsigned long   st_rdev;
	long            st_size;
	long            st_blksize;
	long            st_blocks;
	unsigned long   st_atime;
	unsigned long   st_atime_nsec;
	unsigned long   st_mtime;
	unsigned long   st_mtime_nsec;
	unsigned long   st_ctime;
	unsigned long   st_ctime_nsec;
	long            __unused[3];
};
]] elseif linux then cdef[[
struct stat {
	unsigned long long      st_dev;
	unsigned char   __pad0[4];
	unsigned long   __st_ino;
	unsigned int    st_mode;
	unsigned int    st_nlink;
	unsigned long   st_uid;
	unsigned long   st_gid;
	unsigned long long      st_rdev;
	unsigned char   __pad3[4];
	long long       st_size;
	unsigned long   st_blksize;
	unsigned long long      st_blocks;
	unsigned long   st_atime;
	unsigned long   st_atime_nsec;
	unsigned long   st_mtime;
	unsigned int    st_mtime_nsec;
	unsigned long   st_ctime;
	unsigned long   st_ctime_nsec;
	unsigned long long      st_ino;
};
]] else cdef[[
struct timespec {
	time_t tv_sec;
	long   tv_nsec;
};
struct stat {
	uint32_t        st_dev;
	uint16_t        st_mode;
	uint16_t        st_nlink;
	uint64_t        st_ino;
	uint32_t        st_uid;
	uint32_t        st_gid;
	uint32_t        st_rdev;
	struct timespec st_atimespec;
	struct timespec st_mtimespec;
	struct timespec st_ctimespec;
	struct timespec st_birthtimespec;
	int64_t         st_size;
	int64_t         st_blocks;
	int32_t         st_blksize;
	uint32_t        st_flags;
	uint32_t        st_gen;
	int32_t         st_lspare;
	int64_t         st_qspare[2];
};
]] end

cdef(string.format([[
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int fsync(int fd);
int64_t lseek(int fd, int64_t offset, int whence) asm("lseek%s");
int fstat(int fd, struct stat *buf) asm("fstat%s");
int ftruncate(int fd, int64_t length);
]],
	linux and '64' or '',
	linux and '64' or ''
))

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

local whences = {set = 0, cur = 1, ['end'] = 2} --TODO: , data = ?, hole = ?}
function seek(f, whence, offset)
	whence = assert(whences[whence], 'invalid whence %s', whence)
	local offs = C.lseek(f.fd, offset, whence)
	if offs == -1 then return check(false) end
	return offs
end

function file.truncate(f)
	local offset, err, errcode = seek(f, 'cur', 0)
	if not offset then return offset, err, errcode end
	return check(C.ftruncate(f.fd, offset) == 0)
end

local stat_ct = ffi.typeof'struct stat'
local statbuf
function file.size(f)
	--[[
	local offset, err, errcode  = seek(f, 'cur', 0)
	if not offset then return offset, err, errcode end
	local offset1, err1, errcode1 = seek(f, 'end', 0)
	local offset, err, errcode = seek(f, 'set', offset)
	if not offset then return offset, err, errcode end
	if not offset1 then return offset1, err1, errcode1 end
	return offset1 + 1
	]]
	statbuf = statbuf or stat_ct()
	local ok, err, errcode = check(C.fstat(f.fd, statbuf) == 0)
	print(ok, err, errcode, statbuf.st_size)
	if not ok then return nil, err, errcode end
	return tonumber(statbuf.st_size)
end

--stdio streams --------------------------------------------------------------

cdef'FILE *fdopen(int fd, const char *mode);'

function file.stream(f, mode)
	local fs = C.fdopen(f, mode)
	if fs == nil then return check() end
	ffi.gc(f, nil) --fclose() will close the handle
	ffi.gc(fs, stream.close)
	return fs
end

--directory listing ----------------------------------------------------------

if osx then
	cdef[[
		/* _DARWIN_FEATURE_64_BIT_INODE is NOT defined here? */
		struct dirent {
			uint32_t d_ino;
			uint16_t d_reclen;
			uint8_t  d_type;
			uint8_t  d_namlen;
			char     d_name[256];
		};
	]]
else
	cdef[[
		struct dirent {
			int64_t  d_ino;
			size_t   d_off;
			uint16_t d_reclen;
			uint8_t  d_type;
			char     d_name[256];
		};
	]]
end

cdef[[
typedef struct DIR DIR;
DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
int closedir(DIR *dirp);
]]

dir_ct = ffi.typeof[[
	struct {
		DIR *_dir;
		struct dirent* _dirent;
		int  _dirlen;
		char _dir[?];
	}
]]

local dir = {}

function dir.close(dir)
	if dir:closed() then return end
	local ret = C.closedir(dir._dir)
	dir._dir = nil
	return check(ret == 0)
end

function dir.closed(dir)
	return dir._dir == nil
end

function dir.name(dir)
	if dir:closed() then return nil end
	return str(dir._dentry.d_name)
end

function dir.dir(dir)
	return str(dir._dir, dir._dirlen)
end

function dir.dir(dir)
	error'NYI'
end

function dir.next(dir)
	assert(not dir:closed(), 'directory closed')
	dir._dentry = C.readdir(dir._dir)
	if dir._dentry ~= nil then
		return dir:name(), dir
	else
		local errno = ffi.errno()
		dir:close()
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

local function readonly(val)
	assert(val == nil, 'attribute is read/only')
end

local function _dir_attr(dir, attr)
	if attr == 'type' then
		local t = dir._dentry.d_type
		if t == DT_UNKNOWN then
			--TODO: call lstat here
			dir._dentry.d_type = t --cache it
		end
		return
				t == DT_DIR  and 'dir' --portable
			or t == DT_REG  and 'file' --portable
			or t == DT_LNK  and 'symlink' --portable
			or t == DT_BLK  and 'dev_block'
			or t == DT_CHR  and 'dev_char'
			or t == DT_FIFO and 'pipe'
			or t == DT_SOCK and 'socket'
	elseif attr == 'ctime' then
		--TODO: emulate
	elseif attr == 'mtime' then
		--TODO: emulate
	elseif attr == 'atime' then
		--TODO: emulate
	elseif attr == 'size' then
		--TODO: emulate
	elseif attr == 'inode' then
		return tonumber(dir._dentry.d_ino)
	end
end

function dir_attr(dir, attr)
	local is_symlink = _dir_attr(dir, 'type') == 'symlink'
	return is_symlink, _dir_attr(dir, attr)
end

function dir_iter(path)
	local dir = dir_ct(#path)
	dir._dirlen = #path
	ffi.copy(dir._dir, path)
	dir._dir = C.opendir(path)
	assert_check(dir._dir ~= nil)
	return dir.next, dir
end

--file attributes ------------------------------------------------------------

function size(path, newsize)
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

function perms(path, newperms)
	if newperms then
		newperms = perms_arg(newperms, perms(path))
		--
	else
		--
	end
end

function blocks(path)

end

function blksize(path)

end

--atime and mtime ------------------------------------------------------------

local utimebuf = ffi.typeof[[
	struct {
		time_t actime;
		time_t modtime;
	}
]]

cdef[[
int utime(const char *file, const struct utimebuf *times);
]]

function fs.touch(path, atime, mtime)
	local buf
	if atime then --if not given, atime and mtime are set to current time
		mtime = mtime or atime
		buf = utimebuf()
		buf.actime = atime
		buf.modtime = mtime
	end
	return check(C.utime(path, buf) == 0)
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
		if getcwd(buf, sz) == nil then
			if ffi.errno() ~= ERANGE then
				return check()
			else
				buf, sz = cbuf(sz * 2)
			end
		end
		return str(buf, sz)
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
]]

function fs.mksymlink(link_path, target_path)
	return check(C.symlink(target_path, link_path) == 0)
end

function fs.mkhardlink(link_path, target_path)
	return check(C.link(target_path, link_path) == 0)
end

function readlink(link_path)
	--TODO: get target
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
		return str(buf, sz)
	end

else

	function fs.exedir()

	end

end
