
--libcurl ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libcurl_test'; return end

local ffi = require'ffi'
local bit = require'bit'
require'libcurl_h'
local C = ffi.load'curl'
local curl = {C = C}

--global buffers for C "out" variables
local intbuf = ffi.new'int[1]'
local longbuf = ffi.new'long[1]'
local sizetbuf = ffi.new'size_t[1]'

local function ptr(p) --convert NULL -> nil
	return p ~= nil and p or nil
end

local function X(prefix, x) --convert flag -> C[prefix..flag:upper()]
	return type(x) == 'string' and C[prefix..x:upper()] or x
end

--convert {flag1 = true, ...} -> bit.bor(C[prefix..flag1:upper()], ...)
local function MX(prefix, t)
	local val = 0
	for flag, truthy in pairs(t) do
		if truthy then
			val = bit.bor(val, X(prefix, flag))
		end
	end
end

local function check(code)
	assert(code == C.CURLE_OK)
end

function curl.init(opt)
	if type(opt) == 'table' then
		local function validate(cb) --must set all callbacks or none
			return assert(ptr(cb))
		end
		check(C.curl_global_init_mem(MX('CURL_GLOBAL_', opt.flags or 'all'),
			validate(opt.malloc),
			validate(opt.free),
			validate(opt.realloc),
			validate(opt.strdup),
			validate(opt.calloc)))
	else
		check(C.curl_global_init(MX('CURL_GLOBAL_', opt or 'all')))
	end
	return M
end

curl.free = C.curl_global_cleanup

function curl.version()
	return ffi.string(C.curl_version())
end

function curl.version_info(ver)
	local info = assert(ptr(C.curl_version_info(X('CURLVERSION_', ver or 'now'))))
	local protocols = {}
	local p = info.protocols
	while p ~= nil and p[0] ~= nil do
		table.insert(protocols, ffi.string(p[0]))
		p = p + 1
	end
	local function str(s)
		return s ~= nil and ffi.string(s) or nil
	end
	return {
		age = info.age,
		version = str(info.version),
		version_num = info.version_num,
		version_maj = bit.band(bit.rshift(info.version_num, 16), 0xff),
		version_min = bit.band(bit.rshift(info.version_num,  8), 0xff),
		version_patch = bit.band(info.version_num, 0xff),
		host = str(info.host),
		features = info.features,
		ssl_version = str(info.ssl_version),
		ssl_version_num = info.ssl_version_num,
		libz_version = str(info.libz_version),
		protocols = protocols,
		ares = str(info.ares),
		ares_num = info.ares_num,
		libidn = str(info.libidn),
		iconv_ver_num = info.iconv_ver_num,
		libssh_version = str(info.libssh_version),
	}
end

local info
function curl.checkver(maj, min, patch)
	info = info or curl.version_info()
	min = min or 0
	patch = patch or 0
	if info.version_maj ~= maj then return info.version_maj > maj end
	if info.version_min ~= min then return info.version_min > min end
	if info.version_patch ~= patch then return info.version_patch > patch end
	return true
end

function curl.getdate(s)
	local t = C.curl_getdate(s, nil)
	return t ~= -1 and t or nil
end

function curl.type(x)
	return
		ffi.istype('CURL*',   x) and 'easy' or
		ffi.istype('CURLM*',  x) and 'multi' or
		ffi.istype('CURLSH*', x) and 'share' or
		nil
end

--option encoders ------------------------------------------------------------

--each encoder takes a Lua value and returns the converted, C-typed value
--and optionally a value to keep a reference to while the transfer is alive,
--and then `true` if the value to keep is a callback.

local function ctype(ctype)
	return function(val)
		return ffi.cast(ctype, val)
	end
end

local long  = ctype'long'
local off_t = ctype'curl_off_t'

local function voidp(p)
	return ffi.cast('void*', p), p
end

local function longbool(b)
	return ffi.cast('long', b and 1 or 0)
end

local function str(s)
	return ffi.cast('const char*', s), s
end

local function flag(prefix)
	return function(flag)
		return ffi.cast('long', X(prefix, flag))
	end
end

local function flags(prefix, ctype)
	return function(t)
		return ffi.cast(ctype or 'long', MX(prefix, t))
	end
end

