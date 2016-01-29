---
tagline: MD4 hashing
---

## `local md4 = require'md4'`

A ffi binding of the popular [MD4 implementation][md4 lib] by Alexander Peslyak.

[md4 lib]:    http://openwall.info/wiki/people/solar/software/public-domain-source-code/md4

--------------------------------------- ---------------------------------------
`md4.sum(s[, size]) -> s`    \          Compute the MD4 sum of a string or a cdata buffer.
`md4.sum(cdata, size) -> s`  \          Returns the binary representation of the hash.
											       To get the hex representation, use [glue].tohex().

`md4.digest() -> digest`     \          Get a MD4 digest function that can consume multiple
`digest(s[, size])`          \          data chunks until called with no arguments when
`digest(cdata, size)`        \          it returns the final binary MD4 hash.
`digest() -> s`
--------------------------------------- ---------------------------------------
