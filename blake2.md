---
tagline: BLAKE2 hashing
---

## `local blake2 = require'blake2'`

A ffi binding of the [BLAKE2] fast cryptographic hash.

[BLAKE2]: https://blake2.net/

## API

In the table below, `?` is either `s`, `b`, `sp` or `bp` for each variant
of the BLAKE2 algorithm.

-------------------------------------- --------------------------------------
`blake2.blake2?(s, [#s], [key],        Compute the hash of a string or a cdata buffer.
[#out]) -> hash`

`blake2.blake2?_digest([key | opt_t],  Get a function that can consume multiple
[#out]) -> digest` \                   data chunks until called with no arguments to
`digest(s, [#s])` \                    return the final hash.
`digest() -> hash`

`blake2.bparam(...) -> blake2s_param`  Create a `blake2s_param`
`blake2.sparam(...) -> blake2b_param`  Create a `blake2b_param`
-------------------------------------- --------------------------------------

The hash is returned raw in a Lua string. To get it as hex use [glue].tohex().

The optional `key` arg is for keyed hashing (up to 64 bytes for BLAKE2b,
up to 32 bytes for BLAKE2s).

The optional `#out` arg is for reducing the length of the output hash.

The constructors `blake2s_digest` and `blake2b_digest` can take a table
in place of the `key` arg in which more options can be specified:

* `salt`: salt for randomized hashing (up to 16 bytes for BLAKE2b, up to 8 bytes for BLAKE2s).
* `personal`: personalization string (up to 16 bytes for BLAKE2b, up to 8 bytes for BLAKE2s).
* `fanout`: fanout (0 to 255, 0 if unlimited, 1 in sequential mode).
* `depth`: maximal depth of tree (1 to 255, 255 if unlimited, 1 in sequential mode).
* `leaf_size`: maximal byte length of leaf (0 to 2**32-1, 0 if unlimited or in sequential mode).
* `node_offset`: node offset (0 to 2**64-1 for BLAKE2b, 0 to 2**48-1 for BLAKE2s,
   0 for the first, leftmost, leaf, or in sequential mode).
* `node_depth`: node depth (0 to 255, 0 for leaves, or in sequential mode).
* `inner_size`: inner digest size (0 to 64 for BLAKE2b, 0 to 32 for BLAKE2s, 0 in sequential mode).
* `last_node`: boolean indicating whether the processed node is the last one (false for sequential mode).
* `hash_length`: optional, for reducing the length of the output hash.

![hash tree](http://pythonhosted.org/pyblake2/_images/tree.png)

See section 2.10 in [BLAKE2 specification](https://blake2.net/blake2_20130129.pdf)
for comprehensive review of tree hashing.
