
--Coroutine-based scheduler for LuaSocket and LuaSec sockets.
--Written by Cosmin Apreutesei. Public domain.

if not ... then require'socketloop_test'; return end

local socket = require'socket'
local glue = require'glue'

--assert the result of coroutine.resume(). on error, raise an error with the
--traceback of the not-yet unwound stack.
local function assert_resume(thread, ok, ...)
	if ok then return ... end
	error((...)..'\n'..debug.traceback(thread), 3)
end

--create a new socket loop, dispatching to Lua coroutines or,
--to symmetric coroutines, if coro module given (coro = require'coro').
local function new(coro)

	local loop = {}

	local read, write = {}, {} --{skt: thread}

	--thread API, based on coro or coroutine module.
	local newthread, current, suspend, resume
	if coro then
		function newthread(handler, args)
			--wrap handler so that it terminates in current loop.thread.
			local handler = function(args)
				handler(args)
				coro.transfer(loop.thread)
			end
			local thread = coro.create(handler)
			loop.resume(thread, args)
			return thread
		end
		current = coro.running
		function suspend()
			return coro.transfer(loop.thread)
		end
		resume = coro.transfer
		function loop.resume(thread, args)
			local loop_thread = loop.thread
			--change loop.thread temporarily so that we get back here.
			loop.thread = current()
			resume(thread, args)
			loop.thread = loop_thread
		end
	else
		function newthread(handler, args)
			local thread = coroutine.create(handler)
			resume(thread, args)
			return thread
		end
		current = coroutine.running
		suspend = coroutine.yield
		function resume(thread, args)
			assert_resume(thread, coroutine.resume(thread, args))
		end
		loop.resume = resume
	end
	loop.current = current
	loop.suspend = suspend

	--internal suspend/resume API
	local function wait(rwt, skt)
		rwt[skt] = current()
		suspend()
		rwt[skt] = nil
	end

	local function wake(skt,rwt)
		local thread = rwt[skt]
		if not thread then return end
		resume(thread)
	end

	--async socket API
	local function accept(skt,...)
		wait(read, skt)
		return assert(skt:accept(...))
	end

	local function receive(skt, patt, prefix)
		wait(read, skt)
		local s, err, partial = skt:receive(patt, prefix)
		if not s and err == 'wantread' then
			return receive(skt, patt, partial)
		else
			return s, err, partial
		end
	end

	local function send(skt, data, ...)
		wait(write, skt)
		return skt:send(data, ...)
	end

	local function close(skt,...)
		write[skt] = nil
		read[skt] = nil
		return skt:close(...)
	end

	local function connect(skt, host, port)
		assert(coroutine.running(), 'attempting to connect from the main thread')
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
			wait(write, skt)
			ok, err = skt:connect(host, port)
		end
		return true
	end

	local function call_async(skt, func, ...)
		while true do
			local ret, err = func(...)
			if not ret then
				if err == 'wantread' then
					wait(read, skt)
				elseif err == 'wantwrite' then
					wait(write, skt)
				else
					return nil, err
				end
			else
				return ret
			end
		end
	end

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
		function o:accept(...) return loop.wrap(accept(skt,...)) end
		function o:receive(...) return receive(skt,...) end
		function o:send(...) return send(skt,...) end
		function o:close(...) return close(skt,...) end
		function o:connect(...) return connect(skt, ...) end
		function o:call_async(func, ...) return call_async(skt, func, ...) end

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

	function loop.create_connection(locaddr, locport)
		local skt = socket.try(socket.tcp())
		if locaddr or locport then
			assert(skt:bind(locaddr, locport or 0))
		end
		return loop.wrap(skt)
	end

	function loop.connect(host, port, locaddr, locport)
		local skt = loop.create_connection(locaddr)
		local ok, err = skt:connect(host, port)
		if ok then return skt else return nil, err end
	end

	--call select() and resume the calling threads of the sockets that get loaded.
	function loop.step(timeout)
		if not next(read) and not next(write) then return end
		local reads, writes, err = glue.keys(read), glue.keys(write)
		reads, writes, err = socket.select(reads, writes, timeout)
		loop.thread = current()
		for i=1,#reads do wake(reads[i], read) end
		for i=1,#writes do wake(writes[i], write) end
		return true
	end

	local stop = false
	function loop.stop() stop = true end
	function loop.start(timeout)
		while loop.step(timeout) do
			if stop then break end
		end
	end

	--create a thread set up to transfer control to the loop thread on finish,
	--and run it. return it while suspended in the first async socket call.
	--step() will resume it afterwards.
	function loop.newthread(handler, args)
		--wrap handler to get full traceback from coroutine
		local handler = function(args)
			local ok, err = glue.pcall(handler, args)
			if ok then return ok end
			error(err, 2)
		end
		return newthread(handler, args)
	end

	function loop.newserver(ip, port, handler, accept)
		local server_skt = socket.tcp()
		server_skt:settimeout(0)
		server_skt:setoption('reuseaddr', true)
		assert(server_skt:bind(ip or '*', port or 0))
		assert(server_skt:listen(16384))
		server_skt = loop.wrap(server_skt)
		accept = accept or function() return true end
		local function server()
			while accept() do
				local client_skt = server_skt:accept()
				loop.newthread(handler, client_skt)
			end
		end
		if coro then
			coro.transfer(coro.create(server))
		else
			loop.newthread(server)
		end
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
