---
tagline: md5 hashing
---

## `local md5 = require'md5'`

A ffi binding of the popular [MD5 implementation][md5 lib] by Alexander Peslyak.

[md5 lib]:    http://openwall.info/wiki/people/solar/software/public-domain-source-code/md5

--------------------------------------- ---------------------------------------
`md5.sum(s[, size]) -> s`    \          Compute the MD5 sum of a string or a cdata buffer.
`md5.sum(cdata, size) -> s`  \          Returns the binary representation of the hash.
											       To get the hex representation, use [glue.tohex].

`md5.digest() -> digest`     \          Get a MD5 digest function that can consume multiple
`digest(s[, size])`          \          data chunks until called with no arguments when
`digest(cdata, size)`        \          it returns the final binary MD5 hash.
`digest() -> s`
--------------------------------------- ---------------------------------------

[glue.tohex]: glue.html#tohex
