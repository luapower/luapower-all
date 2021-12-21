---
tagline: fast non-crypto hash
---

## `local xxhash = require'xxhash'`

A ffi binding of the extremely fast non-cryptographic hash algorithm
[xxHash](http://www.xxhash.com/).

## API

### `xxhash.hash32|64|128(data[, len[, seed]]) -> hash`

Compute a 32|64|128 bit hash.
