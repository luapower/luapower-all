
--portable filesystem API for LuaJIT / Windows backend
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
local bit = require'bit'
setfenv(1, require'fs_common')

local C = ffi.C

assert(win, 'platform not Windows')

--types, consts, utils -------------------------------------------------------

if x64 then
	cdef'typedef int64_t ULONG_PTR;'
else
	cdef'typedef int32_t ULONG_PTR;'
end

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
typedef void*          HMODULE;
typedef unsigned char  UCHAR;
typedef unsigned short USHORT;
typedef long           LONG;
typedef unsigned long  ULONG;
typedef long long      LONGLONG;

typedef union {
	struct {
		DWORD LowPart;
		LONG HighPart;
	};
	struct {
		DWORD LowPart;
		LONG HighPart;
	} u;
	LONGLONG QuadPart;
} LARGE_INTEGER, *PLARGE_INTEGER;

typedef struct {
	DWORD  nLength;
	LPVOID lpSecurityDescriptor;
	BOOL   bInheritHandle;
} SECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
]]

local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

local wbuf = mkbuf'WCHAR'
local libuf = ffi.new'LARGE_INTEGER[1]'

local m = ffi.new[[
	union {
		struct { uint32_t lo; uint32_t hi; };
		uint64_t x;
	}
]]
local function split_uint64(x)
	m.x = x
	return m.hi, m.lo
end
local function join_uint64(hi, lo)
	m.hi, m.lo = hi, lo
	return m.x
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

local error_classes = {
	[0x002] = 'not_found', --ERROR_FILE_NOT_FOUND, CreateFileW
	[0x003] = 'not_found', --ERROR_PATH_NOT_FOUND, CreateDirectoryW
	[0x005] = 'access_denied', --ERROR_ACCESS_DENIED, CreateFileW
	[0x050] = 'already_exists', --ERROR_FILE_EXISTS, CreateFileW
	[0x091] = 'not_empty', --ERROR_DIR_NOT_EMPTY, RemoveDirectoryW
	[0x0b7] = 'already_exists', --ERROR_ALREADY_EXISTS, CreateDirectoryW
	[0x10B] = 'not_found', --ERROR_DIRECTORY, FindFirstFileW

	--TODO: mmap
	[0x0008] = 'file_too_short', --readonly file too short
	[0x0057] = 'out_of_mem', --size or address too large
	[0x0070] = 'disk_full',
	[0x01E7] = 'out_of_mem', --address in use
	[0x03ee] = 'file_too_short', --file has zero size
	[0x05af] = 'out_of_mem', --swapfile too short

}

local function check(ret, errcode)
	if ret then return ret end
	errcode = errcode or C.GetLastError()
	local buf, bufsz = errbuf(256)
	local sz = C.FormatMessageA(
		FORMAT_MESSAGE_FROM_SYSTEM, nil, errcode, 0, buf, bufsz, nil)
	local err =
		error_classes[errcode]
		or (sz > 0
			and ffi.string(buf, sz):gsub('[\r\n]+$', '')
			or 'Error '..errcode)
	return ret, err, errcode
end

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
	assert(wsz > 0) --should never happen otherwise
	local buf = wbuf(wsz)
	local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, buf, wsz)
	assert(sz == wsz) --should never happen otherwise
	return buf
end

local mbsbuf = mkbuf'char'

