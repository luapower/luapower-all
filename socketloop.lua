
--Coroutine-based scheduler for LuaSocket and LuaSec sockets.
--Written by Cosmin Apreutesei. Public domain.

if not ... then require'socketloop_test'; return end

local socket = require'socket'
local glue = require'glue'
local add = table.insert

--assert the result of coroutine.resume(). on error, raise an error with the
--traceback of the not-yet unwound stack.
local function assert_resume(thread, ok, ...)
	if ok then return ... end
	error('\n'..(...)..'\n'..debug.traceback(thread), 3)
end

local function new(coro)

	coro = coro or coroutine
	local loop = {}

	function loop.resume(thread, ...)
		return coro.yield('resume', thread, ...)
	end

	function loop.suspend()
		coro.yield()
	end

	function loop.current()
		return coro.running()
	end

	function loop.accept(skt, ...)
		coro.yield('wantread', skt)
		return assert(skt:accept(...))
	end

	function loop.receive(skt, patt, prefix)
		coro.yield('wantread', skt)
		local s, err, partial = skt:receive(patt, prefix)
		if not s and err == 'wantread' then
			return loop.receive(skt, patt, partial)
		else
			return s, err, partial
		end
	end

	function loop.send(skt, data, ...)
		coro.yield('wantwrite', skt)
		return skt:send(data, ...)
	end

	function loop.connect(skt, host, port)
		assert(coro.running(), 'attempting to connect from the main thread')
		assert(skt:settimeout(0, 'b'))
		assert(skt:settimeout(0, 't'))
		local ok, err = skt:connect(host, port)
		while not ok do
			if err == 'already connected' then
				break
			end
			if err ~= 'timeout' and not err:find'in progress$' then
				return nil, err
			end
			coro.yield('wantwrite', skt)
			ok, err = skt:connect(host, port)
		end
		return true
	end

	function loop.call_async(skt, func, ...)
		while true do
			local ret, err = func(...)
			if not ret then
				if err == 'wantread' or err == 'wantwrite' then
					coro.yield(err, skt)
				else
					return nil, err
				end
			else
				return ret
			end
		end
	end

	local read, write = {}, {} --{skt: thread}

	function loop.close(skt)
		read[skt] = nil
		write[skt] = nil
		skt:close()
	end

	local wake
	local function exec(return_thread, cmd, arg, ...)
		if cmd == 'wantread' then
			read[arg] = return_thread
		elseif cmd == 'wantwrite' then
			write[arg] = return_thread
		elseif cmd == 'resume' then
			return wake(arg, ...) --tail call
		else --just suspend
			assert(not cmd)
		end
	end

	function wake(thread, ...)
		exec(thread, assert_resume(thread, coro.resume(thread, ...)))
	end

	local function wakesocket(skt, threadmap)
		local thread = threadmap[skt]
		threadmap[skt] = nil
		wake(thread)
	end

	function loop.step(timeout)
		if next(read) or next(write) then
			local reads, writes = glue.keys(read), glue.keys(write)
			local reads, writes = socket.select(reads, writes, timeout or 0.1)
			for i=1,#reads do wakesocket(reads[i], read) end
			for i=1,#writes do wakesocket(writes[i], write) end
			return true
		end
	end

	local stop = false
	function loop.stop() stop = true end
	function loop.start(timeout)
		while loop.step(timeout) do
			if stop then break end
		end
	end

	--wrappers for sockets and threads ----------------------------------------

	--wrap a luasocket socket object into an object that performs socket
	--operations asynchronously.
	function loop.wrap(skt, skt_type)

		if type(skt) == 'number' then --fd or handle
			local fd, skt_type = skt, skt_type or 'tcp'
			skt = skt_type == 'tcp'  and socket.try(socket.tcp ())
				or skt_type == 'tcp6' and socket.try(socket.tcp6())
				or skt_type == 'udp'  and socket.try(socket.udp ())
				or skt_type == 'udp6' and socket.try(socket.udp6())
				or skt_type == 'unix' and socket.try(socket.unix())
			socket:close() --luasocket should take a fd on its own constructors.
			socket:setfd(fd)
		end

		local o = {}

		--set async methods
		function o:accept(...) return loop.wrap(loop.accept(skt,...)) end
		function o:receive(...) return loop.receive(skt,...) end
		function o:send(...) return loop.send(skt,...) end
		function o:close(...) return loop.close(skt,...) end
		function o:connect(...) return loop.connect(skt, ...) end
		function o:call_async(func, ...) return loop.call_async(skt, func, ...) end

		function o:setsocket(new_skt)
			skt = new_skt
			assert(skt:settimeout(0, 'b'))
			assert(skt:settimeout(0, 't'))
		end
		function o:getsocket() return skt end

		--forward methods to skt
		function o:__index(k)
			if type(k) == 'string' and type(skt[k]) == 'function' then
				local function method(self, ...)
					return skt[k](skt, ...)
				end
				self[k] = method
				return method
			end
			return skt[k]
		end

		return setmetatable(o, o)
	end

	function loop.tcp(locaddr, locport)
		local skt = socket.try(socket.tcp())
		if locaddr or locport then
			assert(skt:bind(locaddr, locport or 0))
		end
		return loop.wrap(skt)
	end

	function loop.newthread(handler, ...)
		local thread = coro.create(handler)
		wake(thread, ...)
		return thread
	end

	function loop.server(ip, port, handler)
		local server_skt = loop.tcp()
		server_skt:settimeout(0)
		server_skt:setoption('reuseaddr', true)
		assert(server_skt:bind(ip or '*', port or 0))
		assert(server_skt:listen(16384))

		accept = accept or function() return true end

		server_skt.client_sockets = {}
		local function client_close(client_skt)
			server_skt.client_sockets[client_skt] = nil
		end

		function server_skt:close_client_sockets()
			for client_skt in pairs(self.client_sockets) do
				client_skt:close()
			end
			assert(not next(self.client_sockets))
		end

		loop.newthread(function()
			while true do
				local client_skt = server_skt:accept()
				server_skt.client_sockets[client_skt] = true
				glue.after(client_skt, 'close', client_close)
				loop.newthread(handler, client_skt)
			end
			server_skt:close_client_sockets()
		end)

		return server_skt
	end

	return loop
end

local loop = new()

glue.autoload(loop, {
	coro = function()
		local coro = require'coro'
		loop.coro = new(coro)
	end,
})

return loop
