---
tagline: portable memory mapping
---

<warn>Work in progress</warn>

* TODO: offset + size -> invalid arg
* TODO: map:access(newaccess) to change access flags after mapping.
* TODO: test flush() with invalid address and/or size (clamp them?)
* TODO: test exec flag
* TODO: allow file descriptors on Windows too (why not?)
* TODO: `mmap.mirror(file,size,times,addr)` version
* TODO: huge page support? is this portable? does it require root?

## `local mmap = require'mmap'`

Memory mapping API that can be used with Windows, Linux and OSX.

Features:

  * file-backed and pagefile-backed (anonymous) memory maps
  * read-only, read/write and copy-on-write access modes plus executable flag
  * name-tagged memory maps for sharing memory between processes
  * mirrored memory maps for using with [lock-free ring buffers][lfrb]
  * synchronous and asynchronous flushing
  * works with filenames, file objects, file descriptors and OS file handles.


## API

----------------------------------------------------------------------------------------------
`mmap.map(args_t) -> map | nil,errmsg,errcode` \
`mmap.map(file, access, size, offset, addr, name) -> map | nil, errmsg, errcode` \
create a memory mapping

`map.addr` \
a `void*` pointer to the mapped address

`map.size` \
the byte size of the mapped block

`map:flush([wait, ][addr, size]) -> true | nil, errmsg, errcode` \
flush (parts of) the mapping to disk

`map:free()` \
release the memory and associated resources

`mmap.mirror(args_t) -> map | nil, errmsg, errcode` \
`mmap.mirror(file, size[, times[, addr]]) -> map | nil, errmsg, errcode` \
create a mirrored memory mapping

`mmap.pagesize() -> bytes` \
allocation granularity

`mmap.aligned_size(bytes[, dir]) -> bytes` \
next/prev page-aligned size

`mmap.aligned_addr(ptr[, dir]) -> ptr` \
next/prev page-aligned address

`mmap.filesize(file) -> size | nil, errmsg, errcode` \
get file size

`mmap.filesize(file, size) -> size | nil,errmsg,errcode` \
(create file and) set file size
----------------------------------------------------------------------------------------------


------------------------------------------------- --------------------------------------------
`mmap.map(args_t) -> map | nil,errmsg,errcode`    create a mapping

`mmap.map(file, access, size, offset,` \          create a mapping
`addr, name) -> map | nil,errmsg,errcode`

`map.addr`                                        a `void*` pointer to the mapped address

`map.size`                                        the byte size of the mapped block

`map:flush([wait, ][addr, size])` \               flush (parts of) the mapping to disk
`-> true | nil,errmsg,errcode`

`map:free()`                                      release the memory and associated resources

`mmap.mirror(args_t)` \                           create a mirrored memory mapping
`-> map | nil,errmsg,errcode`

`mmap.mirror(file, size[, times[, addr]])` \      create a mirrored memory mapping
`-> map | nil,errmsg,errcode`

`mmap.pagesize() -> bytes`                        allocation granularity

`mmap.aligned_size(bytes[, dir]) -> bytes`        next/prev page-aligned size

`mmap.aligned_addr(ptr[, dir]) -> ptr`            next/prev page-aligned address

`mmap.filesize(file)` \                           get file size
`-> size | nil,errmsg,errcode`

`mmap.filesize(file, size)` \                     (create file and) set file size
`-> size | nil,errmsg,errcode`
------------------------------------------------- --------------------------------------------

### `mmap.map(args_t) -> map | nil, errmsg, errcode` <br> `mmap.map(file, access, size, offset, addr, name)` <br> `-> map | nil, errmsg, errcode`

Create a memory map object. Args:

* `file`: the file to map: optional; if nil, a portion of the system pagefile
will be mapped instead; it can be:
	* a utf8 string representing a filename to open.
	* a `FILE*` object opened in a compatible mode.
		* NOTE: `io.open()` files are `FILE*` objects.
	* a Unix file descriptor opened in a compatible mode.
	* a Windows HANDLE opened in a compatible mode.
* `access`: can be either:
	* '' (read-only, default)
	* 'w' (read + write)
	* 'c' (read + copy-on-write)
	* 'x' (read + execute)
	* 'wx' (read + write + execute)
	* 'cx' (read + copy-on-write + execute)
* `size`: the size of the memory segment (optional, defaults to file size).
	* if given it must be > 0 or an error is raised.
	* if not given, the file size is assumed.
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
	* if given, must be >= 0 or an error is raised.
	* must be aligned to a page boundary or an error is raised.
	* ignored when mapping the pagefile.
* `name`: name of the memory map (optional): using the same name in two
different processes (or in the same process) gives access to the same memory.
* `addr`: address to use (optional; an error is raised if zero).

Returns an object (a table) with the fields:

	* `map.addr` - a `void*` pointer to the mapped memory
	* `map.size` - the actual size of the memory block

If the mapping fails, returns `nil,errmsg,errcode` where `errcode` can be:

* `'no_file'` - file not found.
* `'file_too_short'` - the file is shorter than the required size.
* `'disk_full'` - the file cannot be extended because the disk is full.
* `'out_of_mem'` - size or address too large.
* `'invalid_address'` - specified address in use.
* an OS-specific numeric error code.

#### NOTE

* write buffers are flushed before mapping an already-opened file.
* attempting to write to a memory block that wasn't mapped with write
or copy-on-write access results in a crash.
* changes done externally to a mapped file may not be visible immediately
(or at all) to the mapped memory.
* access to shared memory from multiple processes must be synchronized.


### `map:free()`

Free the memory and all associated resources and close the file
if it was opened by `mmap.map()`.


### `map:flush([wait, ][addr, size]) -> true | nil,errmsg,errcode`

Flush (part of) the memory to disk. If the address is not aligned,
it will be automatically aligned to the left. If `wait` is true,
wait until the data has been written to disk.


### `mmap.mirror(args_t) -> map | nil, errmsg, errcode` <br> `mmap.mirror(file, size[, times[, addr]]) -> map | nil, errmsg, errcode`

Create a mirrored memory mapping to use with a [lock-free ring buffer][lfrb].
Args:

* `file`: the file to map: required (the access is 'w').
* `size`: the size of the memory segment: required, automatically aligned
to the next page size.
* `times`: how many times to mirror the segment (optional, default: 2)
* `addr`: address to use (optional).

The result is a table with `addr` and `size` fields and all the mirror map
objects in its array part (freeing the mirror will free all the maps).
The memory block at `addr` is mirrored such that
`(char*)addr[o1*i] == (char*)addr[o2*i]` for any `o1` and `o2` in
`0..times-1` and for any `i` in `0..size-1`.


### `mmap.aligned_size(bytes[, dir]) -> bytes`

Get the next (dir = 'right', default) or previous (dir = 'left') size that is
aligned to a page boundary. It can be used to align offsets and sizes.


### `mmap.aligned_addr(ptr[, dir]) -> ptr`

Get the next (dir = 'right', default) or previous (dir = 'left') address that
is aligned to a page boundary. It can be used to align pointers.


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

__NOTE:__ Do not try to set the file size while the file is mapped.
Unmap it first, set the size, then map it back.