local function mbs(ws, wsz, mbuf) --WCHAR* -> string
	wsz = wsz and wsz + 1 or -1
	mbuf = mbuf or mbsbuf
	local msz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, nil, 0, nil, nil)
	assert(msz > 0) --should never happen otherwise
	local buf = mbuf(msz)
	local sz = C.WideCharToMultiByte(
		CP_UTF8, 0, ws, wsz, buf, msz, nil, nil)
	assert(sz == msz) --should never happen otherwise
	return ffi.string(buf, sz-1)
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
local t = {
	--FILE_* (specific access rights)
	list_directory           = 1, --dirs:  allow listing
	read_data                = 1, --files: allow reading data
	add_file                 = 2, --dirs:  allow creating files
	write_data               = 2, --files: allow writting data
	add_subdirectory         = 4, --dirs:  allow creating subdirs
	append_data              = 4, --files: allow appending data
	create_pipe_instance     = 4, --pipes: allow creating a pipe
	delete_child          = 0x40, --dirs:  allow deleting dir contents
	traverse              = 0x20, --dirs:  allow traversing (not effective)
	execute               = 0x20, --exes:  allow exec'ing
	read_attributes       = 0x80, --allow reading attrs
	write_attributes     = 0x100, --allow setting attrs
	read_ea                  = 8, --allow reading extended attrs
	write_ea              = 0x10, --allow writting extended attrs
	--object's standard access rights
	delete       = 0x00010000,
	read_control = 0x00020000, --allow r/w the security descriptor
	write_dac    = 0x00040000,
	write_owner  = 0x00080000,
	synchronize  = 0x00100000,
	--STANDARD_RIGHTS_*
	standard_rights_required = 0x000F0000,
	standard_rights_read     = 0x00020000, --read_control
	standard_rights_write    = 0x00020000, --read_control
	standard_rights_execute  = 0x00020000, --read_control
	standard_rights_all      = 0x001F0000,
	--GENERIC_*
	generic_read    = 0x80000000,
	generic_write   = 0x40000000,
	generic_execute = 0x20000000,
	generic_all     = 0x10000000,
}
--FILE_ALL_ACCESS
t.all_access = bit.bor(
	t.standard_rights_required,
	t.synchronize,
	0x1ff)
--FILE_GENERIC_*
t.read = bit.bor(
	t.standard_rights_read,
	t.read_data,
   t.read_attributes,
	t.read_ea,
	t.synchronize)
t.write = bit.bor(
	t.standard_rights_write,
	t.write_data,
   t.write_attributes,
	t.write_ea,
	t.append_data,
	t.synchronize)
t.execute = bit.bor(
	t.standard_rights_execute,
	t.read_attributes,
	t.execute,
	t.synchronize)
local access_bits = t

--CreateFile sharing flags
local sharing_bits = {
	--FILE_SHARE_*
	read   = 0x00000001, --allow us/others to read
	write  = 0x00000002, --allow us/others to write
	delete = 0x00000004, --allow us/others to delete or rename
}

--CreateFile creation disposition flags
local creation_bits = {
	create_new        = 1, --create or fail
	create_always     = 2, --open or create + truncate
	open_existing     = 3, --open or fail
	open_always       = 4, --open or create
	truncate_existing = 5, --open + truncate or fail
}

local FILE_ATTRIBUTE_NORMAL = 0x00000080 --for when no bits are set

--CreateFile flags & attributes
local attr_bits = {
	--FILE_ATTRIBUTE_*
	readonly      = 0x00000001,
	hidden        = 0x00000002,
	system        = 0x00000004,
	archive       = 0x00000020,
	temporary     = 0x00000100,
	sparse_file   = 0x00000200,
	reparse_point = 0x00000400,
	compressed    = 0x00000800,
	directory     = 0x00000010,
	device        = 0x00000040,
	--offline     = 0x00001000, --reserved (used by Remote Storage)
	not_indexed   = 0x00002000, --FILE_ATTRIBUTE_NOT_CONTENT_INDEXED
	encrypted     = 0x00004000,
	--virtual     = 0x00010000, --reserved
}

