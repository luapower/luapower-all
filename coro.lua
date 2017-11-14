
--symmetric coroutine implementation from
--    http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf
--
-- changes from the paper:
--   * can yield multiple values.
--   * threads created with coro.create() finish into the creator thread
--   not in main thread, unless otherwise specified.
--   * added coro.wrap() similar to coroutine.wrap().

if not ... then require'coro_test'; return end

local coro = {}
coro.main = function() end
coro.current = coro.main

function coro.create(f, return_thread)
	return_thread = return_thread or coro.current
	return coroutine.wrap(function(...)
		return return_thread, f(...)
	end)
end

local function go(thread, ...)
	if not thread then
		coro.current = coro.main
		return
	end
	coro.current = thread
	if thread == coro.main then
		return ...
	end
	return go(thread(...)) --tail call
end

function coro.transfer(thread, ...)
	if coro.current ~= coro.main then
		return coroutine.yield(thread, ...)
	end
	return go(thread, ...)
end

function coro.wrap(f)
	local thread = coro.create(f)
	return function(...)
		return coro.transfer(thread, ...)
	end
end

return coro

