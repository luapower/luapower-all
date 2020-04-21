
local http = require'http'
local socket = require'socket'
local ffi = require'ffi'
local http_headers = require'http_headers'
http.zlib = require'zlib'

local function P(s)
	return #s, (s:gsub('[\1-\31]', function(c) return '\\'..string.byte(c) end))
end

local function wrap_sock(sock, http)

	sock:settimeout(0)

	function http:read(buf, sz)
		local s = ''
		while s == '' do
			local s1, err, p = sock:receive(sz)
			if s1 or p then
				s = s .. (s1 or p)
			elseif err ~= 'timeout' then
				return nil, err
			end
		end
		assert(#s <= sz)
		ffi.copy(buf, s, #s)
		print('recv', sock, P(s))
		return #s
	end

	function http:send(buf, sz)
		sz = sz or #buf
		local s = ffi.string(buf, sz)
		print('send', sock, P(s))
		return sock:send(s)
	end

	function http:close()
		sock:close()
		print('closed', sock)
	end

	local t = {}
	return function(buf, sz)
		local s = ffi.string(buf, sz)
		table.insert(t, s)
	end, function()
		return table.concat(t)
	end
end

local function test_client()

	local host = 'www.websiteoptimization.com'
	local uri = '/speed/tweak/compress/'

	--local host = 'ptsv2.com'
	--local uri = '/t/anaf/post'

	local sock = socket.tcp()
	assert(sock:connect(host, 80))

	local client = http:new()

	local write_body, flush_body = wrap_sock(sock, client)

	local res, req = client:perform_request{
		uri = uri,
		host = host,
		headers = {
		},
		--method = 'POST',
		--content = '',
		close = true,
		receive_content = write_body,
	}
	local h = http_headers.parse_headers(res.rawheaders)
	pp(res, req, h)

	print('body', sock, P(flush_body()))

	local sha2 = require'sha2'
	local glue = require'glue'
	print('sha2', glue.tohex(sha2.sha256(flush_body())))
	print('sha2', glue.tohex(sha2.sha256(glue.readfile'http_test.html')))

end

--server ---------------------------------------------------------------------

local function test_server()
	local ssock = socket.tcp()
	local server = http:new()
	assert(ssock:bind('127.0.0.1', 80))
	assert(ssock:listen())
	ssock:settimeout(0)
	while true do
		local csock, err
		repeat
			csock, err = ssock:accept()
		until csock or err ~= 'timeout'
		wrap_sock(csock, server)
		while true do
			local req = server:read_request('string')
			pp(req)
			print('cbody', csock, req.content)
			local i = 0
			local function gen_content()
				i = i + 1
				return i == 1 and '123' or i == 2 and '4567890' or nil
			end
			local res = server:make_response(req, {
				content = gen_content,
				--close = true,
				compress = true,
				content_type = 'text/plain',
			})
			local ok, err = server:send_response(res)
			if not ok then print(err) end
		end
	end
end

test_client()
--test_server()