local flag_bits = {
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
	r = {
		access = 'read',
		creation = 'open_existing',
		flags = 'backup_semantics'},
	w = {
		access = 'write file_read_attributes',
		creation = 'create_always',
		flags = 'backup_semantics'},
	['r+'] = {
		access = 'read write',
		creation = 'open_existing',
		flags = 'backup_semantics'},
	['w+'] = {
		access = 'read write',
		creation = 'create_always',
		flags = 'backup_semantics'},
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
	local access   = flags(opt.access or 'read', access_bits)
	local sharing  = flags(opt.sharing or 'read', sharing_bits)
	local creation = flags(opt.creation or 'open_existing', creation_bits)
	local attrbits = flags(opt.attrs, attr_bits)
	attrbits = attrbits == 0 and FILE_ATTRIBUTE_NORMAL or attrbits
	local flagbits = flags(opt.flags, flag_bits)
	local attflags = bit.bor(attrbits, flagbits)
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

function fs.wrap_handle(h)
	return file_ct(h)
end

cdef[[
int _fileno(struct FILE *stream);
HANDLE _get_osfhandle(int fd);
]]

function fs.wrap_fd(fd)
	local h = C._get_osfhandle(fd)
	if h == nil then return check_errno() end
	return fs.wrap_handle(h)
end

function fs.fileno(file)
	local fd = C._fileno(file)
	return check_errno(fd ~= -1 and fd or nil)
end

function fs.wrap_file(file)
	local fd, err, errno = fs.fileno(file)
	if not fd then return nil, err, errno end
	return fs.wrap_fd(fd)
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
]]

local dwbuf = ffi.new'DWORD[1]'

function file.read(f, buf, sz)
	local ok = C.ReadFile(f.handle, buf, sz, dwbuf, nil) ~= 0
	--print(sz, ok, file_seek(f, 1, 0), file_getsize(f))
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

local ofsbuf = ffi.new'LARGE_INTEGER[1]'
function file_seek(f, whence, offset)
	ofsbuf[0].QuadPart = offset
	local ok = C.SetFilePointerEx(f.handle, ofsbuf[0], libuf, whence) ~= 0
	if not ok then return check() end
	return tonumber(libuf[0].QuadPart)
end

--truncate/getsize/setsize ---------------------------------------------------

cdef[[
BOOL SetEndOfFile(HANDLE hFile);
BOOL GetFileSizeEx(HANDLE hFile, PLARGE_INTEGER lpFileSize);
]]

--NOTE: seeking beyond file size and then truncating the file incurs no delay
--on NTFS, but that's not because the file becomes sparse (it doesn't, and
--disk space _is_ reserved), but because the extra zero bytes are not written
--until the first write call _that requires it_. This is a good optimization
--since usually the file will be written sequentially after the truncation
--in which case those extra zero bytes will never get a chance to be written.
function file.truncate(f, opt)
	return check(C.SetEndOfFile(f.handle) ~= 0)
end

function file_getsize(f)
	local ok = C.GetFileSizeEx(f.handle, libuf) ~= 0
	if not ok then return check() end
	return tonumber(libuf[0].QuadPart)
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

function rmfile(path)
	return check(C.DeleteFileW(wcs(path)) ~= 0)
end

local move_bits = {
	--MOVEFILE_*
	replace_existing      =  0x1,
	copy_allowed          =  0x2,
	delay_until_reboot    =  0x4,
	fail_if_not_trackable = 0x20,
	write_through         =  0x8, --for when copy_allowed
}

