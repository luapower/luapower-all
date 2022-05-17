---
tagline: base64 encoding & decoding
---

## `local b64 = require'libb64'`

FFI binding of [libb64](http://libb64.sourceforge.net/), a fast base64 encoder and decoder by Chris Venter.

	b64.encode(s[, size]) -> s
	b64.decode(s[, size]) -> s
	b64.encode(cdata, size) -> s
	b64.decode(cdata, size) -> s

Encode/decode a string or cdata to a string.

	b64.encode_tobuffer(s, [size], out_buf, out_size) -> bytes_written
	b64.decode_tobuffer(s, [size], out_buf, out_size) -> bytes_written
	b64.encode_tobuffer(cdata, size, out_buf, out_size) -> bytes_written
	b64.decode_tobuffer(cdata, size, out_buf, out_size) -> bytes_written

Encode/decode a string or cdata to a buffer.

  * encoding needs a buffer of at least `size * 2 + 3` bytes
  * decoding needs a buffer of at least `math.floor(size * 3 / 4)` bytes

## TODO

Stream-like interface similar to zlib's inflate/deflate. \
Benchmark against this pure ffi implementation[1].

[1]: https://github.com/kengonakajima/luvit-base64/issues/1
