---
tagline: UTF-8 encoding and decoding for LuaJIT
---

## `local utf8 = require'utf8'`

Decode and encode UTF-8 data with control over invalid bytes.

---------------------------------------------------------- --------------------------------------------
`utf8.next(buf, len, i) -> ni, code, byte`                 codepoint (or invalid byte) at index `i`
`utf8.prev(buf, len, i) -> ni, code, byte`                 codepoint (or invalid byte) before index `i`
`utf8.decode(buf, len, out, outlen, repl) -> [out, ]n, p`  decode utf-8 buffer (or get output length)
`utf8.encode(buf, len, out, outlen, repl) -> [out, ]bytes` encode utf-32 buffer (or get output length)
`utf8.chars(s[, start]) -> iter() -> ni, code, byte`       iterate codepoints in string
`utf8.encode_chars({c1,...}, repl | c1,...) -> s`          encode codepoints to utf-8 string
---------------------------------------------------------- --------------------------------------------

### `utf8.next(buf, len, i) -> next_i, code, byte | nil`

Return codepoint (or invalid byte) at index `i`. Return `nil` if `i >= len`.

### `utf8.prev(buf, len, i) -> i, code, byte | nil`

Return codepoint (or invalid byte) before index `i`. Return `nil` if `i <= 0`.

### `utf8.decode(buf, len, out, outlen, repl) -> [out, ]n, p`

Decode utf8 buffer into a utf32 buffer or get output length.

  * if `out` is `nil` the output buffer is allocated by the function.
    * the buffer is n+1 codepoints thus null-terminated.
  * if `out` is `false` the output buffer is not allocated or returned.
  * `n, p` is the number of valid codepoints and the number of invalid bytes.
  * `repl` is an optional codepoint to replace invalid bytes with.
    * if `repl` is not given, invalid bytes are skipped.
    * if `repl` is `'iso-8859-1'`, invalid bytes are treated as iso-8859-1
    characters like browsers do.
    * replaced invalid bytes are counted in `n`.
  * returns `nil, err, sz` on output buffer overflow, where `sz` is the byte
  size of the text that fit into the buffer.

### `utf8.encode(buf, len, out, outlen, repl) -> [out, ]bytes`

Encode utf32 buffer into a utf8 buffer or get output length.

  * if `out` is `nil` the output buffer is allocated by the function.
    * the buffer is n+1 bytes thus null-terminated.
  * if `out` is `false` the output buffer is not allocated or returned.
  * `repl` is an optional valid codepoint to replace invalid codepoints with.
    * if `repl` is not given, invalid codepoints are skipped.
  * returns `nil, err` on error (output buffer overflow).

### `utf8.chars(s[, start]) -> iter() -> next_i, code, byte`

Iterate all the codepoints in a string, returning the index in string where
the _next_ codepoint is, and the codepoint. Invalid bytes are returned in
the second return value, in which case the codepoint is `nil`.

### `utf8.encode_chars({c1, ...}, repl) -> s` <br> `utf8.encode_chars(c1, ...) -> s`

Encode codepoints (given as an array or as separate args) to a utf-8 string.
