---
tagline: unidirectional cdata ring buffers
---

## `local ringbuffer = require'ringbuffer'`

Unidirectional cdata array-based ring buffers with the following properties:

  * elements can be added or removed one by one or in bulk.
  * data can only be added to the tail and removed from the head (FIFO).
  * the buffer is fixed-size and can grow on request.
  * can work with an internally allocated byffer, an external buffer,
  or can be used as an abstract interface over an external API.

## API

------------------------------------------ -----------------------------------------------------
`ringbuffer{size=, ctype=, ...} -> cb`     create a cdata ring buffer
`cb:head(i) -> i`                          normalized offset from head
`cb:tail(i) -> i`                          normalized offset from tail
`cb:segments() -> i1, n1, i2, n2`          offsets and sizes of buffer's occupied segments
`cb:free_segments() -> i1, n1, i2, n2`     offsets and sizes of buffer's free segments
`cb:push(n[, data]) -> i1, n1, i2, n2`     add data to tail, invoking cb:read()
`cb:pull(n[, data]) -> i1, n1, i2, n2`     remove data from head, invoking cb:write()
`cb:checksize(n)`                          grow the buffer to fit at least `n` more elements
`cb:alloc(n) -> cdata`                     allocator (defaults to ffi.new)
`cb:read(dst, di, si, n)`                  segment reader (defaults to ffi.copy)
`cb:write(src, di, si, n)`                 segment writer (defaults to ffi.copy)
`cb.data -> cdata`                         the buffer itself
`b.start -> i`                             start index
`b.size -> n`                              capacity
`b.length -> n`                            occupied size
------------------------------------------ -----------------------------------------------------

### `ringbuffer(cb) -> cb`

Convert an initial table to a ring buffer and return it. The table can have fields:

  * `size`: the size of the buffer.
  * `ctype`: the element type for allocating an internal buffer, or
  * `data`: a pre-allocated buffer.
  * `start`, `length`: optional, in case the buffer comes pre-filled.
  * `alloc`: optional custom allocator, for initial allocation and growing.

## How it works

When `push()` is called with a `data` arg, the `write()` method is called
once or twice with the segments to be written from `data` into the buffer.
When `pull()` is called with a `data` arg, the `read()` method is called once
or twice with the segments to be read from the buffer into `data`.

## As an interface

A ring buffer doesn't have to manage an actual buffer. Instead,
it can be used to manage an external resource that the ring buffer logic
can be applied to. To do this pass `data = true` when creating a buffer
to avoid allocating an actual buffer. Call `push()` and `pull()` without
a `data` arg to avoid calls to `write()` and `read()` and use the buffer
state variables `start`, `length` and `size` as you want. Or, pass `true`
(or any other value) to the `data` arg in `push()` and `pull()` and
override `read()` and `write()` to do the actual moving of data.

## Extending

The ringbuffer function is actually a callable table which can be copied
or inherited from and patched to create custom buffer classes.
