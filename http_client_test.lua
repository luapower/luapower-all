
local client = require'http_client'
client.http.zlib = require'zlib'
local loop = require'socketloop'
local time = require'time'

local function search_page_url(pn)
	return 'https://luapower.com/'
end

function kbytes(n)
	if type(n) == 'string' then n = #n end
	return n and string.format('%.1fkB', n/1024)
end

function mbytes(n)
	if type(n) == 'string' then n = #n end
	return n and string.format('%.1fmB', n/(1024*1024))
end

local client = client:new{
	max_conn = 5,
	max_pipelined_requests = 10,
	debug = true,
}
local n = 0
for i=1,1 do
	loop.newthread(function()
		local res, req = client:request{
			--host = 'www.websiteoptimization.com', uri = '/speed/tweak/compress/',
			host = 'luapower.com', uri = '/',
			--https = true,
			--host = 'mokingburd.de',
			--host = 'www.google.com', https = true,
			receive_content = 'string',
			debug = {protocol = true, stream = false},
			--max_line_size = 1024,
			--close = true,
		}
		if res then
			n = n + (res and res.content and #res.content or 0)
		else
			print('ERROR:', req)
		end
	end)
end
local t0 = time.clock()
loop.start(5)
t1 = time.clock()
print(mbytes(n / (t1 - t0))..'/s')

