
-- HTTP 1.1 client & server protocol in Lua.
-- Written by Cosmin Apreutesei. Public Domain.

if not ... then require'http_server_test'; return end

local clock = require'time'.clock
local glue = require'glue'
local errors = require'errors'
local linebuffer = require'linebuffer'
local http_headers = require'http_headers'
local ffi = require'ffi'
local _ = string.format

local http = {type = 'http_connection', debug_prefix = 'H'}

--error handling -------------------------------------------------------------

local check_io, checkp, check, protect = errors.tcp_protocol_errors'http'

http.check_io = check_io
http.checkp = checkp
http.check = check

function http:protect(method)
	self[method] = protect(self[method])
end

--low-level I/O API ----------------------------------------------------------

function http:create_send_function()
	function self:send(buf, sz)
		self:check_io(self.tcp:send(buf, sz, self.send_expires))
	end
end

function http:close(expires)
	self:check_io(self.tcp:close(expires))
end

--linebuffer-based read API --------------------------------------------------

function http:read_exactly(n, write)
	local read = self.linebuffer.read
	local n0 = n
	while n > 0 do
		local buf, sz = read(n)
		self:check_io(buf, sz)
		write(buf, sz)
		n = n - sz
	end
end

function http:read_line()
	return self:check_io(self.linebuffer.readline())
end

function http:read_until_closed(write_content)
	local read = self.linebuffer.read
	while true do
		local buf, sz = read(1/0)
		if not buf then
			self:check_io(nil, sz)
		elseif sz == 0 then
			break
		end
		write_content(buf, sz)
	end
end

http.max_line_size = 8192

function http:create_linebuffer()
	local function read(buf, sz)
		return self.tcp:recv(buf, sz, self.read_expires)
	end
	self.linebuffer = linebuffer(read, '\r\n', self.max_line_size)
end

--request line & status line -------------------------------------------------

--only useful (i.e. that browsers act on) status codes are listed here.
http.status_messages = {
	[200] = 'OK',
	[500] = 'Internal Server Error', --crash handler.
	[406] = 'Not Acceptable',        --basically 400, based on `accept-encoding`.
	[405] = 'Method Not Allowed',    --basically 400, based on `allowed_methods`.
	[404] = 'Not Found',             --not found and not ok to redirect to home page.
	[403] = 'Forbidden',             --needs login and not ok to redirect to login page.
	[400] = 'Bad Request',           --client bug (misuse of protocol or API).
	[401] = 'Unauthorized',          --only for Authorization / WWW-Authenticate.
	[301] = 'Moved Permanently',     --link changed (link rot protection / upgrade path).
	[303] = 'See Other',             --redirect away from a POST.
	[307] = 'Temporary Redirect',    --retry request with same method this time.
	[308] = 'Permanent Redirect',    --retry request with same method from now on.
	[429] = 'Too Many Requests',     --for throttling.
	[304] = 'Not Modified',          --use for If-None-Match or If-Modified-Since.
	[412] = 'Precondition Failed',   --use for If-Unmodified-Since or If-None-Match.
	[503] = 'Service Unavailable',   --use when server is down and avoid google indexing.
	[416] = 'Range Not Satisfiable', --for dynamic downloadable content.
	[451] = 'Unavailable For Legal Reasons', --to punish EU users for GDPR.
}

function http:send_request_line(method, uri, http_version)
	assert(http_version == '1.1' or http_version == '1.0')
	assert(method and method == method:upper())
	assert(uri)
	self:dp('=>', '%s %s HTTP/%s', method, uri, http_version)
	self:send(_('%s %s HTTP/%s\r\n', method, uri, http_version))
	return true
end

function http:read_request_line()
	local method, uri, http_version =
		self:read_line():match'^([%u]+)%s+([^%s]+)%s+HTTP/(%d+%.%d+)'
	self:dp('<-', '%s %s HTTP/%s', method, uri, http_version)
	self:check(method and (http_version == '1.0' or http_version == '1.1'), 'invalid request line')
	return http_version, method, uri
end

function http:send_status_line(status, message, http_version)
	message = message
		and message:gsub('[\r?\n]', ' ')
		or self.status_messages[status] or ''
	assert(status and status >= 100 and status <= 999, 'invalid status code')
	assert(http_version == '1.1' or http_version == '1.0')
	local s = _('HTTP/%s %d %s\r\n', http_version, status, message)
	self:dp('=>', '%s %s %s', status, message, http_version)
	self:send(s)
end

