
--rs232 serial communication library for LuaJIT.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local fs = require'fs'
local C = ffi.C

local rs = {}

if ffi.abi'win' then

	ffi.cdef[[
	uint32_t GetLastError(void);

	typedef struct _COMMTIMEOUTS {
		 uint32_t ReadIntervalTimeout;
		 uint32_t ReadTotalTimeoutMultiplier;
		 uint32_t ReadTotalTimeoutConstant;
		 uint32_t WriteTotalTimeoutMultiplier;
		 uint32_t WriteTotalTimeoutConstant;
	} COMMTIMEOUTS;

	typedef struct _DCB {
		 uint32_t DCBlength;
		 uint32_t BaudRate;
		 uint32_t fBinary  :1;
		 uint32_t fParity  :1;
		 uint32_t fOutxCtsFlow  :1;
		 uint32_t fOutxDsrFlow  :1;
		 uint32_t fDtrControl  :2;
		 uint32_t fDsrSensitivity  :1;
		 uint32_t fTXContinueOnXoff  :1;
		 uint32_t fOutX  :1;
		 uint32_t fInX  :1;
		 uint32_t fErrorChar  :1;
		 uint32_t fNull  :1;
		 uint32_t fRtsControl  :2;
		 uint32_t fAbortOnError  :1;
		 uint32_t fDummy2  :17;
		 uint16_t wReserved;
		 uint16_t XonLim;
		 uint16_t XoffLim;
		 uint8_t  ByteSize;
		 uint8_t  Parity;
		 uint8_t  StopBits;
		 int8_t  XonChar;
		 int8_t  XoffChar;
		 int8_t  ErrorChar;
		 int8_t  EofChar;
		 int8_t  EvtChar;
		 uint16_t wReserved1;
	} DCB;

	uint32_t QueryDosDeviceA(const char * lpDeviceName, char * lpTargetPath, uint32_t ucchMax);

	int GetCommState(void *hFile, DCB *lpDCB);
	int GetCommTimeouts(void *hFile, COMMTIMEOUTS *lpCommTimeouts);
	int SetCommState(void *hFile, DCB *lpDCB);
	int SetCommTimeouts(void *hFile, COMMTIMEOUTS *lpCommTimeouts);
	int SetupComm(void * hFile, uint32_t dwInQueue, uint32_t dwOutQueue);
	]]

	local ERROR_INSUFFICIENT_BUFFER   = 122

	local INVALID_HANDLE_VALUE        = -1
	local GENERIC_READ                = 0x80000000
	local GENERIC_WRITE               = 0x40000000
	local OPEN_EXISTING               = 3
	local MAX_DWORD                   = 0xFFFFFFFF

	function rs.ports()
		local sz = 1024 * 16
		local buf = ffi.new('uint8_t[?]', sz)
		local n = C.QueryDosDeviceA(nil, buf, sz)
		while(n == 0 and C.GetLastError() == ERROR_INSUFFICIENT_BUFFER) do
			sz = sz * 2
			buf = ffi.new('uint8_t[?]', sz)
			n = C.QueryDosDeviceA(nil, buf, sz)
		end
		if n == 0 then
			local err = C.GetLastError()
			return nil, 'QueryDosDevice() error '.. err, err
		end
		local t = {}
		for s in ffi.string(buf, n):gmatch'COM([^%z]+)' do
			t[#t+1] = tonumber(s)
		end
		return t
	end

	function rs.open(port, baudrate)
		local f = fs.open('//./COM'..port, 'w')

		C.SetupComm(f.handle, 64, 64)

		local timeouts = ffi.new'COMMTIMEOUTS'
		timeouts.ReadIntervalTimeout = 0xffffffff
		C.SetCommTimeouts(f.handle, timeouts)

		local config = ffi.new'DCB'
		C.GetCommState(f.handle, config)
		config.BaudRate = baudrate or 9600
		config.fBinary = -1
		config.fParity = 0
		config.fErrorChar = 0
		config.fNull = 0
		config.fAbortOnError = 0
		config.ByteSize = 8
		config.Parity = 0
		config.StopBits = 0
		config.EvtChar = 10

		if C.SetCommState(f.handle, config) == 0 then
			f:close()
			local err = C.GetLastError()
			return nil, 'SetCommState() error '.. err, err
		end

		return f
	end

else

	function rs.ports()

	end

	function rs.open(port, baudrate)

	end

end

if not ... then

	pp(rs.ports())

	local f = assert(rs.open(4))

	f:close()

	return rs

end
