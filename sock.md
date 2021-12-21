
## `local sock = require'sock'`

Portable coroutine-based async socket API. For scheduling it uses IOCP
on Windows, epoll on Linux and kqueue on OSX.

## Rationale

Replace LuaSocket which doesn't scale being select()-based, and improve on
other aspects too (single file, nothing to compile, use cdata buffers instead
of strings, don't bundle unrelated modules, [coro]-based async only,
multi-threading support).

## Status

<warn>Alpha (Windows & Linux)</warn>

## API

---------------------------------------------------------------- ----------------------------
__address lookup__
`sock.addr(...) -> ai`                                           look-up a hostname
`ai:free()`                                                      free the address list
`ai:next() -> ai|nil`                                            get next address in list
`ai:addrs() -> iter() -> ai`                                     iterate addresses
`ai:type() -> s`                                                 socket type: 'tcp', ...
`ai:family() -> s`                                               address family: 'inet', ...
`ai:protocol() -> s`                                             protocol: 'tcp', 'icmp', ...
`ai:name() -> s`                                                 cannonical name
`ai:tostring() -> s`                                             formatted address
`ai.addr -> sa`                                                  address object
`sa:family() -> s`                                               address family: 'inet', ...
`sa:port() -> n`                                                 address port
`sa:tostring() -> s`                                             'ip:port'
`sa:addr() -> ip`                                                IP address object
`ip:tobinary() -> uint8_t[4|16], 4|16`                           IP address in binary form
`ip:tostring() -> s`                                             IP address in string form
__sockets__
`sock.tcp([family][, protocol]) -> tcp`                          make a TCP socket
`sock.udp([family][, protocol]) -> udp`                          make a UDP socket
`sock.raw([family][, protocol]) -> raw`                          make a raw socket
`s:type() -> s`                                                  socket type: 'tcp', ...
`s:family() -> s`                                                address family: 'inet', ...
`s:protocol() -> s`                                              protocol: 'tcp', 'icmp', ...
`s:close()`                                                      send FIN and/or RST and free socket
`s:bind([host], [port], [af])`                                   bind socket to an address
`s:setopt(opt, val)`                                             set socket option (`'so_*'` or `'tcp_*'`)
`s:getopt(opt) -> val`                                           get socket option
`tcp|udp:connect(host, port, [expires], [af], ...)`              connect to an address
`tcp:send(s|buf, [len], [expires]) -> true`                      send bytes to connected address
`udp:send(s|buf, [len], [expires]) -> len`                       send bytes to connected address
`tcp|udp:recv(buf, maxlen, [expires]) -> len`                    receive bytes
`tcp:listen([backlog, ]host, port, [af])`                        put socket in listening mode
`tcp:accept([expires]) -> ctcp`                                  accept a client connection
`tcp:recvn(buf, len, [expires]) -> buf, len`                     receive n bytes
`udp:sendto(host, port, s|buf, [len], [expires], [af]) -> len`   send a datagram to an address
`udp:recvnext(buf, maxlen, [expires], [flags]) -> len, sa`       receive the next datagram
`tcp:shutdown('r'|'w'|'rw', [expires])`                          send FIN
__scheduling__
`sock.newthread(func[, name]) -> co`                             create a coroutine for async I/O
`sock.resume(thread, ...) -> ...`                                resume thread
`sock.yield(...) -> ...`                                         safe yield (see [coro])
`sock.suspend(...) -> ...`                                       suspend thread
`sock.thread(func, ...) -> co`                                   create thread and resume
`sock.cowrap(f) -> wrapper`                                      see coro.safewrap()
`sock.currentthread() -> co`                                     see coro.running()
`sock.transfer(co, ...) -> ...`                                  see coro.transfer()
`sock.onthreadfinish(co, f)`                                     run `f` when thread finishes
`sock.threadenv[thread] <-> env`                                 get/set thread environment
`sock.poll()`                                                    poll for I/O
`sock.start()`                                                   keep polling until all threads finish
`sock.stop()`                                                    stop polling
`sock.run(f, ...) -> ...`                                        run a function inside a sock thread
`sock.sleep_until(t)`                                            sleep without blocking until sock.clock() value
`sock.sleep(s)`                                                  sleep without blocking for s seconds
`sock.sleep_job() -> sj`                                         make an interruptible sleep job
`sj:sleep_until(t) -> ...`                                       sleep until sock.clock()
`sj:sleep(s) -> ...`                                             sleep for `s` seconds
`sj:wakeup(...)`                                                 wake up the sleeping thread
`sock.runat(t, f) -> sjt`                                        run `f` at clock `t`
`sock.runafter(s, f) -> sjt`                                     run `f` after `s` seconds
`sock.runevery(s, f) -> sjt`                                     run `f` every `s` seconds
`sjt:cancel()`                                                   cancel timer
__multi-threading__
`sock.iocp([iocp_h]) -> iocp_h`                                  get/set IOCP handle (Windows)
`sock.epoll_fd([epfd]) -> epfd`                                  get/set epoll fd (Linux)
---------------------------------------------------------------- ----------------------------

