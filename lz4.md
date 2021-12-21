---
tagline: extremely fast compression
---

## `local lz4 = require'lz4'`

## API

--------------------------------------- ---------------------------------------
__buffer API__

`lz4.compress(src, [#src], dst,
	[#dst], [accel], [level],
	[state], [filldest]) -> #dst`

`lz4.decompress(src, [#src] | true,
	dst, [#dst], [outlen]) -> #dst`

__stream API__

`lz4.compress_stream([hc]) -> cs`

`lz4.decompress_stream() -> ds`

`cs:compress(src, [#src], dst,
	[#dst], [accel/level]) -> #dst`

`ds:decompress(src, [#src] | true,
	dst, [#dst])

__dictionaries__

`cs:load_dict(dict, [#dict])`

`cs:save_dict(dict, #dict)`

`ds:set_dict(dict, [#dict])`

`cs|ds:free()`

`cs|ds:reset()`

__misc__

`lz4.sizeof_state() -> bytes`

`lz4.sizeof_state_hc() -> bytes`

`lz4.compress_bound() -> bytes`

`lz4.version() -> n`
--------------------------------------- ---------------------------------------
