
--proc/system/process: Process API
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.winbase'

ffi.cdef[[
typedef struct _STARTUPINFOW {
	DWORD   cb;
	LPWSTR  lpReserved;
	LPWSTR  lpDesktop;
	LPWSTR  lpTitle;
	DWORD   dwX;
	DWORD   dwY;
	DWORD   dwXSize;
	DWORD   dwYSize;
	DWORD   dwXCountChars;
	DWORD   dwYCountChars;
	DWORD   dwFillAttribute;
	DWORD   dwFlags;
	WORD    wShowWindow;
	WORD    cbReserved2;
	LPBYTE  lpReserved2;
	HANDLE  hStdInput;
	HANDLE  hStdOutput;
	HANDLE  hStdError;
} STARTUPINFOW, *LPSTARTUPINFOW;

void GetStartupInfoW(LPSTARTUPINFOW lpStartupInfo);
]]

STARTF_USESHOWWINDOW    = 0x00000001
STARTF_USESIZE          = 0x00000002
STARTF_USEPOSITION      = 0x00000004
STARTF_USECOUNTCHARS    = 0x00000008
STARTF_USEFILLATTRIBUTE = 0x00000010
STARTF_RUNFULLSCREEN    = 0x00000020  --ignored for non-x86 platforms
STARTF_FORCEONFEEDBACK  = 0x00000040
STARTF_FORCEOFFFEEDBACK = 0x00000080
STARTF_USESTDHANDLES    = 0x00000100
STARTF_USEHOTKEY        = 0x00000200
STARTF_TITLEISLINKNAME  = 0x00000800
STARTF_TITLEISAPPID     = 0x00001000
STARTF_PREVENTPINNING   = 0x00002000

STARTUPINFO = types.STARTUPINFOW

function GetStartupInfo(si)
	si = STARTUPINFO(si)
	C.GetStartupInfoW(si)
	return si
end

--CreateProcess: dwCreationFlag values
DEBUG_PROCESS               = 0x00000001
DEBUG_ONLY_THIS_PROCESS     = 0x00000002
CREATE_SUSPENDED            = 0x00000004
DETACHED_PROCESS            = 0x00000008
CREATE_NEW_CONSOLE          = 0x00000010
NORMAL_PRIORITY_CLASS       = 0x00000020
IDLE_PRIORITY_CLASS         = 0x00000040
HIGH_PRIORITY_CLASS         = 0x00000080
REALTIME_PRIORITY_CLASS     = 0x00000100
BELOW_NORMAL_PRIORITY_CLASS = 0x00004000
ABOVE_NORMAL_PRIORITY_CLASS = 0x00008000
CREATE_NEW_PROCESS_GROUP    = 0x00000200
CREATE_UNICODE_ENVIRONMENT  = 0x00000400
CREATE_SEPARATE_WOW_VDM     = 0x00000800
CREATE_SHARED_WOW_VDM       = 0x00001000
STACK_SIZE_PARAM_IS_A_RESERVATION = 0x00010000
CREATE_BREAKAWAY_FROM_JOB   = 0x01000000
CREATE_DEFAULT_ERROR_MODE   = 0x04000000
CREATE_NO_WINDOW            = 0x08000000
PROFILE_USER                = 0x10000000
PROFILE_KERNEL              = 0x20000000
PROFILE_SERVER              = 0x40000000

ffi.cdef[[
typedef struct _PROCESS_INFORMATION {
	HANDLE hProcess;
	HANDLE hThread;
	DWORD  dwProcessId;
	DWORD  dwThreadId;
} PROCESS_INFORMATION, *LPPROCESS_INFORMATION;

BOOL CreateProcessW(
	LPCWSTR lpApplicationName,
	LPWSTR lpCommandLine,
	LPSECURITY_ATTRIBUTES lpProcessAttributes,
	LPSECURITY_ATTRIBUTES lpThreadAttributes,
	BOOL bInheritHandles,
	DWORD dwCreationFlags,
	LPCSTR lpEnvironment,
	LPCWSTR lpCurrentDirectory,
	LPSTARTUPINFOW lpStartupInfo,
	LPPROCESS_INFORMATION lpProcessInformation
);

BOOL GetExitCodeProcess(
	HANDLE hProcess,
	LPDWORD lpExitCode
);

BOOL TerminateProcess(
	HANDLE hProcess,
	UINT uExitCode
);

HANDLE GetCurrentProcess();

HANDLE GetStdHandle(
	DWORD nStdHandle
);
]]

PROCESS_INFORMATION = types.PROCESS_INFORMATION

ffi.cdef[[
BOOL FreeEnvironmentStringsW(LPWCH penv);
LPWCH GetEnvironmentStringsW();
DWORD GetEnvironmentVariableW(
	LPCWSTR lpName,
	LPWSTR  lpBuffer,
	DWORD   nSize
);
BOOL SetEnvironmentVariableW(
	LPCWSTR lpName,
	LPCWSTR lpValue
);
]]

