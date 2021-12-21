
## `local tls = require'libtls'`

libtls ffi binding. Use it with [libtls_bearssl] or with your own LibreSSL binary.

## Rationale

libtls has a sane API as opposed to OpenSSL which was written by monkeys.
libtls doesn't force us to do I/O in its callbacks which allows us to yield in I/O.
libtls works on user-provided I/O as opposed to LuaSec which only works on sockets.

## Status

Works for me.

## API

------------------------------------------------ -----------------------------
`tls.config(opt) -> conf`                        create a shared config object
`conf:free()`                                    free the config object
`tls.client(conf) -> cts`                        create and configure a client context
`tls.server(conf) -> sts`                        create and configure a server context
`ts:reset(conf)`                                 reset and re-configure a context
`sts:accept(read_cb, write_cb, cb_arg) -> cts`   accept a connection
`cts:connect(vhost, read_cb, write_cb, cb_arg)`  connect to a server
`cts:recv(buf, maxsz) -> sz`                     receive data
`cts:send(s|buf, [sz])`                          send data
`ts:close()`                                     close a connection
`ts:free()`                                      free a context
------------------------------------------------ -----------------------------

#### Config options

----------------------------------- ------------------------------------------
`alpn`
`ca`                                CA certificate
`key`                               server key
`cert`                              server certificate
`ocsp_staple`                       ocsp staple
`crl`                               CRL data
`keypairs`                          `{{cert=, key=, ocsp_staple=},...}`
`ticket_keys`                       `{{keyrev=, key=},...}`
`ciphers`                           cipher list
`dheparams`                         DHE params
`ecdhecurve`                        ECDHE curve
`ecdhecurves`                       ECDHE curves
`protocols`                         protocols ('tlsv1.0'..'tlsv1.3')
`verify_depth`                      certificate verification depth
`prefer_ciphers_client`             prefer client's cipher list
`prefer_ciphers_server`             prefer server's cipher list
`insecure_noverifycert`             don't verify server's certificate
`insecure_noverifyname`             don't verify server's name
`insecure_noverifytime`             disable cert and OSCP validation
`ocsp_require_stapling`             require OCSP stapling
`verify_client`                     check client certificate
`verify_client_optional`            check client certificate if provided
`session_id`                        session id
`session_lifetime`                  session lifetime
----------------------------------- ------------------------------------------

