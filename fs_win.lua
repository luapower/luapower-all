
--portable filesystem API for LuaJIT / Windows API
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
setfenv(1, require'fs_common')

local C = ffi.C
local x64 = ffi.arch == 'x64'
local cdef = ffi.cdef

assert(ffi.abi'win', 'platform not Windows')

--common types and consts ----------------------------------------------------

cdef(string.format('typedef %s ULONG_PTR;', x64 and 'int64_t' or 'int32_t'))

cdef[[
typedef void           VOID, *PVOID, *LPVOID;
typedef VOID*          HANDLE;
typedef unsigned short WORD;
typedef unsigned long  DWORD, *PDWORD, *LPDWORD;
typedef unsigned int   UINT;
typedef int            BOOL;
typedef ULONG_PTR      SIZE_T;
typedef const void*    LPCVOID;
typedef char*          LPSTR;
typedef const char*    LPCSTR;
typedef wchar_t        WCHAR;
typedef WCHAR*         LPWSTR;
typedef const WCHAR*   LPCWSTR;
typedef BOOL           *LPBOOL;
typedef int64_t        LONGLONG;
typedef LONGLONG       LARGE_INTEGER, *PLARGE_INTEGER;
typedef void*          HMODULE;
typedef unsigned char  UCHAR;
typedef unsigned short USHORT;
typedef unsigned long  ULONG;

typedef struct {
	DWORD  nLength;
	LPVOID lpSecurityDescriptor;
	BOOL   bInheritHandle;
} SECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
]]

local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

--ffi tools ------------------------------------------------------------------

local wbuf = mkbuf'WCHAR'

local uint64_union = ffi.typeof[[
	union {
		struct {
			uint32_t lo;
			uint32_t hi;
		};
		uint64_t n;
	}
]]
local u = uint64_union()
local function num64(lo, hi)
	u.lo = lo
	u.hi = hi
	return tonumber(u.n)
end

--error reporting ------------------------------------------------------------

cdef[[
DWORD GetLastError(void);

DWORD FormatMessageA(
	DWORD dwFlags,
	LPCVOID lpSource,
	DWORD dwMessageId,
	DWORD dwLanguageId,
	LPSTR lpBuffer,
	DWORD nSize,
	va_list *Arguments
);
]]

local FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

local errbuf = mkbuf'char'

local errcodes = {
	[0x02] = 'not_found', --ERROR_FILE_NOT_FOUND, CreateFileW
	[0x03] = 'not_found', --ERROR_PATH_NOT_FOUND, CreateDirectoryW
	[0x05] = 'access_denied', --ERROR_ACCESS_DENIED, CreateFileW
	[0x50] = 'already_exists', --ERROR_FILE_EXISTS, CreateFileW
	[0x91] = 'not_empty', --ERROR_DIR_NOT_EMPTY, RemoveDirectoryW
	[0xB7] = 'already_exists', --ERROR_ALREADY_EXISTS, CreateDirectoryW
}

local function check(ret, errcode)
	if ret then return ret end
	errcode = errcode or C.GetLastError()
	local buf, bufsz = errbuf(256)
	local sz = C.FormatMessageA(
		FORMAT_MESSAGE_FROM_SYSTEM,
		nil, errcode, 0, buf, bufsz, nil
	)
	if sz == 0 then return nil, 'Unknown Error' end
	return nil, str(buf, sz), errcodes[errcode] or errcode
end

local assert_check = assert_checker(check)

--utf16/utf8 conversion ------------------------------------------------------

cdef[[
int MultiByteToWideChar(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCSTR   lpMultiByteStr,
	int      cbMultiByte,
	LPWSTR   lpWideCharStr,
	int      cchWideChar
);
int WideCharToMultiByte(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCWSTR  lpWideCharStr,
	int      cchWideChar,
	LPSTR    lpMultiByteStr,
	int      cbMultiByte,
	LPCSTR   lpDefaultChar,
	LPBOOL   lpUsedDefaultChar
);
]]

local CP_UTF8 = 65001

local wcsbuf = mkbuf'WCHAR'

