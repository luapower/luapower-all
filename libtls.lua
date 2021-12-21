
if not ... then require'http_server_test'; return end

--libtls binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libtls_test'; return end

local ffi = require'ffi'
require'libtls_h'
local C = ffi.load(ffi.tls_libname or 'tls')
local M = {C = C}

M.debug = function() end

local function ptr(p) return p ~= nil and p or nil end
local function str(s) return s ~= nil and ffi.string(s) or nil end

local config = {}

function M.config(t)
	if ffi.istype('struct tls_config', t) then
		return t --pass-through
	end
	local self = assert(ptr(C.tls_config_new()))
	self:verify() --default, so `insecure_*` options must be set explicitly.
	if t then
		local ok, err = self:set(t)
		if not ok then
			self:free()
			error(err)
		end
	end
	return self, true
end

function config:free()
	C.tls_config_free(self)
end

local function check(self, ret)
	if ret == 0 then return true end
	return nil, str(C.tls_config_error(self)) or 'unknown tls config error'
end

function config:add_keypair(cert, cert_size, key, key_size, staple, staple_size)
	return check(self, C.tls_config_add_keypair_ocsp_mem(self,
		cert, cert_size or #cert,
		key, key_size or #key,
		staple, staple_size or (staple and #staple or 0)))
end

function config:set_alpn(alpn)
	return check(self, C.tls_config_set_alpn(self, alpn))
end

function config:set_ca(s, sz)
	return check(self, C.tls_config_set_ca_mem(self, s, sz or #s))
end

function config:set_cert(s, sz)
	return check(self, C.tls_config_set_cert_mem(self, s, sz or #s))
end

function config:set_key(s, sz)
	return check(self, C.tls_config_set_key_mem(self, s, sz or #s))
end

function config:set_ocsp_staple(s, sz)
	return check(self, C.tls_config_set_ocsp_staple_mem(self, s, sz or #s))
end

function config:set_keypairs(t)
	for i,t in ipairs(t) do
		if i == 1 then
			if t.cert then
				local ok, err = self:set_cert(t.cert, t.cert_size)
				if not ok then return nil, err end
			end
			if t.key then
				local ok, err = self:set_key(t.key, t.key_size)
				if not ok then return nil, err end
			end
			if t.ocsp_staple then
				local ok, err = self:set_ocsp_staple(t.ocsp_staple, t.ocsp_staple_size)
				if not ok then return nil, err end
			end
		else
			local ok, err = self:add_keypair(
				t.cert, t.cert_size,
				t.key, t.key_size,
				t.ocsp_staple, t.ocsp_staple_size)
			if not ok then return nil, err end
		end
	end
	return true
end

--NOTE: session tickets not supported by BearSSL.
function config:set_ticket_keys(t)
	for _,t in ipairs(t) do
		local ok, err = self:add_ticket_key(t.ticket_key_rev, t.ticket_key, t.ticket_key_size)
		if not ok then return nil, err end
	end
	return true
end

function config:add_ticket_key(keyrev, key, key_size)
	return check(self, C.tls_config_add_ticket_key(self, keyrev, key, key_size or #key))
end

function config:set_ciphers(s)
	s = s:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ':')
	return check(self, C.tls_config_set_ciphers(self, s))
end

function config:set_crl(crl, sz)
	return check(self, C.tls_config_set_crl_mem(self, crl, sz or #crl))
end

function config:set_dheparams(params)
	return check(self, C.tls_config_set_dheparams(self, params))
end

function config:set_ecdhecurve(curve)
	return check(self, C.tls_config_set_ecdhecurve(self, curve))
end

function config:set_ecdhecurves(curves)
	return check(self, C.tls_config_set_ecdhecurves(self, curves))
end

function config:set_protocols(protocols)
	local err
	if type(protocols) == 'string' then
		protocols, err = self:parse_protocols(protocols)
		if not protocols then return nil, err end
	end
	return check(self, C.tls_config_set_protocols(self, protocols))
end

function config:set_verify_depth(verify_depth)
	return check(self, C.tls_config_set_verify_depth(self, verify_depth))
end

local function return_true(f)
	return function(self)
		f(self)
		return true
	end
end
config.prefer_ciphers_client  = return_true(C.tls_config_prefer_ciphers_client)
config.prefer_ciphers_server  = return_true(C.tls_config_prefer_ciphers_server)
config.insecure_noverifycert  = return_true(C.tls_config_insecure_noverifycert)
config.insecure_noverifyname  = return_true(C.tls_config_insecure_noverifyname)
config.insecure_noverifytime  = return_true(C.tls_config_insecure_noverifytime)
config.verify                 = return_true(C.tls_config_verify)
config.ocsp_require_stapling  = return_true(C.tls_config_ocsp_require_stapling)
config.verify_client          = return_true(C.tls_config_verify_client)
config.verify_client_optional = return_true(C.tls_config_verify_client_optional)
config.clear_keys             = return_true(C.tls_config_clear_keys)

local proto_buf = ffi.new'uint32_t[1]'
function config:parse_protocols(s)
	s = s:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ':')
	local ok, err = check(self, C.tls_config_parse_protocols(proto_buf, s))
	if not ok then return nil, err end
	return proto_buf[0]
end

function config:set_session_id(session_id, sz)
	return check(self, C.tls_config_set_session_id(self, session_id, sz or #session_id))
end

function config:set_session_lifetime(lifetime)
	return check(self, C.tls_config_set_session_lifetime(self, lifetime))
end

do
	local function barg(set_method)
		return function(self, arg)
			if not arg then return true end
			return set_method(self)
		end
	end

	local keys = {
		{'ca'                    , config.set_ca, true},
		{'cert'                  , config.set_cert, true},
		{'key'                   , config.set_key, true},
		{'ocsp_staple'           , config.set_ocsp_staple, true},
		{'keypairs'              , config.set_keypairs},
		{'ticket_keys'           , config.set_ticket_keys},
		{'ciphers'               , config.set_ciphers},
		{'alpn'                  , config.set_alpn},
		--NOTE: DHE not supported by BearSSL (but supported by LibreSSL).
		{'dheparams'             , config.set_dheparams},
		{'ecdhecurve'            , config.set_ecdhecurve},
		{'ecdhecurves'           , config.set_ecdhecurves},
		{'protocols'             , config.set_protocols},
		{'prefer_ciphers_client' , barg(config.prefer_ciphers_client)},
		{'prefer_ciphers_server' , barg(config.prefer_ciphers_server)},
		{'insecure_noverifycert' , barg(config.insecure_noverifycert)},
		{'insecure_noverifyname' , barg(config.insecure_noverifyname)},
		{'insecure_noverifytime' , barg(config.insecure_noverifytime)},
		{'verify'                , barg(config.verify)},
		{'verify_client'         , barg(config.verify_client)},
		{'verify_client_optional', barg(config.verify_client_optional)},
		{'verify_depth'          , config.set_verify_depth},
		{'ocsp_require_stapling' , barg(config.ocsp_require_stapling)},
		--NOTE: CRL not supported by BearSSL (but supported by LibreSSL).
		{'crl'                   , config.set_crl, true},
		--TODO: add sessions to libtls-bearssl.
		{'session_id'            , config.set_session_id, true},
		{'session_lifetime'      , config.set_session_lifetime},
	}

	local function load_files(t, loadfile)
		for k,v in pairs(t) do
			if glue.ends(k, '_file') then
				--NOTE: bearssl doesn't handle CRLF.
				t[k:gsub('_file$', '')] = assert(loadfile(v)):gsub('\r', '')
				t[k] = nil
			end
		end
	end

	function config:set(t1)

		local loadfile = t1.loadfile
		local t = {}
		for k,v in pairs(t1) do t[k] = v end
		load_files(t, loadfile)
		if t.keypairs then
			for i,t in ipairs(t.keypairs) do
				load_files(t, loadfile)
			end
		end
		if t.ticket_keys then
			for i,t in ipairs(t.ticket_keys) do
				load_files(t, loadfile)
			end
		end

		for i,kt in ipairs(keys) do
			local k, set_method, is_str = unpack(kt)
			local v = t[k]
			if v ~= nil then
				local sz = is_str and (t[k..'_size'] or #v) or nil
				local ok, err = set_method(self, v, sz)
				if not ok then return nil, err end
				M.debug(('tls config %-25s %s'):format(k,
					tostring(v):gsub('^%s+', ''):gsub('\r?\n%s*', ' \\n ')))
			end
		end
		return true
	end

end

ffi.metatype('struct tls_config', {__index = config})

local function check(self, ret)
	if ret == 0 then return true end
	return nil, str(C.tls_error(self)) or 'unknown tls error'
end

local tls = {}

function tls:configure(t)
	if t then
		local conf, created = M.config(t)
		local ok, err = check(self, C.tls_configure(self, conf))
		if created then
			conf:free() --self holds the only ref to conf now.
		end
		assert(ok, err)
	end
	return self
end

function M.client(conf)
	return assert(ptr(C.tls_client())):configure(conf)
end

function M.server(conf)
	return assert(ptr(C.tls_server())):configure(conf)
end

function tls:reset(conf)
	C.tls_reset(self)
	return self:configure(conf)
end

function tls:free()
	C.tls_free(self)
end

local ctls_buf = ffi.new'struct tls*[1]'
function tls:accept(read_cb, write_cb, cb_arg)
	local ok, err = check(self, C.tls_accept_cbs(self, ctls_buf, read_cb, write_cb, cb_arg))
	if not ok then return nil, err end
	return ctls_buf[0]
end

function tls:connect(vhost, read_cb, write_cb, cb_arg)
	return check(self, C.tls_connect_cbs(self, read_cb, write_cb, cb_arg, vhost))
end

local function checklen(self, ret)
	ret = tonumber(ret)
	if ret >= 0 then return ret end
	if ret == C.TLS_WANT_POLLIN  then return nil, 'wantrecv' end
	if ret == C.TLS_WANT_POLLOUT then return nil, 'wantsend' end
	return nil, str(C.tls_error(self))
end

function tls:recv(buf, sz)
	return checklen(self, C.tls_read(self, buf, sz))
end

function tls:send(buf, sz)
	return checklen(self, C.tls_write(self, buf, sz or #buf))
end

function tls:close()
	local len, err = checklen(self, C.tls_close(self))
	if not len then return nil, err end
	return true
end

ffi.metatype('struct tls', {__index = tls})

return M
