---
tagline: fast non-crypto hash
---

## `local xxhash = require'xxhash'`

A ffi binding of the extremely fast non-cryptographic hash algorithm
[xxHash](http://www.xxhash.com/).

## API

------------------------------------------------ ------------------------------------------------
`xxhash.hash32(data[, len[, seed]]) -> hash`     compute a 32bit hash
`xxhash.hash64(data[, len[, seed]]) -> hash`     compute a 64bit hash
------------------------------------------------ ------------------------------------------------

