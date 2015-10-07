---
tagline: lock-free ring buffer
---

## `local lfrb = require'lfrb'`

Lock-free ring buffer. Maintains two indices which can be advanced
separately from two different threads. It doesn't hold the actual buffer.
Best used with [mmap]ed mirror buffers.

## API

------------------------------ -----------------------------------------------
`lfrb.new(capacity) -> rb`      create a new ring buffer state
`rb.capacity -> n`              ring buffer's capacity
`rb.write_index() -> i`         get current write index
`rb.advance_write_index(n)`     advance the write index by n elements
`rb.read_index() -> i`          get current read index
`rb.
