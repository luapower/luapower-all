-- LuaSocket-API like and BNet-API like source code
-- Author: Matías "Starkkz" Hermosilla
-- License: MIT

local ffi = require("ffi")
local bit = require("bit")
local sock, errno = unpack(require("bnet_h"))
local C = ffi.C

local SOMAXCONN = 128

local INVALID_SOCKET = -1
local INADDR_ANY = 0
local INADDR_NONE = 0XFFFFFFFF

local AF_INET = 2
local SOCK_STREAM = 1
local SOCK_DGRAM = 2
local SOCKET_ERROR = -1

local SD_RECEIVE = 0
local SD_SEND = 1
local SD_BOTH = 2

local TCP_TIMEOUT = 255 + 256 ^ 2 + 256 ^ 3 + 256 ^ 4
local UDP_TIMEOUT = 255 + 256 ^ 2 + 256 ^ 3 + 256 ^ 4

local socket = {
	_VERSION = "LuaSocket 2.0.2",
	_BNETVERSION = "0.0.3",
	_DEBUG = false
}

local FIONREAD
local ioctl_, fd_lib
if ffi.os == "Windows" then
	FIONREAD = 0x4004667F

	local WSADATA = ffi.new("WSADATA")
	sock.WSAStartup(0x101, WSADATA)
	ffi.C.atexit(sock.WSACleanup)

	fd_lib = {
		FD_CLR = function (fd, set)
			for i = 0, set.fd_count do
				if set.fd_array[i] == fd then
					while i < set.fd_count-1 do
						set.fd_array[i] = set.fd_array[i + 1]
						i = i + 1
					end
					set.fd_count = set.fd_count - 1
					break
				end
			end
		end,
		FD_SET = function (fd, set)
			local Index = 0
			for i = 0, set.fd_count do
				if set.fd_array[i] == fd then
					Index = i
					break
				end
			end

			if Index == set.fd_count then
				if set.fd_count < 64 then
					set.fd_array[Index] = fd
					set.fd_count = set.fd_count + 1
				end
			end
		end,
		FD_ZERO = function (set)
			set.fd_count = 0
		end,
		FD_ISSET = sock.__WSAFDIsSet,
	}

	function ioctl_(s, cmd, argp)
		return sock.ioctlsocket(s, cmd, argp)
	end
else
	sock = ffi.C

	fd_lib = {
		FD_CLR = function (fd, set)
			for i = 0, set.fd_count do
				if set.fd_array[i] == fd then
					while i < set.fd_count-1 do
						set.fd_array[i] = set.fd_array[i + 1]
						i = i + 1
					end
					set.fd_count = set.fd_count - 1
					break
				end
			end
		end,
		FD_SET = function (fd, set)
			local Index = 0
			for i = 0, set.fd_count do
				if set.fd_array[i] == fd then
					Index = i
					break
				end
			end

			if Index == set.fd_count then
				if set.fd_count < 64 then
					set.fd_array[Index] = fd
					set.fd_count = set.fd_count + 1
				end
			end
		end,
		FD_ZERO = function (set)
			set.fd_count = 0
		end,
		FD_ISSET = function (fd, set)
			for i = 0, set.fd_count do
				if set.fd_array[i] == fd then
					return true
				end
			end
			return false
		end,
	}

	function ioctl_(s, cmd, argp)
		return sock.ioctl(s, cmd, argp)
	end

	if ffi.os == "MacOS" then
		FIONREAD = 0x4004667F
	else --if ffi.os == "Linux" then
		FIONREAD = 0x0000541B
	end
end

local closesocket_
if ffi.os == "Windows" then
	function closesocket_(s)
		return sock.closesocket(s)
	end
else
	function closesocket_(s)
		return sock.close(s)
	end
end

local function bind_(socket, addr_type, port)
	local sa = ffi.new("struct sockaddr_in")
	if addr_type ~= AF_INET then
		return -1
	end

	ffi.fill(sa, 0, ffi.sizeof(sa))
	sa.sin_family = addr_type
	sa.sin_addr.s_addr = sock.htonl(INADDR_ANY)
	sa.sin_port = sock.htons(port)

	local _sa = ffi.cast("struct sockaddr *", sa)
	return sock.bind(socket, _sa, ffi.sizeof(sa))
end

local function gethostbyaddr_(addr, addr_len, addr_type)
	local e = sock.gethostbyaddr(addr, addr_len, addr_type)
	if e ~= nil then
		return e.h_name
	end
end

local function gethostbyname_(name)
	local e = sock.gethostbyname(name)
	if e ~= nil then
		return e.h_addr_list, e.h_addrtype, e.h_length
	end
end

local function connect_(socket, addr, addr_type, addr_len, port)
	local sa = ffi.new("struct sockaddr_in")
	if addr_type == AF_INET then
		ffi.fill(sa, 0, ffi.sizeof(sa))
		sa.sin_family = addr_type
		sa.sin_port = sock.htons(port)
		ffi.copy(sa.sin_addr, addr, addr_len)

		local Addr = ffi.cast("struct sockaddr *", sa)
		return sock.connect(socket, Addr, ffi.sizeof(sa))
	end
	return SOCKET_ERROR
end

local function select_(n_read, r_socks, n_write, w_socks, n_except, e_socks, timeout)
	local r_set = ffi.new("fd_set")
	local w_set = ffi.new("fd_set")
	local e_set = ffi.new("fd_set")

	r_socks = r_socks or {}
	w_socks = w_socks or {}
	e_socks = e_socks or {}

	local n = -1

	fd_lib.FD_ZERO(r_set)
	for i = 0, n_read do
		if r_socks[i] then
			fd_lib.FD_SET(r_socks[i], r_set)
			if r_socks[i] > n then
				n = r_socks[i]
			end
		end
	end

	fd_lib.FD_ZERO(w_set)
	for i = 0, n_write do
		if w_socks[i] then
			fd_lib.FD_SET(w_socks[i], w_set)
			if w_socks[i] > n then
				n = w_socks[i]
			end
		end
	end

	fd_lib.FD_ZERO(e_set)
	for i = 0, n_except do
		if e_socks[i] then
			fd_lib.FD_SET(e_socks[i], e_set)
			if e_socks[i] > n then
				n = e_socks[i]
			end
		end
	end

	local TimevalPtr
	if timeout < 0 then
		TimevalPtr = ffi.new("struct timeval[0]")
	else
		local Timeval = ffi.new("struct timeval", {tv_sec = timeout / 1000, tv_usec = (timeout % 1000) / 1000})
		TimevalPtr = ffi.new("struct timeval [1]", Timeval)
	end

	local r = sock.select(n + 1, r_set, w_set, e_set, TimevalPtr)
	if r < 0 then
		return r
	end

	for i = 0, n_read do
		if r_socks[i] and not fd_lib.FD_ISSET(r_socks[i], r_set) then
			r_socks[i] = nil
		end
	end
	for i = 0, n_write do
		if w_socks[i] and not fd_lib.FD_ISSET(w_socks[i], w_set) then
			w_rocks[i] = nil
		end
	end
	for i = 0, n_except do
		if e_socks[i] and not fd_lib.FD_ISSET(e_socks[i], e_set) then
			e_socks[i] = nil
		end
	end
	return r
