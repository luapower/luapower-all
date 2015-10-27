---
tagline: portable memory mapping
---

<warn>Work in progress</warn>


TODO: offset & size -> access denied
TODO: invalid address test
TODO: same name test
TODO: resize(newsize) <- files are extended automatically so only for shortening.
TODO: create_temp_file() (can we use io.tmpfile() ?)
TODO: remove_file() (can we use os.remove() ?)


## `local mmap = require'mmap'`

Memory mapping API that can be used with Windows, Linux and OSX.
Can be used for:

  * mapping large files to memory
  * allocating large memory blocks backed by the swap file
  * sharing memory between processes
  * creating executable memory segments
  * creating mirrored segments (ring buffers)


## API

----------------------------------------------- ------------------------------
`mmap.map(t) -> map | nil,errmsg,errcode`       create a memory mapping
`map:flush([addr, size])`                       flush (parts of) the mapping to disk
`map.addr`                                      a `void*` pointer to the mapped address
`map.size`                                      the size of the mapped block
`map.fileno`                                    the OS file handle
`map.autoclose`                                 true means close the file on `map:free()`
`map.autoremove`                                true means remove the file on `map:free()`
`map:free()`                                    release the memory and associated resources
`mmap.mirror(t) -> map | nil,errmsg,errcode`    create a mirrored memory mapping
`mmap.aligned_size(size) -> size`               align a size to page boundary
`mmap.pagesize() -> size`                       current allocation granularity
----------------------------------------------- ------------------------------

### `mmap.map(t) -> map | nil, errmsg, errcode`

Create a memory map object. The `t` arg is a table with the fields:

* `path`: file name to open or create.
* `fileno`: OS file handle to use instead of `path` (the file must be opened
	with compatibile access permissions).
	* if neither `path` nor `fileno` is given, the system's swap file is mapped.
* `access`: can be either:
	* '' (read-only, default)
	* 'w' (read + write)
	* 'c' (read + copy-on-write)
	* 'x' (read + execute)
	* 'wx' (read + write + execute)
	* 'cx' (read + copy-on-write + execute)
* `size`: the size of the memory segment (optional, defaults to file size).
	* if size is given it must be > 0 or an error is raised.
	* if size is not given, the file size is assumed.
		* if the file is empty the mapping fails with 'file_too_short' error.
	* if the file doesn't exist:
		* if write access is given, the file is created.
		* if write access is not given, the mapping fails with 'no_file' error.
	* if the file is shorter than the required offset + size:
		* if write access is not given (or the file is the pagefile which
		can't be resized), the mapping fails with 'file_too_short' error.
		* if write access is given, the file is extended to size.
			* if the disk is full, the mapping fails with 'disk_full' error.
* `offset`: offset in the file (optional, defaults to 0).
	* if given, the offset must be >= 0 or an error is raised.
	* the offset must be aligned to a page boundary or an error is raised.
* `name`: name of the memory map: using the same name in two processes gives
access to the same memory.
* `addr`: address to use (optional).
* `close_file` - optional, default: true if `path` given, false if `fileno` given.
* `remove_file` - optional, default: false.

Returns an object (a table) with the fields:

* `map.addr` - `void*` pointer to the mapped memory
* `map.size` - actual size of the memory block
* `map:free()` - method to free the memory and associated resources
* `map:flush([addr, size])` - flush (a part of) the mapping to disk
* `map.fileno` - OS file handle
* `map.close_file` - true means close the file on `map:free()`
* `map.remove_file` - true means remove the file on `map:free()`

If the mapping fails for know causes, then `nil, error_message, error_code`
is returned, where error_code can be:

* 'no_file' - file not found.
* 'file_too_short' - the file is shorter than the required size.
* 'disk_full' - the file cannot be extended because the disk is full.
* 'out_of_mem' - size too large
* 'invalid_address' - cannot map the file at the given address.
* 'invalid_offset' - offset not aligned to page boundary.

For other error conditions an OS-specific error code is returned instead.

Attempting to write to a memory block that wasn't mapped with write or
copy-on-write access results in access violation (which means a crash
since access violations are not caught by default).

If an opened file is given (`fileno` arg) then write buffers are flushed
before mapping the file.


### `mmap.mirror(t) -> map | nil, errmsg, errcode`

Make a mirrored memory mapping to use with a [ring buffer][lfrb].
The `t` arg is a table with the fields:

* `path` or `fileno`: the file to map: required (the access is 'w').
* `size`: the size of the memory segment: required, automatically aligned to page size.
* `times`: how many times to mirror the segment (optional, default: 2)
* `addr`: address to use (optional).

The result is a table with `addr` and `size` fields and all the mirror map
objects in its array part (freeing the mirror will free all the maps).
The memory block at `addr` is mirrored such that
`(char*)addr[o1*i] == (char*)addr[o2*i]` for any `o1` and `o2` in
`0..times-1` and for any `i` in `0..size-1`.

### `mmap.pagesize() -> bytes`

Get the current page size. Mapped memory is multiple of this size.