local function wcs(s, msz, wbuf) --string -> WCHAR[?]
	msz = msz and msz + 1 or #s + 1
	wbuf = wbuf or wcsbuf
	local wsz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, nil, 0)
	assert_check(wsz ~= 0)
	local buf = wbuf(wsz)
	local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, buf, wsz)
	assert_check(sz == wsz)
	return buf
end

local mbsbuf = mkbuf'char'

local function mbs(ws, wsz, mbuf) --WCHAR* -> string
	wsz = wsz and wsz + 1 or -1
	mbuf = mbuf or mbsbuf
	local msz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, nil, 0, nil, nil)
	assert_check(msz ~= 0)
	local buf = mbuf(msz)
	local sz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, buf, msz, nil, nil)
	assert_check(sz == msz)
	return str(buf, sz-1)
end

--open/close -----------------------------------------------------------------

cdef[[
HANDLE CreateFileW(
	LPCWSTR lpFileName,
	DWORD dwDesiredAccess,
	DWORD dwShareMode,
	LPSECURITY_ATTRIBUTES lpSecurityAttributes,
	DWORD dwCreationDisposition,
	DWORD dwFlagsAndAttributes,
	HANDLE hTemplateFile
);
BOOL CloseHandle(HANDLE hObject);
]]

--CreateFile access rights flags
local access_flags = {
	--FILE_*
	list_directory              = 1, --dirs:  allow listing
	read_data                   = 1, --files: allow reading data
	add_file                    = 2, --dirs:  allow creating files
	write_data                  = 2, --files: allow writting data
	add_subdirectory            = 4, --dirs:  allow creating subdirs
	append_data                 = 4, --files: allow appending data
	create_pipe_instance        = 4, --pipes: allow creating a pipe
	delete_child             = 0x40, --dirs:  allow deleting dir contents
	traverse                 = 0x20, --dirs:  allow traversing (not effective)
	execute                  = 0x20, --exes:  allow exec'ing
	read_attributes          = 0x80, --allow reading attrs
	write_attributes        = 0x100, --allow writting attrs
	read_ea                     = 8, --allow reading extended attrs
	write_ea                 = 0x10, --allow writting extended attrs
	read_control          = 0x20000, --allow reading the security descriptor
	standard_rights_read  = 0x20000,
	standard_rights_write = 0x20000,
	--GENERIC_*
	read               = 0x80000000,
	write              = 0x40000000,
	execute            = 0x20000000,
	all                = 0x10000000,
}

--CreateFile sharing flags
local sharing_flags = {
	--FILE_SHARE_*
	read   = 0x00000001, --allow us/others to read
	write  = 0x00000002, --allow us/others to write
	delete = 0x00000004, --allow us/others to delete or rename
}

--CreateFile creation disposition flags
local creation_flags = {
	create_new        = 1, --create or fail
	create_always     = 2, --open or create + truncate
	open_existing     = 3, --open or fail
	open_always       = 4, --open or create
	truncate_existing = 5, --open + truncate or fail
}

--CreateFile flags & attributes
local attr_flags = {
	--FILE_ATTRIBUTE_*
	readonly             = 0x00000001,
	hidden               = 0x00000002,
	system               = 0x00000004,
	directory            = 0x00000010,
	archive              = 0x00000020,
	device               = 0x00000040,
	normal               = 0x00000080,
	temporary            = 0x00000100,
	sparse_file          = 0x00000200,
	reparse_point        = 0x00000400,
	compressed           = 0x00000800,
	offline              = 0x00001000,
	not_content_indexed  = 0x00002000,
	encrypted            = 0x00004000,
	virtual              = 0x00010000,
}
local flag_flags = {
	--FILE_FLAG_*
	write_through        = 0x80000000,
	overlapped           = 0x40000000,
	no_buffering         = 0x20000000,
	random_access        = 0x10000000,
	sequential_scan      = 0x08000000,
	delete_on_close      = 0x04000000,
	backup_semantics     = 0x02000000,
	posix_semantics      = 0x01000000,
	open_reparse_point   = 0x00200000,
	open_no_recall       = 0x00100000,
	first_pipe_instance  = 0x00080000,
}

local str_opt = {
	r = {access = 'read', creation = 'open_existing'},
	w = {access = 'write', creation = 'create_always'},
	['r+'] = {access = 'read write', creation = 'open_existing'},
	['w+'] = {access = 'read write', creation = 'create_always'},
}