end

local function sendto_(socket, buf, size, flags, dest_ip, dest_port)
	local sa = ffi.new("struct sockaddr_in")
	ffi.fill(sa, 0, ffi.sizeof(sa))

	sa.sin_family = AF_INET
	sa.sin_addr.s_addr = sock.inet_addr(dest_ip)
	sa.sin_port = sock.htons(dest_port)
	return sock.sendto(socket, buf, size, flags, ffi.cast("struct sockaddr *", sa), ffi.sizeof(sa))
end

local function recvfrom_(socket, buf, size, flags)
	local sa = ffi.new("struct sockaddr_in")
	ffi.fill(sa, 0, ffi.sizeof(sa))

	local sasize = ffi.new("int[1]", ffi.sizeof(sa))
	local count = sock.recvfrom(socket, buf, size, flags, ffi.cast("struct sockaddr *", sa), sasize)
	return count, sock.inet_ntoa(sa.sin_addr), sock.ntohs(sa.sin_port)
end

local IO_DONE = 0
local IO_TIMEOUT = -1
local IO_CLOSED = -2

local function io_strerror(err)
	if err == IO_DONE then
		return "closed"
	elseif err == IO_CLOSED then
		return "closed"
	elseif err == IO_TIMEOUT then
		return "timeout"
	end
	return "unknown error"
end

local socket_strerror
if ffi.os == "Windows" then
	local WSAEINTR = 10004
	local WSAEACCES = 10013
	local WSAEFAULT = 10014
	local WSAEINVAL = 10022
	local WSAEMFILE = 10024
	local WSAEWOULDBLOCK = 10035
	local WSAEINPROGRESS = 10036
	local WSAEALREADY = 10037
	local WSAENOTSOCK = 10038
	local WSAEDESTADDRREQ = 10039
	local WSAEMSGSIZE = 10040
	local WSAEPROTOTYPE = 10041
	local WSAENOPROTOOPT = 10042
	local WSAEPROTONOSUPPORT = 10043
	local WSAESOCKTNOSUPPORT = 10044
	local WSAEOPNOTSUPP = 10045
	local WSAEPFNOSUPPORT = 10046
	local WSAEAFNOSUPPORT = 10047
	local WSAEADDRINUSE = 10048
	local WSAEADDRNOTAVAIL = 10049
	local WSAENETDOWN = 10050
	local WSAENETUNREACH = 10051
	local WSAENETRESET = 10052
	local WSAECONNABORTED = 10053
	local WSAECONNRESET = 10054
	local WSAENOBUFS = 10055
	local WSAEISCONN = 10056
	local WSAENOTCONN = 10057
	local WSAESHUTDOWN = 10058
	local WSAETIMEDOUT = 10060
	local WSAECONNREFUSED = 10061
	local WSAEHOSTDOWN = 10064
	local WSAEHOSTUNREACH = 10065
	local WSAEPROCLIM = 10067
	local WSASYSNOTREADY = 10091
	local WSAVERNOTSUPPORTED = 10092
	local WSANOTINITIALISED = 10093
	local WSAEDISCON = 10101
	local WSAHOST_NOT_FOUND = 11001
	local WSATRY_AGAIN = 11002
	local WSANO_RECOVERY = 11003
	local WSANO_DATA = 11004

	local function wstrerror(err)
		if err == WSAEINTR then
			return "Interrupted function call"
		elseif err == WSAEACCES then
			return "Permission denied"
		elseif err == WSAEFAULT then
			return "Bad address"
		elseif err == WSAEINVAL then
			return "Invalid argument"
		elseif err == WSAEMFILE then
			return "Too many open files"
		elseif err == WSAEWOULDBLOCK then
			return "Resource temporarily unavailable"
		elseif err == WSAEINPROGRESS then
			return "Operation now in progress"
		elseif err == WSAEALREADY then
			return "Operation already in progress"
		elseif err == WSAENOTSOCK then
			return "Socket operation on nonsocket"
		elseif err == WSAEDESTADDRREQ then
			return "Destination address required"
		elseif err == WSAEMSGSIZE then
			return "Message too long"
		elseif err == WSAEPROTOTYPE then
			return "Protocol wrong type for socket"
		elseif err == WSAENOPROTOOPT then
			return "Bad protocol option"
		elseif err == WSAEPROTONOSUPPORT then
			return "Protocol not supported"
		elseif err == WSAESOCKTNOSUPPORT then
			return "Socket type not supported"
		elseif err == WSAEOPNOTSUPP then
			return "Operation not supported"
		elseif err == WSAEPFNOSUPPORT then
			return "Protocol family not supported"
		elseif err == WSAEAFNOSUPPORT then
			return "Address family not supported by protocol family"
		elseif err == WSAEADDRINUSE then
			return "Address already in use"
		elseif err == WSAEADDRNOTAVAIL then
			return "Cannot assign requested address"
		elseif err == WSAENETDOWN then
			return "Network is down"
		elseif err == WSAENETUNREACH then
			return "Network is unreachable"
		elseif err == WSAENETRESET then
			return "Network dropped connection on reset"
		elseif err == WSAECONNABORTED then
			return "Software caused connection abort"
		elseif err == WSAECONNRESET then
			return "Connection reset by peer"
		elseif err == WSAENOBUFS then
			return "No buffer space available"
		elseif err == WSAEISCONN then
			return "Socket is already connected"
		elseif err == WSAENOTCONN then
			return "Socket is not connected"
		elseif err == WSAESHUTDOWN then
			return "Cannot send after socket shutdown"
		elseif err == WSAETIMEDOUT then
			return "Connection timed out"
		elseif err == WSAECONNREFUSED then
			return "Connection refused"
		elseif err == WSAEHOSTDOWN then
			return "Host is down"
		elseif err == WSAEHOSTUNREACH then
			return "No route to host"
		elseif err == WSAEPROCLIM then
			return "Too many processes"
		elseif err == WSASYSNOTREADY then
			return "Network subsystem is unavailable"
		elseif err == WSAVERNOTSUPPORTED then
			return "Winsock.dll version out of range"
		elseif err == WSANOTINITIALISED then
			return "Successful WSAStartup not yet performed"
		elseif err == WSAEDISCON then
			return "Graceful shutdown in progress"
		elseif err == WSAHOST_NOT_FOUND then
			return "Host not found"
		elseif err == WSATRY_AGAIN then
			return "Nonauthoritative host not found"
		elseif err == WSANO_RECOVERY then
			return "Nonrecoverable name lookup error"
		elseif err == WSANO_DATA then
			return "Valid name, no data record of requested type"
		end
		return "Unknown error"
	end

	local WSAEADDRINUSE = 10048
	local WSAECONNREFUSED = 10061
	local WSAEISCONN = 10056
	local WSAECONNABORTED = 10053
	local WSAECONNRESET = 10054
	local WSAETIMEDOUT = 10060

	function socket_strerror(err)
		if err <= 0 then
			return io_strerror(err)
		elseif err == WSAEADDRINUSE then
			return "address already in use"
		elseif err == WSAECONNREFUSED then
			return "connection refused"
		elseif err == WSAEISCONN then
			return "already connected"
		elseif err == WSAEACCES then
			return "permission denied"
		elseif err == WSAECONNABORTED then
			return "closed"
		elseif err == WSAECONNRESET then
			return "closed"
		elseif err == WSAETIMEDOUT then
			return "timeout"
		end
		return wstrerror(err)
	end