--TODO: MoveFileExW is actually NOT atomic.
--Use SetFileInformationByHandle with FILE_RENAME_INFO and ReplaceIfExists
--which is atomic and also works on open handles which is even more atomic :)
local default_move_opt = 'replace_existing write_through' --posix
function fs.move(oldpath, newpath, opt)
	return check(C.MoveFileExW(
		wcs(oldpath),
		wcs(newpath, nil, wbuf),
		flags(opt or default_move_opt, move_bits)
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
		sharing = 'read write delete',
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
	local buf, sz = nil, 128

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
	return ffi.string(buf, sz-1) --strip trailing '\'
end

function fs.appdir(appname)
	local dir = os.getenv'LOCALAPPDATA'
	return dir and string.format('%s\\%s', dir, appname)
end

function fs.exedir()
	--C.GetModuleFileNameW(nil, ...)
end

--file attributes ------------------------------------------------------------

cdef[[
typedef struct {
	DWORD dwLowDateTime;
	DWORD dwHighDateTime;
} FILETIME;

typedef struct {
	DWORD    dwFileAttributes;
	FILETIME ftCreationTime;
	FILETIME ftLastAccessTime;
	FILETIME ftLastWriteTime;
	DWORD    dwVolumeSerialNumber;
	DWORD    nFileSizeHigh;
	DWORD    nFileSizeLow;
	DWORD    nNumberOfLinks;
	DWORD    nFileIndexHigh;
	DWORD    nFileIndexLow;
} BY_HANDLE_FILE_INFORMATION, *LPBY_HANDLE_FILE_INFORMATION;

BOOL GetFileInformationByHandle(
	HANDLE                       hFile,
	LPBY_HANDLE_FILE_INFORMATION lpFileInformation
);

typedef enum {
	FileBasicInfo                   = 0,
	FileStandardInfo                = 1,
	FileNameInfo                    = 2,
	FileRenameInfo                  = 3,
	FileDispositionInfo             = 4,
	FileAllocationInfo              = 5,
	FileEndOfFileInfo               = 6,
	FileStreamInfo                  = 7,
	FileCompressionInfo             = 8,
	FileAttributeTagInfo            = 9,
	FileIdBothDirectoryInfo         = 10,
	FileIdBothDirectoryRestartInfo  = 11,
	FileIoPriorityHintInfo          = 12,
	FileRemoteProtocolInfo          = 13,
	FileFullDirectoryInfo           = 14,
	FileFullDirectoryRestartInfo    = 15,
	FileStorageInfo                 = 16,
	FileAlignmentInfo               = 17,
	FileIdInfo                      = 18,
	FileIdExtdDirectoryInfo         = 19,
	FileIdExtdDirectoryRestartInfo  = 20,
} FILE_INFO_BY_HANDLE_CLASS;

typedef struct {
	LARGE_INTEGER CreationTime;
	LARGE_INTEGER LastAccessTime;
	LARGE_INTEGER LastWriteTime;
	LARGE_INTEGER ChangeTime;
	DWORD         FileAttributes;
} FILE_BASIC_INFO, *PFILE_BASIC_INFO;

BOOL GetFileInformationByHandleEx(
	HANDLE                    hFile,
	FILE_INFO_BY_HANDLE_CLASS FileInformationClass,
	LPVOID                    lpFileInformation,
	DWORD                     dwBufferSize
);

BOOL SetFileInformationByHandle(
	HANDLE                    hFile,
	FILE_INFO_BY_HANDLE_CLASS FileInformationClass,
	LPVOID                    lpFileInformation,
	DWORD                     dwBufferSize
);

typedef enum {
    GetFileExInfoStandard
} GET_FILEEX_INFO_LEVELS;

DWORD GetFinalPathNameByHandleW(
	HANDLE hFile,
	LPWSTR lpszFilePath,
	DWORD  cchFilePath,
	DWORD  dwFlags
);
]]

--FILETIME stores time in hundred-nanoseconds from `1601-01-01 00:00:00`.
--timestamp stores the time in seconds from `1970-01-01 00:00:00`.

local TS_FT_DIFF = 11644473600 --seconds

local function filetime(ts) --convert timestamp -> FILETIME
	return (ts + TS_FT_DIFF) * 1e7
end

local function timestamp(ft) --convert FILETIME as uint64 -> timestamp
	return tonumber(ft) * 1e-7 - TS_FT_DIFF
end

local function ft_timestamp(filetime) --convert FILETIME -> timestamp
	return timestamp(filetime.dwHighDateTime * 2^32 + filetime.dwLowDateTime)
end

local function filesize(high, low)
	return high * 2^32 + low
end

local function attrbit(bits, k)
	if k ~= 'directory' and k ~= 'device' and attr_bits[k] then
		return bit.band(attr_bits[k], bits) ~= 0
	end
end

local function attrbits(bits, t)
	for name in pairs(attr_bits) do
		t[name] = attrbit(bits, name) or nil
	end
	return t
end

local changeable_attr_bits = {
	--FILE_ATTRIBUTE_* flags which can be changed directly
	readonly    = attr_bits.readonly,
	hidden      = attr_bits.hidden,
	system      = attr_bits.system,
	archive     = attr_bits.archive,
	temporary   = attr_bits.temporary,
	not_indexed = attr_bits.not_indexed,
}
local function set_attrbits(cur_bits, t)
	cur_bits = cur_bits == FILE_ATTRIBUTE_NORMAL and 0 or cur_bits
	local bits = flags(t, changeable_attr_bits, cur_bits, false)
	return bits == 0 and FILE_ATTRIBUTE_NORMAL or bits
end

local IO_REPARSE_TAG_SYMLINK = 0xA000000C

local function is_symlink(bits, reparse_tag)
	return bit.band(bits, attr_bits.reparse_point) ~= 0
		and (not reparse_tag or reparse_tag == IO_REPARSE_TAG_SYMLINK)
end

local function filetype(bits, reparse_tag)
	return
		is_symlink(bits, reparse_tag) and 'symlink'
		or bit.band(bits, attr_bits.directory) ~= 0 and 'dir'
		or bit.band(bits, attr_bits.device) ~= 0    and 'dev'
		or 'file'
end

local file_info_ct = ffi.typeof'BY_HANDLE_FILE_INFORMATION'
local info
local function file_get_info(f)
	info = info or file_info_ct()
	local ok = C.GetFileInformationByHandle(f.handle, info) ~= 0
	if not ok then return check() end
	return info
end

local file_basic_info_ct = ffi.typeof'FILE_BASIC_INFO'
local binfo
local function file_get_basic_info(f)
	binfo = binfo or file_basic_info_ct()
	local ok = C.GetFileInformationByHandleEx(
		f.handle, C.FileBasicInfo, binfo, ffi.sizeof(binfo)) ~= 0
	if not ok then return check() end
	return binfo
end

local function file_set_basic_info(f, binfo)
	return check(C.SetFileInformationByHandle(
		f.handle, C.FileBasicInfo, binfo, ffi.sizeof(binfo)) ~= 0)
end

local binfo_getters = {
	type = function(binfo) return filetype(binfo.FileAttributes) end,
	btime = function(binfo)
		return timestamp(binfo.CreationTime.QuadPart)
	end,
	atime = function(binfo)
		return timestamp(binfo.LastAccessTime.QuadPart)
	end,
	mtime = function(binfo)
		return timestamp(binfo.LastWriteTime.QuadPart) end,
	ctime = function(binfo)
		return timestamp(binfo.ChangeTime.QuadPart)
	end,
}

local info_getters = {
	volume = function(info)
		return info.dwVolumeSerialNumber
	end,
	size = function(info)
		return filesize(info.nFileSizeHigh, info.nFileSizeLow)
	end,
	nlink = function(info) return info.nNumberOfLinks end,
	id = function(info)
		return join_uint64(info.nFileIndexHigh, info.nFileIndexLow)
	end,
}

local function file_attr_get_all(f)
	local binfo, err, errcode = file_get_basic_info(f)
	if not binfo then return nil, err, errcode end
	local info, err, errcode = file_get_info(f)
	if not info then return nil, err, errcode end
	local t = attrbits(binfo.FileAttributes, {})
	for k, get in pairs(binfo_getters) do
		t[k] = get(binfo) or nil
	end
	for k, get in pairs(info_getters) do
		t[k] = get(info) or nil
	end
	return t
end

function file_attr_get(f, k)
	if not k then
		return file_attr_get_all(f)
	end
	local val = attrbit(0, k)
	if val ~= nil then
		local binfo, err, errcode = file_get_basic_info(f)
		if not binfo then return nil, err, errcode end
		return attrbit(binfo.FileAttributes)
	end
	local get = binfo_getters[k]
	if get then
		local binfo, err, errcode = file_get_basic_info(f)
		if not binfo then return nil, err, errcode end
		return get(binfo)
	end
	local get = info_getters[k]
	if get then
		local info, err, errcode = file_get_info(f)
		if not info then return nil, err, errcode end
		return get(info)
	end
	return nil
end

local function set_filetime(ft, ts)
	return ts and filetime(ts) or ft
end
function file_attr_set(f, t)
	local binfo, err, errcode = file_get_basic_info(f)
	if not binfo then return nil, err, errcode end
	binfo.FileAttributes = set_attrbits(binfo.FileAttributes, t)
	binfo.CreationTime.QuadPart   =
		set_filetime(binfo.CreationTime.QuadPart, t.btime)
	binfo.LastAccessTime.QuadPart =
		set_filetime(binfo.LastAccessTime.QuadPart, t.atime)
	binfo.LastWriteTime.QuadPart  =
		set_filetime(binfo.LastWriteTime.QuadPart, t.mtime)
	binfo.ChangeTime.QuadPart     =
		set_filetime(binfo.ChangeTime.QuadPart, t.ctime)
	return file_set_basic_info(f, binfo)
end

function with_open_file(path, open_opt, func, ...)
	local f, err, errcode = fs.open(path, open_opt)
	if not f then return nil, err, errcode end
	local ret, err, errcode = func(f, ...)
	if ret == nil and err then return nil, err, errcode end
	local ok, err, errcode = f:close()
	if not ok then return nil, err, errcode end
	return ret
end

local open_opt = {
	access = 'read_attributes',
	sharing = 'read write delete',
	creation = 'open_existing',
	flags = 'backup_semantics', --for opening directories
}
local open_opt_symlink = {
	access = 'read_attributes',
	sharing = 'read write delete',
	creation = 'open_existing',
	flags = 'backup_semantics open_reparse_point',
	attrs = 'reparse_point',
}
function fs_attr_get(path, k, deref)
	local opt = deref and open_opt or open_opt_symlink
	return with_open_file(path, opt, file_attr_get, k)
end

local open_opt = {
	access = 'write_attributes',
	sharing = 'read write delete',
	creation = 'open_existing',
}
local open_opt_symlink = {
	access = 'write_attributes',
	sharing = 'read write delete',
	creation = 'open_existing',
	flags = 'backup_semantics open_reparse_point',
	attrs = 'reparse_point',
}
function fs_attr_set(path, t, deref)
	local opt = deref and open_opt or open_opt_symlink
	return with_open_file(path, opt, file_attr_set, t)
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
	DWORD dwReserved0; // reparse tag
	DWORD dwReserved1;
	WCHAR cFileName[MAX_PATH];
	WCHAR cAlternateFileName[14];
} WIN32_FIND_DATAW, *LPWIN32_FIND_DATAW;

HANDLE FindFirstFileW(LPCWSTR, LPWIN32_FIND_DATAW);
BOOL FindNextFileW(HANDLE, LPWIN32_FIND_DATAW);
BOOL FindClose(HANDLE);
]]

