
--memory mapping API Windows, Linux and OSX
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'mmap_test'; return end

local ffi = require'ffi'
local bit = require'bit'
local C = ffi.C
local mmap = {C = C}

local m = ffi.new(ffi.typeof[[
	union {
		struct { uint32_t lo; uint32_t hi; };
		uint64_t x;
	}
]])
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

local function filetype(file)
	if type(file) == 'string' then
		return 'path'
	elseif io.type(file) == 'file' then
		return 'file'
	elseif file then --assume OS file handle
		return 'handle'
	else
		error('file missing', 2)
	end
end

local function parseargs(t,...)

	--dispatch
	local file, access, size, offset, addr, name
	if type(t) == 'table' then
		file, access, size, offset, addr, name =
			t.file, t.access, t.size, t.offset, t.addr, t.name
	else
		file, access, size, offset, addr, name = t, ...
	end

	--apply defaults/convert
	local filetype = file and filetype(file)
	local access = access or ''
	local offset = file and offset or 0
	local addr = addr and ffi.cast('void*', addr)

	--parse access field
	local access_write = access:find'w'
	local access_copy = access:find'c'
	local access_exec = access:find'x'

	--check
	assert(not (access_write and access_copy),
		'w and c access flags are mutually exclusive')
	assert(file or size, 'size expected when mapping the pagefile')
	assert(not size or size > 0, 'size must be > 0')
	assert(offset >= 0, 'offset must be >= 0')
	assert(offset == mmap.aligned_size(offset), 'offset not aligned')
	assert(not addr or addr ~= nil, 'addr can\'t be zero')
	assert(not addr or addr == mmap.aligned_addr(addr), 'addr not aligned')

	return
		file, filetype,
		access_write, access_copy, access_exec,
		size, offset, addr, name
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
		[ERROR_INVALID_ADDRESS] = 'invalid_address', --address in use
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

	local function filehandle(file)
		return C._get_osfhandle(C._fileno(file))
	end

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

	function mmap.filesize(file, size)
		local filetype = filetype(file)
		if filetype == 'path' then
			local h, errmsg, errcode = open(file, size and true)
			if not h then return nil, errmsg, errcode end
			local function pass(...)
				close(h)
				return ...
			end
			return pass(mmap.filesize(h, size))
		elseif filetype == 'handle' then
			if size then --set the size
				--TODO: put the file pointer back where it was!!!
				local ok = C.mmap_SetFilePointerEx(file, size, nil, 0) ~= 0
				if not ok then reterr() end
				local ok = C.SetEndOfFile(file)
				if not ok then reterr() end
				return size
			else --get size
				local psz = ffi.new'int64_t[1]'
				if C.mmap_GetFileSizeEx(file, psz) ~= 1 then
					local err = C.GetLastError()
					return reterr(err)
				end
				return tonumber(psz[0])
			end
		elseif filetype == 'file' then
			return mmap.filesize(filehandle(file), size)
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

		local file, filetype, access_write, access_copy, access_exec,
			size, offset, addr, name = parseargs(...)

		local own_file
		if filetype == 'path' then
			local h, errmsg, errcode = open(file, access_write, access_exec)
			if not h then return nil, errmsg, errcode end
			file = h
			own_file = true
		elseif filetype == 'file' then
			file = filehandle(file)
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
		local name = name and wcs('Local\\'..name) or nil

		local filemap = C.mmap_CreateFileMappingW(
			file or INVALID_HANDLE_VALUE, nil, protect, mhi, mlo, name)

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

		local function flush(self, wait, addr, sz)
			if type(wait) ~= 'boolean' then --wait arg is optional
				wait, addr, sz = false, wait, addr
			end
			local addr = mmap.aligned_addr(addr or self.addr, 'left')
			local ok = C.FlushViewOfFile(addr, sz or 0) ~= 0
			if not ok then reterr() end
			if wait then
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

		return {addr = addr, size = size, free = free, flush = flush}
	end

