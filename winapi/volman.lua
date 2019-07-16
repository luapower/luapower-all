
--proc/volman: Volume Management API
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')

ffi.cdef[[
BOOL GetVolumeInformationW(
	LPCWSTR lpRootPathName,
	LPWSTR  lpVolumeNameBuffer,
	DWORD   nVolumeNameSize,
	LPDWORD lpVolumeSerialNumber,
	LPDWORD lpMaximumComponentLength,
	LPDWORD lpFileSystemFlags,
	LPWSTR  lpFileSystemNameBuffer,
	DWORD   nFileSystemNameSize
);
]]

--lpFileSystemFlags bits
FILE_CASE_SENSITIVE_SEARCH          = 0x00000001
FILE_CASE_PRESERVED_NAMES           = 0x00000002
FILE_DAX_VOLUME                     = 0x20000000
FILE_FILE_COMPRESSION               = 0x00000010
FILE_NAMED_STREAMS                  = 0x00040000
FILE_PERSISTENT_ACLS                = 0x00000008
FILE_READ_ONLY_VOLUME               = 0x00080000
FILE_SEQUENTIAL_WRITE_ONCE          = 0x00100000
FILE_SUPPORTS_ENCRYPTION            = 0x00020000
FILE_SUPPORTS_EXTENDED_ATTRIBUTES   = 0x00800000
FILE_SUPPORTS_HARD_LINKS            = 0x00400000
FILE_SUPPORTS_OBJECT_IDS            = 0x00010000
FILE_UNICODE_ON_DISK                = 0x00000004
FILE_VOLUME_QUOTAS                  = 0x00000020
FILE_SUPPORTS_SPARSE_FILES          = 0x00000040
FILE_SUPPORTS_REPARSE_POINTS        = 0x00000080
FILE_SUPPORTS_REMOTE_STORAGE        = 0x00000100
FILE_VOLUME_IS_COMPRESSED           = 0x00008000
FILE_SUPPORTS_TRANSACTIONS          = 0x00200000
FILE_SUPPORTS_OPEN_BY_FILE_ID       = 0x01000000
FILE_SUPPORTS_USN_JOURNAL           = 0x02000000

local name_buf, serial_buf, len_buf, flags_buf, fsname_buf
function GetVolumeInformation(path)
	local MAX_PATH = 260
	if not name_buf then
		name_buf   = WCS(MAX_PATH+1)
		serial_buf = ffi.new'DWORD[1]'
		len_buf    = ffi.new'DWORD[1]'
		flags_buf  = ffi.new'DWORD[1]'
		fsname_buf = WCS(MAX_PATH+1)
	end
	local last_errmode = SetErrorMode(SEM_FAILCRITICALERRORS)
	local ret = C.GetVolumeInformationW(wcs(path),
		name_buf, MAX_PATH+1,
		serial_buf, len_buf, flags_buf,
		fsname_buf, MAX_PATH+1
	)
	SetErrorMode(last_errmode)
	checknz(ret)
	return {
		volume_name = mbs(name_buf),
		volume_serial = serial_buf[0],
		max_component_length = len_buf[0],
		filesystem_flags = flags_buf[0],
		filesystem_name = mbs(fsname_buf),
	}
end

if not ... then
	require'pp'(GetVolumeInformation'C:\\')
end
