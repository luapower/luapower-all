---
tagline: md5 hashing
---

## `local md5 = require'md5'`

A ffi binding of the popular [MD5 implementation][md5 lib] by Alexander Peslyak.

[md5 lib]:    http://openwall.info/wiki/people/solar/software/public-domain-source-code/md5

## API

--------------------------------------- ---------------------------------------
`md5.sum(s[, #s]) -> s`    \            Compute the MD5 hash of a string or a cdata buffer.

`md5.digest() -> digest`     \          Get a function that can consume multiple
`digest(s[, #s])`            \          data chunks until called with no arguments to
`digest() -> s`                         return the final hash.
`md5.hmac(s, key) -> s`                 compute the HMAC-MD5 of a string.
--------------------------------------- ---------------------------------------

__NOTE__: All functions return the binary representation of the hash.
To get the hex representation, use [glue].tohex().
