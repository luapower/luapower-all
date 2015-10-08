---
tagline: portable memory mapping
---

<warn>Work in progress</warn>

## `local mmap = require'mmap'`

Memory mapping API that can be used with Windows, Linux and OSX.
Can be used for:

  * mapping large files to memory
  * allocating large memory blocks backed by the swap file
  * sharing memory between processes
  * creating executable memory segments
  * creating mirrored segments (ring buffers)

## API

### `mmap.map(t) -> map | nil, errcode, errmsg`

Create a memory map object. The `t` arg is a table with the fields:

* `size`: minimum size of the segment (required); the actual size will
be the next multiple of page size.
* `file`: OS file handle or file descriptor (none); if not given,
a temp file or the system's swap file will be used.
* `offset`: offset in the file (0)
* `name`: name of the mempry map; using the same name in two processes
gives access to the same memory.
* `mirrors`: number of mirrors (0); mirrors map the same memory block
in subsequent address spaces.
* `addr`: address hint.

Returns an object (a table) with the fields:

* `map.addr` - `void*` pointer to the mapped memory
* `map.size` - actual size of the memory block
* `map:free()` - method to free the memory and associated resources

In case of error, returns nil followed by an error code and message.
Possible error codes:

* 'disk_full'
* 'out_of_memory'

For other error conditions, an error is raised instead.

### `mmap.pagesize() -> bytes`

Get the current page size. Mapped memory is multiple of this size.
