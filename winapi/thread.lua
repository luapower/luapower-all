
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

DWORD ResumeThread(
	HANDLE hThread
);
]]

function ResumeThread(h)
	local sc = C.ResumeThread(h)
	if sc == 4294967295 then sc = -1 end
	return retpoz(sc)
end
