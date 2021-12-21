local tls = require'libtls'
local ffi = require'ffi'

local c = tls.client{

	alpn = '123',
	ca = 'x',
	--ciphers = 'P-256',
	--crl = 'x',
	--dheparams = 'a',
	--ecdhecurve = 'x',
	--ecdhecurves = 'z,y',
	ocsp_staple = 'x',
	--protocols = 'x',
	verify_depth = true,

	--TODO: add sessions to libtls-bearssl and test them.
	--session_id = '1',
	--session_lifetime = 1,

	prefer_ciphers_client  = true,
	prefer_ciphers_server  = true,
	insecure_noverifycert  = true,
	insecure_noverifyname  = true,
	insecure_noverifytime  = true,
	ocsp_require_stapling  = true,
	verify                 = true,
	verify_client          = true,
	verify_client_optional = true,
}


c:free()
