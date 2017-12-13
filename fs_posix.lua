
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

--TODO: sort out differences between Linux and OSX here
local o_flags = {
	accmode   = 00000003,
	rdonly    = 00000000,
	wronly    = 00000001,
	rdwr      = 00000002,
	creat     = 00000100, -- not fcntl
	excl      = 00000200, -- not fcntl
	noctty    = 00000400, -- not fcntl
	trunc     = 00001000, -- not fcntl
	append    = 00002000,
	nonblock  = 00004000,
	dsync     = 00010000, -- used to be o_sync, see below
	direct    = 00040000, -- direct disk access hint
	largefile = 00100000,
	directory = 00200000, -- must be a directory
	nofollow  = 00400000, -- don't follow links
	noatime   = 01000000,
	cloexec   = 02000000, -- set close_on_exec
	sync      = 04000000,
}

local str_opt = {
	r = {flags = 'rdonly'},
	w = {flags = 'wronly'},
	['r+'] = {flags = 'rdwr'},
	['w+'] = {flags = 'rdwr'},
}

--expose this because the frontend will set its metatype on it at the end.
file_ct = ffi.typeof[[
	struct {
		int fd;
	};
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
	return f.fd ~= -1
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

cdef(string.format([[
struct stat {
	dev_t     st_dev;     /* ID of device containing file */
	ino_t     st_ino;     /* inode number */
	mode_t    st_mode;    /* protection */
	nlink_t   st_nlink;   /* number of hard links */
	uid_t     st_uid;     /* user ID of owner */
	gid_t     st_gid;     /* group ID of owner */
	dev_t     st_rdev;    /* device ID (if special file) */
	off_t     st_size;    /* total size, in bytes */
	blksize_t st_blksize; /* blocksize for file system I/O */
	blkcnt_t  st_blocks;  /* number of 512B blocks allocated */
	time_t    st_atime;   /* time of last access */
	time_t    st_mtime;   /* time of last modification */
	time_t    st_ctime;   /* time of last status change */
};
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int fsync(int fd);
int64_t lseek(int fd, off_t offset, int whence) asm("lseek%s");
int ftruncate(int fd, off_t length);
int fstat(int fd, struct stat *buf);
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

local whences = {set = 0, cur = 1, ['end'] = 2, data = ?, hole = ?}
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

function file.size(f)
	local offset, err, errcode  = seek(f, 'cur', 0)
	if not offset then return offset, err, errcode end
	local offset1, err1, errcode1 = seek(f, 'end', 0)
	local offset, err, errcode = seek(f, 'set', offset)
	if not offset then return offset, err, errcode end
	if not offset1 then return offset1, err1, errcode1 end
	return offset1 + 1
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

local dirent_def
if osx then
	dirent_def = [[
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
	dirent_def = cdef[[
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
typedef struct  __dirstream DIR;
DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
int closedir(DIR *dirp);
]]

local dir = {}

function dir.close(dir)
	if dir:closed() then return end
	local ret = C.closedir(dir._dentry)
	dir._dentry = nil
	return check(ret == 0)
end

function dir.closed(dir)
	return dir._dentry == nil
end

function dir.next(dir)
	assert(not dir:closed(), 'directory closed')
	local entry = C.readdir(dir._dentry)
	if entry ~= nil then
		return str(entry.d_name), dir
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

function dir.type(dir)
	local t = dir._dentry.d_type
	if t == DT_UNKNOWN then
		--TODO: call lstat here
	end
	return
			t == DT_DIR  and 'dir'
		or t == DT_REG  and 'file'
		or t == DT_BLK  and 'dev_block'
		or t == DT_CHR  and 'dev_char'
		or t == DT_FIFO and 'pipe'
		or t == DT_SOCK and 'socket'
		or t == DT_LNK  and 'symlink'
end

dir_ct = ffi.typeof[[
	struct {
		DIR *_dentry;
	}
]]

function dir_iter(path)
	path = path or fs.pwd()
	local dentry = C.opendir(path)
	assert_check(dentry ~= nil)
	local dir = dir_ct()
	dir._dentry = dentry
	return dir.next, dir
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

function fs.remove(path)
	return check(C.unlink(path) == 0)
end

function fs.move(oldpath, newpath)
	return check(C.rename(oldpath, newpath) == 0)
end

--file attributes ------------------------------------------------------------

function drive(path)

end

function dev(path)

end

function inode(path)

end

function filetype(path)
	--file, dir, link, socket, pipe, char device, block device, other
end

function linknum(path)

end

function uid(path, newuid)

end

function gid(path, newgid)

end

function devtype(path)

end

function atime(path, newatime)

end

function mtime(path, newmtime)

end

function ctime(path, newctime)

end

local function getsize(path)

end

local function setsize(path, newsize)

end

function grow(path, newsize)

end

function shrink(path, newsize)

end

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
};
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


--hardlinks & symlinks -------------------------------------------------------

cdef[[
int link(const char *oldpath, const char *newpath);
int symlink(const char *oldpath, const char *newpath);
]]

function set_symlink_target(link_path, target_path)
	return check(C.symlink(target_path, link_path) == 0)
end

function set_link_target(link_path, target_path)
	return check(C.link(target_path, link_path) == 0)
end

function get_link_target(link_path)

end

function get_symlink_target(link_path)

end

--path manipulation ----------------------------------------------------------

fs.dir_sep = '/'

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

	cdef'_NSGetExecutablePath(char* buf, uint32_t* bufsize);'
	cdef[[
	pid_t getpid(void);
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
