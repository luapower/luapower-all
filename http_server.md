
## `local server = require'http_server'`

HTTP 1.1 coroutine-based async server in Lua.

Features, https, gzip compression, persistent connections, pipelining,
resource limits, multi-level debugging, cdata-buffer-based I/O.

Uses [sock] and [libtls] for I/O and TLS or you can bring your own stack.

GZip compression can be enabled with `client.http.zlib = require'zlib'`.

## Status

<warn>Needs hostile testing<warn>

## API

--------------------------------- --------------------------------------------
`server:new(opt) -> server`       create a server object
--------------------------------- --------------------------------------------

#### Server options

--------------------------------- --------------------------------------------
`libs`                            required: `'sock sock_libtls zlib'`
`listen`                          `{host=, port=, tls=t|f, tls_options=}`
`tls_options`                     options for [libtls]
--------------------------------- --------------------------------------------
