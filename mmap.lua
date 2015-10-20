
--memory mapping API Windows, Linux and OSX
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local bit = require'bit'
local C = ffi.C
local mmap = {C = C}

function mmap.aligned_size(size)
	local pagesize = mmap.pagesize()
	local fpagecount = size / pagesize
	local pagecount = math.floor(fpagecount)
	return (pagecount + (pagecount < fpagecount and 1 or 0)) * pagesize
end

if ffi.os == 'Windows' then

	--winapi types

	ffi.cdef('typedef '..(ffi.abi'64bit' and 'int64_t' or 'int32_t')..' ULONG_PTR;')

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

	--error reporting

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

	local function reterr(msgid)
		local msgid = msgid or C.GetLastError()
		local bufsize = 256
		local buf = ffi.new('char[?]', bufsize)
		local sz = C.FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, nil, msgid, 0, buf, bufsize, nil)
		if sz == 0 then return 'Unknown Error' end
		return nil, ffi.string(buf, sz), msgid
	end

	--pagesize

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

	--utf8 to wide char conversion

	ffi.cdef[[
	int MultiByteToWideChar(
		  UINT     CodePage,
		  DWORD    dwFlags,
		  LPCSTR   lpMultiByteStr,
		  int      cbMultiByte,
		  LPWSTR   lpWideCharStr,
		  int      cchWideChar);
	]]

	local CP_UTF8 = 65001
	local ERROR_INSUFFICIENT_BUFFER = 122

	function wcs(s)
		local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, #s + 1, nil, 0)
		local buf = ffi.new('wchar_t[?]', sz)
		C.MultiByteToWideChar(CP_UTF8, 0, s, #s + 1, buf, sz)
		return buf
	end

	--file opening and file mapping

	ffi.cdef[[
	HANDLE mmap_CreateFileW(
		LPCWSTR lpFileName,
		DWORD dwDesiredAccess,
		DWORD dwShareMode,
		LPVOID lpSecurityAttributes,
		DWORD dwCreationDisposition,
		DWORD dwFlagsAndAttributes,
		HANDLE hTemplateFile
	) asm("CreateFileW");

	BOOL mmap_GetFileSizeEx(
	  HANDLE         hFile,
	  int64_t*       lpFileSize
	) asm("GetFileSizeEx");

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
	BOOL CloseHandle(HANDLE hObject);

	BOOL mmap_SetFilePointerEx(
	  HANDLE         hFile,
	  int64_t        liDistanceToMove,
	  int64_t*       lpNewFilePointer,
	  DWORD          dwMoveMethod
	) asm("SetFilePointerEx");

	BOOL SetEndOfFile(HANDLE hFile);
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
	local CREATE_NEW        = 1
	local CREATE_ALWAYS     = 2
	local OPEN_EXISTING     = 3
	local OPEN_ALWAYS       = 4
	local TRUNCATE_EXISTING = 5

	local STANDARD_RIGHTS_REQUIRED = 0x000F0000
	local STANDARD_RIGHTS_ALL      = 0x001F0000

	local PAGE_NOACCESS          = 0x001
	local PAGE_READONLY          = 0x002
	local PAGE_READWRITE         = 0x004
	local PAGE_WRITECOPY         = 0x008
	local PAGE_EXECUTE           = 0x010
	local PAGE_EXECUTE_READ      = 0x020 --XP SP2+
	local PAGE_EXECUTE_READWRITE = 0x040 --XP SP2+
	local PAGE_EXECUTE_WRITECOPY = 0x080 --Vista SP1+
	local PAGE_GUARD             = 0x100
	local PAGE_NOCACHE           = 0x200
	local PAGE_WRITECOMBINE      = 0x400

	local SECTION_QUERY                = 0x0001
	local SECTION_MAP_WRITE            = 0x0002
	local SECTION_MAP_READ             = 0x0004
	local SECTION_MAP_EXECUTE          = 0x0008
	local SECTION_EXTEND_SIZE          = 0x0010
	local SECTION_MAP_EXECUTE_EXPLICIT = 0x0020
	local SECTION_ALL_ACCESS           = bit.bor(STANDARD_RIGHTS_REQUIRED,
		SECTION_QUERY, SECTION_MAP_WRITE, SECTION_MAP_READ, SECTION_MAP_EXECUTE,
		SECTION_EXTEND_SIZE)

	local FILE_MAP_WRITE      = SECTION_MAP_WRITE
	local FILE_MAP_READ       = SECTION_MAP_READ
	local FILE_MAP_ALL_ACCESS = SECTION_ALL_ACCESS
	local FILE_MAP_COPY       = 0x00000001
	local FILE_MAP_RESERVE    = 0x80000000
	local FILE_MAP_EXECUTE    = SECTION_MAP_EXECUTE_EXPLICIT --XP SP2+

	local ERROR_INVALID_ADDRESS = 0x000001E7
	local ERROR_DISK_FULL       = 0x00000070

	local m = ffi.new(ffi.typeof[[
		union {
			struct { int32_t lo; int32_t hi; };
			uint64_t x;
		}
	]])
	local function split_uint64(x)
		m.x = x
		return m.hi, m.lo
	end

	function mmap.map(t)
		assert(type(t) == 'table', 'options table expected')

		local maxsize = mmap.aligned_size(t.size or 0) --0 means whole file
		local access = t.access or ''
		local allow_write = access:find'w'
		local allow_exec = access:find'x'

		local hfile, own_hfile
		if t.file then
			hfile = t.file
		elseif t.path then
			local access = bit.bor(
				GENERIC_READ,
				allow_write and GENERIC_WRITE or 0,
				allow_exec and GENERIC_EXECUTE or 0)
			local sharemode = bit.bor(FILE_SHARE_READ, FILE_SHARE_WRITE, FILE_SHARE_DELETE)
			local creationdisp = OPEN_ALWAYS
			local flagsandattrs = 0
			local h = C.mmap_CreateFileW(wcs(t.path), access, sharemode, nil, creationdisp, flagsandattrs, nil)
			if h == INVALID_HANDLE_VALUE then
				return reterr()
			end
			hfile = h
			own_hfile = true
		else
			hfile = INVALID_HANDLE_VALUE
		end

		local protect = bit.bor(
			 allow_exec and (allow_write and PAGE_EXECUTE_READWRITE or PAGE_EXECUTE_READ)
			 or (allow_write and PAGE_READWRITE or PAGE_READONLY))
	 	local mhi, mlo = split_uint64(maxsize)
		local name = t.name and wcs('Local\\'..t.name) or nil
		local hfilemap = C.mmap_CreateFileMappingW(hfile, nil, protect, mhi, mlo, name)
		if hfilemap == nil then
			local err = C.GetLastError()
			if own_hfile then
				C.CloseHandle(hfile)
			end
			return reterr(err)
		end

		--[[
		local size = t.size
		if not size then
			if hfile ~= INVALID_HANDLE_VALUE then
				local psz = 'int64_t[1]'
				assert(C.mmap_GetFileSizeEx(hfile, psz) == 0)
				size = tonumber(psz[0])
			end
		end
		]]

		local access = bit.bor(
			STANDARD_RIGHTS_REQUIRED,
			SECTION_QUERY,
			FILE_MAP_READ,
			allow_write and FILE_MAP_WRITE or 0,
			--allow_append and SECTION_EXTEND_SIZE  or 0,
			allow_exec and SECTION_MAP_EXECUTE or 0)
		local times = (t.mirrors or 0) + 1
		local offset = t.offset or 0
		local ohi, olo = split_uint64(offset)
		local baseaddr = t.addr or nil
		local addr = C.MapViewOfFileEx(hfilemap, access, ohi, olo, maxsize, baseaddr)
		if addr == nil then
			local err = C.GetLastError()
			C.CloseHandle(hfilemap)
			if own_hfile then
				C.CloseHandle(hfile)
			end
			return reterr(err)
		end
		local function free()
			C.UnmapViewOfFile(addr)
			C.CloseHandle(hfilemap)
			if own_hfile then
				C.CloseHandle(hfile)
			end
		end
		return {file = hfile, handle = hfilemap, addr = addr, size = maxsize, free = free}
	end

elseif ffi.os == 'Linux' or ffi.os == 'OSX' then

	if ffi.os == 'OSX' then
		ffi.cdef'typedef int64_t off_t;'
	else
		ffi.cdef'typedef long int off_t;'
	end

	ffi.cdef[[
	int __getpagesize(void);

	void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
	int munmap(void *addr, size_t length);
	int mprotect(void *addr, size_t len, int prot);

	int shm_open(const char *name, int oflag, mode_t mode);
	int shm_unlink(const char *name);

	void unlink(char*);
	void close(int fd);
	]]

	mmap.pagesize = C.__getpagesize

	local PROT_READ  = 1
	local PROT_WRITE = 2
	local PROT_EXEC  = 4
	local MAP_PRIVATE = 2
	local MAP_ANON = ffi.os == 'Linux' and 0x20 or 0x1000

	function mmap.map(t)
		assert(t, 'options table expected')
		local fd = t.file

		if t.name then
			local shm_path = '/dev/shm/XXXXXX'
			local tmp_path = '/tmp/XXXXXX'
			fd = mkstemp(shm_path) or mkstemp(tmp_path)
			if unlink(chosen_path) ~= 0 then
				close(fd)
				return
			end
		end

		local size = assert(t.size, 'size missing')
		local access = bit.bor(
			PROT_READ,
			t.access and bit.bor(
				t.access:find'w' and PROT_WRITE or 0,
				t.access:find'x' and PROT_EXEC or 0
			)
		)
		local file = t.file or -1
		local offset = t.offset or 0
		local ret = C.mmap(t.addr, size, access, bit.bor(MAP_PRIVATE, MAP_ANON), file, offset)
		if ffi.cast('intptr_t', ret) == ffi.cast('intptr_t', -1) then
			error(string.format('mmap errno: %d', ffi.errno()))
		end
		return checkh(ret)
	end

	function protect(addr, size)
		checkz(C.mprotect(addr, size, bit.bor(PROT_READ, PROT_EXEC)))
	end

	function free(addr, size)
		checkz(C.munmap(addr, size))
	end

	function mmap.mirrors(size, times)

		local times = times or 2
		local size = mmap.aligned_size(size)

		local chosen_path
		local function mkstemp(path)
			local fd = C.mkstemp(path)
			if fd < 0 then return end
			chosen_path = path
			return fd
		end

		local shm_path = '/dev/shm/soundio-XXXXXX'
		local tmp_path = '/tmp/soundio-XXXXXX'

		local fd = mkstemp(shm_path) or mkstemp(tmp_path)

		if unlink(chosen_path) ~= 0 then
			close(fd)
			return
		end

		if ftruncate(fd, actual_size) ~= 0 then
			close(fd)
			return
		end

		local addr = mmap(nil, actual_size * 2, PROT_NONE,
			bit.bor(MAP_ANONYMOUS, MAP_PRIVATE), -1, 0)

		if addr == MAP_FAILED then
			return
		end

		local other_addr = mmap(addr, actual_size,
			bit.bor(PROT_READ, PROT_WRITE), bit.bor(MAP_FIXED, MAP_SHARED), fd, 0)

		if other_addr ~= addr then
			munmap(addr, 2 * actual_size)
			close(fd)
			return
		end

		local other_addr = mmap(addr + actual_size, actual_size,
			bit.bor(PROT_READ, PROT_WRITE), bit.bor(MAP_FIXED, MAP_SHARED), fd, 0)

		if other_addr ~= addr + actual_size then
			munmap(addr, 2 * actual_size)
			close(fd)
			return
		end

		if close(fd) ~= 0 then
			return
		end

		local function free()
			munmap(addr, 2 * actual_size)
		end

		ffi.gc(addr, free)

		return addr
	end

end

function mmap.mirrors(size, times)

	local times = times or 2
	local size = mmap.aligned_size(size)

	local map, errcode, errmsg = mmap.map{size = size * times}
	if not map then return nil, errcode, errmsg end

	local addr
	while true do
		::continue::
		--find a big enough address space
		addr = MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, size * times)
		if not addr then
			CloseHandle(hMapFile)
			return
		end
		--unmap it, then try to map it again in pieces
		UnmapViewOfFile(addr)
		--map it in pieces
		for i = 0, times-1 do
			local addr1 = addr + (size * i)
			local addr2 = MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, size, addr1)
			if addr2 ~= addr1 then
				if C.GetLastError() == ERROR_INVALID_ADDRESS then
					--unmap current pieces and try again
					if addr2 then
						UnmapViewOfFile(addr2)
					end
					for i = 0, i-1 do
						UnmapViewOfFile(addr + (size * i))
					end
					goto continue
				end
				CloseHandle(hMapFile)
				return
			end
		end
		break
	end

	local function free()
		for i = 0, times-1 do
			UnmapViewOfFile(addr + (size * i))
		end
		CloseHandle(hMapFile)
	end

	ffi.gc(addr, free)

	return addr, size, free
end


--demo

if not ... then

	local function map_swap()
		local map = assert(mmap.map{access = 'w', size = 1000})
		print(map.addr, map.size)
		local p = ffi.cast('int32_t*', map.addr)
		for i = 0, map.size/4-1 do
			p[i] = i
		end
		for i = 0, map.size/4-1 do
			assert(p[i] == i)
		end
		map:free()
	end

	local function map_file_readonly()
		local map = assert(mmap.map{path = 'mmap.lua'})
		print(map.addr, map.size)
		assert(ffi.string(map.addr, 20):find'--memory mapping')
		map:free()
	end

	local function map_file_exec()
		local map = assert(mmap.map{path = 'bin/mingw64/luajit.exe', access = 'x'})
		print(map.addr, map.size)
		assert(ffi.string(map.addr, 2) == 'MZ')
		map:free()
	end

	local function map_file_write()
		local map = assert(mmap.map{path = 'mmap.tmp', size = 1000})
		print(map.addr, map.size)
		local p = ffi.cast('int32_t*', map.addr)
		for i = 0, map.size/4-1 do
			p[i] = i
		end
		for i = 0, map.size/4-1 do
			--assert(p[i] == i)
		end
		map:free()
	end

	local function mirror()
		for i = 1, 1000 do
			local size = 2^16
			local times = 50
			local addr, n, free = mmap.mirrors(size, times)
			print(i, addr, n)
			assert(addr)
			local p = ffi.cast('char*', addr)
			p[0] = 123
			for i = 1, times-1 do
				assert(p[i*size] == 123)
			end
			free()
		end
	end

	map_swap()
	map_file_readonly()
	map_file_exec()
	map_file_write()

end

return mmap
