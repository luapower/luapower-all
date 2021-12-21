---
tagline: SHA1 in Lua
---

## `local sha1 = require'sha1'`

SHA1 algorithm in Lua.

----------------------------------- -----------------------------------
`sha1.sha1(s) -> s`                 compute the SHA-1 hash of a string.
`sha1.sha1_hmac(s, key) -> s`       compute the HMAC-SHA1 of a string.
----------------------------------- -----------------------------------

These functions return the binary representation of the hash.
To get the hex representation, use [glue.tohex].

[glue.tohex]: glue.html#tohex