dir_ct = ffi.typeof[[
	struct {
		HANDLE _handle;
		WIN32_FIND_DATAW _fdata;
		DWORD _errcode; // return `false, err, errcode` on the next iteration
		int  _loaded;   // _fdata is loaded for the next iteration
		int  _dirlen;
		char _dir[?];
	}
]]

function dir.close(dir)
	if dir:closed() then return end
	local ok = C.FindClose(dir._handle) ~= 0
	dir._handle = INVALID_HANDLE_VALUE --ignore failure, prevent double-close
	ffi.gc(dir, nil)
	return check(ok)
end

function dir.closed(dir)
	return dir._handle == INVALID_HANDLE_VALUE
end

function dir_ready(dir)
	return not (dir._loaded == 1 or dir._errcode ~= 0)
end

local ERROR_NO_MORE_FILES = 18

function dir_name(dir)
	return mbs(dir._fdata.cFileName)
end

function dir.dir(dir)
	return ffi.string(dir._dir, dir._dirlen)
end

function dir.next(dir)
	if dir:closed() then
		if dir._errcode ~= 0 then
			local errcode = dir._errcode
			dir._errcode = 0
			return check(false, errcode)
		end
		return nil
	end
	if dir._loaded == 1 then
		dir._loaded = 0
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

function fs_dir(path)
	assert(not path:find'[%*%?]') --no globbing allowed
	local dir = dir_ct(#path)
	dir._dirlen = #path
	ffi.copy(dir._dir, path, #path)
	dir._handle = C.FindFirstFileW(wcs(path .. '\\*'), dir._fdata)
	if dir._handle == INVALID_HANDLE_VALUE then
		dir._errcode = C.GetLastError()
	else
		dir._loaded = 1
	end
	return dir.next, dir
end

function dir_attr_get(dir, attr)
	if attr == 'type' then
		return filetype(dir._fdata.dwFileAttributes, dir._fdata.dwReserved0)
	elseif attr == 'atime' then
		return ft_timestamp(dir._fdata.ftLastAccessTime)
	elseif attr == 'mtime' then
		return ft_timestamp(dir._fdata.ftLastWriteTime)
	elseif attr == 'btime' then
		return ft_timestamp(dir._fdata.ftCreationTime)
	elseif attr == 'size' then
		return filesize(dir._fdata.nFileSizeHigh, dir._fdata.nFileSizeLow)
	elseif attr == 'dosname' then
		local s = mbs(dir._fdata.cAlternateFileName)
		return s ~= '' and s or nil
	else
		local val = attrbit(dir._fdata.dwFileAttributes, attr)
		if val ~= nil then return val end
		return nil, false --not found
	end
end

--memory mapping -------------------------------------------------------------

ffi.cdef[[
typedef struct {
	WORD wProcessorArchitecture;
	WORD wReserved;
	DWORD dwPageSize;
	LPVOID lpMinimumApplicationAddress;
	LPVOID lpMaximumApplicationAddress;
	LPDWORD dwActiveProcessorMask;
	DWORD dwNumberOfProcessors;
	DWORD dwProcessorType;
	DWORD dwAllocationGranularity;
	WORD wProcessorLevel;
	WORD wProcessorRevision;
} SYSTEM_INFO, *LPSYSTEM_INFO;

VOID GetSystemInfo(LPSYSTEM_INFO lpSystemInfo);
]]

local pagesize
function fs.pagesize()
	if not pagesize then
		local sysinfo = ffi.new'SYSTEM_INFO'
		C.GetSystemInfo(sysinfo)
		pagesize = sysinfo.dwAllocationGranularity
	end
	return pagesize
end

ffi.cdef[[
HANDLE CreateFileMappingW(
	HANDLE hFile,
	LPSECURITY_ATTRIBUTES lpFileMappingAttributes,
	DWORD flProtect,
	DWORD dwMaximumSizeHigh,
	DWORD dwMaximumSizeLow,
	LPCWSTR *lpName
);

HANDLE OpenFileMappingW(
  DWORD   dwDesiredAccess,
  BOOL    bInheritHandle,
  LPCWSTR lpName
);

void* MapViewOfFileEx(
	HANDLE hFileMappingObject,
	DWORD dwDesiredAccess,
	DWORD dwFileOffsetHigh,
	DWORD dwFileOffsetLow,
	SIZE_T dwNumberOfBytesToMap,
	LPVOID lpBaseAddress
);

BOOL UnmapViewOfFile(LPCVOID lpBaseAddress);

BOOL FlushViewOfFile(
	LPCVOID lpBaseAddress,
	SIZE_T dwNumberOfBytesToFlush
);

BOOL VirtualProtect(
	LPVOID lpAddress,
	SIZE_T dwSize,
	DWORD  flNewProtect,
	PDWORD lpflOldProtect);
]]

local A = {
	page_noaccess                = 0x0001,
	page_readonly                = 0x0002,
	page_readwrite               = 0x0004,
	page_writecopy               = 0x0008, --no file auto-grow with this!
	page_execute                 = 0x0010,
	page_execute_read            = 0x0020, --xp sp2+
	page_execute_readwrite       = 0x0040, --xp sp2+
	page_execute_writecopy       = 0x0080, --vista sp1+
	page_guard                   = 0x0100,
	page_nocache                 = 0x0200,
	page_writecombine            = 0x0400,
	section_query                = 0x0001,
	section_map_write            = 0x0002,
	section_map_read             = 0x0004,
	section_map_execute          = 0x0008,
	section_extend_size          = 0x0010,
	section_map_execute_explicit = 0x0020, --xp sp2+
	file_map_write               = 0x0002, --section_map_write
	file_map_read                = 0x0004, --section_map_read
	file_map_copy                = 0x00000001,
	file_map_reserve             = 0x80000000,
	file_map_execute             = 0x0020, --execute_explicit, xp sp2+
}

local function protect_bits(access_write, access_exec, access_copy)
	return bit.bor(
		access_exec
			and (access_write
				and A.page_execute_readwrite
				or A.page_execute_read)
			or (access_write
				and A.page_readwrite
				or A.page_readonly))
end

function fs_map(file, write, exec, copy, size, offset, addr, tagname)

	if type(file) == 'string' then
		local open_opt = {
			access = 'read execute ' ..
				(write and 'write' or ''),
			sharing = 'read write delete',
			creation = write and 'open_always' or 'open_existing',
		}
		local f, err, errno = fs.open(file, open_opt)
		if not f then return nil, err, errno end
	else
		assert(fs.isfile(file), 'invalid file argument')
	end

	local protect = protect_bits(write, exec)
	local mhi, mlo = split_uint64(size or 0) --0 means whole file
	local tagname = tagname and wcs('Local\\'..tagname)
	local filemap
	if false then
		--TODO: test shared memory (see if OpenFileMappingW is needed)
		--filemap = C.OpenFileMappingW(tagname)
	else
		filemap = C.CreateFileMappingW(
			file and file.handle or INVALID_HANDLE_VALUE,
			nil, protect, mhi, mlo, tagname)
	end

	if filemap == nil then
		--convert `file_too_short` error into `out_of_mem` error when
		--opening the swap file.
		if not file and err == ERROR_NOT_ENOUGH_MEMORY then
			err = ERROR_COMMITMENT_LIMIT
		end
		return check(err)
	end

	local access = bit.bor(
		not write and not copy and A.file_map_read or 0,
		write and A.file_map_write or 0,
		copy and A.file_map_copy or 0,
		exec and A.section_map_execute or 0)
	local ohi, olo = split_uint64(offset)
	local baseaddr = addr

	local addr = C.MapViewOfFileEx(
		filemap, access, ohi, olo, size or 0, baseaddr)

	if addr == nil then
		local err = C.GetLastError()
		close(filemap)
		closefile()
		return reterr(err)
	end

	local function free()
		C.UnmapViewOfFile(addr)
		close(filemap)
		closefile()
	end

	local function flush(self, async, addr, sz)
		if type(async) ~= 'boolean' then --async arg is optional
			async, addr, sz = false, async, addr
		end
		local addr = mmap.aligned_addr(addr or self.addr, 'left')
		local ok = C.FlushViewOfFile(addr, sz or 0) ~= 0
		if not ok then return reterr() end
		if not async then
			local ok = C.FlushFileBuffers(file) ~= 0
			if not ok then return reterr() end
		end
		return true
	end

	--if size wasn't given, get the file size so that the user always knows
	--the actual size of the mapped memory.
	if not size then
		local filesize, errmsg, errcode = mmap.filesize(file)
		if not filesize then return nil, errmsg, errcode end
		size = filesize - offset
	end

	local function unlink() --no-op
		assert(tagname, 'no tagname given')
	end

	return {addr = addr, size = size, free = free, flush = flush,
		unlink = unlink, protect = protect}

end

function fs.unlink_mapfile(tagname) --no-op
	map_check_tagname(tagname)
end

function fs.protect(addr, size, access)
	local write, exec = map_access_args(access or 'x')
	local protect = protect_bits(write, exec)
	local old = ffi.new'DWORD[1]'
	local ok = C.VirtualProtect(addr, size, prot, old) ~= 0
	if not ok then return reterr() end
	return true
end
