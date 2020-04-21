
if not ... then require'http_server_test'; return end

local loop = require'socketloop'
local http = require'http'
local uri = require'uri'
local time = require'time'
local glue = require'glue'

local _ = string.format
local attr = glue.attr
local push = table.insert
local pull = function(t)
	return table.remove(t, 1)
end

local server = {
	type = 'http_server', http = http,
}

local server = {}

server.dbg = glue.noop

function server:utc_time(date)
	return glue.time(date, true)
end

function server:new(t)
	local self = glue.object(self, {}, t)
	if self.debug then
		local dbg = require'http_debug'
		dbg:install_to_server(self)
	end
	local function handler(sock)
		local http = self.http:new()
		while true do
			local req = http:read_request('string')
			--print('cbody', csock, req.content)
			local res = server:make_response(req, {
				content = gen_content,
				compress = true,
			})
			local ok, err = server:send_response(res)
			if not ok then print(err) end
		end
	end
	self.socket = loop.newserver(self.ip, self.port, handler)
end

return server