else
	function socket_strerror(err)
		if err <= 0 then
			return io_strerror(err)
		elseif err == EADDRINUSE then
			return "address already in use"
		elseif err == EISCONN then
			return "already connected"
		elseif err == EACCES then
			return "permission denied"
		elseif err == ECONNREFUSED then
			return "connection refused"
		elseif err == ECONNABORTED then
			return "closed"
		elseif err == ECONNRESET then
			return "closed"
		elseif err == ETIMEDOUT then
			return "timeout"
		end
		return ffi.string(C.strerror(err))
	end
end

function socket.CountHostIPs(Host)
	assert(Host)
	local Addresses, AdressType, AddressLength = gethostbyname_(Host)
	if Addresses == nil or AddressType ~= AF_INET or AddressLength ~= 4 then
		return 0
	end

	local Count = 0
	while Addresses[Count] ~= nil do
		Count = Count + 1
	end
	return Count
end

function socket.IntIP(IP)
	local ServerIP = sock.inet_addr(IP)
	if ServerIP == INADDR_NONE then
		local Addresses, AddressType, AddressLength = gethostbyname_(IP)
		if Addresses == nil or AddressType ~= AF_INET or AddressLength ~= 4 then
			return 0
		end
		local PAddress = Addresses[0]
		if PAddress == nil then
			return 0
		end
		return sock.htonl(bit.bor(bit.lshift(PAddress[3], 24), bit.lshift(PAddress[2], 16), bit.lshift(PAddress[1], 8), PAddress[0]))
	end
	return 0
end

function socket.StringIP(IP)
	assert(IP)
	local HTONL = sock.htonl(IP)
	local Addr = ffi.new("struct in_addr")
	Addr.s_addr = HTONL
	local NTOA = sock.inet_ntoa(Addr)
	return ffi.string(NTOA)
end

local TUDPStream = {}
local UDP = {__index = TUDPStream}
ffi.metatype("struct TUDPStream", UDP)

function UDP:__gc()
	self:Close()
end

function TUDPStream:ReadByte()
	local n = ffi.new("byte [1]"); self:Read(n, 1)
	return n[0]
end

function TUDPStream:ReadShort()
	local n = ffi.new("byte [2]"); self:Read(n, 2)
	return n[0] + n[1] * 256
end

function TUDPStream:ReadInt()
	local n = ffi.new("byte [4]"); self:Read(n, 4)
	return n[0] + n[1] * 256 + n[2] * 65536 + n[3] * 16777216
end

function TUDPStream:ReadLong()
	local n = ffi.new("byte [8]"); self:Read(n, 8)
	local Value = ffi.new("unsigned long")
	local LongByte = ffi.new("unsigned long", 256)
	for i = 0, 7 do
		Value = Value + ffi.new("unsigned long", n[i]) * LongByte ^ i
	end
	return Value
end

function TUDPStream:ReadLine()
	local Buffer = ""
	local Size = 0
	while self:Size() > 0 do
		local Char = self:ReadByte()
		if Char == 10 or Char == 0 then
			break
		end
		if Char ~= 13 then
			Buffer = Buffer .. char(Char)
		end
	end
	return Buffer
end

function TUDPStream:ReadString(Length)
	if Length > 0 then
		local Buffer = ffi.new("byte [?]", Length); self:Read(Buffer, Length)
		return ffi.string(Buffer, Length)
	end
	return ""
end

function TUDPStream:WriteByte(n)
	local q = ffi.new("byte [1]")
	q[0] = bit.band(n, 0xff)
	return self:Write(q, 1)
end