elseif ffi.os == 'Linux' or ffi.os == 'OSX' then

	--POSIX types -------------------------------------------------------------

	if ffi.os == 'OSX' then
		ffi.cdef'typedef int64_t off_t;'
	else
		ffi.cdef'typedef long int off_t;'
	end
	ffi.cdef'typedef unsigned short mode_t;'

	--error reporting ---------------------------------------------------------

	local errcodes = {
		--TODO
	}

	local function reterr(errno)
		local errno = errno or ffi.errno()
		local errcode = errcodes[errno] or errno
		return nil, 'OS error '..errcode, errcode
	end

	--get pagesize ------------------------------------------------------------

	ffi.cdef'int __getpagesize();'
	mmap.pagesize = C.__getpagesize

	--FILE* to fileno conversion ----------------------------------------------

	ffi.cdef[[
	typedef struct FILE FILE;
	int fileno(FILE *stream);
	]]
	local fileno = C.fileno

	--open/close file ---------------------------------------------------------

	ffi.cdef[[
	int open(const char *path, int oflag, ...);
	void close(int fd);
	]]

	local function oct(s) return tonumber(s, 8) end
	local O_RDONLY    = 0
	local O_WRONLY    = 1
	local O_RDWR      = 2
	local O_CREAT     = oct'0100'
	--local O_EXCL      = oct'0200'
	--local O_NOCTTY    = oct'0400'
	--local O_TRUNC     = oct'01000'
	--local O_APPEND    = oct'02000'
	--local O_NONBLOCK  = oct'04000'
	--local O_NDELAY    = O_NONBLOCK
	--local O_SYNC      = oct'4010000'
	--local O_FSYNC     = O_SYNC
	--local O_ASYNC     = oct'020000'

	local function open(path, access_write)
		local oflags = bit.bor(access_write and O_RDWR or O_RDONLY, O_CREAT)
		local fd = C.open(path, oflags)
		if fd == -1 then return reterr() end
		return fd
	end

	local close = C.close

	--get/set file size -------------------------------------------------------

	local SEEK_SET = 0
	local SEEK_CUR = 1
	local SEEK_END = 2

	ffi.cdef[[
	int ftruncate(int fd, off_t length);
	off_t lseek(int fd, off_t offset, int whence);
	]]

	function mmap.filesize(file, size)
		local filetype = filetype(file)
		if filetype == 'path' then
			local fd, errmsg, errcode = open(file, size and true)
			if not fd then return nil, errmsg, errcode end
			local function pass(...)
				close(fd)
				return ...
			end
			return pass(mmap.filesize(fd, size))
		elseif filetype == 'handle' then
			if size then --set size
				if C.ftruncate(file, size) ~= 0 then
					return reterr()
				end
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
		elseif filetype == 'file' then
			return mmap.filesize(fileno(file), size)
		end
	end

	--file mapping ------------------------------------------------------------

	ffi.cdef[[
	void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
	int munmap(void *addr, size_t length);
	int msync(void *addr, size_t length, int flags);
	int mprotect(void *addr, size_t len, int prot);
	int shm_open(const char *name, int oflag, mode_t mode);
	int shm_unlink(const char *name);
	]]

	--mmap() access flags
	local PROT_READ  = 1
	local PROT_WRITE = 2
	local PROT_EXEC  = 4

	--mmap() flags
	local MAP_SHARED  = 1
	local MAP_PRIVATE = 2 --copy-on-write
	local MAP_ANON = ffi.os == 'Linux' and 0x20 or 0x1000

	--msync() flags
	local MS_ASYNC      = 1
	local MS_SYNC       = 4
	local MS_INVALIDATE = 2

	function mmap.map(...)

		local file, filetype, access_write, access_copy, access_exec,
			size, offset, addr, name = parseargs(...)

		local own_file
		if filetype == 'path' then
			local fd, errmsg, errcode = open(file, access_write)
			if not fd then return nil, errmsg, errcode end
			file = fd
			own_file = true
		elseif filetype == 'file' then
			file = fileno(file)
		end

		local access = bit.bor(
			PROT_READ,
			bit.bor(
				access_write and PROT_WRITE or 0,
				access_exec and PROT_EXEC or 0))
		local flags = bit.bor(
			access_copy and MAP_PRIVATE or MAP_SHARED,
			file and 0 or MAP_ANON,
			addr and MAP_FIXED or 0)

		if file then
			if not size then --if size not given, assume entire file
				local filesize, errmsg, errcode = mmap.filesize(file)
				if not filesize then return nil, errmsg, errcode end
				size = filesize - offset
			elseif access_write then --if file too short, extend it
				local filesize = mmap.filesize(file)
				if filesize < offset + size then
					local ok, errmsg, errcode = mmap.filesize(file, offset + size)
					if not ok then return nil, errmsg, errcode end
				end
			end
		end

		--flush the buffers before mapping to see the current view of the file.
		if file and not own_file then
			--TODO:
		end

		--print(addr, size, access, flags, file or -1, offset)
		local addr = C.mmap(addr, size, access, flags, file or -1, offset)
		if ffi.cast('intptr_t', addr) == -1 then
			return reterr()
		end

		local function flush(self, wait, addr, sz)
			if type(wait) ~= 'boolean' then --wait arg is optional
				wait, addr, sz = false, wait, addr
			end
			local addr = mmap.aligned_addr(addr or self.addr, 'left')
			local flags = bit.bor(wait and MS_SYNC or MS_ASYNC, MS_INVALIDATE)
			local ok = C.msync(addr, sz or self.size, flags) ~= 0
			if not ok then return reterr() end
			return true
		end

		local function free()
			local ret = C.munmap(addr, size)
			if ret == 0 then return true end
			return reterr()
		end

		return {addr = addr, size = size, free = free, flush = flush}
	end

	function protect(addr, size)
		checkz(C.mprotect(addr, size, bit.bor(PROT_READ, PROT_EXEC)))
	end

else
	error'platform not supported'
end

function mmap.mirror(t)
	local t = t or {}
	local file = t.file
	local filetype = filetype(file)
	local size = t.size or mmap.pagesize()
	local times = t.times or 2
	local size = mmap.aligned_size(size)
	local access = 'w'
	assert(times > 0, 'times must be > 0')

	local retries = -1
	local max_retries = t.max_retries or 100
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
		addr = t.addr}
	if not map then return nil, errmsg, errcode end

	--now free it so we can allocate it again in chunks all pointing at
	--the same offset 0 in the file, thus mirroring the same data.
	local maps = {}
	maps.addr = map.addr
	maps.size = size
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
