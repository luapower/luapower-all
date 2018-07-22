---
tagline: UTF-8 encoding and decoding for LuaJIT
---

## `local utf8 = require'utf8'`

---------------------------------------------------------- --------------------------------------------
`utf8.decode(buf, len, [out], [outlen], repl) -> n, p`     decode utf8 buffer (or get output length)
`utf8.encode(buf, len, [out], [outlen]) -> bytes`          encode utf32 buffer (or get output length)
`utf8.next(buf, len, i) -> next_i, [codepoint]`            codepoint at index `i`
`utf8.chars(s[, start]) -> iter() -> next_i, [codepoint]`  iterate codepoints in string
---------------------------------------------------------- --------------------------------------------

NOTE: `repl` is an optional codepoint to be used in place of invalid bytes
in utf8. If not given, invalid bytes are skipped and their count is returned
as `p`. If `repl` is `'iso-8859-1'`, then invalid bytes are treated as
iso-8859-1 characters like browsers do.