All function return `nil, err` on error (but raise on user error
or unrecoverable OS failure). Some error messages are normalized
across platforms, like 'access_denied' and 'address_already_in_use'
so they can be used in conditionals.

I/O functions only work inside threads created with `sock.newthread()`.

The optional `expires` arg controls the timeout of the operation and must be
a `sock.clock()`-relative value (which is in seconds). If the expiration clock
is reached before the operation completes, `nil, 'timeout'` is returned.

`host, port` args are passed to `sock.addr()` (with the optional `af` arg),
which means that an already resolved address can be passed as `ai, nil`
in place of `host, port`.

## Address lookup

### `sock.addr(...) -> ai`

Look-up a hostname. Returns an "address info" object which is a OS-allocated
linked list of one or more addresses resolved with the system's `getaddrinfo()`.
The args can be either an existing `ai` object which is passed through, or:

  * `host, port, [socket_type], [family], [protocol], [af]`

where

  * `host` can be a hostname, ip address or `'*'` which means "all interfaces".
  * `port` can be a port number, a service name or `0` which means "any available port".
  * `socket_type` can be `'tcp'`, `'udp'`, `'raw'` or `0` (the default, meaning "all").
  * `family` can be `'inet'`, `'inet6'` or `'unix'` or `0` (the default, meaning "all").
  * `protocol` can be `'ip'`, `'ipv6'`, `'tcp'`, `'udp'`, `'raw'`, `'icmp'`,
  `'igmp'` or `'icmpv6'` or `0` (the default is either `'tcp'`, `'udp'`
  or `'raw'`, based on socket type).
  * `af` are a [glue.bor()][glue] list of `passive`, `cannonname`,
    `numerichost`, `numericserv`, `all`, `v4mapped`, `addrconfig`
    which map to `getaddrinfo()` flags.

NOTE: `getaddrinfo()` is blocking. If that's a problem, use [resolver].

## Sockets

### `sock.tcp([family][, protocol]) -> tcp`

Make a TCP socket. The default family is `'inet'`.

### `sock.udp([family][, protocol]) -> udp`

Make an UDP socket. The default family is `'inet'`.

### `sock.raw([family][, protocol]) -> raw`

Make a raw socket. The default family is `'inet'`.

### `s:close()`

Close the connection and free the socket.

For TCP sockets, if 1) there's unread incoming data (i.e. recv() hasn't
returned 0 yet), or 2) `so_linger` socket option was set with a zero timeout,
then a TCP RST packet is sent to the client, otherwise a FIN is sent.

### `s:bind([host], [port], [af])`

Bind socket to an interface/port (which default to '*' and 0 respectively
meaning all interfaces and a random port).

### `tcp|udp:connect(host, port, [expires], [af])`

Connect to an address, binding the socket to `('*', 0)` if not bound already.

For UDP sockets, this has the effect of filtering incoming packets so that
only those coming from the connected address get through the socket. Also,
you can call connect() multiple times (use `('*', 0)` to switch back to
unfiltered mode).

### `tcp:send(s|buf, [len], [expires], [flags]) -> true`

Send bytes to the connected address.
Partial writes are signaled with `nil, err, writelen`.
Trying to send zero bytes is allowed but it's a no-op (doesn't go to the OS).

### `udp:send(s|buf, [len], [expires], [flags]) -> len`

Send bytes to the connected address.
Empty packets (zero bytes) are allowed.

### `tcp|udp:recv(buf, maxlen, [expires], [flags]) -> len`

Receive bytes from the connected address.
With TCP, returning 0 means that the socket was closed on the other side.
With UDP it just means that an empty packet was received.

### `tcp:listen([backlog, ]host, port, [af])`

