
--symmetric coroutines from the paper at
--    http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf
--Written by Cosmin Apreutesei. Public Domain.

--Tip: don't be deceived by the small size of this code.

if not ... then require'coro_test'; return end

local coroutine = coroutine
local resume = coroutine.resume
local yield = coroutine.yield
local cocreate = coroutine.create
local costatus = coroutine.status

local coro = {}
local callers = setmetatable({}, {__mode = 'k'}) --{thread -> caller_thread}
local main, is_main = coroutine.running()
assert(is_main, 'coro must be loaded from the main thread')
local current = main

local function assert_thread(thread, level)
	if type(thread) ~= 'thread' then
		local err = string.format('coroutine expected but %s given', type(thread))
		error(err, level)
	end
	return thread
end

local function unprotect(thread, ok, ...)
	if not ok then
		local s = debug.traceback(thread, (...))
		s = s:gsub('stack traceback:', tostring(thread)..' stack traceback:')
		error(s, 2)
	end
	return ...
end

--the coroutine ends by transferring control to the caller (or finish) thread.
local function finish(thread, ...)
	local caller = callers[thread]
	if not caller then
		error('coroutine ended without transferring control', 3)
	end
	callers[thread] = nil
	return caller, true, ...
end
function coro.create(f)
	local thread
	thread = cocreate(function(ok, ...)
		return finish(thread, f(...))
	end)
	--uncomment to debug transfers (require'$log' first):
	--pr('C', thread, 'by', current)
	return thread
end

function coro.running()
	return current, current == main
end

function coro.status(thread)
	assert_thread(thread, 2)
	return costatus(thread)
end

local go --fwd. decl.
local function check(thread, ok, ...)
	if not ok then
		--the coroutine finished with an error. pass the error back to the
		--caller thread, or to the main thread if there's no caller thread.
		return go(callers[thread] or main, ok, ..., debug.traceback()) --tail call
	end
	return go(...) --tail call: loop over the next transfer request.
end
function go(thread, ok, ...)
	current = thread
	if thread == main then
		--transfer to the main thread: stop the scheduler.
		return ok, ...
	end
	--transfer to a coroutine: resume it and check the result.
	return check(thread, resume(thread, ok, ...)) --tail call
end

local function ptransfer(thread, ...)
	assert_thread(thread, 3)
	assert(thread ~= current, 'trying to transfer to the running thread')
	if current ~= main then
		--we're inside a coroutine: signal the transfer request by yielding.
		return yield(thread, true, ...)
	else
		--we're in the main thread: start the scheduler.
		return go(thread, true, ...) --tail call
	end
end

coro.ptransfer = ptransfer

function coro.transfer(thread, ...)
	--uncomment to debug transfers (require'$log' first):
	--pr(current, '>', thread, ...)
	return unprotect(thread, ptransfer(thread, ...))
end

local function remove_caller(thread, ...)
	callers[thread] = nil
	return ...
end
function coro.resume(thread, ...)
	assert(thread ~= current, 'trying to resume the running thread')
	assert(thread ~= main, 'trying to resume the main thread')
	callers[thread] = current
	return remove_caller(thread, ptransfer(thread, ...))
end

function coro.yield(...)
	assert(current ~= main, 'yielding from the main thread')
	local caller = callers[current]
	assert(caller, 'yielding from a non-resumed thread')
	return coro.transfer(caller, ...)
end

function coro.wrap(f)
	local thread = coro.create(f)
	return function(...)
		return unprotect(thread, coro.resume(thread, ...))
	end
end

function coro.safewrap(f)
	local calling_thread, yielding_thread
	local function yield(...)
		yielding_thread = current
		return coro.transfer(calling_thread, ...)
	end
	local function finish(...)
		yielding_thread = nil
		return coro.transfer(calling_thread, ...)
	end
	local function wrapper(...)
		return finish(f(yield, ...))
	end
	local thread = coro.create(wrapper)
	yielding_thread = thread
	local create_thread = current
	return function(...)
		calling_thread = current
		assert(yielding_thread, 'cannot resume dead coroutine')
		return coro.transfer(yielding_thread, ...)
	end, thread
end

function coro.install()
	_G.coroutine = coro
	return coroutine
end

return coro
