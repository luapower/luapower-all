
--symmetric coroutines from the paper at
--    http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'coro_test'; return end

local coroutine = coroutine

local coro = {}
local coro_mt = {}
local current --nil means main thread

function coro_mt.__tostring(thread)
	return thread.name or tostring(thread.co)
end

local function assert_thread(thread, level)
	if getmetatable(thread) == coro_mt then
		return thread
	end
	local err = string.format('coroutine expected but %s given', type(thread))
	error(err, level)
end

--the caller is the thread that called resume() on this thread, if any.
local function caller_thread(thread)
	local caller = thread.caller
	return caller ~= true and caller or nil --true means main thread
end

local function unprotect(ok, ...)
	if not ok then
		error(..., 2)
	end
	return ...
end

--the coroutine ends by transferring control to the caller thread. coroutines
--that are transfer()ed into must give up control explicitly before ending.
local function finish(thread, ...)
	if not thread.caller then
		error('coroutine ended without transferring control', 3)
	end
	return caller_thread(thread), true, ...
end
function coro.create(f)
	local thread = setmetatable({}, coro_mt)
	thread.co = coroutine.create(function(ok, ...)
		return finish(thread, f(...))
	end)
	return thread
end

function coro.running()
	return current
end

function coro.status(thread)
	assert_thread(thread, 2)
	return coroutine.status(thread.co)
end

local go --fwd. decl.
local function check(thread, ok, ...)
	if not ok then
		--the coroutine finished with an error. pass the error back to the
		--caller thread, or to the main thread if there's no caller thread.
		return go(caller_thread(thread), ok, ..., debug.traceback()) --tail call
	end
	return go(...) --tail call: loop over the next transfer request.
end
function go(thread, ok, ...)
	current = thread
	if not thread then
		--transfer to the main thread: stop the scheduler.
		return ok, ...
	end
	--transfer to a coroutine: resume it and check the result.
	return check(thread, coroutine.resume(thread.co, ok, ...)) --tail call
end

local function transfer(thread, ...)
	if thread ~= nil then
		assert_thread(thread, 3)
	end
	if current then
		--we're inside a coroutine: signal the transfer request by yielding.
		return coroutine.yield(thread, true, ...)
	else
		--we're in the main thread: start the scheduler.
		return go(thread, true, ...) --tail call
	end
end

function coro.transfer(thread, ...)
	return unprotect(transfer(thread, ...))
end

local function remove_caller(thread, ...)
	thread.caller = nil
	return ...
end
function coro.resume(thread, ...)
	assert(thread ~= current, 'trying to resume the running thread')
	assert(thread, 'trying to resume the main thread')
	thread.caller = current or true
	return remove_caller(thread, transfer(thread, ...))
end

function coro.yield(...)
	assert(current, 'yielding from the main thread')
	assert(current.caller, 'yielding from a non-resumed thread')
	return coro.transfer(caller_thread(current), ...)
end

function coro.wrap(f, name)
	local thread = coro.create(f)
	thread.name = name
	return function(...)
		return unprotect(coro.resume(thread, ...))
	end
end

function coro.install()
	_G.coroutine = coro
	return coroutine
end

return coro