function TUDPStream:WriteShort(n)
	local q = ffi.new("byte [2]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff)
	return self:Write(q, 2)
end

function TUDPStream:WriteInt(n)
	local q = ffi.new("byte [4]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff); n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff); n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff)
	return self:WriteBytes(q, 4)
end

function TUDPStream:WriteLong(n)
	local q = ffi.new("byte [8]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff); n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff); n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff); n = bit.rshift(n - q[3], 8)
	q[4] = bit.band(n, 0xff); n = bit.rshift(n - q[4], 8)
	q[5] = bit.band(n, 0xff); n = bit.rshift(n - q[5], 8)
	q[6] = bit.band(n, 0xff); n = bit.rshift(n - q[6], 8)
	q[7] = bit.band(n, 0xff)
	return self:WriteBytes(q, 8)
end

function TUDPStream:WriteLine(String)
	local Line = String .. "\n"
	return self:Write(Line, #Line)
end

function TUDPStream:WriteString(String)
	return self:Write(String, #String)
end

function TUDPStream:Read(Buffer, Size)
	local Size = math.min(Size, self.RecvSize)
	if Size > 0 then
		ffi.copy(Buffer, self.RecvBuffer, Size)
		if Size < self.RecvSize then
			self.RecvBuffer = self.RecvBuffer + Size
			self.RecvSize = self.RecvSize - Size
		else
			self.RecvBuffer = ffi.new("byte [0]")
			self.RecvSize = 0
		end
	end
	return Size
end

function TUDPStream:Write(Buffer, Size)
	local NewBuffer = ffi.new("byte [?]", self.SendSize + Size)
	if self.SendSize > 0 then
		ffi.copy(NewBuffer, self.SendBuffer, self.SendSize)
		ffi.copy(NewBuffer + self.SendSize, Buffer, Size)
		self.SendBuffer = NewBuffer
		self.SendSize = self.SendSize + Size
	else
		ffi.copy(NewBuffer, Buffer, Size)
		self.SendBuffer = NewBuffer
		self.SendSize = Size
	end
	return Size
end

function TUDPStream:Size()
	return self.RecvSize
end

function TUDPStream:Eof()
	if self.Socket == INVALID_SOCKET then
		return true
	end
	return self.RecvSize == 0
end

function TUDPStream:Close()
	if self.Socket ~= INVALID_SOCKET then
		local Error = sock.shutdown(self.Socket, SD_BOTH)
		if Error ~= 0 then
			return false, socket_strerror(Error)
		end

		local Error = closesocket_(self.Socket)
		if Error ~= 0 then
			return false, socket_strerror(Error)
		end
		self.Socket = INVALID_SOCKET
	end
end

function TUDPStream:Timeout(Recv)
	assert(Recv)
	if Recv >= 0 then
		self.Timeout = ffi.new("unsigned int", Recv or 0)
	end
end

function TUDPStream:SendTo(IP, Port)
	if self.Socket == INVALID_SOCKET or self.SendSize == 0 then
		return false
	end

	if select_(0, nil, 1, {self.Socket}, 0, nil, 0) ~= 1 then
		return false
	end

	if not Port or Port == 0 then
		Port = self.MessagePort
	end
	if not IP then
		IP = ffi.string(self.MessageIP)
	end

	local Result = sendto_(self.Socket, ffi.string(self.SendBuffer, self.SendSize), self.SendSize, 0, IP, Port)
	if Result == SOCKET_ERROR or Result == 0 then
		return false
	end

	if Result == self.SendSize then
		self.SendBuffer = ffi.new("byte [0]")
		self.SendSize = 0
		return true
	end

	local NewBuffer = ffi.new("byte [?]", self.SendSize - Result)
	ffi.copy(NewBuffer, self.SendBuffer + Result, self.SendSize - Result)
	self.SendBuffer = NewBuffer
	self.SendSize = self.SendSize - Result
	return true
end

function TUDPStream:RecvFrom()
	if self.Socket == INVALID_SOCKET then
		return false
	end

	if select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeout) ~= 1 then
		return false
	end

	local Size = ffi.new("int [1]")
	if ioctl_(self.Socket, FIONREAD, Size) == SOCKET_ERROR then
		return false
	end

	Size = Size[0]
	if Size <= 0 then
		return false
	end

	if self.RecvSize > 0 then
		local NewBuffer = ffi.new("byte [?]", self.RecvSize + Size)
		ffi.copy(NewBuffer, self.RecvBuffer, self.RecvSize)
		self.RecvBuffer = NewBuffer
	else
		self.RecvBuffer = ffi.new("byte [?]", Size)
	end

	local Result, MessageIP, MessagePort = recvfrom_(self.Socket, self.RecvBuffer + self.RecvSize, Size, 0)
	if Result == SOCKET_ERROR or Result == 0 then
		return false
	end
	self.MessageIP = MessageIP
	self.MessagePort = MessagePort
	self.RecvSize = self.RecvSize + Result
	return MessageIP, MessagePort
end

function TUDPStream:MsgIP()
	return ffi.string(self.MessageIP)
end

function TUDPStream:MsgPort()
	return tonumber(self.messagePort)
end

function TUDPStream:GetIP()
	return ffi.string(self.LocalIP)
end

function TUDPStream:GetPort()
	return tonumber(self.LocalPort)
end

function socket.CreateUDPStream(Port)
	local Port = Port or 0
	local Socket = sock.socket(AF_INET, SOCK_DGRAM, 0)
	if Socket == INVALID_SOCKET then
		return nil
	end

	if bind_(Socket, AF_INET, Port) == SOCKET_ERROR then
		local BindError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(BindError)
	end

	local Address = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", Address)
	local SizePtr = ffi.new("int [1]")
	SizePtr[0] = ffi.sizeof(Address)

	if sock.getsockname(Socket, Addr, SizePtr) == SOCKET_ERROR then
		local GetSockNameError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(GetSockNameError)
	end

	local LocalIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
	local LocalPort = tonumber(sock.ntohs(Address.sin_port))

	local Stream = ffi.new("struct TUDPStream")
	Stream.Socket = Socket
	Stream.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
	Stream.LocalPort = ffi.new("unsigned short", LocalPort)
	Stream.Timeout = ffi.new("unsigned int", UDP_TIMEOUT or 0)
	Stream.UDP = true

	Stream.SendBuffer = ffi.new("byte [0]")
	Stream.RecvBuffer = ffi.new("byte [0]")
	return Stream
end

local TTCPStream = {}
local TCP = {__index = TTCPStream}
ffi.metatype("struct TTCPStream", TCP)

function TCP:__gc()
	self:Close()
end

function TTCPStream:ReadByte()
	local n = ffi.new("byte [1]"); self:Read(n, 1)
	return n[0]
end

function TTCPStream:ReadShort()
	local n = ffi.new("byte [2]"); self:Read(n, 2)
	return n[0] + n[1] * 256
end

function TTCPStream:ReadInt()
	local n = ffi.new("byte [4]"); self:Read(n, 4)
	return n[0] + n[1] * 256 + n[2] * 65536 + n[3] * 16777216
end

function TTCPStream:ReadLong()
	local n = ffi.new("byte [8]"); self:Read(n, 8)
	local Value = ffi.new("unsigned long")
	local LongByte = ffi.new("unsigned long", 256)
	for i = 0, 7 do
		Value = Value + ffi.new("unsigned long", n[i]) * LongByte ^ i
	end
	return Value
end

function TTCPStream:ReadLine()
	local Buffer = ""
	local Size = 0
	while self:Size() > 0 do
		local Char = self:ReadByte()
		if Char == 10 or Char == 0 then
			break
		end
		if Char ~= 13 then
			Buffer = Buffer .. char(Char)
		end
	end
	return Buffer
end

function TTCPStream:ReadString(Length)
	if Length > 0 then
		local Buffer = ffi.new("byte [?]", Length); self:Read(Buffer, Length)
		return ffi.string(Buffer, Length)
	end
	return ""
end

function TTCPStream:WriteByte(n)
	local q = ffi.new("byte [1]", bit.band(n, 0xff))
	return self:Write(q, 1)
end

function TTCPStream:WriteShort(n)
	local q = ffi.new("byte [2]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff)
	return self:Write(q, 2)
end

function TTCPStream:WriteInt(n)
	local q = ffi.new("byte [4]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff); n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff); n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff)
	return self:WriteBytes(q, 4)
end

function TTCPStream:WriteLong(n)
	local q = ffi.new("byte [8]")
	q[0] = bit.band(n, 0xff); n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff); n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff); n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff); n = bit.rshift(n - q[3], 8)
	q[4] = bit.band(n, 0xff); n = bit.rshift(n - q[4], 8)
	q[5] = bit.band(n, 0xff); n = bit.rshift(n - q[5], 8)
	q[6] = bit.band(n, 0xff); n = bit.rshift(n - q[6], 8)
	q[7] = bit.band(n, 0xff)
	return self:WriteBytes(q, 8)
end

function TTCPStream:WriteLine(String)
	local Line = String.."\n"
	return self:Write(Line, #Line)
end

function TTCPStream:WriteString(String)
	return self:Write(String, #String)
end

function TTCPStream:SetTimeout(Read, Accept)
	assert(Read)
	assert(Accept)
	if Read < 0 then Read = 0 end
	if Accept < 0 then Accept = 0 end
	self.Timeouts = ffi.new("unsigned int [2]", Read, Accept)
end

function TTCPStream:Read(Buffer, Size)
	if self.Socket == INVALID_SOCKET then
		return 0
	end

	if select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeouts[0]) ~= 1 then
		return 0
	end

	local Result = sock.recv(self.Socket, Buffer, Size, 0)
	if Result == SOCKET_ERROR then
		return 0
	end

	self.Received = self.Received + Result
	return Result
end

function TTCPStream:Write(Buffer, Size)
	if self.Socket == INVALID_SOCKET then
		return 0
	end

	if select_(1, nil, 1, {self.Socket}, 0, nil, 0) ~= 1 then
		return 0
	end

	local Result = sock.send(self.Socket, Buffer, Size, 0)
	if Result == SOCKET_ERROR then
		return 0
	end

	self.Sent = self.Sent + Result
	return Result
end

function TTCPStream:Size()
	local Size = ffi.new("int [1]")
	if ioctl_(self.Socket, FIONREAD, Size) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	return Size[0]
end

function TTCPStream:Connected()
	if self.Socket == INVALID_SOCKET then
		return false
	end
	return select_(1, {self.Socket}, 0, nil, 0, nil, 0) == 0
end

function TTCPStream:Eof()
	return self:Size() == 0
end

function TTCPStream:Close()
	local Error = sock.shutdown(self.Socket, SD_BOTH)
	if Error ~= 0 then
		return nil, socket_strerror(Error)
	end

	local Error = closesocket_(self.Socket)
	if Error ~= 0 then
		return nil, socket_strerror(Error)
	end
	self.Socket = INVALID_SOCKET
	return true
end

function TTCPStream:GetIP()
	return ffi.string(self.LocalIP)
end

function TTCPStream:GetPort()
	return tonumber(self.LocalPort)
end

function socket.OpenTCPStream(Server, ServerPort, LocalPort)
	assert(Server)
	assert(ServerPort)
	local LocalPort = LocalPort or 0
	local ServerIP = sock.inet_addr(Server)
	if ServerIP == INADDR_NONE then
		local Addresses, AddressType, AddressLength = gethostbyname_(Server)
		local Errno = errno()
		if Addresses == nil or AddressType ~= AF_INET or AddressLength ~= 4 then
			return nil, socket_strerror(Errno)
		end
		local PAddress = Addresses[0]
		if PAddress == nil then
			return nil, socket_strerror(Errno)
		end
		ServerIP = bit.bor(bit.lshift(PAddress[3], 24), bit.lshift(PAddress[2], 16), bit.lshift(PAddress[1], 8), PAddress[0])
	end

	local Socket = sock.socket(AF_INET, SOCK_STREAM, 0)
	if Socket == INVALID_SOCKET then
		return nil, socket_strerror(errno())
	end

	if bind_(Socket, AF_INET, LocalPort) == SOCKET_ERROR then
		local BindError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(BindError)
	end

	local SAddress = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", SAddress)
	local SizePtr = ffi.new("int [1]")
	SizePtr[0] = ffi.sizeof(SAddress)

	if sock.getsockname(Socket, Addr, SizePtr) == SOCKET_ERROR then
		local GetSockNameError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(GetSockNameError)
	end

	local LocalIP = ffi.string(sock.inet_ntoa(SAddress.sin_addr))
	local LocalPort = tonumber(sock.ntohs(SAddress.sin_port))

	local Stream = ffi.new("struct TTCPStream")
	Stream.Socket = Socket
	Stream.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
	Stream.LocalPort = ffi.new("unsigned short", LocalPort)

	local ServerPtr = ffi.new("int[1]", ServerIP)
	if connect_(Socket, ServerPtr, AF_INET, 4, ServerPort) == SOCKET_ERROR then
		local ConnectError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(ConnectError)
	end

	local RemoteAddress = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", RemoteAddress)
	local SizePtr = ffi.new("int [1]", ffi.sizeof(RemoteAddress))

	if sock.getpeername(Socket, Addr, SizePtr) == SOCKET_ERROR then
		local GetPeerNameError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(GetPeerNameError)
	end

	local RemoteIP = ffi.string(sock.inet_ntoa(RemoteAddress.sin_addr))
	local RemotePort = tonumber(sock.ntohs(RemoteAddress.sin_port))

	Stream.RemoteIP = ffi.new("char [?]", #RemoteIP, RemoteIP)
	Stream.RemotePort = ffi.new("unsigned short", RemotePort)

	Stream.Age = socket.gettime()
	Stream.Timeouts = ffi.new("unsigned int[2]")
	Stream.TCP = true

	return Stream
end

function socket.CreateTCPServer(Port, Backlog)
	local Port = Port or 0
	local Socket = sock.socket(AF_INET, SOCK_STREAM, 0)
	if Socket == INVALID_SOCKET then
		return nil, socket_strerror(errno())
	end

	if bind_(Socket, AF_INET, Port) == SOCKET_ERROR then
		local BindError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(BindError)
	end

	local SAddress = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", SAddress)
	local SizePtr = ffi.new("int [1]")
	SizePtr[0] = ffi.sizeof(SAddress)

	if sock.getsockname(Socket, Addr, SizePtr) == SOCKET_ERROR then
		local GetSockNameError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(GetSockNameError)
	end

	local LocalIP = ffi.string(sock.inet_ntoa(SAddress.sin_addr))
	local LocalPort = tonumber(sock.ntohs(SAddress.sin_port))

	local Stream = ffi.new("struct TTCPStream")
	Stream.Socket = Socket
	Stream.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
	Stream.LocalPort = ffi.new("unsigned short", LocalPort)

	if sock.listen(Socket, Backlog or SOMAXCONN) == SOCKET_ERROR then
		local ListenError = errno()

		local Error = sock.shutdown(Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(ListenError)
	end

	Stream.Age = socket.gettime()
	Stream.Timeouts = ffi.new("unsigned int[2]")
	Stream.TCP = true

	return Stream
end

function TTCPStream:Accept()
	if self.Socket == INVALID_SOCKET then
		return nil
	end

	local Select = select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeouts[1])
	if Select ~= 1 then
		if Select == SOCKET_ERROR then
			return nil, socket_strerror(errno())
		end
		return nil, "timeout"
	end

	local Address = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", Address)
	local SizePtr = ffi.new("int [1]", ffi.sizeof(Address))

	local Socket = sock.accept(self.Socket, Addr, SizePtr)
	if Socket == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	local Stream = ffi.new("struct TTCPStream")
	Stream.Socket = Socket

	local LocalIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
	local LocalPort = tonumber(sock.ntohs(Address.sin_port))
	local RemoteIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
	local RemotePort = tonumber(sock.ntohs(Address.sin_port))

	Stream.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
	Stream.LocalPort = ffi.new("unsigned short", LocalPort)
	Stream.RemoteIP = ffi.new("char [?]", #RemoteIP, RemoteIP)
	Stream.RemotePort = ffi.new("unsigned short", RemotePort)

	Stream.Timeouts = ffi.new("unsigned int [2]", TCP_TIMEOUT, TCP_TIMEOUT)
	Stream.TCP = true
	return Stream
end

---------- LuaSocket-like api

-- TCP streams
function TTCPStream:accept()
	if self.Socket == INVALID_SOCKET then
		return nil
	end

	local Select = select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeouts[1])
	if Select ~= 1 then
		if Select == SOCKET_ERROR then
			return nil, socket_strerror(errno())
		end
		return nil, "timeout"
	end

	local Address = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", Address)
	local SizePtr = ffi.new("int [1]", ffi.sizeof(Address))

	local Socket = sock.accept(self.Socket, Addr, SizePtr)
	if Socket == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	local Stream = ffi.new("struct TTCPStream")
	Stream.Socket = Socket

	local LocalIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
	local LocalPort = tonumber(sock.ntohs(Address.sin_port))
	local RemoteIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
	local RemotePort = tonumber(sock.ntohs(Address.sin_port))

	Stream.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
	Stream.LocalPort = ffi.new("unsigned short", LocalPort)
	Stream.RemoteIP = ffi.new("char [?]", #RemoteIP, RemoteIP)
	Stream.RemotePort = ffi.new("unsigned short", RemotePort)

	Stream.Timeouts = ffi.new("unsigned int [2]", TCP_TIMEOUT, TCP_TIMEOUT)
	Stream.TCP = true
	return Stream
end

function TTCPStream:bind(Address, Port)
	local Address = tostring(Address) or ""
	local Port = tonumber(Port) or 0
	if Address == "*" or Address == "localhost" then
		if bind_(self.Socket, AF_INET, Port or 0) == SOCKET_ERROR then
			local BindError = errno()

			local Error = sock.shutdown(self.Socket, SD_BOTH)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			local Error = closesocket_(self.Socket)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end
			return nil, socket_strerror(BindError)
		end

		local SockAddress = ffi.new("struct sockaddr_in")
		local Addr = ffi.cast("struct sockaddr * ", SockAddress)
		local SizePtr = ffi.new("int [1]", ffi.sizeof(SockAddress))

		if sock.getsockname(self.Socket, Addr, SizePtr) == SOCKET_ERROR then
			local GetSockNameError = errno()

			local Error = sock.shutdown(self.Socket, SD_BOTH)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			local Error = closesocket_(self.Socket)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			return nil, socket_strerror(GetSockNameError)
		end

		local LocalIP = ffi.string(sock.inet_ntoa(SockAddress.sin_addr))
		local LocalPort = tonumber(sock.ntohs(SockAddress.sin_port))

		self.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
		self.LocalPort = ffi.new("unsigned short", LocalPort)

		self.Timeouts = ffi.new("unsigned int [2]", TCP_TIMEOUT, TCP_TIMEOUT)
		return true
	end
end

function TTCPStream:connect(address, port)
	if self.LocalPort == 0 then
		local Success, Error = self:bind("*", Port)
		if not Success then
			return nil, Error
		end
	end

	local ServerIP = sock.inet_addr(address)
	if ServerIP == INADDR_NONE then
		local Addresses, AddressType, AddressLength = gethostbyname_(address)
		local Errno = errno()
		if Addresses == nil or AddressType ~= AF_INET or AddressLength ~= 4 then
			return nil, socket_strerror(Errno)
		end
		local PAddress = Addresses[0]
		if PAddress == nil then
			return nil, socket_strerror(Errno)
		end
		ServerIP = bit.bor(bit.lshift(PAddress[3], 24), bit.lshift(PAddress[2], 16), bit.lshift(PAddress[1], 8), PAddress[0])
	end

	local ServerPtr = ffi.new("int [1]", ServerIP)
	if connect_(self.Socket, ServerPtr, AF_INET, 4, port) == SOCKET_ERROR then
		local ConnectError = errno()

		local Error = sock.shutdown(self.Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(self.Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(ConnectError)
	end

	local PeerAddress = ffi.new("struct sockaddr_in")
	local Addr = ffi.cast("struct sockaddr *", PeerAddress)
	local SizePtr = ffi.new("int [1]", ffi.sizeof(PeerAddress))

	if sock.getpeername(self.Socket, Addr, SizePtr) == SOCKET_ERROR then
		local GetPeerNameError = errno()

		local Error = sock.shutdown(self.Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(self.Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(GetPeerNameError)
	end

	local RemoteIP = ffi.string(sock.inet_ntoa(PeerAddress.sin_addr))
	local RemotePort = tonumber(sock.ntohs(PeerAddress.sin_port))

	self.RemoteIP = ffi.new("char [?]", #RemoteIP, RemoteIP)
	self.RemotePort = ffi.new("unsigned short", RemotePort)
	return true
end

function TTCPStream:getpeername()
	return ffi.string(self.RemoteIP), tonumber(self.RemotePort)
end

function TTCPStream:getsockname()
	return ffi.string(self.LocalIP), tonumber(self.LocalPort)
end

function TTCPStream:getstats()
	local Age = socket.gettime() - tonumber(self.Age)
	return tonumber(self.Received), tonumber(self.Sent), Age
end

function TTCPStream:close()
	local Error = sock.shutdown(self.Socket, SD_BOTH)
	if Error ~= 0 then
		return nil, socket_strerror(Error)
	end

	local Error = closesocket_(self.Socket)
	if Error ~= 0 then
		return nil, socket_strerror(Error)
	end
	self.Socket = INVALID_SOCKET
	return true
end

function TTCPStream:listen(backlog)
	if sock.listen(self.Socket, backlog or SOMAXCONN) == SOCKET_ERROR then
		local ListenError = errno()

		local Error = sock.shutdown(self.Socket, SD_BOTH)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		local Error = closesocket_(self.Socket)
		if Error ~= 0 then
			return nil, socket_strerror(Error)
		end

		return nil, socket_strerror(ListenError)
	end
	return true
end

function TTCPStream:receive(pattern, prefix)
	local prefix = prefix or ""
	if pattern == "*a" then
		local Buffer = ffi.new("byte [4096]")
		local Result = sock.recv(self.Socket, Buffer, 4096, 0)
		if Result == SOCKET_ERROR then
			return nil, socket_strerror(errno())
		end

		self.Received = self.Received + ffi.sizeof(Buffer)
		return prefix .. ffi.string(Buffer)
	elseif pattern == nil or pattern == "*l" then
		local Line = ""
		repeat
			local Buffer = ffi.new("byte [1]")
			local Result = sock.recv(self.Socket, Buffer, 1, 0)
			if Result == SOCKET_ERROR then
				return nil, socket_strerror(errno())
			end

			self.Received = self.Received + 1
			local Byte = Buffer[0]
			if Byte == 13 then
				break
			elseif Byte ~= 10 then
				Line = Line .. string.char(Byte)
			end
		until self:Eof()
		return prefix .. Line
	elseif type(pattern) == "number" then
		local Size = tonumber(pattern)
		if Size > 0 then
			local Buffer = ffi.new("byte [?]", Size)
			local Result = sock.recv(self.Socket, Buffer, Size, 0)
			if Result == SOCKET_ERROR then
				return nil, socket_strerror(errno())
			end
			self.Received = self.Received + ffi.sizeof(Buffer)
			return prefix .. ffi.string(Buffer)
		end
		return prefix
	end

	if not self:Connected() then
		return nil, "closed"
	end
	return nil, "timeout"
end

function TTCPStream:send(data, i, j)
	if self.Socket == INVALID_SOCKET then
		return nil, "closed"
	end

	if i and j then
		data = data:sub(i, j)
	elseif i then
		data = data:sub(i)
	end

	local Select = select_(1, nil, 1, {self.Socket}, 0, nil, 0)
	if Select == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	local Result = sock.send(self.Socket, data, #data, 0)
	if Result == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	self.Sent = self.Sent + #data
	return Result
end

function TTCPStream:setstats(received, sent, age)
	self.Received = received
	self.Sent = sent
	self.Age = socket.gettime() - (tonumber(age) or 0)
end

function TTCPStream:settimeout(value, mode)
	if mode == nil or mode == "t" then
		self.Timeouts = ffi.new("unsigned int [2]", value, value)
	elseif mode == "b" then
		self.Timeouts = ffi.new("unsigned int [2]", value, self.Timeouts[1])
	end
	return true
end

function TTCPStream:shutdown(mode)
	if mode == "both" then
		sock.shutdown(self.Socket, SD_BOTH)
	elseif mode == "send" then
		sock.shutdown(self.Socket, SD_SEND)
	elseif mode == "receive" then
		sock.shutdown(self.Socket, SD_RECEIVE)
	end
	return 1
end

-- UDP streams
function TUDPStream:close()
	local Error = sock.shutdown(self.Socket, SD_BOTH)
	if Error ~= 0 then
		return false, socket_strerror(Error)
	end

	local Error = closesocket_(self.Socket)
	if Error ~= 0 then
		return false, socket_strerror(Error)
	end
	self.Socket = INVALID_SOCKET
	return true
end

function TUDPStream:getpeername()
	return ffi.string(self.RemoteIP), tonumber(self.RemotePort)
end

function TUDPStream:getsockname()
	return ffi.string(self.LocalIP), tonumber(self.LocalPort)
end

function TUDPStream:receive(size)
	local size = size or 4096
	if select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeout) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	local Size = ffi.new("int [1]")
	if ioctl_(self.Socket, FIONREAD, Size) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	Size = Size[0]
	if Size <= 0 then
		return nil, "timeout"
	end

	local Buffer = ffi.new("char [?]", Size)
	local Result, MessageIP, MessagePort = recvfrom_(self.Socket, Buffer, Size, 0)
	if Result == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	self.MessageIP = MessageIP
	self.MessagePort = MessagePort
	self.RecvSize = self.RecvSize + Result

	if self.RemoteIP == nil or self.RemotePort == nil then
		return ffi.string(Buffer)
	elseif MessageIP ~= ffi.string(self.RemoteIP) or MessagePort ~= tonumber(self.RemotePort) then
		return nil, "timeout"
	end
	return ffi.string(Buffer)
end

function TUDPStream:receivefrom(size)
	local size = size or 4096
	if select_(1, {self.Socket}, 0, nil, 0, nil, self.Timeout) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	local Size = ffi.new("int [1]")
	if ioctl_(self.Socket, FIONREAD, Size) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end

	Size = Size[0]
	if Size <= 0 then
		return nil, "timeout"
	end

	local Buffer = ffi.new("char [?]", Size)
	local Result, MessageIP, MessagePort = recvfrom_(self.Socket, Buffer, Size, 0)
	if Result == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	self.MessageIP = MessageIP
	self.MessagePort = MessagePort
	self.RecvSize = self.RecvSize + Result

	return ffi.string(Buffer), ffi.string(MessageIP), tonumber(MessagePort)
end

function TUDPStream:send(datagram)
	if select_(0, nil, 1, {self.Socket}, 0, nil, 0) ~= 1 then
		return nil, socket_strerror(errno())
	end

	local IP = ffi.string(self.RemoteIP) or ""
	local Port = self.RemotePort or 0
	local Result = sendto_(self.Socket, datagram, #datagram, 0, IP, Port)
	if Result == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	return Result
end

function TUDPStream:sendto(datagram, ip, port)
	if select_(0, nil, 1, {self.Socket}, 0, nil, 0) ~= 1 then
		return nil, socket_strerror(errno())
	end

	local Result = sendto_(self.Socket, datagram, #datagram, 0, ip, port)
	if Result == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	return true
end

function TUDPStream:setpeername(address, port)
	if address == nil or port == nil then
		self.RemoteIP = nil
		self.RemotePort = nil
	end
	if self.LocalPort == 0 then
		local Bind, Error = self:setsockname("*", 0)
		if Bind == nil then
			return nil, Error
		end
	end
	self.RemoteIP = ffi.new("char [?]", #address, tostring(address))
	self.RemotePort = tonumber(port) or 0
	return true
end

function TUDPStream:setsockname(address, port)
	if address == "*" or address == "localhost" then
		if bind_(self.Socket, AF_INET, port or 0) == SOCKET_ERROR then
			local BindError = errno()

			local Error = sock.shutdown(self.Socket, SD_BOTH)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			local Error = closesocket_(self.Socket)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			return nil, socket_strerror(BindError)
		end

		local Address = ffi.new("struct sockaddr_in")
		local Addr = ffi.cast("struct sockaddr *", Address)
		local SizePtr = ffi.new("int[1]", ffi.sizeof(Address))

		if sock.getsockname(self.Socket, Addr, SizePtr) == SOCKET_ERROR then
			local GetSockNameError = errno()

			local Error = sock.shutdown(Socket, SD_BOTH)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			local Error = closesocket_(Socket)
			if Error ~= 0 then
				return nil, socket_strerror(Error)
			end

			return nil, socket_strerror(GetSockNameError)
		end

		local LocalIP = ffi.string(sock.inet_ntoa(Address.sin_addr))
		local LocalPort = tonumber(sock.ntohs(Address.sin_port))

		self.LocalIP = ffi.new("char [?]", #LocalIP, LocalIP)
		self.LocalPort = ffi.new("unsigned short", LocalPort)
		return true
	end
end

function TUDPStream:settimeout(value)
	self.Timeout = ffi.new("unsigned int", value or 0)
	return true
end

function socket.tcp()
	local Socket = sock.socket(AF_INET, SOCK_STREAM, 0)
	if Socket == INVALID_SOCKET then
		return nil, socket_strerror(errno())
	end

	local Stream = ffi.new("struct TTCPStream")
	Stream.Socket = Socket
	Stream.TCP = true
	return Stream
end

function socket.udp()
	local Socket = sock.socket(AF_INET, SOCK_DGRAM, 0)
	if Socket == INVALID_SOCKET then
		return nil, socket_strerror(errno())
	end

	local Stream = ffi.new("struct TUDPStream")
	Stream.Socket = Socket
	Stream.Timeout = ffi.new("unsigned int", UDP_TIMEOUT or 0)
	Stream.UDP = true

	Stream.SendBuffer = ffi.new("char [0]")
	Stream.RecvBuffer = ffi.new("char [0]")
	return Stream
end

function socket.protect(func)
	local function pass(ok, ...)
		if ok then
			return ...
		end
		return nil, ...
	end
	return function(...)
		return pass(pcall(func, ...))
	end
end

function socket.select(recvt, sendt, timeout)
	if type(recvt) == "table" then
		local ReceiveTable = {}
		for _, Stream in pairs(recvt) do
			table.insert(ReceiveTable, Stream.Socket)
		end

		local SendTable = {}
		for _, Stream in pairs(SendTable) do
			table.insert(SendTable, Stream.Socket)
		end

		local Select = select_(#ReceiveTable, ReceiveTable, #SendTable, SendTable, 0, nil, timeout or 0)
		if Select == SOCKET_ERROR then
			return nil, nil, socket_strerror(errno())
		end

		table.sort(ReceiveTable)
		table.sort(SendTable)
		return ReceiveTable, SendTable
	end
end

function socket.skip(d, ...)
	local skip = {}
	for Key, Value in pairs({...}) do
		if Key >= d then
			skip[Key - d + 1] = value
		end
	end
	return unpack(skip)
end

function socket.bind(address, port, backlog)
	local address = address and tostring(address) or "*"
	local port = tonumber(port) or 0
	local Stream, Error = socket.tcp()
	if Stream == nil then
		return nil, Error
	end

	local Bind, Error = Stream:bind(address, port)
	if Bind == nil then
		return nil, Error
	end

	local Listen, Error = Stream:listen(backlog)
	if Listen == nil then
		return nil, Error
	end
	return Stream
end

function socket.connect(address, port, locaddr, locport)
	local port = tonumber(port) or 0
	local locport = tonumber(locport) or 0

	local Stream, Error = socket.tcp()
	if Stream == nil then
		return nil, Error
	end

	local Bind, Error = Stream:bind(locaddr or "*", locport)
	if Bind == nil then
		return nil, Error
	end

	local Connected, Error = Stream:connect(address, port)
	if Connected == nil then
		return nil, Error
	end
	return Stream
end

if ffi.os == "Windows" then
	function socket.sleep(t)
		C.Sleep(t * 1000)
	end
else
	function socket.sleep(t)
		C.poll(nil, 0, s * 1000)
	end
end

if ffi.os == "Windows" then
	local Start = ffi.new("SYSTEMTIME"); C.GetSystemTime(Start)
	local StartTime = Start.wSecond + Start.wMilliseconds/1000

	function socket.gettime()
		local Time = ffi.new("SYSTEMTIME"); C.GetSystemTime(Time)
		return (Time.wSecond + Time.wMilliseconds/1000) - StartTime
	end
else
	local Start = ffi.new("struct timeval"); C.gettimeofday(Start, nil)
	local StartTime = Start.tv_sec + Start.tv_usec/1.0e6

	function socket.gettime()
		local Time = ffi.new("struct timeval"); C.gettimeofday(Time, nil)
		return (Time.tv_sec + Time.tv_usec/1.0e6) - StartTime
	end
end

-- socket.dns.* api
socket.dns = {}

function socket.dns.gethostname()
	local Name = ffi.new("char [256]")
	if sock.gethostname(Name, 256) == SOCKET_ERROR then
		return nil, socket_strerror(errno())
	end
	return ffi.string(Name)
end

function socket.dns.tohostname(address)
end

function socket.dns.toip(address)
	local address = address or ""
	local AddrIP = sock.inet_addr(address)
	if AddrIP == INADDR_NONE then
		local Addresses, AddressType, AddressLength = gethostbyname_(address)
		if Addresses == nil or AddressType ~= AF_INET or AddressLength ~= 4 then
			return nil, socket_strerror(errno())
		end
		local PrimaryAddress = Addresses[0]
		if PrimaryAddress == nil then
			return nil, socket_strerror(errno())
		end

		local Information = {
			ip = {},
			name = address,
			alias = {}
		}

		local Count = 0
		while Addresses[Count] ~= nil do
			local Address = Addresses[Count]
			local IntAddr = bit.bor(bit.lshift(Address[3], 24), bit.lshift(Address[2], 16), bit.lshift(Address[1], 8), Address[0])
			local in_addr = ffi.new("struct in_addr", {s_addr = IntAddr})
			local NTOA = sock.inet_ntoa(in_addr)
			Information.ip[Count + 1] = ffi.string(NTOA)
			Count = Count + 1
		end
		return Information.ip[1], Information
	end
	return nil, socket_strerror(errno())
end

return socket
