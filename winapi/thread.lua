
--proc/system/thread: Threads API
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'

setfenv(1, require'winapi')
require'winapi.winbase'

ffi.cdef[[
typedef DWORD (*LPTHREAD_START_ROUTINE)(LPVOID lpThreadParameter);

HANDLE CreateThread(
	LPSECURITY_ATTRIBUTES   lpThreadAttributes,
	SIZE_T                  dwStackSize,
	LPTHREAD_START_ROUTINE  lpStartAddress,
	LPVOID                  lpParameter,
	DWORD                   dwCreationFlags,
	LPDWORD                 lpThreadId
);
]]