--{var = val, ...} -> 'var1=val1\0...'
local function encode_env(env)
	if not env then return nil end
	if type(env) == 'string' or type(env) == 'cdata' then
		return env
	end
	local t = {}
	for k in pairs(env) do
		t[#t+1] = k
	end
	table.sort(t) --Windows says they must be sorted in Unicode order, pff...
	local dt = {}
	for i,k in ipairs(t) do
		dt[i] = k:gsub('[%z=]', '_') .. '=' .. tostring(env[k])
	end
	table.insert(dt, '')
	return table.concat(dt, '\0')..'\0' --Lua adds the last \0
end

function CreateProcess(
	cmd, env, cur_dir,
	start_info, inherit_all_handles,
	create_flags, proc_sec_attr, thread_sec_attr
)
	local proc_info = PROCESS_INFORMATION()
	start_info = start_info or STARTUPINFO() --can't be nil.
	local ret, err, code = retnz(C.CreateProcessW(
		nil,
		wcs(cmd),
		proc_sec_attr,
		thread_sec_attr,
		inherit_all_handles or false,
		flags(create_flags),
		encode_env(env),
		wcs(cur_dir),
		start_info,
		proc_info
	))
	if not ret then return nil, err, code end
	return proc_info
end

STILL_ACTIVE = 259

function GetExitCodeProcess(hproc)
	local exitcode = ffi.new'DWORD[1]'
	checknz(C.GetExitCodeProcess(hproc, exitcode))
	local exitcode = exitcode[0]
	if exitcode == STILL_ACTIVE then return nil end
	return exitcode
end

function TerminateProcess(hproc, exitcode)
	return retnzb(C.TerminateProcess(hproc, exitcode or 0))
end

GetCurrentProcess = C.GetCurrentProcess

function GetEnvironmentStrings()
	local ws = ptr(C.GetEnvironmentStringsW())
	if not ws then return nil end
	local i = 0
	local j = 0
	local t = {}
	while true do
		if ws[j] == 0 then
			if i == j then break end
			table.insert(t, mbs(ws + i))
			i = j + 1
		end
		j = j + 1
	end
	checknz(C.FreeEnvironmentStringsW(ws))
	return t
end

local ERROR_ENVVAR_NOT_FOUND = 203

function GetEnvironmentVariable(k) --note: os.getenv() can do the same.
	local k = wcs(k)
	local sz, err, code = retnz(C.GetEnvironmentVariableW(k, nil, 0))
	if code == ERROR_ENVVAR_NOT_FOUND then return nil end --not found
	assert(sz, err)
	local buf, sz = WCS(sz)
	checknz(C.GetEnvironmentVariableW(k, buf, sz))
	return mbs(buf)
end

function SetEnvironmentVariable(k, v)
	return checknz(C.SetEnvironmentVariableW(wcs(k), v and wcs(tostring(v)) or nil))
end

STD_INPUT_HANDLE  = tonumber(ffi.cast('DWORD', -10))
STD_OUTPUT_HANDLE = tonumber(ffi.cast('DWORD', -11))
STD_ERROR_HANDLE  = tonumber(ffi.cast('DWORD', -12))

local checkvh = checkwith(function(h) return h ~= INVALID_HANDLE_VALUE, h end)
function GetStdHandle(handle)
	return checkvh(C.GetStdHandle(flags(handle)))
end

--job objects ----------------------------------------------------------------

ffi.cdef[[
HANDLE CreateJobObjectW(
	LPSECURITY_ATTRIBUTES lpJobAttributes,
	LPCWSTR               lpName
);

BOOL AssignProcessToJobObject(
	HANDLE hJob,
	HANDLE hProcess
);

typedef struct _JOBOBJECT_BASIC_LIMIT_INFORMATION {
	LARGE_INTEGER PerProcessUserTimeLimit;
	LARGE_INTEGER PerJobUserTimeLimit;
	DWORD LimitFlags;
	SIZE_T MinimumWorkingSetSize;
	SIZE_T MaximumWorkingSetSize;
	DWORD ActiveProcessLimit;
	ULONG_PTR Affinity;
	DWORD PriorityClass;
	DWORD SchedulingClass;
} JOBOBJECT_BASIC_LIMIT_INFORMATION, *PJOBOBJECT_BASIC_LIMIT_INFORMATION;

typedef struct _IO_COUNTERS {
    ULONGLONG  ReadOperationCount;
    ULONGLONG  WriteOperationCount;
    ULONGLONG  OtherOperationCount;
    ULONGLONG ReadTransferCount;
    ULONGLONG WriteTransferCount;
    ULONGLONG OtherTransferCount;
} IO_COUNTERS;

typedef struct _JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
	JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
	IO_COUNTERS                       IoInfo;
	SIZE_T                            ProcessMemoryLimit;
	SIZE_T                            JobMemoryLimit;
	SIZE_T                            PeakProcessMemoryUsed;
	SIZE_T                            PeakJobMemoryUsed;
} JOBOBJECT_EXTENDED_LIMIT_INFORMATION, *PJOBOBJECT_EXTENDED_LIMIT_INFORMATION;

typedef enum _JOBOBJECTINFOCLASS {
	JobObjectBasicAccountingInformation = 1,
	JobObjectBasicLimitInformation,
	JobObjectBasicProcessIdList,
	JobObjectBasicUIRestrictions,
	JobObjectSecurityLimitInformation,  // deprecated
	JobObjectEndOfJobTimeInformation,
	JobObjectAssociateCompletionPortInformation,
	JobObjectBasicAndIoAccountingInformation,
	JobObjectExtendedLimitInformation,
	JobObjectJobSetInformation,
	JobObjectGroupInformation,
	MaxJobObjectInfoClass
} JOBOBJECTINFOCLASS;

BOOL SetInformationJobObject(
	HANDLE             hJob,
	JOBOBJECTINFOCLASS JobObjectInformationClass,
	LPVOID             lpJobObjectInformation,
	DWORD              cbJobObjectInformationLength
);

BOOL IsProcessInJob(
	HANDLE ProcessHandle,
	HANDLE JobHandle,
	PBOOL  Result
);
]]

