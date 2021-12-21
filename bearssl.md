
BearSSL, linked by [libtls_bearssl] which is used by [sock] for TLS.

## Limitations

 * no TLS sessions (bearssl has them but they aren't wrapped by [libtls_bearssl])
 so if you're a client you might want to keep-alive your connections.
 * No TLS 1.3, and [no wonder](https://bearssl.org/tls13.html).
 * No CRL or OCSP, but you wouldn't want to use those anyway,
 these are silly things, browsers don't use them anymore.
 Use OneCRL for this which is also a hack but at least it scales.
 * No DHE by design (use ECDHE).