function http:read_status_line()
	local line = self:read_line()
	local http_version, status, status_message
		= line:match'^HTTP/(%d+%.%d+)%s+(%d%d%d)%s*(.*)'
	self:dp('<=', '%s %s %s', status, status_message, http_version)
	status = tonumber(status)
	self:check(http_version and status, 'invalid status line')
	return http_version, status, status_message
end

--headers --------------------------------------------------------------------

function http:format_header(k, v)
	return http_headers.format_header(k, v)
end

function http:parsed_headers(rawheaders)
	return http_headers.parsed_headers(rawheaders)
end

--special value to have a header removed because `false` might be a valid value.
http.remove = {}

--header names are case-insensitive.
--multiple spaces in header values are equivalent to a single space.
--spaces around header values are ignored.
--header names and values must not contain newlines.
--passing a table as value will generate duplicate headers for each value
--  (set-cookie will come like that because it's not safe to send it folded).
function http:send_headers(headers)
	for k, v in glue.sortedpairs(headers) do
		if v ~= http.remove then
			k, v = self:format_header(k, v)
			if v then
				if type(v) == 'table' then --must be sent unfolded.
					for i,v in ipairs(v) do
						self:dp('->', '%-17s %s', k, v)
						self:send(_('%s: %s\r\n', k, v))
					end
				else
					self:dp('->', '%-17s %s', k, v)
					self:send(_('%s: %s\r\n', k, v))
				end
			end
		end
	end
	self:send'\r\n'
end

function http:read_headers(rawheaders)
	local line, name, value
	line = self:read_line()
	while line ~= '' do --headers end up with a blank line
		name, value = line:match'^([^:]+):%s*(.*)'
		self:check(name, 'invalid header')
		name = name:lower() --header names are case-insensitive
		line = self:read_line()
		while line:find'^%s' do --unfold any folded values
			value = value .. line
			line = self:read_line()
		end
		value = value:gsub('%s+', ' ') --multiple spaces equal one space.
		value = value:gsub('%s*$', '') --around-spaces are meaningless.
		self:dp('<-', '%-17s %s', name, value)
		if http_headers.nofold[name] then --prevent folding.
			if rawheaders[name] then --duplicate header: add to list.
				table.insert(rawheaders[name], value)
			else
				rawheaders[name] = {value}
			end
		else
			if rawheaders[name] then --duplicate header: fold.
				rawheaders[name] = rawheaders[name] .. ',' .. value
			else
				rawheaders[name] = value
			end
		end
	end
end

--body -----------------------------------------------------------------------

function http:set_body_headers(headers, content, content_size, close)
	if type(content) == 'string' then
		assert(not content_size, 'content_size would be ignored')
		headers['content-length'] = #content
	elseif type(content) == 'cdata' then
		headers['content-length'] = assert(content_size, 'content_size missing')
	elseif type(content) == 'function' then
		if content_size then
			headers['content-length'] = content_size
		elseif not close then
			headers['transfer-encoding'] = 'chunked'
		end
	end
end

function http:read_chunks(write_content)
	local total = 0
	local chunk_num = 0
	while true do
		chunk_num = chunk_num + 1
		local line = self:read_line()
		local len = tonumber(string.gsub(line, ';.*', ''), 16) --len[; extension]
		self:check(len, 'invalid chunk size')
		total = total + len
		self:dp('<<', '%7d bytes; chunk %d', len, chunk_num)
		if len == 0 then --last chunk (trailers not supported)
			self:read_line()
			break
		end
		self:read_exactly(len, write_content)
		self:read_line()
	end
	self:dp('<<', '%7d bytes in %d chunks', total, chunk_num)
end

function http:send_chunked(read_content)
	local total = 0
	local chunk_num = 0
	while true do
		chunk_num = chunk_num + 1
		local chunk, len = read_content()
		if chunk then
			local len = len or #chunk
			total = total + len
			self:dp('>>', '%7d bytes; chunk %d', len, chunk_num)
			self:send(_('%X\r\n', len))
			self:send(chunk, len)
			self:send'\r\n'
		else
			self:dp('>>', '%7d bytes; chunk %d', 0, chunk_num)
			self:send'0\r\n\r\n'
			break
		end
	end
	self:dp('>>', '%7d bytes in %d chunks', total, chunk_num)
end

function http:zlib_decoder(format, write)
	assert(self.zlib, 'zlib not loaded')
	local decode = self.cowrap(function(yield)
		self.zlib.inflate(yield, write, nil, format)
	end)
	decode()
	return decode
end

function http:chained_decoder(write, encodings)
	if encodings then
		for i = #encodings, 1, -1 do
			local encoding = encodings[i]
			if encoding == 'identity' or encoding == 'chunked' then
				--identity does nothing, chunked would already be set.
			elseif encoding == 'gzip' or encoding == 'deflate' then
				write = self:zlib_decoder(encoding, write)
			else
				error'unsupported encoding'
			end
		end
	end
	return write
end

--TODO: avoid string creation
function http:zlib_encoder(format, content, content_size)
	assert(self.zlib, 'zlib not loaded')
	if type(content) == 'string' then
		return self.zlib.deflate(content, '', nil, format)
	elseif type(content) == 'cdata' then
		local s = ffi.string(content, content_size)
		return self.zlib.deflate(s, '', nil, format)
	elseif type(content) == 'function' then
		return (self.cowrap(function(yield)
			self.zlib.deflate(content, yield, nil, format)
		end))
	else
		assert(false, type(content))
	end
end

function http:send_body(content, content_size, transfer_encoding, close)
	if transfer_encoding == 'chunked' then
		self:send_chunked(content)
	else
		assert(not transfer_encoding, 'invalid transfer-encoding')
		if type(content) == 'function' then
			local total = 0
			while true do
				local chunk, len = content()
				if not chunk then break end
				local len = len or #chunk
				total = total + len
				self:dp('>>', '%7d bytes total', len)
				self:send(chunk, len)
			end
			self:dp('>>', '%7d bytes total', total)
		else
			local len = content_size or #content
			if len > 0 then
				self:dp('>>', '%7d bytes', len)
				self:send(content, len)
			end
		end
	end
	self:dp('  ', '')
	if close then
		--this is the "http graceful close" you hear about: we send a FIN to
		--the client then we wait for it to close the connection in response
		--to our FIN, and only after that we can close our end.
		--if we'd just call close() that would send a RST to the client which
		--would cut the client's pending input stream (it's how TCP works).
		--TODO: limit how much traffic we absorb for this.
		self.tcp:shutdown('w', self.send_expires)
		self:read_until_closed(glue.noop)
		self:close(self.send_expires)
	end
