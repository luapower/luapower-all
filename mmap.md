---
tagline: portable memory mapping
---

<warn>Work in progress</warn>

* TODO: offset + size -> invalid arg
* TODO: change access flags after opening (eg. replace 'w' with 'x')
* `mmap.mirror(file,...)` version
* `filesize(file, size)` error tests
*

## `local mmap = require'mmap'`

Memory mapping API that can be used with Windows, Linux and OSX.
Can be used for:

  * loading large files in memory without consuming memory
  * allocating large memory blocks backed by the swap file
  * sharing memory between processes
  * creating executable memory segments
  * creating mirrored segments (ring buffers)


## API

------------------------------------------------- --------------------------------------------
`mmap.map(t) -> map | nil,errmsg,errcode`         create a mapping

`mmap.map(file, access, size, offset,` \          create a mapping
`addr, name) -> map | nil,errmsg,errcode`

`map:flush([wait, ][addr, size])` \               flush (parts of) the mapping to disk
`-> true | nil,errmsg,errcode`

`map.addr`                                        a `void*` pointer to the mapped address

`map.size`                                        the byte size of the mapped block

`map.fileno`                                      the OS file handle

`map:free()`                                      release the memory and associated resources

`mmap.mirror(t) -> map | nil,errmsg,errcode`      create a mirrored memory mapping

`mmap.aligned_size(bytes) -> bytes`               next page-aligned size

`mmap.pagesize() -> bytes`                        allocation granularity

`mmap.filesize(file)`                             get file size
`-> size | nil,errmsg,errcode`

`mmap.filesize(file, size)`                       (create file and) set file size
`-> size | nil,errmsg,errcode`
------------------------------------------------- --------------------------------------------

### `mmap.map(t) -> map | nil, errmsg, errcode` <br> `mmap.map(file, access, size, offset, addr, name)` <br> `-> map | nil, errmsg, errcode`

Create a memory map object. The `t` arg is a table with the fields:

* `file`: the file to map: optional; if not given, a portion of the system
page file is mapped instead; it can be:
	* a string representing a filename to open.
	* a `FILE*` object opened in a compatible mode.
	* an OS file handle opened in a compatible mode.
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
		* if the file is empty the mapping fails with `'file_too_short'` error.
	* if the file doesn't exist:
		* if write access is given, the file is created.
		* if write access is not given, the mapping fails with `'no_file'` error.
	* if the file is shorter than the required offset + size:
		* if write access is not given (or the file is the pagefile which
		can't be resized), the mapping fails with `'file_too_short'` error.
		* if write access is given, the file is extended.
			* if the disk is full, the mapping fails with `'disk_full'` error.
* `offset`: offset in the file (optional, defaults to 0).
	* if given, the offset must be >= 0 or an error is raised.
	* the offset must be aligned to a page boundary or an error is raised.
* `name`: name of the memory map: using the same name in two processes gives
access to the same memory.
* `addr`: address to use (optional; an error is raised if zero).

Returns an object (a table) with the fields:

* `map.addr` - a `void*` pointer to the mapped memory
* `map.size` - the actual size of the memory block
* `map.fileno` - the OS file handle
* `map.close_file` - a read-only flag which if true, the file will be closed
on `map:free()`.

If the mapping fails, returns `nil,errmsg,errcode` where `errcode` can be:

* `'no_file'` - file not found.
* `'file_too_short'` - the file is shorter than the required size.
* `'disk_full'` - the file cannot be extended because the disk is full.
* `'out_of_mem'` - size or address too large.
* `'invalid_address'` - specified address in use.
* an OS-specific numeric error code.

Attempting to write to a memory block that wasn't mapped with write or
copy-on-write access results in access violation (which means a crash
since access violations are not caught by default).

If an opened file is given (`fileno` arg) then the write buffers are flushed
before mapping the file.


### `map:free()`

Free the memory and all associated resources and close the file
if it was opened by `mmap.map()`.


### `map:flush([wait, ][addr, size]) -> true | nil,errmsg,errcode`

Flush (part of) the memory to disk.
If `wait` is true, wait until the data has been written to disk.


### `mmap.mirror(t) -> map | nil, errmsg, errcode`

Make a mirrored memory mapping to use with a [ring buffer][lfrb].
The `t` arg is a table with the fields:

* `file`: the file to map: required (the access is 'w').
* `size`: the size of the memory segment: required, automatically aligned
to page size.
* `times`: how many times to mirror the segment (optional, default: 2)
* `addr`: address to use (optional).

The result is a table with `addr` and `size` fields and all the mirror map
objects in its array part (freeing the mirror will free all the maps).
The memory block at `addr` is mirrored such that
`(char*)addr[o1*i] == (char*)addr[o2*i]` for any `o1` and `o2` in
`0..times-1` and for any `i` in `0..size-1`.


### `mmap.aligned_size(bytes) -> bytes`

Get the next larger size that is aligned to a page boundary.
It can be used to align offsets and to specify sizes.


### `mmap.pagesize() -> bytes`

Get the current page size. Memory will always be allocated in multiples
of this size and file offsets must be aligned to this size too.


### `mmap.filesize(file) -> size | nil,errmsg,errcode`

Get file size. Can fail with `'not_found'` or an OS specific error code.


### `mmap.filesize(file, size) -> size | nil,errmsg,errcode`

Enlarge or truncate a file to a specific size. If the file does not exist
it is created. Can fail with `'disk_full'` or an OS specific error code.
When enlarging, the appended data is undefined. When truncating, the data
up to the specified size is preserved.