--expose this because the frontend will set its metatype at the end.
file_ct = ffi.typeof[[
	struct {
		HANDLE handle;
	}
]]

function fs.open(path, opt)
	opt = opt or 'r'
	if type(opt) == 'string' then
		opt = assert(str_opt[opt], 'invalid option %s', opt)
	end
	local access   = flags(opt.access or 'read', access_flags)
	local sharing  = flags(opt.sharing or 'read write', sharing_flags)
	local creation = flags(opt.creation or 'open_existing', creation_flags)
	local attflags = bit.bor(
		flags(opt.flags, flag_flags),
		flags(opt.attrs, attr_flags))
	local h = C.CreateFileW(
		wcs(path), access, sharing, nil, creation, attflags, nil)
	if h == INVALID_HANDLE_VALUE then return check() end
	return ffi.gc(file_ct(h), file.close)
end

function file.closed(f)
	return f.handle == INVALID_HANDLE_VALUE
end

function file.close(f)
	if f:closed() then return end
	local ret = C.CloseHandle(f.handle)
	if ret == 0 then return check(false) end
	f.handle = INVALID_HANDLE_VALUE
	ffi.gc(f, nil)
	return true
end

--i/o ------------------------------------------------------------------------

cdef[[
typedef struct _OVERLAPPED {
	ULONG_PTR Internal;
	ULONG_PTR InternalHigh;
	union {
		struct {
			DWORD Offset;
			DWORD OffsetHigh;
		};
	  PVOID Pointer;
	};
	HANDLE hEvent;
} OVERLAPPED, *LPOVERLAPPED;

typedef struct _OVERLAPPED_ENTRY {
	ULONG_PTR    lpCompletionKey;
	LPOVERLAPPED lpOverlapped;
	ULONG_PTR    Internal;
	DWORD        dwNumberOfBytesTransferred;
} OVERLAPPED_ENTRY, *LPOVERLAPPED_ENTRY;

BOOL ReadFile(
	HANDLE       hFile,
	LPVOID       lpBuffer,
	DWORD        nNumberOfBytesToRead,
	LPDWORD      lpNumberOfBytesRead,
	LPOVERLAPPED lpOverlapped
);

BOOL WriteFile(
	HANDLE       hFile,
	LPCVOID      lpBuffer,
	DWORD        nNumberOfBytesToWrite,
	LPDWORD      lpNumberOfBytesWritten,
	LPOVERLAPPED lpOverlapped
);

BOOL FlushFileBuffers(HANDLE hFile);

BOOL SetFilePointerEx(
	HANDLE         hFile,
	LARGE_INTEGER  liDistanceToMove,
	PLARGE_INTEGER lpNewFilePointer,
	DWORD          dwMoveMethod
);

BOOL SetEndOfFile(HANDLE hFile);
BOOL GetFileSizeEx(HANDLE hFile, PLARGE_INTEGER lpFileSize);
]]

local dwbuf = ffi.new'DWORD[1]'
local u64buf = ffi.new'uint64_t[1]'

function file.read(f, buf, sz)
	local ok = C.ReadFile(f.handle, buf, sz, dwbuf, nil) ~= 0
	if not ok then return check() end
	return dwbuf[0]
end

function file.write(f, buf, sz)
	local ok = C.WriteFile(f.handle, buf, sz, dwbuf, nil) ~= 0
	if not ok then return check() end
	return dwbuf[0]
end

function file.flush(f)
	return check(C.FlushFileBuffers(f.handle) ~= 0)
end

local whences = {set = 0, cur = 1, ['end'] = 2}
function seek(f, whence, offset)
	whence = assert(whences[whence], 'invalid whence %s', whence)
	local ok = C.SetFilePointerEx(f.handle, offset, u64buf, whence) ~= 0
	if not ok then return check() end
	return tonumber(u64buf[0])
end

function file.truncate(f)
	return check(C.SetEndOfFile(f.handle) ~= 0)
end

function file.size(f)
	local ok = C.GetFileSizeEx(f.handle, u64buf) ~= 0
	if not ok then return check() end
	return tonumber(u64buf[0])
end

--stdio streams --------------------------------------------------------------

