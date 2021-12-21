---
tagline: base64 encoding & decoding
---

## `local b64 = require'base64'`

Fast base64 encoding & decoding in Lua with ffi.

## API

### b64.[encode|decode](s[, size], [outbuf], [outbuf_size]) -> s | outbuf, len

Encode/decode string or cdata buffer.

### b64.url[encode|decode](s) -> s

Encode/decode URL based on RFC4648 Section 5 / RFC7515 Section 2 (JSON Web Signature).