Put the socket in listening mode, binding the socket if not bound already
(in which case `host` and `port` args are ignored). The `backlog` defaults
to `1/0` which means "use the maximum allowed".

### `tcp:accept([expires]) -> ctcp`

Accept a client connection. The connection socket has additional fields:
`remote_addr`, `remote_port`, `local_addr`, `local_port`.

### `tcp:recvn(buf, len, [expires]) -> buf, len`

Repeat recv until `len` bytes are received.
Partial reads are signaled with `nil, err, readlen`.

### `udp:sendto(host, port, s|buf, [maxlen], [expires], [flags], [af]) -> len`

Send a datagram to a specific destination, regardless of whether the socket
is connected or not.

### `udp:recvnext(buf, maxlen, [expires], [flags]) -> len, sa`

Receive the next incoming datagram, wherever it came from, along with the
source address. If the socket is connected, packets are still filtered though.

### `tcp:shutdown('r'|'w'|'rw')`

Shutdown the socket for receiving, sending or both. Does not block.

Sends a TCP FIN packet to indicate refusal to send/receive any more data
on the connection. The FIN packet is only sent after all the current pending
data is sent (unlike RST which is sent immediately). When a FIN is received
recv() returns 0.

Calling close() without shutdown may send a RST (see the notes on `close()`
for when that can happen) which may cause any data that is pending either
on the sender side or on the receiving side to be discarded (that's how TCP
works: RST has that data-cutting effect).

Required for lame protocols like HTTP with pipelining: a HTTP server
that wants to close the connection before honoring all the received
pipelined requests needs to call `s:shutdown'w'` (which sends a FIN to
the client) and then continue to receive (and discard) everything until
a recv that returns 0 comes in (which is a FIN from the client, as a reply
to the FIN from the server) and only then it can close the connection without
messing up the client.

## Scheduling

Scheduling is based on synchronous coroutines provided by [coro] which
allows coroutine-based iterators that perform socket I/O to be written.

### `sock.newthread(func) -> co`

Create a coroutine for performing async I/O. The coroutine must be resumed
to start. When the coroutine finishes, the control is transfered to
the I/O thread (the thread that called `start()`).

Full-duplex I/O on a socket can be achieved by performing reads in one thread
and writes in another.

### `sock.resume(thread, ...)`

Resume a thread, which means transfer control to it, but also temporarily
change the I/O thread to be this thread so that the first suspending call
(send, recv, sleep, suspend, etc.) gives control back to this thread.
This is _the_ trick to starting multiple threads before starting polling.

### `sock.suspend(...) -> ...`

Suspend current thread, transfering to the polling thread (but also see resume()).

### `sock.poll(timeout) -> true | false,'timeout'`

Poll for the next I/O event and resume the coroutine that waits for it.

Timeout is in seconds with anything beyond 2^31-1 taken as infinte
and defaults to infinite.

### `sock.start(timeout)`

Start polling. Stops after the timeout expires and there's no more I/O
or `stop()` was called.

### `sock.stop()`

Tell the loop to stop dequeuing and return.

### `sock.sleep_until(t)`

Sleep until a time.clock() value without blocking other threads.

### `sock.sleep(s)`

Sleep `s` seconds without blocking other threads.

### `sock.sleep_job() -> sj`

Make an interruptible sleeping job. Put the current thread sleep using
`sj:sleep()` or `sj:sleep_until()` and then from another thread call
`sj:wakeup()` to resume the sleeping thread. Any arguments passed to
`wakeup()` will be returned by `sleep()`.

## Multi-threading

### `sock.iocp([iocp_handle]) -> iocp_handle`

Get/set the global IOCP handle (Windows).

IOCPs can be shared between OS threads and having a single IOCP for all
threads (as opposed to having one IOCP per thread/Lua state) enables the
kernel to better distribute the completion events between threads.

To share the IOCP with another Lua state running on a different thread,
get the IOCP handle with `sock.iocp()`, copy it over to the other state,
then set it with `sock.iocp(copied_iocp)`.

### `sock.epoll_fd([epfd]) -> epfd`

Get/set the global epoll fd (Linux).

Epoll fds can be shared between OS threads and having a single epfd for all
threads is more efficient for the kernel than having one epfd per thread.

To share the epfd with another Lua state running on a different thread,
get the epfd with `sock.epoll_fd()`, copy it over to the other state,
then set it with `sock.epoll_fd(copied_epfd)`.
