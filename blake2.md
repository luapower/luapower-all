---
tagline: BLAKE2 hashing
---

## `local blake2 = require'blake2'`

A ffi binding of the [BLAKE2](https://blake2.net/) fast cryptographic hash.

## API

In the table below, `?` is either `s`, `b`, `sp` or `bp` for each variant
of the BLAKE2 algorithm.

---------------------------------------------------------------- -----------------------------------------------
`blake2.blake2?(s, [size], [key], [#out]) -> s` \                compute the hash of a string or a cdata buffer.
`blake2.blake2?(cdata, size, [key]) -> s`

`blake2.blake2?_digest([key, [#out] | opt_t]) -> digest` \       get an object/function that can consume multiple
                                                                 data chunks before returning the hash

`digest[:update](s, [size])` \                                   consume a data chunk
`digest[:update](cdata, size)`

`digest[:final]() -> s`                                          finalize and get the hash
`digest:final_to_buffer(buf)`                                    finalize and write the hash to a buffer
`digest:length() -> n`                                           hash byte length

`digest:reset()`                                                 prepare for another digestion
---------------------------------------------------------------- -----------------------------------------------

The hash is returned raw in a Lua string. To get it as hex use [glue].tohex().

The optional `key` arg is for keyed hashing (up to 64 bytes for BLAKE2b,
up to 32 bytes for BLAKE2s).

The optional `#out` arg is for reducing the length of the output hash.

The constructors `blake2s_digest` and `blake2b_digest` can take a table
in place of the `key` arg in which more options can be specified:

* `salt` (''): salt for randomized hashing (up to 16 bytes for BLAKE2b, up to 8 bytes for BLAKE2s).
* `personal` (''): personalization string (up to 16 bytes for BLAKE2b, up to 8 bytes for BLAKE2s).
* `fanout` (1): fanout (0 to 255, 0 if unlimited, 1 in sequential mode).
* `depth` (1): maximal depth of tree (1 to 255, 255 if unlimited, 1 in sequential mode).
* `leaf_length` (0): maximal byte length of leaf (0 to 2^32-1, 0 if unlimited or in sequential mode).
* `node_offset` (0): node offset (0 to 2^64-1 for BLAKE2b, 0 to 2^48-1 for BLAKE2s,
   0 for the first, leftmost, leaf, or in sequential mode).
* `node_depth` (0): node depth (0 to 255, 0 for leaves, or in sequential mode).
* `inner_length` (0): inner digest length (0 to 64 for BLAKE2b, 0 to 32 for BLAKE2s, 0 in sequential mode).
* `key`: key string for keyed hashing (up to 64 bytes for BLAKE2b, up to 32 bytes for BLAKE2s).
* `hash_length`: optional, for reducing the length of the output hash.

__NOTE:__ the `salt` and `personal` options are zero-padded so `'foo'` is
the same value as `'foo\0'` or `'foo\0\0'` with them (not so with `key`).

See section 2.10 in [BLAKE2 specification](https://blake2.net/blake2_20130129.pdf)
for comprehensive review of tree hashing.
