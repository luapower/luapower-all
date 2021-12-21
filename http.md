
## `local http = require'http'`

HTTP 1.1 client & server protocol in Lua.
Uses [sock] for I/O but you can bring your own.

GZip compression can be enabled with `http.zlib = require'zlib'`.

This module only implements the actual protocol. For a working HTTP client
and server based on this module, see [http_client] and [http_server].

## Status

Works in developement, not used 24/7 yet.

## API

`http:new(opt) -> http`

Create a HTTP protocol object that should be used on a single freshly open
HTTP or HTTPS connection to either perform HTTP requests on it (as client)
or to read-in HTTP requests and send-out responses (as server).

The table `opt` can contain:

--------------------------------- --------------------------------------------
`tcp`                             the I/O API (required)
`port`                            if client: server's port (optional)
`https`                           if client: `true` if using TLS (optional)
`max_line_size`                   change the HTTP line size limit
--------------------------------- --------------------------------------------

### Client-side API

#### `http:make_request(opt) -> req`

Make a HTTP request object. The table `opt` can contain:

--------------------------------- --------------------------------------------
`host`                            vhost name
`max_line_size`                   change the HTTP line size limit
`close`                           close the connection after replying
`content`, `content_size`         body: string, read function or cdata buffer
`compress`                        `false`: don't compress body
--------------------------------- --------------------------------------------

#### `http:send_request(req) -> true | nil,err,errtype`

Send a request.

#### `http:read_response(req) -> res | nil,err,errtype`

Receive server's response.

### Server-side API

#### `http:read_request(receive_content) -> req`

Receive a client's request.

#### `http:make_response(req, opt) -> res`

Construct a HTTP response object.

The `opt` table can contain:

--------------------------------- --------------------------------------------
`close`                           close the connection (and tell client to)
`content`, `content_size`         body: string, read function or cdata buffer
`compress`                        `false`: don't compress body
`allowed_methods`                 allowed methods: `{method->true}` (optional)
`content_type`                    content type (optional)
--------------------------------- --------------------------------------------

#### `http:send_response(res) -> true | nil,err,errtype`

Send a response.