end

function http:read_body_to_writer(headers, write, from_server, close, state)
	if state then state.body_was_read = false end
	write = write and self:chained_decoder(write, headers['content-encoding'])
		or glue.noop
	local te = headers['transfer-encoding']
	if te and te[#te] == 'chunked' then
		self:read_chunks(write)
	elseif headers['content-length'] then
		local len = headers['content-length']
		self:dp('<<', '%7d bytes total', len)
		self:read_exactly(len, write)
	elseif from_server and close then
		self:dp('<<', '?? bytes (reading until closed)')
		self:read_until_closed(write)
	end
	if close and from_server then
		self:close(self.read_expires)
	end
	if state then state.body_was_read = true end
end

function http:read_body(headers, write, from_server, close, state)
	if write == 'string' or write == 'buffer' then
		local to_string = write == 'string'
		local write, collect = glue.dynarray_pump()
		self:read_body_to_writer(headers, write, from_server, close, state)
		local buf, sz = collect()
		if to_string then
			return ffi.string(buf, sz)
		else
			return buf, sz
		end
	elseif write == 'reader' then
		--don't read the body, but return a reader function for it instead.
		return (self.cowrap(function(yield)
			self:read_body_to_writer(headers, yield, from_server, close, state)
			return nil, 'eof'
		end))
	else
		self:read_body_to_writer(headers, write, from_server, close, state)
		return true
	end
end

--client-side ----------------------------------------------------------------

local creq = {}
http.client_request_class = creq

function http:build_request(t, cookies)
	local req = glue.object(creq,
		{http = self, type = 'http_request', debug_prefix = 'R'})

	req.http_version = t.http_version or '1.1'
	req.method = t.method or 'GET'
	req.uri = t.uri or '/'

	req.headers = {}

	assert(t.host, 'host missing') --required, even for HTTP/1.0.
	local default_port = self.https and 443 or 80
	local port = self.port ~= default_port and self.port or nil
	req.headers['host'] = {host = t.host, port = port}

	req.close = t.close or req.http_version == '1.0'
	if req.close then
		req.headers['connection'] = 'close'
	end

	if self.zlib then
		req.headers['accept-encoding'] = 'gzip, deflate'
	end

	req.headers['cookie'] = cookies

	req.content, req.content_size = t.content, t.content_size
	if self.zlib and t.compress ~= false then
		req.headers['content-encoding'] = 'gzip'
		req.content, req.content_size =
			self:encode_content(req.content, req.content_size, 'gzip')
	end

	self:set_body_headers(req.headers, req.content, req.content_size, req.close)
	glue.update(req.headers, t.headers)

	req.receive_content = t.receive_content
	req.request_timeout = t.request_timeout
	req.reply_timeout   = t.reply_timeout

	return req
end

function http:send_request(req)
	local dt = req.request_timeout
	self.start_time = clock()
	self.send_expires = dt and self.start_time + dt or nil
	self:send_request_line(req.method, req.uri, req.http_version)
	self:send_headers(req.headers)
	self:send_body(req.content, req.content_size, req.headers['transfer-encoding'])
	return true
end
http:protect'send_request'

function http:should_have_response_body(method, status)
	if method == 'HEAD' then return false end
	if status == 204 or status == 304 then return false end
	if status >= 100 and status < 200 then return false end
	return true
end

function http:should_redirect(req, res)
	local method, status = req.method, res.status
	return res.headers['location']
		and (status == 301 or status == 302 or status == 303 or status == 307)
end

local function is_ip(s)
	return s:find'^%d+%.%d+%.%d+%.%d+'
end

function http:cookie_default_path(req_uri)
	return '/' --TODO
end

--either the cookie domain matches host exactly or the domain is a suffix.
function http:cookie_domain_matches_request_host(domain, host)
	return not domain or domain == host or (
		host:sub(-#domain) == domain
		and host:sub(-#domain-1, -#domain-1) == '.'
		and not is_ip(host)
	)
end

--cookie path matches request path exactly, or
--cookie path ends in `/` and is a prefix of the request path, or
--cookie path is a prefix of the request path, and the first
--character of the request path that is not included in the cookie path is `/`.
function http:cookie_path_matches_request_path(cpath, rpath)
	if cpath == rpath then
		return true
	elseif cpath == rpath:sub(1, #cpath) then
		if cpath:sub(-1, -1) == '/' then
			return true
		elseif rpath:sub(#cpath + 1, #cpath + 1) == '/' then
			return true
		end
	end
	return false
end

--NOTE: cookies are not port-specific nor protocol-specific.
function http:should_send_cookie(cookie, host, path, https)
	return (https or not cookie.secure)
		and self:cookie_domain_matches_request_host(cookie, host)
		and self:cookie_path_matches_request_path(cookie, path)
end

local cres = {}

function http:read_response(req)
	local res = glue.object(cres, {})
	res.rawheaders = {}

	local dt = req.reply_timeout
	self.read_expires = dt and clock() + dt or nil

	res.http_version, res.status = self:read_status_line()

	while res.status == 100 do --ignore any 100-continue messages
		self:read_headers(res.rawheaders)
		res.http_version, res.status = self:read_status_line()
	end

	self:read_headers(res.rawheaders)
	res.headers = self:parsed_headers(res.rawheaders)

	res.close = req.close
		or (res.headers['connection'] and res.headers['connection'].close)
		or res.http_version == '1.0'

	local receive_content = req.receive_content
	if self:should_redirect(req, res) then
		receive_content = nil --ignore the body
		res.redirect_location = self:check(res.headers['location'], 'no location')
		res.receive_content = req.receive_content
	end

	if self:should_have_response_body(req.method, res.status) then
		res.content, res.content_size =
			self:read_body(res.headers, receive_content, true, res.close, res)
	end

	return res
end
http:protect'read_response'

--server side ----------------------------------------------------------------

local sreq = {}
http.server_request_class = sreq

function http:read_request()
	self.start_time = clock()
	local req = glue.object(sreq, {http = self})
	req.http_version, req.method, req.uri = self:read_request_line()
	req.rawheaders = {}
	self:read_headers(req.rawheaders)
	req.headers = self:parsed_headers(req.rawheaders)
	req.close = req.headers['connection'] and req.headers['connection'].close
	return req
end
http:protect'read_request'

function sreq:read_body(write)
	return self.http:read_request_body(self, write)
end

function http:read_request_body(req, write)
	return self:read_body(req.headers, write, false, false, req)
end
http:protect'read_request_body'

local function content_size(opt)
	return type(opt.content) == 'string' and #opt.content
		or opt.content_size
end

local function no_body(res, status)
	res.status = status
	res.content, res.content_size = ''
end

local function q0(t)
	return type(t) == 'table' and t.q == 0
end

http.nocompress_mime_types = glue.index{
	'image/gif',
	'image/jpeg',
	'image/png',
	'image/x-icon',
	'font/woff',
	'font/woff2',
	'application/pdf',
	'application/zip',
	'application/x-gzip',
	'application/x-xz',
	'application/x-bz2',
	'audio/mpeg',
	'text/event-stream',
}

function http:accept_content_type(req, opt)
	return true, opt.content_type
end

function http:accept_content_encoding(req, opt)
	local accept = req.headers['accept-encoding']
	if not accept then
		return true
	end
	local compress = opt.compress ~= false and self.zlib
		and (content_size(opt) or 1/0) >= 1000
		and (not opt.content_type or not self.nocompress_mime_types[opt.content_type])
	if not compress then
		return true
	end
	if not q0(accept.gzip   ) then return true, 'gzip'    end
	if not q0(accept.deflate) then return true, 'deflate' end
	return true
end

function http:encode_content(content, content_size, content_encoding)
	if content_encoding == 'gzip' or content_encoding == 'deflate' then
		content, content_size =
			self:zlib_encoder(content_encoding, content, content_size)
	else
		assert(not content_encoding, 'invalid content-encoding')
	end
	return content, content_size
end

function http:allow_method(req, opt)
	local allowed_methods = opt.allowed_methods
	return not allowed_methods or allowed_methods[req.method], allowed_methods
end

local sres = {}

function http:build_response(req, opt, time)
	local res = glue.object(self.response,
		{http = self, request = req, type = 'http_response', debug_prefix = '<'})
	res.headers = {}

	res.http_version = opt.http_version or req.http_version

	res.close = opt.close or req.close
	if res.close then
		res.headers['connection'] = 'close'
	end

	if opt.status then
		res.status = opt.status
		res.status_message = opt.status_message
	else
		res.status = 200
	end

	local allow, methods = self:allow_method(req, opt)
	if not allow then
		res.headers['allow'] = methods
		no_body(res, 405) --method not allowed
		return res
	end

	local accept, content_type = self:accept_content_type(req, opt)
	if not accept then
		no_body(res, 406) --not acceptable
		return res
	else
		res.headers['content-type'] = content_type
	end

	local accept, content_encoding = self:accept_content_encoding(req, opt)
	if not accept then
		no_body(res, 406) --not acceptable
		return res
	else
		res.headers['content-encoding'] = content_encoding
	end

	res.content, res.content_size =
		self:encode_content(opt.content, opt.content_size, content_encoding)

	res.headers['date'] = time

	self:set_body_headers(res.headers, res.content, res.content_size, res.close)
	glue.update(res.headers, opt.headers)

	return res
end

function http:send_response(res)
	self:send_status_line(res.status, res.status_message, res.http_version)
	self:send_headers(res.headers)
	self:send_body(res.content, res.content_size, res.headers['transfer-encoding'], res.close)
	return true
end
http:protect'send_response'

--instantiation --------------------------------------------------------------

function http:log(severity, module, event, fmt, ...)
	local logging = self.logging
	if not logging or logging.filter[severity] then return end
	local S = self.tcp or '-'
	local dt = clock() - self.start_time
	local s = fmt and _(fmt, logging.args(...)) or ''
	logging.log(severity, module, event, '%-4s %6.2fs %s', S, dt, s)
end

function http:new(t)

	local self = glue.object(self, {}, t)

	if self.debug and self.debug.tracebacks then
		self.tracebacks = true --for tcp_protocol_errors.
	end

	if self.debug and (self.logging == nil or self.logging == true) then
		self.logging = require'logging'
	end

	if self.debug and self.debug.protocol then

		function self:dp(...)
			return self:log('', 'http', ...)
		end

	else
		self.dp = glue.noop
	end

	if self.debug and self.debug.stream then

		local function ds(event, s)
			self:log('', 'http', event, '%5s %s', s and #s or '', s or '')
		end

		glue.override(self.tcp, 'recv', function(inherited, self, buf, ...)
			local sz, err, errcode = inherited(self, buf, ...)
			if not sz then return nil, err, errcode end
			ds('<', ffi.string(buf, sz))
			return sz
		end)

		glue.override(self.tcp, 'send', function(inherited, self, buf, ...)
			local sz, err, errcode = inherited(self, buf, ...)
			if not sz then return nil, err, errcode end
			ds('>', ffi.string(buf, sz))
			return sz
		end)

		glue.override(self.tcp, 'close', function(inherited, self, ...)
			local ok, err, errcode = inherited(self, ...)
			if not ok then return nil, err, errcode  end
			ds('CC')
			return ok
		end)

	end

	self:create_linebuffer()
	self:create_send_function()
	return self
end

return http
