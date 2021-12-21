
--proc/system/module: LoadLibrary API
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.winuser'

ffi.cdef[[
HMODULE GetModuleHandleW(
	LPCWSTR lpModuleName
);

BOOL GetModuleHandleExW(
	DWORD dwFlags,
	LPCWSTR lpModuleName,
	HMODULE* phModule
);

DWORD GetModuleFileNameW(
	HMODULE hModule,
	LPWSTR  lpFilename,
	DWORD   nSize
);

HMODULE LoadLibraryW(LPCWSTR lpLibFileName);
]]

function GetModuleHandle(name)
	return checkh(C.GetModuleHandleW(wcs(name)))
end

GET_MODULE_HANDLE_EX_FLAG_PIN                 = 0x00000001
GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT  = 0x00000002
GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS        = 0x00000004

function GetModuleHandleEx(name, GMHX, h)
	h = h or arrays.HMODULE(1)
	checknz(C.GetModuleHandleExW(flags(GMHX), wcs(name), h))
	return h[0]
end

local ERROR_INSUFFICIENT_BUFFER = 122

function GetModuleFilename(hmodule)
	local bsz = 2048
	::again::
	local buf = WCS(bsz)
	local sz = checkpoz(C.GetModuleFileNameW(hmodule, buf, bsz))
	if GetLastError() == ERROR_INSUFFICIENT_BUFFER then
		bsz = bsz * 2
		goto again
	end
	return mbs(buf, sz)
end

function LoadLibrary(filename)
    return checkh(C.LoadLibraryW(wcs(filename)))
end

if not ... then
	local file = GetModuleFilename()
	print(file)
	print(GetModuleHandle())
	print(GetModuleHandleEx(file))
	print(LoadLibrary'shell32')
end
