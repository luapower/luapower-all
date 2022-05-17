
if not ... then require'http_server_test'; return end

--secure sockets with libtls.
--Written by Cosmin Apreutesei. Public Domain.

local sock = require'sock'
local glue = require'glue'
local tls = require'libtls'
local ffi = require'ffi'
local C = tls.C

local stcp = {issocket = true, istcpsocket = true, istlssocket = true}
local client_stcp = glue.update({}, sock.tcp_class)
local server_stcp = glue.update({}, sock.tcp_class)
local M = {}

local w_bufs = {}
local r_bufs = {}
local bufs_n = 0
local buf_freelist = {}
local buf_freelist_n = 0

local function alloc_buf_slot()
	if buf_freelist_n > 0 then
		buf_freelist_n = buf_freelist_n - 1
		return buf_freelist[buf_freelist_n + 1]
	else
		bufs_n = bufs_n + 1
		return bufs_n
	end
end

local function free_buf_slot(i)
	buf_freelist_n = buf_freelist_n + 1
	buf_freelist[buf_freelist_n] = i
end

local read_cb = ffi.cast('tls_read_cb', function(tls, buf, sz, i)
	sz = tonumber(sz)
	i = tonumber(i)
	local r_buf, r_sz = r_bufs[2*i], r_bufs[2*i+1]
	if not r_buf then
		r_bufs[2*i] = buf
		r_bufs[2*i+1] = sz
		return C.TLS_WANT_POLLIN
	else
		assert(r_buf == buf)
		assert(r_sz <= sz)
		r_bufs[2*i] = false
		return r_sz
	end
end)

local write_cb = ffi.cast('tls_write_cb', function(tls, buf, sz, i)
	sz = tonumber(sz)
	i = tonumber(i)
	local w_buf, w_sz = w_bufs[2*i], w_bufs[2*i+1]
	if not w_buf then
		w_bufs[2*i] = buf
		w_bufs[2*i+1] = sz
		return C.TLS_WANT_POLLOUT
	else
		assert(w_buf == buf)
		assert(w_sz <= sz)
		w_bufs[2*i] = false
		return w_sz
	end
end)

local function checkio(self, expires, tls_ret, tls_err)
	if tls_err == 'wantrecv' then
		local i = self.buf_slot
		local buf, sz = r_bufs[2*i], r_bufs[2*i+1]
		local len, err = self.tcp:recv(buf, sz, expires)
		if not len then
			return false, len, err
		end
		r_bufs[2*i+1] = len
		return true
	elseif tls_err == 'wantsend' then
		local i = self.buf_slot
		local buf, sz = w_bufs[2*i], w_bufs[2*i+1]
		local len, err = self.tcp:_send(buf, sz, expires)
		if not len then
			return false, len, err
		end
		w_bufs[2*i+1] = len
		return true
	else
		return false, tls_ret, tls_err
	end
end

function client_stcp:recv(buf, sz, expires)
	if self._closed then return 0 end
	while true do
		local recall, ret, err = checkio(self, expires, self.tls:recv(buf, sz))
		if not recall then return ret, err end
	end
end

function client_stcp:_send(buf, sz, expires)
	if self._closed then return nil, 'eof' end
	while true do
		local recall, ret, err = checkio(self, expires, self.tls:send(buf, sz))
		if not recall then return ret, err end
	end
end

function stcp:close(expires)
	if self._closed then return true end
	self._closed = true --close barrier.
	local recall, tls_ok, tls_err
	repeat
		recall, tls_ok, tls_err = checkio(self, expires, self.tls:close())
	until not recall
	self.tls:free()
	local tcp_ok, tcp_err = self.tcp:close()
	self.tls = nil
	self.tcp = nil
	free_buf_slot(self.buf_slot)
	if not tls_ok then return false, tls_err end
	if not tcp_ok then return false, tcp_err end
	return true
end

local function wrap_stcp(stcp_class, tcp, tls, buf_slot)
	return glue.object(stcp_class, {
		tcp = tcp,
		tls = tls,
		buf_slot = buf_slot,
	})
end

function M.client_stcp(tcp, servername, opt)
	local tls, err = tls.client(opt)
	if not tls then
		return nil, err
	end
	local buf_slot = alloc_buf_slot()
	local ok, err = tls:connect(servername, read_cb, write_cb, buf_slot)
	if not ok then
		tls:free()
		return nil, err
	end
	return wrap_stcp(client_stcp, tcp, tls, buf_slot)
end

function M.server_stcp(tcp, opt)
	local tls, err = tls.server(opt)
	if not tls then
		return nil, err
	end
	local buf_slot = alloc_buf_slot()
	return wrap_stcp(server_stcp, tcp, tls, buf_slot)
end

function server_stcp:accept()
	local ctcp, err = self.tcp:accept()
	if not ctcp then
		return nil, err
	end
	local buf_slot = alloc_buf_slot()
	local ctls, err = self.tls:accept(read_cb, write_cb, buf_slot)
	if not ctls then
		free_buf_slot(buf_slot)
		return nil, err
	end
	return wrap_stcp(client_stcp, ctcp, ctls, buf_slot)
end

function stcp:closed()
	return self._closed or false
end

--function stcp:shutdown(mode, expires)
--	return self:close(expires)
--end

function stcp:shutdown(mode)
	return self.tcp:shutdown(mode)
end

glue.update(client_stcp, stcp)
glue.update(server_stcp, stcp)

M.config = tls.config

return M
