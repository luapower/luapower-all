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

* `path`: file name to open or create (none); if `path` (or `file`)
is not given, the system's swap file will be mapped instead.
* `file`: OS file handle to use instead of `path`.
* `size`: the minimum size of the memory segment.
	* the actual size will be the next multiple of system page size.
	* must be > 0 or the call fails.
	* if not given, the current file size is used.
* `offset`: offset in the file (0)
* `name`: name of the mempry map
	* using the same name in two processes gives access to the same memory.
* `addr`: address to use (none).

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
