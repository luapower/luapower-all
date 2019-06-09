
## `local lrucache = require'lrucache'`

LRU cache limited by an abstract size. Values can have different sizes. When
a new value is put in the cache and the cache is full, just enough old values
are removed to make room for the new value and not exceed the cache max size.

## API

-------------------------------------- -------------------------------------------------
`lrucache([options]) -> cache`         create a new cache
`cache.max_size <- size`               set the cache size limit
`cache:clear()`                        clear the cache
`cache:free()`                         destroy the cache
`cache:free_value(val)`                value destructor (to be overriden)
`cache:value_size(val) -> size`        get value size (to be overriden; returns 1)
`cache:free_size() -> size`            size left until `max_size`
`cache:get(key) -> val`                get a value from the cache by key
`cache:remove(key) -> val`             remove a value from the cache by key
`cache:remove_val(val) -> key`         remove a value from the cache
`cache:remove_last() -> val`           remove the last value from the cache
`cache:put(key, val)`                  put a value in the cache, making room as needed
-------------------------------------- -------------------------------------------------
