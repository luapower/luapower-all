
if not ... then require'http_server_test'; return end

--secure sockets with libtls.
--Written by Cosmin Apreutesei. Public Domain.

require'sock' --not used directly, but it is a dependency.
local glue = require'glue'
local tls = require'libtls'
local ffi = require'ffi'
local C = tls.C

local stcp = {issocket = true, istcpsocket = true, istlssocket = true}
local client_stcp = {}
local server_stcp = {}
local M = {}

local cb_r_buf, cb_r_sz, cb_r_len
local cb_w_buf, cb_w_sz, cb_w_len

local read_cb = ffi.cast('tls_read_cb', function(self, buf, sz)
	sz = tonumber(sz)
	if cb_r_buf == nil then
		cb_r_buf = buf
		cb_r_sz  = sz
		return C.TLS_WANT_POLLIN
	else
		assert(cb_r_buf == buf)
		assert(cb_r_sz  == sz)
		assert(cb_r_len <= sz)
		cb_r_buf = nil
		return cb_r_len
	end
end)

local write_cb = ffi.cast('tls_write_cb', function(self, buf, sz)
	sz = tonumber(sz)
	if cb_w_buf == nil then
		cb_w_buf = buf
		cb_w_sz  = sz
		return C.TLS_WANT_POLLOUT
	else
		assert(cb_w_buf == buf)
		assert(cb_w_sz  == sz)
		assert(cb_w_len <= sz)
		cb_w_buf = nil
		return cb_w_len
	end
end)

function M.client_stcp(tcp, servername, opt)
	local tls, err = tls.client(opt)
	if not tls then
		return nil, err
	end
	local ok, err = tls:connect(servername, read_cb, write_cb)
	if not ok then
		tls:free()
		return nil, err
	end
	return glue.object(client_stcp, {
		tcp = tcp,
		tls = tls,
	})
end

function M.server_stcp(tcp, opt)
	local tls, err = tls.server(opt)
	if not tls then
		return nil, err
	end
	return glue.object(server_stcp, {
		tcp = tcp,
		tls = tls,
	})
end

function server_stcp:accept()
	local ctcp, err, errcode = self.tcp:accept()
	if not ctcp then
		return nil, err, errcode
	end
	local ctls, err = self.tls:accept(read_cb, write_cb)
	if not ctls then
		return nil, err
	end
	return glue.object(client_stcp, {
		tcp = ctcp,
		tls = ctls,
	})
end

local function checkio(self, expires, tls_ret, tls_err)
	if tls_err == 'wantrecv' then
		local buf, sz = cb_r_buf, cb_r_sz
		local t1, t2, t3 = cb_w_buf, cb_w_sz, cb_w_len
		if cb_w_buf then
			assert(false) --TODO: full-duplex protocol
		end
		local len, err, errcode = self.tcp:recv(buf, sz, expires)
		cb_w_buf, cb_w_sz, cb_w_len = t1, t2, t3
		if not len then
			return false, len, err, errcode
		end
		cb_r_buf, cb_r_sz, cb_r_len = buf, sz, len
		return true
	elseif tls_err == 'wantsend' then
		local buf, sz = cb_w_buf, cb_w_sz
		local t1, t2, t3 = cb_r_buf, cb_r_sz, cb_r_len
		if cb_r_buf then
			assert(false) --TODO: full-duplex protocol
		end
		local len, err, errcode = self.tcp:send(buf, sz, expires)
		cb_r_buf, cb_r_sz, cb_r_len = t1, t2, t3
		if not len then
			return false, len, err, errcode
		end
		cb_w_buf, cb_w_sz, cb_w_len = buf, sz, len
		return true
	else
		return false, tls_ret, tls_err
	end
end

function client_stcp:recv(buf, sz, expires)
	if self._closed then return 0 end
	cb_r_buf = nil
	cb_w_buf = nil
	while true do
		local recall, ret, err, errcode = checkio(self, expires, self.tls:recv(buf, sz))
		if not recall then return ret, err, errcode end
	end
end

function client_stcp:send(buf, sz, expires)
	if self._closed then return nil, 'eof' end
	cb_r_buf = nil
	cb_w_buf = nil
	while true do
		local recall, ret, err, errcode = checkio(self, expires, self.tls:send(buf, sz))
		if not recall then return ret, err, errcode end
	end
end

function client_stcp:shutdown(mode)
	return self.tcp:shutdown(mode)
end

function stcp:close(expires)
	if self._closed then return true end
	self._closed = true --close barrier.
	cb_r_buf = nil
	cb_w_buf = nil
	local recall, tls_ok, tls_err, tls_errcode
	repeat
		recall, tls_ok, tls_err, tls_errcode = checkio(self, expires, self.tls:close())
	until not recall
	self.tls:free()
	local tcp_ok, tcp_err, tcp_errcode = self.tcp:close()
	self.tls = nil
	self.tcp = nil
	if not tls_ok then return false, tls_err, tls_errcode end
	if not tcp_ok then return false, tcp_err, tcp_errcode end
	return true
end

function stcp:closed()
	return self._closed or false
end

function stcp:shutdown(mode, expires)
	return self:close(expires)
end

glue.update(client_stcp, stcp)
glue.update(server_stcp, stcp)

M.config = tls.config

return M
