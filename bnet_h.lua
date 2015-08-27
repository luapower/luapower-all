--Written by Matías "Starkkz" Hermosilla. BNet sockets library.

local ffi = require("ffi")

ffi.cdef [[
	typedef uintptr_t SOCKET;
	struct TUDPStream {
		unsigned int Timeout;
		SOCKET Socket;

		char * LocalIP;
		unsigned short LocalPort;

		char * MessageIP;
		unsigned short MessagePort;

		char * RemoteIP;
		unsigned short RemotePort;

		int RecvSize;
		int SendSize;
		char * RecvBuffer;
		char * SendBuffer;
		bool UDP;
	};
	struct TTCPStream {
		unsigned int * Timeouts;
		SOCKET Socket;

		char * RemoteIP;
		unsigned short RemotePort;

		char * LocalIP;
		unsigned short LocalPort;

		bool TCP;
		int Received;
		int Sent;
		int Age;
	};
]]

if ffi.os == "Windows" then
	ffi.cdef [[
		typedef uint16_t u_short;
		typedef uint32_t u_int;
		typedef unsigned long u_long;
		typedef unsigned char byte;
		struct sockaddr {
			unsigned short sa_family;
			char sa_data[14];
		};
		struct in_addr {
			uint32_t s_addr;
		};
		struct sockaddr_in {
			short   sin_family;
			unsigned short sin_port;
			struct  in_addr sin_addr;
			char    sin_zero[8];
		};
		typedef unsigned short WORD;
		typedef struct WSAData {
			WORD wVersion;
			WORD wHighVersion;
			char szDescription[257];
			char szSystemStatus[129];
			unsigned short iMaxSockets;
			unsigned short iMaxUdpDg;
			char *lpVendorInfo;
		} WSADATA, *LPWSADATA;
		typedef struct hostent {
			char *h_name;
			char **h_aliases;
			short h_addrtype;
			short h_length;
			byte **h_addr_list;
		};
		typedef struct timeval {
			long tv_sec;
			long tv_usec;
		} timeval;
		typedef struct fd_set {
			u_int fd_count;
			SOCKET  fd_array[64];
		} fd_set;
		u_long htonl(u_long hostlong);
		u_short htons(u_short hostshort);
		u_short ntohs(u_short netshort);
		u_long ntohl(u_long netlong);
		unsigned long inet_addr(const char *cp);
		char *inet_ntoa(struct in_addr in);
		SOCKET socket(int af, int type, int protocol);
		SOCKET accept(SOCKET s,struct sockaddr *addr,int *addrlen);
		int bind(SOCKET s, const struct sockaddr *name, int namelen);
		int closesocket(SOCKET s);
		int connect(SOCKET s, const struct sockaddr *name, int namelen);
		int getsockname(SOCKET s, struct sockaddr *addr, int *namelen);
		int getpeername(SOCKET s, struct sockaddr *name, int *namelen);
		int ioctlsocket(SOCKET s, long cmd, u_long * argp);
		int listen(SOCKET s, int backlog);
		int recv(SOCKET s, char *buf, int len, int flags);
		int recvfrom(SOCKET s, char *buf, int len, int flags, struct sockaddr *from, int *fromlen);
		int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, const struct timeval *timeout);
		int send(SOCKET s, const char *buf, int len, int flags);
		int sendto(SOCKET s, const char *buf, int len, int flags, const struct sockaddr *to, int tolen);
		int shutdown(SOCKET s, int how);
		int gethostname(char *name, int  namelen);
		struct hostent *gethostbyname(const char *name);
		struct hostent *gethostbyaddr(const char *addr, int len, int type);

		int __WSAFDIsSet(SOCKET fd, fd_set * set);
		int WSAStartup(WORD wVersionRequested, LPWSADATA lpWSAData);
		int WSACleanup(void);

		int WSAGetLastError(void);

		int atexit(void (__cdecl * func)( void));
		void Sleep(int ms);

		typedef struct _SYSTEMTIME {
			WORD wYear;
			WORD wMonth;
			WORD wDayOfWeek;
			WORD wDay;
			WORD wHour;
			WORD wMinute;
			WORD wSecond;
			WORD wMilliseconds;
		} SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME;;
		void GetSystemTime(LPSYSTEMTIME lpSystemTime);
	]]
	local SocketLibrary = ffi.load("ws2_32")

	local function ErrorFunction()
		return tonumber(SocketLibrary.WSAGetLastError())
	end

	return {SocketLibrary, ErrorFunction}
else
	ffi.cdef [[
		typedef uint16_t u_short;
		typedef uint32_t u_int;
		typedef unsigned long u_long;
		typedef unsigned char byte;
		typedef unsigned long size_t;
		struct sockaddr {
			unsigned short sa_family;
			char sa_data[14];
		};
		struct in_addr {
			uint32_t s_addr;
		};
		struct sockaddr_in {
			short   sin_family;
			u_short sin_port;
			struct  in_addr sin_addr;
			char    sin_zero[8];
		};
		typedef struct hostent {
			char *h_name;
			char **h_aliases;
			short h_addrtype;
			short h_length;
			byte **h_addr_list;
		};
		typedef struct timeval {
			long int tv_sec;
			long int tv_usec;
		};
		typedef struct fd_set {
			u_int fd_count;
			SOCKET  fd_array[64];
		} fd_set;
		u_long htonl(u_long hostlong);
		u_short htons(u_short hostshort);
		u_short ntohs(u_short netshort);
		u_long ntohl(u_long netlong);
		unsigned long inet_addr(const char *cp);
		char *inet_ntoa(struct in_addr in);
		SOCKET socket(int af, int type, int protocol);
		SOCKET accept(SOCKET s,struct sockaddr *addr,int *addrlen);
		int bind(SOCKET s, const struct sockaddr *name, int namelen);
		int close(SOCKET s);
		int connect(SOCKET s, const struct sockaddr *name, int namelen);
		int getsockname(SOCKET s, struct sockaddr *addr, int *namelen);
		int getpeername(SOCKET s, struct sockaddr *addr, int *namelen);
		int ioctl(SOCKET s, long cmd, u_long *argp);
		int listen(SOCKET s, int backlog);
		int recv(SOCKET s, char *buf, int len, int flags);
		int recvfrom(SOCKET s, char *buf, int len, int flags, struct sockaddr *from, int *fromlen);
		int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, const struct timeval *timeout);
		int send(SOCKET s, const char *buf, int len, int flags);
		int sendto(SOCKET s, const char *buf, int len, int flags, const struct sockaddr *to, int tolen);
		int shutdown(SOCKET s, int how);
		int gethostname(char *name, size_t len);
		struct hostent *gethostbyname(const char *name);
		struct hostent *gethostbyaddr(const char *addr, int len, int type);

		char * strerror(int errnum);
		int poll(struct pollfd * fds, unsigned long nfds, int timeout);

		struct timezone {
			int tz_minuteswest;
			int tz_dsttime;
		};
		int gettimeofday(struct timeval * tv, struct timezone * tz);
	]]

	return {ffi.C, ffi.errno}
end
