
## `local mp = require'msgpack'`

MessagePack v5 decoder and encoder for LuaJIT.

---------------------------------------------------- -----------------------------------
`mp.new([mp]) -> mp`                                 create a new mp instance (optional)
__Decoding__
`mp:decode_next(p, [n], [i]) -> next_i, v`           decode value at offset `i` in `p`
`mp:decode_each(p, [n], [i]) -> iter() -> next_i, v` decode all values up to `n` bytes
__Encoding__
`mp:encoding_buffer([min_size]) -> b`                create a buffer for encoding
`b:encode(v) -> b`                                   encode a value (see below)
`b:encode_array(t, [n]) -> b`                        encode an array
`b:encode_map(t, [pairs]) -> b`                      encode a map
`b:encode_int(x) -> b`                               encode a number as integer
`b:encode_float(x) -> b`                             encode a float
`b:encode_double(x) -> b`                            encode a double
`b:encode_bin(v, [n]) -> b`                          encode a byte array
`b:encode_ext(type, [n]) -> b`                       encode the header for an ext value
`b:encode_ext_int(ctype, x) -> b`                    encode a raw integer (see code)
`b:encode_timestamp(ts) -> b`                        encode a timestamp value
`b:size() -> n`                                      get the buffer content size
`b:get() -> p, n`                                    get the buffer and its size
`b:tostring() -> s`                                  get the buffer as a string
`b:reset() -> b`                                     reset the buffer for reuse
`mp.array(...) -> t`                                 create an encodable array from args
`mp.toarray(t, [n]) -> t`                            add `mp.N` to table `t`
__Customization__
`mp.nil_key`                                         value to decode nil keys to (skip)
`mp.nan_key`                                         value to decode NaN keys to (skip)
`mp.nil_element`                                     value to decode nil array elements to (`nil`)
`mp.decode_i64`                                      `int64_t` decoder (`tonumber`)
`mp.decode_u64`                                      `uint64_t` decoder (`tonumber`)
`mp.decoder[type] = f(mp, p, i, len) -> next_i, v`   add a decoder for an ext type
`mp:decode_unknown(mp, p, i, len, type_code) end`    decode an unknown ext type
`mp:isarray(t)`                                      decide if `t` is an array or map
`mp.N`                                               key for array element count
`mp.error(err)`                                      custom error constructor
---------------------------------------------------- -----------------------------------

Decoding behavior:

* `nil` and `NaN` table keys are skipped, unless `mp.nil_key` / `mp.nan_key` is set.
* `nil` array elements create Lua sparse arrays, unless `mp.nil_element` is set.
* extension types are decoded with `mp.decoder[type]`, falling back to
`mp:decode_unknown()` (pre-defined as a stub that returns `nil`).
* decoding errors are raised with `mp.error()` which defaults to `error`
(see [errors] for why you'd want to replace this).
* there's no way to tell an empty array from an empty map.

Encoding behavior:

* Lua numbers are packed as either integers (the smallest possible) or doubles.
* 64bit cdata numbers are packed as 64bit integers.
* Lua tables are encoded as arrays or maps based on `mp:isarray()` which
by default returns `true` only if there's a `mp.N` key present in the table.
Use `mp.array()` to make a Lua table that will be encoded as an array
or call `b:encode_array()` on any table.
* you can set `[mp.N] = true` in the array to mean that the element count is `#t`.
