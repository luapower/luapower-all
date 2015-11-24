
--libcurl ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'libcurl_h'
local C = ffi.load'curl'
local M = {C = C}

--easy interface -------------------------------------------------------------

local easy = {}

local function strerror(code)
	return ffi.string(C.curl_easy_strerror(code))
end

function ret(code)
	if code == C.CURLE_OK then return true end
	return nil, strerror(code), code
end

local function check(code)
	local ok, err, errcode = ret(code)
	if ok then return true end
	error('libcurl error: '..err, 2)
end

local function longbool(b) return 'long', b and 1 or 0 end
local function long(i) return 'long', i end
local function str(s) return 'char*', ffi.cast('const char*', s) end
local function flag(prefix)
	return function(flag) return 'long', C[prefix..flag:upper()] end
end
local function flags(prefix, ctype)
	return function(val) return ctype, val end --TODO
end
local function strlist(t)
	local buf = ffi.new('const char*[?]', #t)
	for i=1,#t do
		buf[i] = t[i]
	end
	return 'char*', buf
end
local function ctype(ctype)
	return function(val) return ctype, val end
end
local slist = ctype'struct curl_slist *'
local off_t = ctype'curl_off_t'
local voidp = ctype'void*'

local options = {
	TIMEOUT = long,
	VERBOSE = longbool,

	STDERR = voidp, --FILE*
	ERRORBUFFER = ctype'char*', --output buffer
	FAILONERROR = longbool,

	NOPROGRESS = longbool,
	PROGRESSFUNCTION = ctype'curl_progress_callback',
	PROGRESSDATA = voidp,

	URL = str,
	PORT = long,
	PROTOCOLS = flags'CURLPROTO_',
	DEFAULT_PROTOCOL = str,
	USERPWD = str, --user:pass
	RANGE = str,
	REFERER = str,
	USERAGENT = str,
	POSTFIELDS = str,
	COOKIE = str,
	COOKIEFILE = voidp,
	POST = longbool,
	PUT = longbool,
	HEADER = longbool,
	HEADERDATA = voidp,
	NOBODY = longbool,
	FOLLOWLOCATION = longbool,

	PROXY = str,
	PROXYTYPE = flag'CURLPROXY_',
	PROXYPORT = long,
	PROXYUSERPWD = str,
	PROXY_SERVICE_NAME = str,
	PROXYAUTH = flags('CURLAUTH_', 'unsigned long'),
	PROXY_TRANSFER_MODE = longbool,
	PROXYUSERNAME = str,
	PROXYPASSWORD = str,
	PROXYHEADER = slist,
	NOPROXY = str, --proxy exception list

	WRITEFUNCTION = ctype'curl_write_callback',
	WRITEDATA = voidp, --FILE* or callback arg

	READFUNCTION = ctype'curl_read_callback',
	READDATA = voidp,

	INFILESIZE = long,

	LOW_SPEED_LIMIT = long,
	LOW_SPEED_TIME = long,
	MAX_SEND_SPEED_LARGE = off_t,
	MAX_RECV_SPEED_LARGE = off_t,

	RESUME_FROM = long,
	KEYPASSWD = str,
	CRLF = longbool,
	QUOTE = str,
	TIMECONDITION = flag'CURL_TIMECOND_',
	TIMEVALUE = long, --time_t
	CUSTOMREQUEST = str,
	POSTQUOTE = slist,
	UPLOAD = longbool,
	DIRLISTONLY = longbool,
	APPEND = longbool,
	TRANSFERTEXT = longbool,
	AUTOREFERER = longbool,
	POSTFIELDSIZE = long,

	HTTPHEADER = slist,
	HTTPPOST = ctype'struct curl_httppost *',
	HTTPPROXYTUNNEL = longbool,
	HTTPGET = longbool,
	HTTP_VERSION = flag'CURL_HTTP_VERSION_',
	HTTP200ALIASES = slist,
	HTTPAUTH = flags('CURLAUTH_', 'unsigned long'),
	HTTP_TRANSFER_DECODING = longbool,
	HTTP_CONTENT_DECODING = longbool,

	INTERFACE = str,
	KRBLEVEL = longbool,
	CAINFO = str,
	MAXREDIRS = long,
	FILETIME = longbool,
	TELNETOPTIONS = slist,
	MAXCONNECTS = long,
	FRESH_CONNECT = longbool,
	FORBID_REUSE = longbool,
	RANDOM_FILE = str,
	EGDSOCKET = str,
	CONNECTTIMEOUT = long,
	HEADERFUNCTION = ctype'curl_write_callback',
	COOKIEJAR = str,

	USE_SSL = flag'CURLUSESSL_',
	SSLCERT = str,
	SSLVERSION = long,
	SSLCERTTYPE = str,
	SSLKEY = str,
	SSLKEYTYPE = str,
	SSLENGINE = str,
	SSLENGINE_DEFAULT = longbool,
	SSL_OPTIONS = flags'CURLSSLOPT_',
	SSL_CIPHER_LIST = strlist,
	SSL_VERIFYHOST = function(b) return 'long', b and 2 or 0 end,
	SSL_VERIFYPEER = longbool,
	SSL_CTX_FUNCTION = ctype'curl_ssl_ctx_callback',
	SSL_CTX_DATA = voidp,
	SSL_SESSIONID_CACHE = longbool,
	SSL_ENABLE_NPN = longbool,
	SSL_ENABLE_ALPN = longbool,
	SSL_VERIFYSTATUS = longbool,
	SSL_FALSESTART = longbool,

	PREQUOTE = slist,
	DEBUGFUNCTION = ctype'curl_debug_callback',
	DEBUGDATA = voidp,
	COOKIESESSION = longbool,
	CAPATH = str,
	BUFFERSIZE = long,
	NOSIGNAL = longbool,
	SHARE = ctype'struct Curl_share *',
	ACCEPT_ENCODING = str,
	PRIVATE = voidp,
	UNRESTRICTED_AUTH = longbool,

	SERVER_RESPONSE_TIMEOUT = long,
	IPRESOLVE = flag'CURL_IPRESOLVE_',
	MAXFILESIZE = long,
	INFILESIZE_LARGE = off_t,
	RESUME_FROM_LARGE = off_t,
	MAXFILESIZE_LARGE = off_t,
	POSTFIELDSIZE_LARGE = long,
	TCP_NODELAY = longbool,
	FTPSSLAUTH = flag'CURLFTPAUTH_',
	IOCTLFUNCTION = ctype'curl_ioctl_callback',
	IOCTLDATA = voidp,
	COOKIELIST = str,
	IGNORE_CONTENT_LENGTH = longbool,

	FTPPORT = str, --IP:PORT
	FTP_USE_EPRT = longbool,
	FTP_CREATE_MISSING_DIRS = flag'CURLFTP_CREATE_DIR_',
	FTP_RESPONSE_TIMEOUT = long,
	FTP_USE_EPSV = longbool,
	FTP_ACCOUNT = str,
	FTP_SKIP_PASV_IP = longbool,
	FTP_FILEMETHOD = flag'CURLFTPMETHOD_',
	FTP_USE_PRET = longbool,
	FTP_SSL_CCC = flag'CURLFTPSSL_CCC_',
	FTP_ALTERNATIVE_TO_USER = str,

	LOCALPORT = long,
	LOCALPORTRANGE = long,
	CONNECT_ONLY = longbool,
	CONV_FROM_NETWORK_FUNCTION = ctype'curl_conv_callback',
	CONV_TO_NETWORK_FUNCTION = ctype'curl_conv_callback',
	CONV_FROM_UTF8_FUNCTION = ctype'curl_conv_callback',
	SOCKOPTFUNCTION = ctype'curl_sockopt_callback',
	SOCKOPTDATA = voidp,

	SSH_AUTH_TYPES = flags'CURLSSH_AUTH_',
	SSH_PUBLIC_KEYFILE = str,
	SSH_PRIVATE_KEYFILE = str,
	SSH_KNOWNHOSTS = str,
	SSH_KEYFUNCTION = ctype'curl_sshkeycallback',
	SSH_KEYDATA = voidp,
	SSH_HOST_PUBLIC_KEY_MD5 = str,

	TIMEOUT_MS = long,
	CONNECTTIMEOUT_MS = long,
	NEW_FILE_PERMS = long,
	NEW_DIRECTORY_PERMS = long,
	POSTREDIR = flag'CURL_REDIR_',
	OPENSOCKETFUNCTION = ctype'curl_opensocket_callback',
	OPENSOCKETDATA = voidp,
	COPYPOSTFIELDS = str,
	SEEKFUNCTION = ctype'curl_seek_callback',
	SEEKDATA = voidp,
	CRLFILE = str,
	ISSUERCERT = str,
	ADDRESS_SCOPE = long,
	CERTINFO = longbool,
	USERNAME = str,
	PASSWORD = str,

	SOCKS5_GSSAPI_SERVICE = str,
	SOCKS5_GSSAPI_NEC = longbool,

	REDIR_PROTOCOLS = flags'CURLPROTO_',

	MAIL_FROM = str,
	MAIL_RCPT = str,
	MAIL_AUTH = str,

	RTSP_REQUEST = flag'CURL_RTSPREQ_',
	RTSP_SESSION_ID = str,
	RTSP_STREAM_URI = str,
	RTSP_TRANSPORT = str,
	RTSP_CLIENT_CSEQ = long,
	RTSP_SERVER_CSEQ = long,

	TFTP_BLKSIZE = long,

	INTERLEAVEDATA = voidp,
	INTERLEAVEFUNCTION = ctype'curl_write_callback',

	CHUNK_BGN_FUNCTION = ctype'curl_chunk_bgn_callback',
	CHUNK_END_FUNCTION = ctype'curl_chunk_end_callback',
	CHUNK_DATA = voidp,

	FNMATCH_FUNCTION = ctype'curl_fnmatch_callback',
	FNMATCH_DATA = voidp,

	RESOLVE = slist,
	WILDCARDMATCH = longbool,

	TLSAUTH_USERNAME = str,
	TLSAUTH_PASSWORD = str,
	TLSAUTH_TYPE = str,

	TRANSFER_ENCODING = longbool,
	CLOSESOCKETFUNCTION = ctype'curl_closesocket_callback',
	CLOSESOCKETDATA = voidp,
	GSSAPI_DELEGATION = long,
	ACCEPTTIMEOUT_MS = long,

	TCP_KEEPALIVE = longbool,
	TCP_KEEPIDLE = long,
	TCP_KEEPINTVL = long,

	SASL_IR = longbool,
	XOAUTH2_BEARER = str,

	XFERINFOFUNCTION = ctype'curl_xferinfo_callback',
	XFERINFODATA = voidp,

	NETRC = flag'CURL_NETRC_',
	NETRC_FILE = str,

	DNS_SERVERS = str,
	DNS_INTERFACE = str,
	DNS_LOCAL_IP4 = str,
	DNS_LOCAL_IP6 = str,
	DNS_USE_GLOBAL_CACHE = longbool,
	DNS_CACHE_TIMEOUT = long,

	LOGIN_OPTIONS = str,
	EXPECT_100_TIMEOUT_MS = long,
	HEADEROPT = flag'CURLHEADER_',
	PINNEDPUBLICKEY = str,
	UNIX_SOCKET_PATH = str,
	PATH_AS_IS = longbool,
	SERVICE_NAME = str,
	PIPEWAIT = longbool,
}

function M.easy(opt)
	local self = C.curl_easy_init()
	assert(self ~= nil)
	ffi.gc(self, self.free)
	if opt then
		for k,v in pairs(opt) do
			local k = k:upper()
			local check = options[k]
			if not check then
				error('invalid option '..k)
			end
			local ctype, cval = check(v) --keep v from being gc'ed
			local optnum = C['CURLOPT_'..k]
			check(C.curl_easy_setopt(self, optnum, ffi.cast(ctype, cval)))
		end
	end
	return self
end

easy.strerror = strerror

function easy:perform()
	return check(C.curl_easy_perform(self))
end

function easy:free()
	ffi.gc(self, nil)
	C.curl_easy_cleanup(self)
end

function easy:getinfo(...)
	local info = ffi.new'CURLINFO'
	C.curl_easy_getinfo(self, info, ...)
end

function easy:duphandle()
	return C.curl_easy_duphandle(self)
end

function easy:reset()
	C.curl_easy_reset(self)
end

function easy:recv()
	return check(C.curl_easy_recv(self, buf, buflen, n))
end

function easy:send()
	return check(C.curl_easy_send(self, buf, buflen, n))
end

ffi.metatype('CURL', {__index = easy})


if not ... then

local curl = M
local easy = curl.easy{
	url = 'http://google.com/',
	verbose = true,
}
easy:perform()
easy:free()

end

return M
