
--symmetric coroutine implementation from
--    http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf
--
-- changes from the paper:
--   * threads created with coro.create() finish into the creator thread
--   not in main thread, unless otherwise specified.
--   * added coro.wrap() similar to coroutine.wrap().

local coro = {}
coro.main = function() end
coro.current = coro.main

function coro.create(f, return_thread)
	return_thread = return_thread or coro.current
	return coroutine.wrap(function(val)
		return return_thread, f(val)
	end)
end

function coro.transfer(thread, val)
	if coro.current ~= coro.main then
		return coroutine.yield(thread, val)
	end
	--dispatching loop (executes in main thread)
	while thread do
		coro.current = thread
		if thread == coro.main then
			return val
		end
		thread, val = thread(val)
	end
	coro.current = coro.main
end

function coro.wrap(f)
	local thread = coro.create(f)
	return function(val)
		return coro.transfer(thread, val)
	end
end

if not ... then require'coro_test' end

return coro

