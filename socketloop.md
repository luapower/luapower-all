---
tagline: TCP sockets with coroutines
---

## `local loop = require'socketloop'`

A socket loop enables coroutine-based asynchronous I/O programming model for
[TCP sockets][TCP socket]. The concept is similar to [Copas], the API and the
implementation are different. Supports both [symmetric][coro] and asymmetric
coroutines.

[Copas]: http://keplerproject.github.com/copas/

## API

----------------------------------------------------------------- ---------------------------------
`loop.wrap(socket|fd) -> asocket`                                 wrap a TCP socket or a fd to an async socket
`loop.connect(host, port, [local_ip], [local_port]) -> asocket`   make an async TCP connection
`loop.tcp([local_ip], [local_port]) -> asocket`                   create an async TCP socket
`loop.newthread(handler, arg)`                                    create a thread for one connection
`loop.current() -> thread`                                        current thread
`loop.suspend()`                                                  suspend current thread
`loop.resume(thread, arg)`                                        resume a suspended thread
`loop.newserver(ip, port, handler) -> skt`                        dispatch inbound connections to a function
`loop.start([timeout])`                                           start the loop
`loop.stop()`                                                     stop the loop (if started)
`loop.step([timeout]) -> true|false`                              dispatch pending reads and writes
`loop.coro -> loop`                                               [coro]-based loop
`asocket:call_async(func, ...) -> ret, err`                       call a multi-step async function
`asocket:getsocket() -> socket`                                   get the wrapped LuaSocket
`asocket:setsocket(socket)`                                       set the wrapped LuaSocket
----------------------------------------------------------------- ---------------------------------

### `loop.wrap(socket) -> asocket`

Wrap a [TCP socket] into an asynchronous socket with the same API
as the original, which btw is kept as `asocket.socket`.

Being asynchronous means that if each socket is used from its own coroutine,
different sockets won't block each other waiting for reads and writes,
as long as the loop is doing the dispatching. The asynchronous methods are:
`connect()`, `accept()`, `receive()`, `send()`, `close()`.

An async socket should only be used inside a loop thread.

### `loop.connect(host, port, [local_ip], [local_port]) -> asocket`

Make a TCP connection and return an async socket.

[TCP socket]: http://w3.impa.br/~diego/software/luasocket/tcp.html

### `loop.tcp([local_ip], [local_port]) -> asocket`

Create an async TCP socket optionally binding it to a specific local IP and port.

### `loop.newthread(handler, arg) -> thread`

Create and resume a thead (either a coroutine or a coro thread).
The thread is suspended and control returns to the caller as soon as:

  * an async socket method is called,
  * `loop.suspend()` is called,
  * the thread finishes.


### `loop.current() -> thread`

Return the current thread (either a coroutine or a coro thread).

### `loop.suspend()`

Suspend the current thread. To resume a suspended thread,
call `loop.resume()` from another thread.

### `loop.resume(thread, arg)`

Resume a suspended thread without blocking the current thread. The call
returns as soon as the thread gets suspended again in an async I/O call
or in `loop.suspend()`.

Only resume threads that were previously suspended by calling `loop.suspend()`.
Resuming a thread that is suspended in an async call is undefined behavior.

### `loop.newserver(ip, port, handler)`

Create a TCP socket and start accepting connections on it, and call
`handler(client_skt)` on a separate coroutine for each accepted connection.

### `loop.start([timeout])`

Start dispatching reads and writes continuously in a loop.
The loop should be started only if there's at least one thread suspended in
an async socket call.

### `loop.stop()`

Stop the dispatch loop (if started).

### `loop.step([timeout]) -> true|false`

Dispatch currently pending reads and writes to their respective threads.

### `loop = require'socketloop'.coro`

An alternative loop that dispatches to [symmetric coroutines][coro] instead
of Lua coroutines.

## Example

```lua
local loop = require'socketloop'
local http = require'socket.http'

local function getpage(url)
	local t = {}
	local ok, code, headers = http.request{
		url = url,
		sink = ltn12.sink.table(t),
		create = function()
			return loop.wrap(socket.try(socket.tcp()))
		end,
	}
	assert(ok, code)
	return table.concat(t), headers, code
end

loop.newthread(function()
	local body = getpage'http://google.com/'
	print('got ' .. #body .. ' bytes')
end)

loop.start()
```

### `asocket:call_async(func, ...) -> ret, err`

Call `func(...)` repeatedly until it doesn't signal the need to wait for
data to read or write anymore. The function performs I/O on `asocket`
and returns `nil|false, 'wantread'` when it needs to poll for more bytes
to read and `nil|false, 'wantwrite'` when it needs to wait for the write
buffer to become accessible for writing.
