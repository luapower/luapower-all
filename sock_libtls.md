
## `local stls = require'sock_libtls'`

Secure async TCP sockets with [sock] and [libtls].

## API

----------------------------------------------------- -----------------------------------
`stls.client_stcp(tcp, servername, opt) -> cstcp`     create a secure socket for a client
`stls.server_stcp(tcp, opt) -> sstcp`                 create a secure socket for a server
`cstcp:recv()`                                        same semantics as `tcp:recv()`
`cstcp:send()`                                        same semantics as `tcp:send()`
`cstcp:recvn()`                                       same semantics as `tcp:recvn()`
`cstcp:recvall()`                                     same semantics as `tcp:recvall()`
`cstcp:recvall_read()`                                same semantics as `tcp:recvall_read()`
`sstcp:accept() -> cstcp`                             accept a client connection
`cstcp:shutdown('r'|'w'|'rw')`                        calls `self.tcp:shutdown()`
`cstcp:close()`                                       close client socket
`sstcp:close()`                                       close server socket
----------------------------------------------------- -----------------------------------
