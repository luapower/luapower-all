
--memory mapping API for Windows, Linux and OSX
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local bit = require'bit'

local mmap = {}

function mmap.aligned_size(size)
	local pagesize = mmap.pagesize()
	local fpagecount = size / pagesize
	local pagecount = math.floor(fpagecount)
	return (pagecount + (pagecount < fpagecount and 1 or 0)) * pagesize
end

if ffi.os == 'Windows' then

	ffi.cdef('typedef '..(ffi.abi'64bit' and 'int64_t' or 'int32_t')..' ULONG_PTR;')

	ffi.cdef[[
	typedef void*     HANDLE;
	typedef int16_t   WORD;
	typedef int32_t   DWORD;
	typedef int       BOOL;
	typedef ULONG_PTR SIZE_T;

	typedef struct {
		DWORD  nLength;
		void*  lpSecurityDescriptor;
		BOOL   bInheritHandle;
	} *LPSECURITY_ATTRIBUTES;

	HANDLE CreateFileMappingW(
		HANDLE hFile,
		LPSECURITY_ATTRIBUTES lpFileMappingAttributes,
		DWORD flProtect,
		DWORD dwMaximumSizeHigh,
		DWORD dwMaximumSizeLow,
		const wchar_t *lpName
	);

	char* MapViewOfFileEx(
		HANDLE hFileMappingObject,
		DWORD dwDesiredAccess,
		DWORD dwFileOffsetHigh,
		DWORD dwFileOffsetLow,
		SIZE_T dwNumberOfBytesToMap,
		void* lpBaseAddress
	);

	BOOL UnmapViewOfFile(const void* lpBaseAddress);

	BOOL FlushViewOfFile(
		const void* lpBaseAddress,
		SIZE_T dwNumberOfBytesToFlush
	);

	BOOL CloseHandle (HANDLE hObject);

	typedef struct {
		WORD wProcessorArchitecture;
		WORD wReserved;
		DWORD dwPageSize;
		void* lpMinimumApplicationAddress;
		void* lpMaximumApplicationAddress;
		DWORD* dwActiveProcessorMask;
		DWORD dwNumberOfProcessors;
		DWORD dwProcessorType;
		DWORD dwAllocationGranularity;
		WORD wProcessorLevel;
		WORD wProcessorRevision;
	} SYSTEM_INFO, *LPSYSTEM_INFO;

	void GetSystemInfo(LPSYSTEM_INFO lpSystemInfo);
	DWORD GetLastError(void);
	]]

	local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

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

	local function reth(h)
		return h ~= nil and h or nil
	end

	local function retnz(ret)
		return ret ~= 0
	end

	local function checknz(ret)
		if ret ~= 0 then return end
		error('error', 2)
	end

	local function wcs(s)
		--TODO: utf-8 to wcs conversion
		return s
	end

	local C = ffi.C

	local pagesize
	function mmap.pagesize()
		if not pagesize then
			local sysinfo = ffi.new'SYSTEM_INFO'
			C.GetSystemInfo(sysinfo)
			pagesize = sysinfo.dwAllocationGranularity
		end
		return pagesize
	end

	local function CreateFileMapping(hfile, secattrs, protect, maxsize, name)
		hfile = hfile or INVALID_HANDLE_VALUE
		local mhi, mlo = split_uint64(maxsize)
		return reth(C.CreateFileMappingW(
			hfile, secattrs, protect, mhi, mlo, wcs(name)))
	end

	local function MapViewOfFile(hfilemap, access, offset, sz, baseaddr)
		local ohi, olo = split_uint64(offset)
		return reth(C.MapViewOfFileEx(hfilemap, access, ohi, olo, sz, baseaddr))
	end

	local function UnmapViewOfFile(baseaddr)
		checknz(C.UnmapViewOfFile(baseaddr))
	end

	local function FlushViewOfFile(baseaddr, sz)
		return retnz(C.FlushViewOfFile(baseaddr, sz))
	end

	local function CloseHandle(h)
		checknz(C.CloseHandle(h))
	end

	function mmap.map(t)
		assert(t, 'options table expected')
		local hfile = t.file or INVALID_HANDLE_VALUE
		local access = t.access and bit.bor(
			t.access:find'w' and PAGE_READWRITE or PAGE_READONLY,
			t.access:find'x' and PAGE_EXECUTE or 0
		) or PAGE_READWRITE
	 	local size = mmap.aligned_size(t.size or 0) --0 means whole file
		local name = t.name
		local h = CreateFileMapping(hfile, nil, access, size, name)
		if not h then return end
		local access = FILE_MAP_ALL_ACCESS
		local times = (t.mirrors or 0) + 1
		local addr = MapViewOfFile(h, access, t.offset or 0, size, t.addr or 0)
		if not addr then
			CloseHandle(h)
			return
		end
		local function free()
			for i = 0, times-1 do
				UnmapViewOfFile(addr + (size * i))
			end
			CloseHandle(h)
		end
		return {file = hfile, handle = h, addr = addr, size = size, free = free}
	end

	--mirroring ---------------------------------------------------------------

	function mmap.mirrors(size, times)

		local times = times or 2
		local size = mmap.aligned_size(size)

		local hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, size * times)
		if not hMapFile then return end

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

elseif ffi.os == 'Linux' or ffi.os == 'OSX' then

	if ffi.os == 'OSX' then
		ffi.cdef'typedef int64_t off_t;'
	else
		ffi.cdef'typedef long int off_t;'
	end

	print(ffi.sizeof('off_t'))

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

--demo

if not ... then
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

return mmap
