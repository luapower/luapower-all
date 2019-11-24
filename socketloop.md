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

-------------------------------------------- ---------------------------------
`loop.tcp([locaddr], [locport]) -> asocket`  make an async TCP socket
`loop.wrap(socket|fd) -> asocket`            wrap a TCP socket or a fd to an async socket
`loop.thread(handler, ...) -> thread`        create and start an async I/O thread
`loop.suspend() -> ...`                      suspend thread to be transfered into later
`loop.resume(thread, ...)`                   resume a suspended thread without waiting on it
`loop.current() -> thread`                   return the current thread
`loop.server(host, port, handler)-> ssocket` dispatch inbound connections to a function
`loop.start()`                               start the select loop
`loop.stop()`                                stop the loop (if started)
`loop.step() -> true|false`                  dispatch pending reads and writes
`loop.coro -> loop`                          alternative [coro]-based loop
`asocket:call_async(func, ...) -> ret, err`  call a multi-step async function
`asocket:getsocket() -> socket`              get the wrapped LuaSocket
`asocket:setsocket(socket)`                  set the wrapped LuaSocket
`ssocket:close_client_sockets()`             close all client sockets
-------------------------------------------- ---------------------------------

### `loop.tcp([locaddr], [locport]) -> asocket`

Create an async [TCP socket].

Being asynchronous means that when different sockets are used from different
coroutines they don't block each other as long as the loop is doing the
dispatching via `loop.start()` or `loop.step()`.
The asynchronous methods are: `connect()`, `accept()`, `receive()`, `send()`.

An async socket should only be used inside a loop thread.

[TCP socket]: http://w3.impa.br/~diego/software/luasocket/tcp.html

### `loop.wrap(socket) -> asocket`

Wrap a [TCP socket] into an asynchronous socket with the same API
as the original (which is kept in `asocket.socket`).

### `loop.thread(handler, ...) -> thread`

Create and resume a thead (either a coroutine or a coro thread).
The thread is suspended and control returns to the caller as soon as:

  * an async socket method is called,
  * `loop.suspend()` is called,
  * the thread finishes.

### `loop.suspend() -> ...`

Suspend the current thread. To resume a suspended thread, call `loop.resume()`
from another thread. `loop.suspend()` returns the arguments passed to
`loop.resume()`.

### `loop.resume(thread, ...)`

Resume a previously suspended thread without waiting on it, i.e. the call
returns as soon as the thread is suspended again in I/O or in `suspend()`.

Only resume a thread that is waiting on `loop.suspend()`. Resuming a thread
that is waiting in an async I/O call is undefined behavior.

### `loop.server(ip, port, handler) -> ssocket`

Create a TCP socket and start accepting connections on it, and call
`handler(client_skt)` on a separate coroutine for each accepted connection.

The preferred way to stop a server immediately is to call `loop.stop()`
and then call `ssocket:close_client_sockets()` after `loop.start()` returns.

### `loop.start()`

Start dispatching reads and writes continuously in a loop.
The loop should be started only if there's at least one thread suspended in
an async socket call.

### `loop.stop()`

Stop the dispatch loop (if started).

### `loop.step() -> true|false`

Dispatch currently pending reads and writes to their respective threads.

### `loop = require'socketloop'.coro`

An alternative loop that dispatches to [symmetric coroutines][coro] instead
of Lua coroutines. Another way of enabling coro coroutines is to install
them with `coro.install()` and continue to use the default loop.

### `asocket:call_async(func, ...) -> ret, err`

Call `func(...)` repeatedly until it doesn't signal the need to wait for
data to read or write anymore. The function performs I/O on `asocket`
and returns `nil|false, 'wantread'` when it needs to poll for more bytes
to read and `nil|false, 'wantwrite'` when it needs to wait for the write
buffer to become accessible for writing.

### `ssocket:close_client_sockets()`

Close all client sockets on a server socket.
