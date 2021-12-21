
if not ... then require'http_server_test'; return end

local http = require'http'
local time = require'time'
local glue = require'glue'
local errors = require'errors'

local _ = string.format
local attr = glue.attr
local push = table.insert

local server = {
	type = 'http_server', http = http,
	tls_options = {
		loadfile = glue.readfile,
		protocols = 'tlsv1.2',
		ciphers = [[
			ECDHE-ECDSA-AES256-GCM-SHA384
			ECDHE-RSA-AES256-GCM-SHA384
			ECDHE-ECDSA-CHACHA20-POLY1305
			ECDHE-RSA-CHACHA20-POLY1305
			ECDHE-ECDSA-AES128-GCM-SHA256
			ECDHE-RSA-AES128-GCM-SHA256
			ECDHE-ECDSA-AES256-SHA384
			ECDHE-RSA-AES256-SHA384
			ECDHE-ECDSA-AES128-SHA256
			ECDHE-RSA-AES128-SHA256
		]],
		prefer_ciphers_server = true,
	},
}

function server:bind_libs(libs)
	for lib in libs:gmatch'[^%s]+' do
		if lib == 'sock' then
			local sock = require'sock'
			self.tcp           = sock.tcp
			self.cowrap        = sock.cowrap
			self.newthread     = sock.newthread
			self.resume        = sock.resume
			self.thread        = sock.thread
			self.start         = sock.start
			self.sleep         = sock.sleep
			self.currentthread = sock.currentthread
		elseif lib == 'sock_libtls' then
			local socktls = require'sock_libtls'
			self.stcp          = socktls.server_stcp
		elseif lib == 'zlib' then
			self.http.zlib = require'zlib'
		else
			assert(false)
		end
	end
end

function server:time(ts)
	return glue.time(ts)
end

server.request_finish = glue.noop --request finalizer stub

function server:log(tcp, severity, module, event, fmt, ...)
	local logging = self.logging
	if not logging or logging.filter[severity] then return end
	local s = fmt and _(fmt, logging.args(...)) or ''
	logging.log(severity, module, event, '%-4s %s', tcp, s)
end

function server:check(tcp, ret, ...)
	if ret then return ret end
	return self:log(tcp, 'ERROR', 'htsrv', ...)
end

function server:new(t)

	local self = glue.object(self, {}, t)

	if self.libs then
		self:bind_libs(self.libs)
	end

	if self.debug and (self.logging == nil or self.logging == true) then
		self.logging = require'logging'
	end

	local function handler(ctcp, listen_opt)

		local http = self.http:new({
			debug = self.debug,
			max_line_size = self.max_line_size,
			tcp = ctcp,
			cowrap = self.cowrap,
			currentthread = self.currentthread,
			listen_options = listen_opt,
		})

		while not ctcp:closed() do

			local req, err = http:read_request()
			if not req then
				local eof = errors.is(err, 'socket') and err.message == 'eof'
				self:check(ctcp, eof, 'read_request', '%s', err)
				break
			end

			local finished, write_body, sending_response

			local function send_response(opt)
				if opt.content == nil then
					opt.content = ''
				end
				sending_response = true
				local res = http:build_response(req, opt, self:time())
				local ok, err = http:send_response(res)
				self:check(ctcp, ok, 'send_response', '%s', err)
				finished = true
			end

			function req.respond(req, opt, want_write_body)
				if want_write_body then
					write_body = self.cowrap(function(yield)
						opt.content = yield
						send_response(opt)
					end)
					write_body()
					return write_body
				else
					send_response(opt)
				end
			end

			function req.raise(req, status, content)
				local err
				if type(status) == 'number' then
					err = {status = status, content = content}
				elseif type(status) == 'table' then
					err = status
				else
					assert(false)
				end
				errors.raise('http_response', err)
			end

			req.thread = self.currentthread()

			local ok, err = errors.catch(nil, self.respond, req)
			self:request_finish(req)

			if not ok then
				if errors.is(err, 'http_response') then
					assert(not sending_response, 'response already sent')
					req:respond(err)
				elseif not sending_response then
					self:check(ctcp, false, 'respond', '%s', err)
					req:respond{status = 500}
				else
					error(_('respond() error:\n%s', err))
				end
			elseif not finished then --eof not signaled.
				if write_body then
					write_body() --eof
				else
					send_response({})
				end
			end

			--the request must be entirely read before we can read the next request.
			if req.body_was_read == nil then
				req:read_body()
			end
			assert(req.body_was_read, 'request body was not read')

		end
	end

	local stop
	function self:stop()
		stop = true
	end

	self.sockets = {}

	for i,t in ipairs(self.listen) do
		if t.addr == false then
			goto continue
		end

		local tcp = assert(self.tcp())
		assert(tcp:setopt('reuseaddr', true))
		local addr, port = t.addr or '*', t.port or (t.tls and 443 or 80)

		local ok, err = tcp:listen(addr, port)
		if not ok then
			self:check(tcp, false, 'listen', '("%s", %s): %s', addr, port, err)
			goto continue
		end
		self:log(tcp, 'note', 'htsrv', 'LISTEN', '%s:%d', addr, port)

		if t.tls then
			local opt = glue.update(self.tls_options, t.tls_options)
			local stcp, err = self.stcp(tcp, opt)
			if self:check(tcp, stcp, 'stcp', '%s', err) then
				tcp:close()
				goto continue
			end
			tcp = stcp
		end
		push(self.sockets, tcp)

		function accept_connection()
			local ctcp, err = tcp:accept()
			if not self:check(tcp, ctcp, 'accept',' %s', err) then
				return
			end
			self.thread(function()
				self:log(ctcp, 'note', 'htsrv', 'accept')
				local ok, err = glue.pcall(handler, ctcp, t)
				self:log(ctcp, 'note', 'htsrv', 'closed')
				self:check(ctcp, ok, 'handler', '%s', err)
				ctcp:close()
			end)
		end

		self.thread(function()
			while not stop do
				accept_connection()
			end
		end)

		::continue::
	end

	return self
end

return server