cdef[[
FILE *_fdopen(int fd, const char *mode);
int _open_osfhandle (HANDLE osfhandle, int flags);
]]

function file.stream(f, mode)
	local flags = 0
	local fd = C._open_osfhandle(f.handle, flags)
	if fd == -1 then return check_errno() end
	local fs = C._fdopen(fd, mode)
	if fs == nil then return check_errno() end
	ffi.gc(f, nil) --fclose() will close the handle
	ffi.gc(fs, stream.close)
	return fs
end

--file attributes decoding ---------------------------------------------------

cdef[[
typedef struct {
	DWORD dwLowDateTime;
	DWORD dwHighDateTime;
} FILETIME;
]]

--FILETIME stores time in hundred-nanoseconds from `1601-01-01 00:00:00`.
--timestamp stores the time in seconds from `1970-01-01 00:00:00`.
local function timestamp(filetime) --convert FILETIME -> timestamp
	local ns = num64(filetime.dwLowDateTime, filetime.dwHighDateTime)
	return ns * 1e-7 - 11644473600
end

local IO_REPARSE_TAG_SYMLINK = 0xA000000C

local function is_symlink(data, reserved0)
	return bit.band(data.dwFileAttributes, attr_flags.reparse_point) ~= 0
		and (not reserved0 or reserved0 == IO_REPARSE_TAG_SYMLINK)
end

--NOTE: this should not return nil so we can tell ret vals from errors!
local function _get_attr(data, k, reserved0)
	if not k then
		local t = {}
		t.type  = _get_attr(data, 'type' , reserved0)
		t.ctime = _get_attr(data, 'ctime', reserved0)
		t.mtime = _get_attr(data, 'mtime', reserved0)
		t.atime = _get_attr(data, 'atime', reserved0)
		t.size  = _get_attr(data, 'size' , reserved0)
		for flag, mask in pairs(attr_flags) do
			t[flag] = _get_attr(data, flag) or nil
		end
		return t
	elseif k == 'type' then
		local bits = data.dwFileAttributes
		return
			is_symlink(data, reserved0) and 'symlink'
			or bit.band(bits, attr_flags.directory) ~= 0 and 'dir'
			or bit.band(bits, attr_flags.device) ~= 0    and 'dev'
			or 'file'
	elseif k == 'ctime' then
		return timestamp(data.ftCreationTime)
	elseif k == 'mtime' then
		return timestamp(data.ftLastWriteTime)
	elseif k == 'atime' then
		return timestamp(data.ftLastAccessTime)
	elseif k == 'size' then
		return num64(data.nFileSizeLow, data.nFileSizeHigh)
	elseif attr_flags[k] then
		return bit.band(attr_flags[k], data.dwFileAttributes) ~= 0
	else
		return false
	end
end

local function get_attr(data, k, reserved0)
	return is_symlink(data, reserved0), _get_attr(data, k, reserved0)
end

--directory listing ----------------------------------------------------------

cdef[[
enum {
	MAX_PATH = 260
};

typedef struct {
	DWORD dwFileAttributes;
	FILETIME ftCreationTime;
	FILETIME ftLastAccessTime;
	FILETIME ftLastWriteTime;
	DWORD nFileSizeHigh;
	DWORD nFileSizeLow;
	DWORD dwReserved0;
	DWORD dwReserved1;
	WCHAR cFileName[MAX_PATH];
	WCHAR cAlternateFileName[14];
} WIN32_FIND_DATAW, *LPWIN32_FIND_DATAW;

HANDLE FindFirstFileW(LPCWSTR, LPWIN32_FIND_DATAW);
BOOL FindNextFileW(HANDLE, LPWIN32_FIND_DATAW);
BOOL FindClose(HANDLE);
]]

function dir.closed(dir)
	return dir._handle == 0
end

function dir.close(dir)
	if dir:closed() then return end
	local h = dir._handle
	dir._handle = nil
	return check(C.FindClose(h) ~= 0)
end

local ERROR_NO_MORE_FILES = 18

function dir.name(dir)
	if dir:closed() then return nil end
	return mbs(dir._fdata.cFileName)
end

function dir.dir(dir)
	return str(dir._dir, dir._dirlen)
end

