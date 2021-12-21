
--secure sockets for http client and server protocols based on luasocket and luasec.
--Written by Cosmin Apreutesei. Public Domain.

local loop = require'socketloop'
local ffi = require'ffi'

local M = {}

M.tcp       = loop.tcp
M.suspend   = loop.suspend
M.resume    = loop.resume
M.thread    = loop.current
M.newthread = loop.newthread
M.start     = loop.start
M.sleep     = function() end

--http<->luasocket binding ---------------------------------------------------

function M.http_bind_socket(http, sock)

	function http:getsocket() return sock end
	function http:setsocket(newsock) sock = newsock end

	function http:io_recv(buf, sz)
		local s, err, p = sock:receive(sz, nil, true)
		if not s then return nil, err end
		assert(#s <= sz)
		ffi.copy(buf, s, #s)
		return #s
	end

	function http:io_send(buf, sz)
		sz = sz or #buf
		local s = ffi.string(buf, sz)
		return sock:send(s)
	end

	function http:close()
		sock:close()
		self.closed = true
	end

end

--http<->luasec binding ------------------------------------------------------

function M.http_bind_tls(self, http, tcp, vhost, mode)

	local ssl = require'ssl'

	assert(mode == 'client' or mode == 'server')
	local stcp = ssl.wrap(tcp, {
		mode     = mode,
		protocol = 'any',
		options  = {'all', 'no_sslv2', 'no_sslv3', 'no_tlsv1'},
		verify   = self.tls_insecure_noverifycert and 'none' or 'peer',
		cafile   = self.tls_ca_file,
	})
	stcp:sni(vhost)
	tcp:setsocket(stcp)
	local ok, err
	if tcp.call_async then
		ok, err = tcp:call_async(tcp.dohandshake, tcp)
	else
		while true do
			ok, err = stcp:dohandshake()
			if ok or (err ~= 'wantread' and err ~= 'wantwrite') then
				break
			end
		end
	end
	if not ok then
		http:close()
		return nil, err
	end
	return true
end


return M