local function slist(t)
	local slist, dt = t
	if type(t) == 'table' then
		slist = ffi.new('struct curl_slist[?]', #t)
		dt = {slist}
		for i=1,#t do
			local s = t[i]
			slist[i-1].data = ffi.cast('char*', s)
			slist[i-1].next = i < #t and slist[i] or nil
			table.insert(dt, s)
		end
	end
	return ffi.cast('struct curl_slist*', slist), dt
end

local function pchararray(t, self)
	local buf, dt = t
	if type(t) == 'table' then
		buf = ffi.new('char*[?]', #t)
		dt = {buf}
		for i,s in ipairs(t) do
			buf[i-1] = s
			table.insert(dt, s)
		end
	end
	return ffi.cast('char**', buf), dt
end

local function cb(ctype) --callback
	return function(func, self)
		if not func then return nil, nil, true end
		local cb = ffi.cast(ctype, func)
		if type(func) ~= 'function' then return cb end
		return cb, {cb = cb, refcount = 1}, true
	end
end

local function httppost(post)
	return ffi.cast('struct curl_httppost*', post), post
end

--easy interface -------------------------------------------------------------

local easy = {}
setmetatable(easy, easy) --for __call
curl.easy = easy
local easy_mt = {__index = easy}

function easy:__call(opt)
	local self = assert(ptr(C.curl_easy_init()))
	if opt then
		if type(opt) == 'string' then
			self:set('url', opt)
		else
			self:set(opt)
		end
	end
	return self
end

function easy:clone(opt)
	local oldself = self
	local self = assert(ptr(C.curl_easy_duphandle(self)))
	self:_copy_pinned_vals(oldself)
	if opt then
		if type(opt) == 'string' then
			self:set('url', opt)
		else
			self:set(opt)
		end
	end
	return self
end

function easy.strerror(code)
	return ffi.string(C.curl_easy_strerror(code))
end

function easy:_ret(code, retval)
	if code == C.CURLE_OK then return retval or self end
	return nil, self.strerror(code), code
end

function easy:_check(code, retval)
	if code == C.CURLE_OK then return retval or self end
	error('libcurl error: '..self.strerror(code), 2)
end

function easy:_cleanup()
	C.curl_easy_cleanup(self)
end
function easy:close()
	self:_cleanup()
	self:_free_pinned_vals()
end
easy_mt.__gc = easy.close

--options --------------------------------------------------------------------

easy._setopt_options = {
	[C.CURLOPT_TIMEOUT] = long,
	[C.CURLOPT_VERBOSE] = longbool,
	[C.CURLOPT_STDERR] = voidp, --FILE*
	[C.CURLOPT_ERRORBUFFER] = ctype'char*', --output buffer
	[C.CURLOPT_FAILONERROR] = longbool,
	[C.CURLOPT_NOPROGRESS] = longbool,
	[C.CURLOPT_PROGRESSFUNCTION] = cb'curl_progress_callback',
	[C.CURLOPT_PROGRESSDATA] = voidp,
	[C.CURLOPT_URL] = str,
	[C.CURLOPT_PORT] = long,
	[C.CURLOPT_PROTOCOLS] = flags'CURLPROTO_',
	[C.CURLOPT_DEFAULT_PROTOCOL] = str,
	[C.CURLOPT_USERPWD] = str, --user:pass
	[C.CURLOPT_RANGE] = str,
	[C.CURLOPT_REFERER] = str,
	[C.CURLOPT_USERAGENT] = str,
	[C.CURLOPT_POSTFIELDS] = str,
	[C.CURLOPT_COOKIE] = str,
	[C.CURLOPT_COOKIEFILE] = voidp,
	[C.CURLOPT_POST] = longbool,
	[C.CURLOPT_PUT] = longbool,
	[C.CURLOPT_HEADER] = longbool,
	[C.CURLOPT_HEADERDATA] = voidp,
	[C.CURLOPT_NOBODY] = longbool,
	[C.CURLOPT_FOLLOWLOCATION] = longbool,
	[C.CURLOPT_PROXY] = str,
	[C.CURLOPT_PROXYTYPE] = flag'CURLPROXY_',
	[C.CURLOPT_PROXYPORT] = long,
	[C.CURLOPT_PROXYUSERPWD] = str,
	[C.CURLOPT_PROXY_SERVICE_NAME] = str,
	[C.CURLOPT_PROXYAUTH] = flags('CURLAUTH_', 'unsigned long'),
	[C.CURLOPT_PROXY_TRANSFER_MODE] = longbool,
	[C.CURLOPT_PROXYUSERNAME] = str,
	[C.CURLOPT_PROXYPASSWORD] = str,
	[C.CURLOPT_PROXYHEADER] = slist,
	[C.CURLOPT_NOPROXY] = str, --proxy exception list
	[C.CURLOPT_WRITEFUNCTION] = cb'curl_write_callback',
	[C.CURLOPT_WRITEDATA] = voidp, --FILE* or callback arg
	[C.CURLOPT_READFUNCTION] = cb'curl_read_callback',
	[C.CURLOPT_READDATA] = voidp,
	--[C.CURLOPT_INFILESIZE] = long,
	[C.CURLOPT_LOW_SPEED_LIMIT] = long,
	[C.CURLOPT_LOW_SPEED_TIME] = long,
	[C.CURLOPT_MAX_SEND_SPEED] = off_t,
	[C.CURLOPT_MAX_RECV_SPEED] = off_t,
	--[C.CURLOPT_RESUME_FROM] = long,
	[C.CURLOPT_KEYPASSWD] = str,
	[C.CURLOPT_CRLF] = longbool,
	[C.CURLOPT_QUOTE] = str,
	[C.CURLOPT_TIMECONDITION] = flag'CURL_TIMECOND_',
	[C.CURLOPT_TIMEVALUE] = long, --time_t
	[C.CURLOPT_CUSTOMREQUEST] = str,
	[C.CURLOPT_POSTQUOTE] = slist,
	[C.CURLOPT_UPLOAD] = longbool,
	[C.CURLOPT_DIRLISTONLY] = longbool,
	[C.CURLOPT_APPEND] = longbool,
	[C.CURLOPT_TRANSFERTEXT] = longbool,
	[C.CURLOPT_AUTOREFERER] = longbool,
	--[C.CURLOPT_POSTFIELDSIZE] = long,
	[C.CURLOPT_HTTPHEADER] = slist,
	[C.CURLOPT_HTTPPOST] = httppost,
	[C.CURLOPT_HTTPPROXYTUNNEL] = longbool,
	[C.CURLOPT_HTTPGET] = longbool,
	[C.CURLOPT_HTTP_VERSION] = flag'CURL_HTTP_VERSION_',
	[C.CURLOPT_HTTP200ALIASES] = slist,
	[C.CURLOPT_HTTPAUTH] = flags('CURLAUTH_', 'unsigned long'),
	[C.CURLOPT_HTTP_TRANSFER_DECODING] = longbool,
	[C.CURLOPT_HTTP_CONTENT_DECODING] = longbool,
	[C.CURLOPT_INTERFACE] = str,
	[C.CURLOPT_KRBLEVEL] = longbool,
	[C.CURLOPT_CAINFO] = str,
	[C.CURLOPT_MAXREDIRS] = long,
	[C.CURLOPT_FILETIME] = longbool,
	[C.CURLOPT_TELNETOPTIONS] = slist,
	[C.CURLOPT_MAXCONNECTS] = long,
	[C.CURLOPT_FRESH_CONNECT] = longbool,
	[C.CURLOPT_FORBID_REUSE] = longbool,
	[C.CURLOPT_RANDOM_FILE] = str,
	[C.CURLOPT_EGDSOCKET] = str,
	[C.CURLOPT_CONNECTTIMEOUT] = long,
	[C.CURLOPT_HEADERFUNCTION] = cb'curl_write_callback',
	[C.CURLOPT_COOKIEJAR] = str,
	[C.CURLOPT_USE_SSL] = flag'CURLUSESSL_',
	[C.CURLOPT_SSLCERT] = str,
	[C.CURLOPT_SSLVERSION] = long,
	[C.CURLOPT_SSLCERTTYPE] = str,
	[C.CURLOPT_SSLKEY] = str,
	[C.CURLOPT_SSLKEYTYPE] = str,
	[C.CURLOPT_SSLENGINE] = str,
	[C.CURLOPT_SSLENGINE_DEFAULT] = longbool,
	[C.CURLOPT_SSL_OPTIONS] = flags'CURLSSLOPT_',
	[C.CURLOPT_SSL_CIPHER_LIST] = str,
	[C.CURLOPT_SSL_VERIFYHOST] = function(b) return 'long', b and 2 or 0 end,
	[C.CURLOPT_SSL_VERIFYPEER] = longbool,
	[C.CURLOPT_SSL_CTX_FUNCTION] = cb'curl_ssl_ctx_callback',
	[C.CURLOPT_SSL_CTX_DATA] = voidp,
	[C.CURLOPT_SSL_SESSIONID_CACHE] = longbool,
	[C.CURLOPT_SSL_ENABLE_NPN] = longbool,
	[C.CURLOPT_SSL_ENABLE_ALPN] = longbool,
	[C.CURLOPT_SSL_VERIFYSTATUS] = longbool,
	[C.CURLOPT_SSL_FALSESTART] = longbool,
	[C.CURLOPT_PREQUOTE] = slist,
	[C.CURLOPT_DEBUGFUNCTION] = cb'curl_debug_callback',
	[C.CURLOPT_DEBUGDATA] = voidp,
	[C.CURLOPT_COOKIESESSION] = longbool,
	[C.CURLOPT_CAPATH] = str,
	[C.CURLOPT_BUFFERSIZE] = long,
	[C.CURLOPT_NOSIGNAL] = longbool,
	[C.CURLOPT_SHARE] = ctype'CURLSH*',
	[C.CURLOPT_ACCEPT_ENCODING] = str,
	[C.CURLOPT_PRIVATE] = voidp,
	[C.CURLOPT_UNRESTRICTED_AUTH] = longbool,
	[C.CURLOPT_SERVER_RESPONSE_TIMEOUT] = long,
	[C.CURLOPT_IPRESOLVE] = flag'CURL_IPRESOLVE_',
	--[C.CURLOPT_MAXFILESIZE] = long,
	[C.CURLOPT_INFILESIZE] = off_t,
	[C.CURLOPT_RESUME_FROM] = off_t,
	[C.CURLOPT_MAXFILESIZE] = off_t,
	[C.CURLOPT_POSTFIELDSIZE] = off_t,
	[C.CURLOPT_TCP_NODELAY] = longbool,
	[C.CURLOPT_FTPSSLAUTH] = flag'CURLFTPAUTH_',
	[C.CURLOPT_IOCTLFUNCTION] = cb'curl_ioctl_callback',
	[C.CURLOPT_IOCTLDATA] = voidp,
	[C.CURLOPT_COOKIELIST] = str,
	[C.CURLOPT_IGNORE_CONTENT_LENGTH] = longbool,
	[C.CURLOPT_FTPPORT] = str, --IP:PORT
	[C.CURLOPT_FTP_USE_EPRT] = longbool,
	[C.CURLOPT_FTP_CREATE_MISSING_DIRS] = flag'CURLFTP_CREATE_DIR_',
	[C.CURLOPT_FTP_RESPONSE_TIMEOUT] = long,
	[C.CURLOPT_FTP_USE_EPSV] = longbool,
	[C.CURLOPT_FTP_ACCOUNT] = str,
	[C.CURLOPT_FTP_SKIP_PASV_IP] = longbool,
	[C.CURLOPT_FTP_FILEMETHOD] = flag'CURLFTPMETHOD_',
	[C.CURLOPT_FTP_USE_PRET] = longbool,
	[C.CURLOPT_FTP_SSL_CCC] = flag'CURLFTPSSL_CCC_',
	[C.CURLOPT_FTP_ALTERNATIVE_TO_USER] = str,
	[C.CURLOPT_LOCALPORT] = long,
	[C.CURLOPT_LOCALPORTRANGE] = long,
	[C.CURLOPT_CONNECT_ONLY] = longbool,
	[C.CURLOPT_CONV_FROM_NETWORK_FUNCTION] = cb'curl_conv_callback',
	[C.CURLOPT_CONV_TO_NETWORK_FUNCTION] = cb'curl_conv_callback',
	[C.CURLOPT_CONV_FROM_UTF8_FUNCTION] = cb'curl_conv_callback',
	[C.CURLOPT_SOCKOPTFUNCTION] = cb'curl_sockopt_callback',
	[C.CURLOPT_SOCKOPTDATA] = voidp,
	[C.CURLOPT_SSH_AUTH_TYPES] = flags'CURLSSH_AUTH_',
	[C.CURLOPT_SSH_PUBLIC_KEYFILE] = str,
	[C.CURLOPT_SSH_PRIVATE_KEYFILE] = str,
	[C.CURLOPT_SSH_KNOWNHOSTS] = str,
	[C.CURLOPT_SSH_KEYFUNCTION] = cb'curl_sshkeycallback',
	[C.CURLOPT_SSH_KEYDATA] = voidp,
	[C.CURLOPT_SSH_HOST_PUBLIC_KEY_MD5] = str,
	[C.CURLOPT_TIMEOUT_MS] = long,
	[C.CURLOPT_CONNECTTIMEOUT_MS] = long,
	[C.CURLOPT_NEW_FILE_PERMS] = long,
	[C.CURLOPT_NEW_DIRECTORY_PERMS] = long,
	[C.CURLOPT_POSTREDIR] = flag'CURL_REDIR_',
	[C.CURLOPT_OPENSOCKETFUNCTION] = cb'curl_opensocket_callback',
	[C.CURLOPT_OPENSOCKETDATA] = voidp,
	[C.CURLOPT_COPYPOSTFIELDS] = str,
	[C.CURLOPT_SEEKFUNCTION] = cb'curl_seek_callback',
	[C.CURLOPT_SEEKDATA] = voidp,
	[C.CURLOPT_CRLFILE] = str,
	[C.CURLOPT_ISSUERCERT] = str,
	[C.CURLOPT_ADDRESS_SCOPE] = long,
	[C.CURLOPT_CERTINFO] = longbool,
	[C.CURLOPT_USERNAME] = str,
	[C.CURLOPT_PASSWORD] = str,
	[C.CURLOPT_SOCKS5_GSSAPI_SERVICE] = str,
	[C.CURLOPT_SOCKS5_GSSAPI_NEC] = longbool,
	[C.CURLOPT_REDIR_PROTOCOLS] = flags'CURLPROTO_',
	[C.CURLOPT_MAIL_FROM] = str,
	[C.CURLOPT_MAIL_RCPT] = str,
	[C.CURLOPT_MAIL_AUTH] = str,
	[C.CURLOPT_RTSP_REQUEST] = flag'CURL_RTSPREQ_',
	[C.CURLOPT_RTSP_SESSION_ID] = str,
	[C.CURLOPT_RTSP_STREAM_URI] = str,
	[C.CURLOPT_RTSP_TRANSPORT] = str,
	[C.CURLOPT_RTSP_CLIENT_CSEQ] = long,
	[C.CURLOPT_RTSP_SERVER_CSEQ] = long,
	[C.CURLOPT_TFTP_BLKSIZE] = long,
	[C.CURLOPT_INTERLEAVEDATA] = voidp,
	[C.CURLOPT_INTERLEAVEFUNCTION] = cb'curl_write_callback',
	[C.CURLOPT_CHUNK_BGN_FUNCTION] = cb'curl_chunk_bgn_callback',
	[C.CURLOPT_CHUNK_END_FUNCTION] = cb'curl_chunk_end_callback',
	[C.CURLOPT_CHUNK_DATA] = voidp,
	[C.CURLOPT_FNMATCH_FUNCTION] = cb'curl_fnmatch_callback',
	[C.CURLOPT_FNMATCH_DATA] = voidp,
	[C.CURLOPT_RESOLVE] = slist,
	[C.CURLOPT_WILDCARDMATCH] = longbool,
	[C.CURLOPT_TLSAUTH_USERNAME] = str,
	[C.CURLOPT_TLSAUTH_PASSWORD] = str,
	[C.CURLOPT_TLSAUTH_TYPE] = str,
	[C.CURLOPT_TRANSFER_ENCODING] = longbool,
	[C.CURLOPT_CLOSESOCKETFUNCTION] = cb'curl_closesocket_callback',
	[C.CURLOPT_CLOSESOCKETDATA] = voidp,
	[C.CURLOPT_GSSAPI_DELEGATION] = long,
	[C.CURLOPT_ACCEPTTIMEOUT_MS] = long,
	[C.CURLOPT_TCP_KEEPALIVE] = longbool,
	[C.CURLOPT_TCP_KEEPIDLE] = long,
	[C.CURLOPT_TCP_KEEPINTVL] = long,
	[C.CURLOPT_SASL_IR] = longbool,
	[C.CURLOPT_XOAUTH2_BEARER] = str,
	[C.CURLOPT_XFERINFOFUNCTION] = cb'curl_xferinfo_callback',
	[C.CURLOPT_XFERINFODATA] = voidp,
	[C.CURLOPT_NETRC] = flag'CURL_NETRC_',
	[C.CURLOPT_NETRC_FILE] = str,
	[C.CURLOPT_DNS_SERVERS] = str,
	[C.CURLOPT_DNS_INTERFACE] = str,
	[C.CURLOPT_DNS_LOCAL_IP4] = str,
	[C.CURLOPT_DNS_LOCAL_IP6] = str,
	[C.CURLOPT_DNS_USE_GLOBAL_CACHE] = longbool,
	[C.CURLOPT_DNS_CACHE_TIMEOUT] = long,
	[C.CURLOPT_LOGIN_OPTIONS] = str,
	[C.CURLOPT_EXPECT_100_TIMEOUT_MS] = long,
	[C.CURLOPT_HEADEROPT] = flag'CURLHEADER_',
	[C.CURLOPT_PINNEDPUBLICKEY] = str,
	[C.CURLOPT_UNIX_SOCKET_PATH] = str,
	[C.CURLOPT_PATH_AS_IS] = longbool,
	[C.CURLOPT_SERVICE_NAME] = str,
	[C.CURLOPT_PIPEWAIT] = longbool,
}

easy._setopt = C.curl_easy_setopt
easy._setopt_prefix = 'CURLOPT_'

function easy:set(k, v)
	if type(k) == 'table' then
		for k,v in pairs(k) do
			self:set(k, v)
		end
		return
	end
	local optnum = X(self._setopt_prefix, k)
	local convert = assert(self._setopt_options[optnum])
	--pinval is for anchoring the value for the lifetime of the request.
	--v itself must also be kept but only until _setopt() returns.
	local cval, pinval, iscallback = convert(v)
	local ok, err, errcode = self:_check(self._setopt(self, optnum, cval), true)
	if not ok then
		return nil, err, errcode
	end
	self:_update_pinned_val(optnum, pinval, iscallback)
	return self
end

function easy:reset(opt)
	self:_free_pinned_vals()
	C.curl_easy_reset(self)
	if opt then
		self:set(opt)
	end
	return self
end

function easy:perform()
	return self:_ret(C.curl_easy_perform(self))
end

--pinned values --------------------------------------------------------------

local pins = {} --{CURL*|CURLM*|CURLSH* = {optnum = value}}
local cbs  = {} --{CURL*|CURLM*|CURLSH* = {optnum = value}}

local function free_cb(t)
	if not t then return end
	t.refcount = t.refcount - 1
	if t.refcount > 0 then return end
	t.cb:free()
	t.cb = nil
end

function easy:_update_pinned_val(optnum, pinval, iscallback)
	if not iscallback then
		pins[self] = pins[self] or {}
		pins[self][optnum] = pinval
	else
		cbs[self] = cbs[self] or {}
		free_cb(cbs[self][optnum])
		cbs[self][optnum] = pinval
	end
end

function easy:_copy_pinned_vals(oldself)
	if pins[oldself] then
		pins[self] = {}
		for k,v in pairs(pins[oldself]) do
			pins[self][k] = v
		end
	end
	if cbs[oldself] then
		cbs[self] = {}
		for optnum, t in pairs(cbs[oldself]) do
			t.refcount = t.refcount + 1
			cbs[self][optnum] = t
		end
	end
end

function easy:_free_pinned_vals()
	if cbs[self] then
		for optnum, t in pairs(cbs[self]) do
			free_cb(t)
		end
		cbs[self] = nil
	end
	pins[self] = nil
end

--info -----------------------------------------------------------------------

local function strbuf(buf)
	return ffi.new'char*[1]', function(buf)
		return buf[0] ~= nil and ffi.string(buf[0]) or nil
	end
end
local function longbuf(buf)
	return ffi.new'long[1]', function(buf)
		local n = tonumber(buf[0])
		return n ~= -1 and n or nil
	end
end
local function longboolbuf(buf)
	return ffi.new'long[1]', function(buf)
		return buf[0] ~= 0
	end
end
local function doublebuf(buf)
	return ffi.new'double[1]', function(buf)
		return buf[0] ~= -1 and buf[0] or nil
	end
end
local function decode_slist(buf)
		local slist0 = buf[0]
		local t = {}
		local slist = slist0
		while slist ~= nil do
			t[#t+1] = ffi.string(slist.data)
			slist = slist.next
		end
		if slist0 ~= nil then
			C.curl_slist_free_all(slist0)
		end
		return t
	end
local function slistbuf(buf)
	return ffi.new'struct curl_slist*[1]', decode_slist
end
local function certinfobuf(buf)
	return ffi.new'struct curl_certinfo*[1]', function(buf)
		return buf[0].certinfo ~= nil and decode_slist(buf[0].certinfo) or {}
	end
end
local function tlssessioninfobuf(buf)
	return ffi.new'struct curl_tlssessioninfo*[1]', function(buf)
		return buf[0]
	end
end
local function socketbuf(buf)
	return ffi.new'curl_socket_t[1]', function(buf)
		return buf[0]
	end
end

local info_buffers = {
	[C.CURLINFO_EFFECTIVE_URL] = strbuf,
	[C.CURLINFO_RESPONSE_CODE] = longbuf,
	[C.CURLINFO_TOTAL_TIME] = doublebuf,
	[C.CURLINFO_NAMELOOKUP_TIME] = doublebuf,
	[C.CURLINFO_CONNECT_TIME] = doublebuf,
	[C.CURLINFO_PRETRANSFER_TIME] = doublebuf,
	[C.CURLINFO_SIZE_UPLOAD] = doublebuf,
	[C.CURLINFO_SIZE_DOWNLOAD] = doublebuf,
	[C.CURLINFO_SPEED_DOWNLOAD] = doublebuf,
	[C.CURLINFO_SPEED_UPLOAD] = doublebuf,
	[C.CURLINFO_HEADER_SIZE] = longbuf,
	[C.CURLINFO_REQUEST_SIZE] = longbuf,
	[C.CURLINFO_SSL_VERIFYRESULT] = longboolbuf,
	[C.CURLINFO_FILETIME] = longbuf,
	[C.CURLINFO_CONTENT_LENGTH_DOWNLOAD] = doublebuf,
	[C.CURLINFO_CONTENT_LENGTH_UPLOAD] = doublebuf,
	[C.CURLINFO_STARTTRANSFER_TIME] = doublebuf,
	[C.CURLINFO_CONTENT_TYPE] = strbuf,
	[C.CURLINFO_REDIRECT_TIME] = doublebuf,
	[C.CURLINFO_REDIRECT_COUNT] = longbuf,
	[C.CURLINFO_PRIVATE] = strbuf,
	[C.CURLINFO_HTTP_CONNECTCODE] = longbuf,
	[C.CURLINFO_HTTPAUTH_AVAIL] = longbuf,
	[C.CURLINFO_PROXYAUTH_AVAIL] = longbuf,
	[C.CURLINFO_OS_ERRNO] = longbuf,
	[C.CURLINFO_NUM_CONNECTS] = longbuf,
	[C.CURLINFO_SSL_ENGINES] = slistbuf,
	[C.CURLINFO_COOKIELIST] = slistbuf,
	[C.CURLINFO_LASTSOCKET] = longbuf,
	[C.CURLINFO_FTP_ENTRY_PATH] = strbuf,
	[C.CURLINFO_REDIRECT_URL] = strbuf,
	[C.CURLINFO_PRIMARY_IP] = strbuf,
	[C.CURLINFO_APPCONNECT_TIME] = doublebuf,
	[C.CURLINFO_CERTINFO] = certinfobuf,
	[C.CURLINFO_CONDITION_UNMET] = longboolbuf,
	[C.CURLINFO_RTSP_SESSION_ID] = strbuf,
	[C.CURLINFO_RTSP_CLIENT_CSEQ] = longbuf,
	[C.CURLINFO_RTSP_SERVER_CSEQ] = longbuf,
	[C.CURLINFO_RTSP_CSEQ_RECV] = longbuf,
	[C.CURLINFO_PRIMARY_PORT] = longbuf,
	[C.CURLINFO_LOCAL_IP] = strbuf,
	[C.CURLINFO_LOCAL_PORT] = longbuf,
	[C.CURLINFO_TLS_SESSION] = tlssessioninfobuf,
	[C.CURLINFO_ACTIVESOCKET] = socketbuf,
}

function easy:info(k)
	local infonum = X('CURLINFO_', k)
	local buf, decode = assert(info_buffers[infonum])()
	self:_check(C.curl_easy_getinfo(self, infonum, buf))
	return decode(buf)
end

--misc -----------------------------------------------------------------------

function easy:recv(buf, buflen)
	local code = C.curl_easy_recv(self, buf, buflen, sizetbuf)
	return self:_ret(code, sizetbuf[0])
end

function easy:send(buf, buflen, n)
	local code = C.curl_easy_send(self, buf, buflen, sizetbuf)
	return self:_ret(code, sizetbuf[0])
end

function easy:escape(s)
	local p = C.curl_easy_escape(self, s, #s)
	if p == nil then return end
	local s = ffi.string(p)
	C.curl_free(p)
	return s
end

function easy:unescape(s)
	local p = C.curl_easy_unescape(self, s, #s, intbuf)
	if p == nil then return end
	local s = ffi.string(p, intbuf[0])
	C.curl_free(p)
	return s
end

function easy:pause(flags)
	self:_check(C.curl_easy_pause(MX('CURLPAUSE_', flags)))
end

ffi.metatype('CURL', easy_mt)

--multi interface ------------------------------------------------------------

local multi = {}
setmetatable(multi, multi) --for __call
curl.multi = multi
local multi_mt = {__index = multi}

function multi:__call(opt)
	local self = assert(ptr(C.curl_multi_init()))
	if opt then
		self:set(opt)
	end
	return self
end

function multi.strerror(code)
	return ffi.string(C.curl_multi_strerror(code))
end
multi._ret = easy._ret
multi._check = easy._check

function multi:_cleanup()
	self:_check(C.curl_multi_cleanup(self))
end
multi.close = easy.close
multi_mt.__gc = multi.close

multi._setopt_options = {
	[C.CURLMOPT_SOCKETFUNCTION] = cb'curl_socket_callback',
	[C.CURLMOPT_SOCKETDATA] = voidp,
	[C.CURLMOPT_PIPELINING] = flags'CURLPIPE_',
	[C.CURLMOPT_TIMERFUNCTION] = cb'curl_multi_timer_callback',
	[C.CURLMOPT_TIMERDATA] = voidp,
	[C.CURLMOPT_MAXCONNECTS] = longbool,
	[C.CURLMOPT_MAX_HOST_CONNECTIONS] = longbool,
	[C.CURLMOPT_MAX_PIPELINE_LENGTH] = longbool,
	[C.CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE] = longbool,
	[C.CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE] = longbool,
	[C.CURLMOPT_PIPELINING_SITE_BL] = pcharlist,
	[C.CURLMOPT_PIPELINING_SERVER_BL] = pchararray,
	[C.CURLMOPT_MAX_TOTAL_CONNECTIONS] = long,
	[C.CURLMOPT_PUSHFUNCTION] = cb'curl_push_callback',
	[C.CURLMOPT_PUSHDATA] = voidp,
}
multi._setopt = C.curl_multi_setopt
multi._setopt_prefix = 'CURLMOPT_'
multi.set = easy.set

multi._update_pinned_val = easy._update_pinned_val
multi._free_pinned_vals = easy._free_pinned_vals

function multi:perform()
	local code = C.curl_multi_perform(self, intbuf)
	return self:_ret(code, intbuf[0])
end

function multi:add(etr)
	return self:_check(C.curl_multi_add_handle(self, etr))
end

function multi:remove(etr)
	return self:_check(C.curl_multi_remove_handle(self, etr))
end

function multi:fdset(read_fd_set, write_fd_set, exc_fd_set)
	local code = C.curl_multi_fdset(self,
		read_fd_set, write_fd_set, exc_fd_set, intbuf)
	return self:_ret(code, intbuf[0])
end

function multi:wait(timeout, extra_fds, extra_nfds)
	local code = C.curl_multi_wait(self,
		extra_fds, extra_nfds or 0, (timeout or 0) * 1000, intbuf)
	return self:_ret(code, intbuf[0])
end

function multi:timeout()
	self:_check(C.curl_multi_timeout(self, longbuf))
	return longbuf[0] ~= -1 and longbuf[0] / 1000 or nil
end

function multi:info_read()
	local msg = ptr(C.curl_multi_info_read(self, intbuf))
	return msg, intbuf[0]
end

function multi:socket_action(sock, bits)
	local bits = MX('CURL_CSELECT_', bits)
	local code = C.curl_multi_socket_action(self, sock, bits, intbuf)
	return self:_ret(code, intbuf[0])
end

function multi:assign(sockfd, pd)
	return self:_check(C.curl_multi_assign(self, sockfd, p))
end

ffi.metatype('CURLM', multi_mt)

--share interface ------------------------------------------------------------

local share = {}
setmetatable(share, share) --for __call
curl.share = share
local share_mt = {__index = share}

function share:__call(opt)
	local self = assert(ptr(C.curl_share_init()))
	if opt then
		self:set(opt)
	end
	return self
end

function share.strerror(code)
	return ffi.string(C.curl_share_strerror(code))
end
share._ret = easy._ret
share._check = easy._check

function share:_cleanup()
	self:_check(C.curl_share_cleanup(self))
end
share.free = easy.close
share_mt.__gc = share.free

share._setopt_options = {
	[C.CURLSHOPT_SHARE]   = flag('CURL_LOCK_DATA_', 'int'),
	[C.CURLSHOPT_UNSHARE] = flag('CURL_LOCK_DATA_', 'int'),
	[C.CURLSHOPT_LOCKFUNC]   = cb'curl_lock_function',
	[C.CURLSHOPT_UNLOCKFUNC] = cb'curl_unlock_function',
	[C.CURLSHOPT_USERDATA] = voidp,
}
share._setopt = C.curl_share_setopt
share._setopt_prefix = 'CURLSHOPT_'
share.set = easy.set

share._update_pinned_val = easy._update_pinned_val
share._free_pinned_vals = easy._free_pinned_vals

ffi.metatype('CURLSH', share_mt)

--HTTP multipart/formdata POST -----------------------------------------------
--TODO: remove this C API from hell when we add a multipart lib written in Lua.

local form = {}
setmetatable(form, form) --for __call
curl.form = form
local form_mt = {__index = form}

local strerr = {
	[C.CURL_FORMADD_MEMORY] = 'Out of memory',
	[C.CURL_FORMADD_OPTION_TWICE] = 'Duplicate option',
	[C.CURL_FORMADD_NULL] = 'Null value',
	[C.CURL_FORMADD_UNKNOWN_OPTION] = 'Unknown option',
	[C.CURL_FORMADD_INCOMPLETE] = 'Missing options',
	[C.CURL_FORMADD_ILLEGAL_ARRAY] = 'Illegal array',
	[C.CURL_FORMADD_DISABLED] = 'Form module disabled',
}
function form_strerror(code)
	return strerr[tonumber(code)] or 'Unknown error '..code
end

local convert_option --fw. decl.

local function formarray(t)
	assert(#t % 2 == 0)
	local array = ffi.new('struct curl_forms[?]', #t+1)
	local pins = {array}
	local j = 0
	for i=1,#t,2 do
		local option, value = convert_option(t[i], t[i+1], pins)
		array[j].option = option
		array[j].value = ffi.cast('char*', value)
		j = j + 1
	end
	array[j].option = ffi.cast('long', C.CURLFORM_END)
	return array, pins
end

local formopt_options = {
	[C.CURLFORM_COPYNAME] = str,
	[C.CURLFORM_PTRNAME] = str,
	[C.CURLFORM_NAMELENGTH] = long,
	[C.CURLFORM_COPYCONTENTS] = str,
	[C.CURLFORM_PTRCONTENTS] = str,
	[C.CURLFORM_CONTENTSLENGTH] = long,
	[C.CURLFORM_FILECONTENT] = str,
	[C.CURLFORM_ARRAY] = formarray,
	[C.CURLFORM_FILE] = str,
	[C.CURLFORM_BUFFER] = str,
	[C.CURLFORM_BUFFERPTR] = voidp,
	[C.CURLFORM_BUFFERLENGTH] = long,
	[C.CURLFORM_CONTENTTYPE] = str,
	[C.CURLFORM_CONTENTHEADER] = slist,
	[C.CURLFORM_FILENAME] = str,
	[C.CURLFORM_STREAM] = voidp,
	[C.CURLFORM_CONTENTLEN] = off_t, --new in 7.46.0
}
function convert_option(option, value, pins)
	local optnum = X('CURLFORM_', option)
	local convert = assert(formopt_options[optnum])
	local cval, pinval = convert(value)
	table.insert(pins, pinval)
	return ffi.cast('long', optnum), cval
end

function curl.form()
	local first_item_buf = ffi.new'struct curl_httppost*[1]'
	local last_item_buf  = ffi.new'struct curl_httppost*[1]'

	ffi.gc(first_item_buf, function()
		if first_item_buf[0] == nil then return end --nothing was yet added
		C.curl_formfree(first_item_buf[0])
	end)

	local pins = {}
	local form = {}

	function form:add(...) --add a section
		local n = select('#', ...)
		assert(n % 2 == 0)
		local newpins = {}
		local args = {}
		for i=1,n,2 do
			local option = select(i, ...)
			local value = select(i+1, ...)
			local option, value = convert_option(option, value, newpins)
			table.insert(args, option)
			table.insert(args, value)
		end
		table.insert(args, ffi.cast('long', C.CURLFORM_END))
		local ret = C.curl_formadd(first_item_buf, last_item_buf, unpack(args))
		if ret ~= 0 then error(form_strerror(ret)) end
		--adding new pins only if the add was successful.
		table.insert(pins, newpins)
		return self
	end

	local function get(callback)
		local function append(_, buf, len)
			if callback(buf, tonumber(len)) ~= false then
				return len
			else
				return 0
			end
		end
		local append_cb = ffi.cast('curl_formget_callback', append)
		local ret = C.curl_formget(first_item_buf[0], nil, append_cb)
		append_cb:free()
		assert(ret == 0, 'curl_formget failed')
	end
	function form:get(arg)
		assert(first_item_buf[0] ~= nil, 'form empty')
		if not arg then
			local t = {}
			get(function(buf, len) table.insert(t, ffi.string(buf, len)) end)
			return table.concat(t)
		elseif type(arg) == 'table' then
			get(function(buf, len) table.insert(arg, ffi.string(buf, len)) end)
			return arg
		elseif type(arg) == 'function' then
			get(arg)
		else
			error('invalid arg')
		end
	end

	return form
end

return curl
