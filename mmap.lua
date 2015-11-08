
--memory mapping API for Windows, Linux and OSX.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'mmap_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local C = ffi.C
local mmap = {C = C}

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

function mmap.aligned_size(size, dir) --dir can be 'l' or 'r' (default: 'r')
	if ffi.istype('uint64_t', size) then --an uintptr_t on x64
		local pagesize = mmap.pagesize()
		local hi, lo = split_uint64(size)
		local lo = mmap.aligned_size(lo, dir)
		return join_uint64(hi, lo)
	else
		local pagesize = mmap.pagesize()
		if not (dir and dir:find'^l') then --align to the right
			size = size + pagesize - 1
		end
		return bit.band(size, bit.bnot(pagesize - 1))
	end
end

function mmap.aligned_addr(addr, dir)
	return ffi.cast('void*', mmap.aligned_size(ffi.cast('uintptr_t', addr), dir))
end

local function check_tagname(tagname)
	assert(tagname, 'no tagname given')
	assert(not tagname:find'[/\\]', 'invalid tagname')
	return tagname
end

local function parseargs(t,...)

	--dispatch
	local file, access, size, offset, addr, tagname
	if type(t) == 'table' then
		file, access, size, offset, addr, tagname =
			t.file, t.access, t.size, t.offset, t.addr, t.tagname
	else
		file, access, size, offset, addr, tagname = t, ...
	end

	--apply defaults/convert
	local access = access or ''
	local offset = file and offset or 0
	local addr = addr and ffi.cast('void*', addr)

	--parse access field
	local access_write = access:find'w'
	local access_copy = access:find'c'
	local access_exec = access:find'x'

	--check
	assert(file or size, 'file and/or size expected')
	assert(not access:find'[^rwcx]', 'invalid access flags')
	assert(not (access_write and access_copy), 'invalid access flags')
	assert(not (file and tagname), 'cannot have both file and tagname')
	assert(not size or size > 0, 'size must be > 0')
	assert(offset >= 0, 'offset must be >= 0')
	assert(offset == mmap.aligned_size(offset), 'offset not page-aligned')
	assert(not addr or addr ~= nil, 'addr can\'t be zero')
	assert(not addr or addr == mmap.aligned_addr(addr), 'addr not page-aligned')
	if tagname then check_tagname(tagname) end

	return file, access_write, access_copy, access_exec,
		size, offset, addr, tagname
end

