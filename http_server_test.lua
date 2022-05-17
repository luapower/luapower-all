
local ffi = require'ffi'
local server  = require'http_server'
ffi.tls_libname = 'tls_bearssl'

--local webb_respond = require'http_server_webb'

local server = server:new{
	libs = 'sock zlib sock_libtls',
	listen = {
		{
			host = 'localhost',
			addr = '127.0.0.1',
			port = 80,
		},
		{
			--host = 'localhost',
			addr = '127.0.0.1',
			port = 443,
			tls = true,
			tls_options = {
				keypairs = {
					{
						cert_file = 'localhost.crt',
						key_file  = 'localhost.key',
					},
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
		local out = req:respond({
			--compress = false,
			want_out_function = true,
		})
		out(('hello '):rep(1000))
		--raise{status = 404, content = 'Dude, no page here'}
	end,
	--respond = webb_respond,
}

server.start()