function CreateJobObject(name, sa)
	return checkh(C.CreateJobObjectW(sa, wcs(name)))
end

function AssignProcessToJobObject(job, proc)
	return checknz(C.AssignProcessToJobObject(job, proc))
end

--Basic Limits

JOB_OBJECT_LIMIT_WORKINGSET                 = 0x00000001
JOB_OBJECT_LIMIT_PROCESS_TIME               = 0x00000002
JOB_OBJECT_LIMIT_JOB_TIME                   = 0x00000004
JOB_OBJECT_LIMIT_ACTIVE_PROCESS             = 0x00000008
JOB_OBJECT_LIMIT_AFFINITY                   = 0x00000010
JOB_OBJECT_LIMIT_PRIORITY_CLASS             = 0x00000020
JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME          = 0x00000040
JOB_OBJECT_LIMIT_SCHEDULING_CLASS           = 0x00000080

--Extended Limits
JOB_OBJECT_LIMIT_PROCESS_MEMORY             = 0x00000100
JOB_OBJECT_LIMIT_JOB_MEMORY                 = 0x00000200
JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = 0x00000400
JOB_OBJECT_LIMIT_BREAKAWAY_OK               = 0x00000800
JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK        = 0x00001000
JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE          = 0x00002000
JOB_OBJECT_LIMIT_SUBSET_AFFINITY            = 0x00004000

--UI restrictions for jobs

JOB_OBJECT_UILIMIT_NONE             = 0x00000000

JOB_OBJECT_UILIMIT_HANDLES          = 0x00000001
JOB_OBJECT_UILIMIT_READCLIPBOARD    = 0x00000002
JOB_OBJECT_UILIMIT_WRITECLIPBOARD   = 0x00000004
JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = 0x00000008
JOB_OBJECT_UILIMIT_DISPLAYSETTINGS  = 0x00000010
JOB_OBJECT_UILIMIT_GLOBALATOMS      = 0x00000020
JOB_OBJECT_UILIMIT_DESKTOP          = 0x00000040
JOB_OBJECT_UILIMIT_EXITWINDOWS      = 0x00000080

JOB_OBJECT_UILIMIT_ALL              = 0x000000FF

JOB_OBJECT_SECURITY_NO_ADMIN            = 0x00000001
JOB_OBJECT_SECURITY_RESTRICTED_TOKEN    = 0x00000002
JOB_OBJECT_SECURITY_ONLY_TOKEN          = 0x00000004
JOB_OBJECT_SECURITY_FILTER_TOKENS       = 0x00000008

JOBOBJECT_EXTENDED_LIMIT_INFORMATION = struct{
	ctype = 'JOBOBJECT_EXTENDED_LIMIT_INFORMATION',
}

function SetInformationJobObject(job, objinfoclass, objinfo)
	objinfo = JOBOBJECT_EXTENDED_LIMIT_INFORMATION(objinfo)
	return checknz(C.SetInformationJobObject(job, objinfoclass,
		objinfo, ffi.sizeof(objinfo)))
end

local bbuf = ffi.new'BOOL[1]'
function IsProcessInJob(p, job)
	checknz(C.IsProcessInJob(p, job, bbuf))
	return bbuf[0] ~= 0
end

--self-test ------------------------------------------------------------------

if not ... then
	local si = GetStartupInfo()
	assert(si.wShowWindow == 0)

	SetEnvironmentVariable('az', '333')
	SetEnvironmentVariable('wa', '555')
	assert(GetEnvironmentVariable'wa' == '555')
	SetEnvironmentVariable'wa'
	assert(not GetEnvironmentVariable'wa')
	require'pp'(GetEnvironmentStrings())
end