if ffi.os == 'Windows' then

	--winapi types ------------------------------------------------------------

	if ffi.abi'64bit' then
		ffi.cdef'typedef int64_t ULONG_PTR;'
	else
		ffi.cdef'typedef int32_t ULONG_PTR;'
	end

	ffi.cdef[[
	typedef void*          HANDLE;
	typedef int16_t        WORD;
	typedef int32_t        DWORD, *LPDWORD;
	typedef uint32_t       UINT;
	typedef int            BOOL;
	typedef ULONG_PTR      SIZE_T;
	typedef void           VOID, *LPVOID;
	typedef const void*    LPCVOID;
	typedef char*          LPSTR;
	typedef const char*    LPCSTR;
	typedef wchar_t*       LPWSTR;
	typedef const wchar_t* LPCWSTR;
	]]

	--error reporting ---------------------------------------------------------

	ffi.cdef[[
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

	local ERROR_FILE_NOT_FOUND     = 0x0002
	local ERROR_NOT_ENOUGH_MEMORY  = 0x0008
	local ERROR_INVALID_PARAMETER  = 0x0057
	local ERROR_DISK_FULL          = 0x0070
	local ERROR_INVALID_ADDRESS    = 0x01E7
	local ERROR_FILE_INVALID       = 0x03ee
	local ERROR_COMMITMENT_LIMIT   = 0x05af

	local errcodes = {
		[ERROR_FILE_NOT_FOUND] = 'not_found',
		[ERROR_NOT_ENOUGH_MEMORY] = 'file_too_short', --readonly file too short
		[ERROR_INVALID_PARAMETER] = 'out_of_mem', --size or address too large
		[ERROR_DISK_FULL] = 'disk_full',
		[ERROR_COMMITMENT_LIMIT] = 'file_too_short', --swapfile too short
		[ERROR_FILE_INVALID] = 'file_too_short', --file has zero size
		[ERROR_INVALID_ADDRESS] = 'out_of_mem', --address in use
	}

	local function reterr(msgid)
		local msgid = msgid or C.GetLastError()
		local bufsize = 256
		local buf = ffi.new('char[?]', bufsize)
		local sz = C.FormatMessageA(
			FORMAT_MESSAGE_FROM_SYSTEM, nil, msgid, 0, buf, bufsize, nil)
		if sz == 0 then return 'Unknown Error' end
		return nil, ffi.string(buf, sz), errcodes[msgid] or msgid
	end

	--getting pagesize --------------------------------------------------------

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
	function mmap.pagesize()
		if not pagesize then
			local sysinfo = ffi.new'SYSTEM_INFO'
			C.GetSystemInfo(sysinfo)
			pagesize = sysinfo.dwAllocationGranularity
		end
		return pagesize
	end

	--utf8 to wide char conversion --------------------------------------------

	ffi.cdef[[
	int MultiByteToWideChar(
		UINT CodePage,
		DWORD dwFlags,
		LPCSTR lpMultiByteStr,
		int cbMultiByte,
		LPWSTR lpWideCharStr,
		int cchWideChar);
	]]

	local CP_UTF8 = 65001

	local function wcs(s)
		local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, #s + 1, nil, 0)
		local buf = ffi.new('wchar_t[?]', sz)
		C.MultiByteToWideChar(CP_UTF8, 0, s, #s + 1, buf, sz)
		return buf
	end

	--FILE* to HANDLE conversion ----------------------------------------------

	ffi.cdef[[
	typedef struct FILE FILE;
	int _fileno(FILE*);
	HANDLE _get_osfhandle(int fd);
	]]

	local fileno = C._fileno          -- FILE* -> fd
	local fdhandle = C._get_osfhandle -- fd -> HANDLE

	--open/close file ---------------------------------------------------------

	ffi.cdef[[
	HANDLE mmap_CreateFileW(
		LPCWSTR lpFileName,
		DWORD   dwDesiredAccess,
		DWORD   dwShareMode,
		LPVOID  lpSecurityAttributes,
		DWORD   dwCreationDisposition,
		DWORD   dwFlagsAndAttributes,
		HANDLE  hTemplateFile
	) asm("CreateFileW");

	BOOL CloseHandle(HANDLE hObject);
	]]

	local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

	--CreateFile dwDesiredAccess flags
	local GENERIC_READ    = 0x80000000
	local GENERIC_WRITE   = 0x40000000
	local GENERIC_EXECUTE = 0x20000000

	--CreateFile dwShareMode flags
	local FILE_SHARE_READ        = 0x00000001
	local FILE_SHARE_WRITE       = 0x00000002
	local FILE_SHARE_DELETE      = 0x00000004

	--CreateFile dwCreationDisposition flags
	--local CREATE_NEW        = 1
	--local CREATE_ALWAYS     = 2
	local OPEN_EXISTING     = 3
	local OPEN_ALWAYS       = 4
	--local TRUNCATE_EXISTING = 5

	local function open(filename, access_write, access_exec)
		local access = bit.bor(
			GENERIC_READ,
			access_write and GENERIC_WRITE or 0,
			access_exec and GENERIC_EXECUTE or 0)
		local sharemode = bit.bor(
			FILE_SHARE_READ,
			FILE_SHARE_WRITE,
			FILE_SHARE_DELETE)
		local creationdisp = access_write and OPEN_ALWAYS or OPEN_EXISTING
		local flagsandattrs = 0
		local h = C.mmap_CreateFileW(
			wcs(filename), access, sharemode, nil,
			creationdisp, flagsandattrs, nil)
		if h == INVALID_HANDLE_VALUE then
			return reterr()
		end
		return h
	end

	local close = C.CloseHandle

	--get/set file size -------------------------------------------------------

	ffi.cdef[[
	BOOL mmap_GetFileSizeEx(
		HANDLE hFile,
		int64_t* lpFileSize
	) asm("GetFileSizeEx");

	BOOL mmap_SetFilePointerEx(
	  HANDLE         hFile,
	  int64_t        liDistanceToMove,
	  int64_t*       lpNewFilePointer,
	  DWORD          dwMoveMethod
	) asm("SetFilePointerEx");

	BOOL SetEndOfFile(HANDLE hFile);
	]]

	local FILE_BEGIN   = 0
	local FILE_CURRENT = 1
	local FILE_END     = 2

	function mmap.filesize(file, size)
		if type(file) == 'string' then
			local h, errmsg, errcode = open(file, size and true)
			if not h then return nil, errmsg, errcode end
			local function pass(...)
				close(h)
				return ...
			end
			return pass(mmap.filesize(h, size))
		elseif io.type(file) == 'file' then
			return mmap.filesize(fileno(file), size)
		elseif type(file) == 'number' then
			return mmap.filesize(fdhandle(file), size)
		elseif ffi.istype('HANDLE', file) then
			if size then --set the size
				--get current position
				local curpos = ffi.new'int64_t[1]'
				local ok = C.mmap_SetFilePointerEx(file, 0, curpos, FILE_CURRENT) ~= 0
				if not ok then reterr() end
				--set current position to new file size
				local ok = C.mmap_SetFilePointerEx(file, size, nil, FILE_BEGIN) ~= 0
				if not ok then reterr() end
				--truncate the file to current position
				local ok = C.SetEndOfFile(file)
				if not ok then reterr() end
				--set current position back to where it was
				local ok = C.mmap_SetFilePointerEx(file, curpos[0], nil, FILE_BEGIN) ~= 0
				if not ok then reterr() end
				--return file new file size
				return size
			else --get size
				local psz = ffi.new'int64_t[1]'
				if C.mmap_GetFileSizeEx(file, psz) ~= 1 then
					local err = C.GetLastError()
					return reterr(err)
				end
				return tonumber(psz[0])
			end
		else
			error'file expected'
		end
	end

	--file mapping ------------------------------------------------------------

	ffi.cdef[[
	HANDLE mmap_CreateFileMappingW(
		HANDLE hFile,
		LPVOID lpFileMappingAttributes,
		DWORD flProtect,
		DWORD dwMaximumSizeHigh,
		DWORD dwMaximumSizeLow,
		const wchar_t *lpName
	) asm("CreateFileMappingW");

	void* MapViewOfFileEx(
		HANDLE hFileMappingObject,
		DWORD dwDesiredAccess,
		DWORD dwFileOffsetHigh,
		DWORD dwFileOffsetLow,
		SIZE_T dwNumberOfBytesToMap,
		LPVOID lpBaseAddress
	);

	BOOL UnmapViewOfFile(LPCVOID lpBaseAddress);
	BOOL FlushViewOfFile(LPCVOID lpBaseAddress, SIZE_T dwNumberOfBytesToFlush);
	BOOL FlushFileBuffers(HANDLE hFile);
	]]

	--local STANDARD_RIGHTS_REQUIRED = 0x000F0000
	--local STANDARD_RIGHTS_ALL      = 0x001F0000

	--local PAGE_NOACCESS          = 0x001
	local PAGE_READONLY          = 0x002
	local PAGE_READWRITE         = 0x004
	--local PAGE_WRITECOPY         = 0x008
	--local PAGE_EXECUTE           = 0x010
	local PAGE_EXECUTE_READ      = 0x020 --XP SP2+
	local PAGE_EXECUTE_READWRITE = 0x040 --XP SP2+
	--local PAGE_EXECUTE_WRITECOPY = 0x080 --Vista SP1+
	--local PAGE_GUARD             = 0x100
	--local PAGE_NOCACHE           = 0x200
	--local PAGE_WRITECOMBINE      = 0x400

	--local SECTION_QUERY                = 0x0001
	local SECTION_MAP_WRITE            = 0x0002
	local SECTION_MAP_READ             = 0x0004
	local SECTION_MAP_EXECUTE          = 0x0008
	--local SECTION_EXTEND_SIZE          = 0x0010
	--local SECTION_MAP_EXECUTE_EXPLICIT = 0x0020

	local FILE_MAP_WRITE      = SECTION_MAP_WRITE
	local FILE_MAP_READ       = SECTION_MAP_READ
	local FILE_MAP_COPY       = 0x00000001
	--local FILE_MAP_RESERVE    = 0x80000000
	--local FILE_MAP_EXECUTE    = SECTION_MAP_EXECUTE_EXPLICIT --XP SP2+

	function mmap.map(...)

		local file, access_write, access_copy, access_exec,
			size, offset, addr, tagname = parseargs(...)

		local own_file
		if type(file) == 'string' then
			local h, errmsg, errcode = open(file, access_write, access_exec)
			if not h then return nil, errmsg, errcode end
			file = h
			own_file = true
		elseif type(file) == 'number' then
			file = fdhandle(file)
		elseif io.type(file) == 'file' then
			file = fdhandle(fileno(file))
		end

		--flush the buffers before mapping to see the current view of the file.
		if file and not own_file then
			local ok = C.FlushFileBuffers(file) ~= 0
			if not ok then return reterr() end
		end

		local function closefile()
			if not own_file then return end
			close(file)
		end

		local protect = bit.bor(
			access_exec and
				(access_write and PAGE_EXECUTE_READWRITE or PAGE_EXECUTE_READ) or
				(access_write and PAGE_READWRITE or PAGE_READONLY))
		local mhi, mlo = split_uint64(size or 0) --0 means whole file

		local tagname = tagname and wcs('Local\\'..tagname)

		local filemap = C.mmap_CreateFileMappingW(
			file or INVALID_HANDLE_VALUE, nil, protect, mhi, mlo, tagname)

		if filemap == nil then
			local err = C.GetLastError()
			closefile()
			return reterr(err)
		end

		local access = bit.bor(
			not access_write and not access_copy and FILE_MAP_READ or 0,
			access_write and FILE_MAP_WRITE or 0,
			access_copy and FILE_MAP_COPY or 0,
			access_exec and SECTION_MAP_EXECUTE or 0)
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
			if not ok then reterr() end
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
			unlink = unlink}
	end

	function mmap.unlink(tagname) --no-op
		check_tagname(tagname)
	end

elseif ffi.os == 'Linux' or ffi.os == 'OSX' then

	local linux = ffi.os == 'Linux'
	local osx = ffi.os == 'OSX'

	--POSIX types -------------------------------------------------------------

	if osx then
		ffi.cdef'typedef int64_t off_t;'
	else
		ffi.cdef'typedef long int off_t;'
	end
	ffi.cdef'typedef unsigned short mode_t;'

	--error reporting ---------------------------------------------------------

	ffi.cdef'char *strerror(int errnum);'

	local ENOENT = 2
	local ENOMEM = 12
	local EINVAL = 22
	local EFBIG  = 27
	local EDQUOT = osx and 69 or 122

	local errcodes = {
		[ENOENT] = 'not_found',
		[ENOMEM] = 'out_of_mem',
		[EINVAL] = 'file_too_short',
		[EFBIG] = 'disk_full',
		[EDQUOT] = 'disk_full',
	}

	local function reterr(errno)
		local errno = errno or ffi.errno()
		local errcode = errcodes[errno] or errno
		local errmsg = ffi.string(C.strerror(errno))
		return nil, errmsg, errcode
	end

	--get pagesize ------------------------------------------------------------

	if linux then
		ffi.cdef'int __getpagesize();'
		mmap.pagesize = C.__getpagesize
	else
		ffi.cdef'int getpagesize();'
		mmap.pagesize = C.getpagesize
	end

	--FILE* to fileno conversion ----------------------------------------------

	ffi.cdef[[
	typedef struct FILE FILE;
	int fileno(FILE *stream);
	]]
	local fileno = C.fileno

	--open/close file ---------------------------------------------------------

	ffi.cdef[[
	int open(const char *path, int oflag, mode_t mode);
	void close(int fd);
	int fsync(int fd);
	int shm_open(const char *name, int oflag, mode_t mode);
	int shm_unlink(const char *name);
	]]

	local function oct(s) return tonumber(s, 8) end
	local O_RDONLY    = 0
	--local O_WRONLY    = 1
	local O_RDWR      = 2
	local O_CREAT     = osx and 0x00200 or oct'00100'
	--local O_EXCL      = osx and 0x00800 or oct'00200'
	--local O_NOCTTY    = osx and 0x20000 or oct'00400'
	--local O_TRUNC     = osx and 0x00400 or oct'01000'
	--local O_APPEND    = osx and 0x00008 or oct'02000'
	--local O_NONBLOCK  = osx and 0x00004 or oct'04000'
	--local O_NDELAY    = O_NONBLOCK
	--local O_SYNC      = osx and 0x00080 or oct'4010000'
	--local O_FSYNC     = O_SYNC
	--local O_ASYNC     = osx and 0x00040 or oct'020000'

	local librt = linux and ffi.load'rt' or C

	local function open(path, access_write, access_exec, shm)
		local oflags = access_write and bit.bor(O_RDWR, O_CREAT) or O_RDONLY
		local perms = oct'444' +
			(access_write and oct'222' or 0) +
			(access_exec and oct'111' or 0)
		local open = shm and librt.shm_open or C.open
		local fd = open(path, oflags, perms)
		if fd == -1 then return reterr() end
		return fd
	end

	local close = C.close

	--get/set file size -------------------------------------------------------

	ffi.cdef[[
	int ftruncate(int fd, off_t length);
	off_t lseek(int fd, off_t offset, int whence);
	]]

	local SEEK_SET = 0
	local SEEK_CUR = 1
	local SEEK_END = 2

	function mmap.filesize(file, size)
		if type(file) == 'string' then
			local access_write = size and true
			local fd, errmsg, errcode = open(file, access_write)
			if not fd then return nil, errmsg, errcode end
			local function pass(...)
				close(fd)
				return ...
			end
			return pass(mmap.filesize(fd, size))
		elseif io.type(file) == 'file' then
			return mmap.filesize(fileno(file), size)
		elseif type(file) == 'number' then
			if size then --set size
				local ok = C.ftruncate(file, size) == 0
				if not ok then return reterr() end
				return size
			else --get size
				local ofs = C.lseek(file, 0, SEEK_CUR)
				if ofs == -1 then return reterr() end
				local size = tonumber(C.lseek(file, 0, SEEK_END))
				if size == -1 then return reterr() end
				local ofs = C.lseek(file, ofs, SEEK_SET)
				if ofs == -1 then return reterr() end
				return size
			end
		else
			error'file expected'
		end
	end

	--file mapping ------------------------------------------------------------

	ffi.cdef[[
	void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
	int munmap(void *addr, size_t length);
	int msync(void *addr, size_t length, int flags);
	int mprotect(void *addr, size_t len, int prot);
	]]

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

	function mmap.map(...)

		local file, access_write, access_copy, access_exec,
			size, offset, addr, tagname = parseargs(...)

		local fd, close
		if type(file) == 'string' then
			local errmsg, errcode
			fd, errmsg, errcode = open(file, access_write, access_exec)
			if not fd then return nil, errmsg, errcode end
			function close()
				C.close(fd)
			end
		elseif io.type(file) == 'file' then
			fd = fileno(file)
		elseif tagname then
			local errmsg, errcode
			tagname = '/'..tagname
			fd, errmsg, errcode = open(tagname, access_write, access_exec, true)
			if not fd then return reterr() end
		end

		--emulate Windows behavior for missing size and size mismatches.
		if file then
			if not size then --if size not given, assume entire file
				local filesize, errmsg, errcode = mmap.filesize(fd)
				if not filesize then
					if close then close() end
					return nil, errmsg, errcode
				end
				size = filesize - offset
			elseif access_write then --if writable file too short, extend it
				local filesize = mmap.filesize(fd)
				if filesize < offset + size then
					local ok, errmsg, errcode = mmap.filesize(fd, offset + size)
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
					return nil, 'File too short', 'file_too_short'
				end
			end
		elseif tagname and access_write then
			local ok = C.ftruncate(fd, size) == 0
			if not ok then return reterr() end
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

		local access = bit.bor(
			PROT_READ,
			bit.bor(
				(access_write or access_copy) and PROT_WRITE or 0,
				access_exec and PROT_EXEC or 0))

		local flags = bit.bor(
			access_copy and MAP_PRIVATE or MAP_SHARED,
			fd and 0 or MAP_ANON,
			addr and MAP_FIXED or 0)

		local addr = C.mmap(addr, size, access, flags, fd or -1, offset)

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
			local addr = mmap.aligned_addr(addr or self.addr, 'left')
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
			unlink = unlink}
	end

	function protect(addr, size)
		checkz(C.mprotect(addr, size, bit.bor(PROT_READ, PROT_EXEC)))
	end

	function mmap.unlink(tagname)
		librt.shm_unlink('/'..check_tagname(tagname))
	end

else
	error'platform not supported'
end

function mmap.mirror(t,...)

	--dispatch
	local file, size, times, addr
	if type(t) == 'table' then
		file, size, times, addr = t.file, t.size, t.times, t.addr
	else
		file, size, times, addr = t, ...
	end

	--apply defaults/convert/check
	local size = mmap.aligned_size(size or mmap.pagesize())
	local times = times or 2
	local access = 'w'
	assert(times > 0, 'times must be > 0')

	local retries = -1
	local max_retries = 100
	::try_again::
	retries = retries + 1
	if retries > max_retries then
		return nil, 'maximum retries reached', 'max_retries'
	end

	--try to allocate a contiguous block
	local map, errmsg, errcode = mmap.map{
		file = file,
		size = size * times,
		access = access,
		addr = addr}
	if not map then
		return nil, errmsg, errcode
	end

	--now free it so we can allocate it again in chunks all pointing at
	--the same offset 0 in the file, thus mirroring the same data.
	local maps = {addr = map.addr, size = size}
	map:free()

	local addr = ffi.cast('char*', maps.addr)

	function maps:free()
		for _,map in ipairs(self) do
			map:free()
		end
	end

	for i = 1, times do
		local map1, errmsg, errcode = mmap.map{
			file = file,
			size = size,
			addr = addr + (i - 1) * size,
			access = access}
		if not map1 then
			maps:free()
			goto try_again
		end
		maps[i] = map1
	end

	return maps
end

return mmap
