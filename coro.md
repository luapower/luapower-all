---
tagline: symmetric coroutines
---

## `local coro = require'coro'`

Symmetric coroutines are coroutines that allow you to transfer control to a
specific coroutine, unlike Lua's standard coroutines which only allow you to
suspend execution to the calling coroutine.

This is the implementation from the paper
[Coroutines in Lua](http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf).

Changes from the paper:

 * can yield multiple values.
 * threads created with `coro.create()` finish into the creator thread not
 main thread, unless otherwise specified.
 * added `coro.wrap()` similar to `coroutine.wrap()`.

## API

### `coro.create(f[, return_thread]) -> coro_thread`

Create a symmetric coroutine, optionally specifying the thread which the
coroutine should transfer control to when it finishes execution (defaults to
`coro.current`.

### `coro.transfer(coro_thread[, ...]) -> ...`

Transfer control to a symmetric coroutine, suspending execution. The target
coroutine either hasn't started yet, or it is itself suspended in a call to
`coro.transfer()`, in which case it resumes and receives the values as the
return values of the call. Likewise, the coroutine which transfers execution
will stay suspended until `coro.transfer()` is called again with it as target.

### `coro.current -> coro_thread`

Currently running symmetric coroutine. Defaults to `coro.main`.

### `coro.main -> coro_thread`

The coroutine representing the main thread (the thread that calls
`coro.transfer` for the first time).

### `coro.wrap(f) -> f`

Similar to `coroutine.wrap` for symmetric coroutines. Useful for creating
iterators in an environment of symmetric coroutines in which simply calling
`coroutine.yield` is not an option:

~~~{.lua}
local parent = coro.current
local iter = coro.wrap(function(...)
	local function yield(...)
		coro.transfer(parent, ...)
	end
	...
	yield(...)
end)
~~~