--TODO: remove last arg so that next can be called directly without arg!
function dir.next(dir, last)
	assert(not dir:closed(), 'directory closed')
	if not last then
		return dir:name(), dir
	else
		local ret = C.FindNextFileW(dir._handle, dir._fdata)
		if ret ~= 0 then
			return dir:name(), dir
		else
			local errcode = C.GetLastError()
			dir:close()
			if errcode == ERROR_NO_MORE_FILES then
				return nil
			end
			return check(false, errcode)
		end
	end
end

function dir_attr(dir, attr)
	return get_attr(dir._fdata, attr, dir._fdata.dwReserved0)
end

dir_ct = ffi.typeof[[
	struct {
		HANDLE _handle;
		WIN32_FIND_DATAW _fdata;
		int  _dirlen;
		char _dir[?];
	}
]]

function dir_iter(path)
	assert(not path:find'[%*%?]') --no globbing allowed
	local dir = dir_ct(#path)
	dir._dirlen = #path
	ffi.copy(dir._dir, path)
	local h = C.FindFirstFileW(wcs(path .. '\\*'), dir._fdata)
	assert_check(h ~= INVALID_HANDLE_VALUE)
	dir._handle = h
	return dir.next, dir
end


--file attributes ------------------------------------------------------------

cdef[[
typedef enum {
    GetFileExInfoStandard
} GET_FILEEX_INFO_LEVELS;

typedef struct {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
} WIN32_FILE_ATTRIBUTE_DATA;

DWORD GetFileAttributesExW(
	LPCWSTR lpFileName,
	GET_FILEEX_INFO_LEVELS fInfoLevelId,
	WIN32_FILE_ATTRIBUTE_DATA* lpFileInformation
);
]]

local data = ffi.new'WIN32_FILE_ATTRIBUTE_DATA'
function fs_attr(path, attr, deref_symlinks)
	local ok = C.GetFileAttributesExW(
		wcs(path),
		C.GetFileExInfoStandard,
		data) ~= 0
	if not ok then
		return check(false)
	end
	return get_attr(data, attr)
end

--filesystem operations ------------------------------------------------------

cdef[[
BOOL CreateDirectoryW(LPCWSTR, LPSECURITY_ATTRIBUTES);
BOOL RemoveDirectoryW(LPCWSTR);
int SetCurrentDirectoryW(LPCWSTR lpPathName);
DWORD GetCurrentDirectoryW(DWORD nBufferLength, LPWSTR lpBuffer);
BOOL DeleteFileW(LPCWSTR lpFileName);
BOOL MoveFileExW(
	LPCWSTR lpExistingFileName,
	LPCWSTR lpNewFileName,
	DWORD   dwFlags
);
]]

function mkdir(path)
	return check(C.CreateDirectoryW(wcs(path), nil) ~= 0)
end

function rmdir(path)
	return check(C.RemoveDirectoryW(wcs(path)) ~= 0)
end

function chdir(path)
	return check(C.SetCurrentDirectoryW(wcs(path)) ~= 0)
end

function getcwd()
	local sz = C.GetCurrentDirectoryW(0, nil)
	if sz == 0 then return check() end
	local buf = wbuf(sz)
	local sz = C.GetCurrentDirectoryW(sz, buf)
	if sz == 0 then return check() end
	return mbs(buf, sz)
end

function remove(path)
	return check(C.DeleteFileW(wcs(path)) ~= 0)
end

local move_flags = {
	--MOVEFILE_*
	replace_existing      =  0x1,
	copy_allowed          =  0x2,
	delay_until_reboot    =  0x4,
	fail_if_not_trackable = 0x20,
	write_through         =  0x8,
}

local default_move_opt = {'replace_existing', 'write_through'} --posix
function fs.move(oldpath, newpath, opt)
	return check(C.MoveFileExW(
		wcs(oldpath),
		wcs(newpath, nil, wbuf),
		flags(opt or default_move_opt, move_flags)
	) ~= 0)
end

--symlinks & hardlinks -------------------------------------------------------

cdef[[
BOOL CreateSymbolicLinkW (
	LPCWSTR lpSymlinkFileName,
	LPCWSTR lpTargetFileName,
	DWORD dwFlags
);
BOOL CreateHardLinkW(
	LPCWSTR lpFileName,
	LPCWSTR lpExistingFileName,
	LPSECURITY_ATTRIBUTES lpSecurityAttributes
);

BOOL DeviceIoControl(
	HANDLE       hDevice,
	DWORD        dwIoControlCode,
	LPVOID       lpInBuffer,
	DWORD        nInBufferSize,
	LPVOID       lpOutBuffer,
	DWORD        nOutBufferSize,
	LPDWORD      lpBytesReturned,
	LPOVERLAPPED lpOverlapped
);
]]

local SYMBOLIC_LINK_FLAG_DIRECTORY = 0x1

function fs.mksymlink(link_path, target_path, is_dir)
	local flags = is_dir and SYMBOLIC_LINK_FLAG_DIRECTORY or 0
	return check(C.CreateSymbolicLinkW(
		wcs(link_path),
		wcs(target_path, nil, wbuf),
		flags) ~= 0)
end

function fs.mkhardlink(link_path, target_path)
	return check(C.CreateHardLinkW(
		wcs(link_path),
		wcs(target_path, nil, wbuf),
		nil) ~= 0)
end

do
	local function CTL_CODE(DeviceType, Function, Method, Access)
		return bit.bor(
			bit.lshift(DeviceType, 16),
			bit.lshift(Access, 14),
			bit.lshift(Function, 2),
			Method)
	end
	local FILE_DEVICE_FILE_SYSTEM = 0x00000009
	local METHOD_BUFFERED         = 0
	local FILE_ANY_ACCESS         = 0
	local FSCTL_GET_REPARSE_POINT = CTL_CODE(
		FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS)

	local readlink_opt = {
		access = 'read',
		share = 'read write delete',
		creation = 'open_existing',
		flags = 'backup_semantics open_reparse_point',
		attrs = 'reparse_point',
	}

	local REPARSE_DATA_BUFFER = ffi.typeof[[
		struct {
			ULONG  ReparseTag;
			USHORT ReparseDataLength;
			USHORT Reserved;
			USHORT SubstituteNameOffset;
			USHORT SubstituteNameLength;
			USHORT PrintNameOffset;
			USHORT PrintNameLength;
			ULONG  Flags;
			WCHAR  PathBuffer[?];
		}
	]]

	local szbuf = ffi.new'DWORD[1]'
	local buf, sz = nil, 256

	local ERROR_INSUFFICIENT_BUFFER = 122
	local ERROR_MORE_DATA = 234

	function readlink(path)
		local f, err, errcode = fs.open(path, readlink_opt)
		if not f then return nil, err, errcode end
		::again::
		local buf = buf or REPARSE_DATA_BUFFER(sz)
		local ok = C.DeviceIoControl(
			f.handle, FSCTL_GET_REPARSE_POINT, nil, 0,
			buf, ffi.sizeof(buf), szbuf, nil) ~= 0
		if not ok then
			local err = C.GetLastError()
			if err == ERROR_INSUFFICIENT_BUFFER or err == ERROR_MORE_DATA then
				buf, sz = nil, sz * 2
				goto again
			end
			f:close()
			return check(false)
		end
		f:close()
		return mbs(
			buf.PathBuffer + buf.SubstituteNameOffset / 2,
			buf.SubstituteNameLength / 2)
	end
end

--common paths ---------------------------------------------------------------

cdef[[
DWORD GetTempPathW(DWORD nBufferLength, LPWSTR lpBuffer);
DWORD GetModuleFileNameW(HMODULE hModule, LPWSTR lpFilename, DWORD nSize);
]]

function fs.homedir()
	return os.getenv'USERPROFILE'
end

function fs.tmpdir()
	local buf, bufsz = wbuf()
	local sz = C.GetTempPathW(bufsz, buf)
	if sz == 0 then return check() end
	if sz > bufsz then
		buf, bufsz = wbuf(sz)
		local sz = C.GetTempPathW(bufsz, buf)
		assert(sz <= bufsz)
		if sz == 0 then return check() end
	end
	return str(buf, sz-1) --strip trailing '\'
end

function fs.appdir(appname)
	local dir = os.getenv'LOCALAPPDATA'
	return dir and string.format('%s\\%s', dir, appname)
end

function fs.exedir()
	--C.GetModuleFileNameW(nil, ...)
end

