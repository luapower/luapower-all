
--ffi.tls_libname = 'tls_libressl'
local server  = require'http_server'
--local libtls = require'libtls'
--libtls.debug = print

--local webb_respond = require'http_server_webb'

local server = server:new{
	libs = 'sock zlib', --sock_libtls
	listen = {
		{
			host = 'localhost',
			--port = 443,
			port = 8080,
			tls = false,
			tls_options = {
				keypairs = {
					{
						cert_file = 'localhost.crt',
						key_file  = 'localhost.key',
					}
				},
			},
		},
	},
	debug = {
		protocol = true,
		--stream = true,
		tracebacks = true,
	},
	respond = function(req, thread)
		local read_body = req:read_body'reader'
		while true do
			local buf, sz = read_body()
			if buf == nil and sz == 'eof' then break end
			local s = ffi.string(buf, sz)
			print(s)
		end
		local write_body = req:respond({
			--compress = false,
		}, true)
		write_body(('hello '):rep(1000))
		--raise{status = 404, content = 'Dude, no page here'}
	end,
	--respond = webb_respond,
}

server.start()
