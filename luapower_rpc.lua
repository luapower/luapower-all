
--Simple generic RPC server that allows uploading and executing Lua functions
--into separate Lua states, one state per connection.
--Written by Cosmin Apreutesei. Public Domain.

local glue = require'glue'
local pp = require'pp'
local luastate = require'luastate'

local rpc = {}

--logging

rpc.verbose = false
local function log(...)
	if not rpc.verbose then return end
	print(...)
end

--transport

rpc.bind_ip = '*'
rpc.default_ip = '127.0.0.1'
rpc.default_port = '19994'

local function packt(...)
	return {n = select('#', ...), ...}
end

local function unpackt(t)
	return unpack(t, 1, t.n)
end

local function parse(s)
	local f, err = loadstring('return '..s)
	if not f then return nil, err end
	return glue.unprotect(pcall(f))
end

local function format(t)
	return pp.format(t)
end

local function send(skt, t)
	local s = format(t)
	return skt:send(#s..'\n'..s)
end

local function receive(skt)
	local s, err = skt:receive'*l'
	local sz = tonumber(s)
	if not sz then return nil, 'message size expected, got '..tostring(s)..', '..tostring(err) end
	local s = skt:receive(sz)
	if not s then return nil, sz..' bytes message expected' end
	return parse(s)
end

local function enum(t)
	if t.error then
		return 'error: '..t.error
	end
	local dt = {n=t.n}
	for i=1,t.n do
		dt[i] = pp.format(t[i])
	end
	return table.concat(dt, ', ', 1, t.n)
end

function rpc.server(ip, port)

	local loop = require'socketloop'
	local ffi = require'ffi'
	local socket = require'socket'

	ip = ip or rpc.bind_ip
	port = port or rpc.default_port

	local srv_skt

	local function handler(skt)

		local state = luastate.open()
		state:openlibs()

		local function pass(ok, ...)
			return ok and packt(...) or {error = ...}
		end
		local function handle(msg) --{cmd=name, args = packt}
			if msg.cmd == 'stop' then
				skt:close() --important on Linux!
				srv_skt:close()
				log('rpc server: stopped.')
				os.exit()
			elseif msg.cmd == 'restart' then
				local cmd =
					(ffi.os == 'Windows' and 'start ' or '')..
					arg[-1]..' '..arg[0]..' '..table.concat(arg, ' ')..
					(ffi.os == 'Windows' and '' or ' &')
				skt:close() --important on Linux!
				srv_skt:close()
				log('rpc server: restarting: '..cmd)
				os.execute(cmd)
				os.exit()
			elseif msg.cmd == 'exec' then
				local args = msg.args
				local func = args[1]
				if type(func) == 'function' then
					state:push(func)
				elseif type(func) == 'string' then
					state:getglobal(func)
				end
				local retvals = pass(state:pcall(select(2, unpackt(args))))
				if not send(skt, retvals) then return end
				log('rpc server: '..msg.cmd..'('..enum(args)..')')
				return true
			end
		end
		while true do
			local msg = receive(skt)
			if not msg then break end
			if not handle(msg) then break end
		end
		skt:close()
		state:close()
	end

	srv_skt = loop.newserver(ip, port, handler)
	log('listening on '..ip..':'..port)

	return srv_skt
end

function rpc.connect(ip, port, connect)

	ip = ip or rpc.default_ip
	port = port or rpc.default_port

	if not connect then
		local loop = require'socketloop'
		connect = loop.connect
	end
	local skt, err = connect(ip, port)
	if not skt then return nil, err end
	local function close()
		skt:close()
	end
	local function rpcall(cmd, ...)
		assert(cmd)
		local msg = {cmd = cmd, args = packt(...)}
		assert(send(skt, msg))
		if cmd == 'restart' or cmd == 'stop' then
			skt:close()
			return
		end
		local retvals = assert(receive(skt))
		if retvals.error then
			error(retvals.error, 2)
		end
		return unpackt(retvals)
	end
	return setmetatable({
			socket = skt,
			close = close,
		}, {
			__index = function(t, k)
				t[k] = function(...)
					return rpcall(k, ...)
				end
				return t[k]
			end,
		})
end

--loaded as module

if ... == 'luapower_rpc' then
	return rpc
end

--cmdline interface

local loop = require'socketloop'

local v, ip, port = ...
if v ~= '-v' then
	v, ip, port = false, v, ip
end
rpc.verbose = v and true

if ip == '--help' then
	print('Usage: '..arg[-1]..' '..arg[0]..' [-v] [ip [port]]')
	os.exit()
end

if ip == '--test' then
	local srv = rpc.server()
	loop.newthread(function()
		--two connections, two states
		local c1 = assert(rpc.connect())
		local c2 = assert(rpc.connect())
		--inject the inc function in each state
		local function inject_inc()
			function inc(x)
				i = (i or 0) + x
				return i
			end
		end
		c1.exec(inject_inc)
		c2.exec(inject_inc)
		--exec inc 1000 times in each state
		local function inc1000(x)
			local n
			for i = 1,1000 do
				n = inc(x)
			end
			return n
		end
		local i1 = c1.exec(inc1000, 1)
		local i2 = c2.exec(inc1000, 2)
		assert(i1 == 1000)
		assert(i2 == 2000)
		--close connections
		c1.close()
		c2.close()
		loop.stop()
		print'ok'
	end)
	loop.start(1)
	os.exit()
end

local srv = rpc.server(ip, port)
loop.start(1)

