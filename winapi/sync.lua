
--proc/system/sync: Synchronization API
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.winbase'

ffi.cdef[[
HANDLE CreateMutexW(
	LPSECURITY_ATTRIBUTES lpMutexAttributes,
	BOOL                  bInitialOwner,
	LPCWSTR               lpName
);
]]

local ERROR_ACCESS_DENIED = 0x5
local ERROR_ALREADY_EXISTS = 0xB7
local errors = {
	[ERROR_ACCESS_DENIED] = 'access_denied',
	[ERROR_ALREADY_EXISTS] = 'already_exists',
}

function CreateMutex(sec, initial_owner, name)
	local h = checkh(C.CreateMutexW(sec, initial_owner, wcs(name)))
	local err = GetLastError()
	if err == 0 then return h end
	return h, errors[err] or err
end

if not ... then
	print(CreateMutex(nil, false, 'my mutex'))
end
