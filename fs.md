---
tagline: portable filesystem support
---

<warn>Memory mapping is not finished yet!</warn>

## `local fs = require'fs'`

Filesystem API for Windows, Linux and OSX. Features:

  * utf8 filenames on all platforms
  * symlinks and hard links on all platforms
  * memory mapping on all platforms
  * unified error codes for recoverable error cases
  * cdata buffer-based I/O
  * platform-specific extra-functionality fully exposed

## API

------------------------------------------------- -------------------------------------------------
__file objects__
`fs.open(path[, mode|opt]) -> f`                  open file
`f:close()`                                       close file
`f:closed() -> true|false`                        check if file is closed
`fs.isfile(f) -> true|false`                      check if `f` is a file object
`f.handle -> HANDLE`                              Windows HANDLE (Windows platforms)
`f.fd -> fd`                                      POSIX file descriptor (POSIX platforms)
__stdio streams__
`f:stream(mode) -> fs`                            open a `FILE*` object from a file
`fs:close()`                                      close the `FILE*` object
__file i/o__
`f:read(buf, len) -> readlen`                     read data from file
`f:write(buf, len) -> writelen`                   write data to file
`f:flush()`                                       flush buffers
`f:seek([whence] [, offset]) -> pos`              get/set the file pointer
`f:truncate([opt])`                               truncate file to current file pointer
`f:buffered_read([ctype], [bufsize]) -> read()`   get a buffered read function
__open file attributes__
`f:attr([attr]) -> val|t`                         get/set attribute(s) of open file
__directory listing__
`fs.dir(dir, [dot_dirs]) -> d, next`              directory contents iterator
`d:next() -> name, d`                             call the iterator explicitly
`d:close()`                                       close iterator
`d:closed() -> true|false`                        check if iterator is closed
`d:name() -> s`                                   dir entry's name
`d:dir() -> s`                                    dir that was passed to `fs.dir()`
`d:path() -> s`                                   full path of the dir entry
`d:attr([attr, ][deref]) -> t|val`                get/set dir entry attribute(s)
`d:is(type, [deref]) -> true|false`               check if dir entry is of type
__file attributes__
`fs.attr(path, [attr, ][deref]) -> t|val`         get/set file attribute(s)
`fs.is(path, [type], [deref]) -> true|false`      check if file exists or is of a certain type
__filesystem operations__
`fs.mkdir(path, [recursive], [perms])`            make directory
`fs.cd([path]) -> path`                           get/set current directory
`fs.remove(path, [recursive])`                    remove file or directory (recursively)
`fs.move(path, newpath, [opt])`                   rename/move file on the same filesystem
__symlinks & hardlinks__
`fs.mksymlink(symlink, path, is_dir)`             create a symbolic link for a file or dir
`fs.mkhardlink(hardlink, path)`                   create a hard link for a file
`fs.readlink(path) -> path`                       dereference a symlink recursively
__common paths__
`fs.homedir() -> path`                            get current user's home directory
`fs.tmpdir() -> path`                             get temporary directory
`fs.exedir() -> path`                             get the directory of the running executable
__low level__
`fs.wrap_handle(HANDLE) -> f`                     wrap opened HANDLE (Windows)
`fs.wrap_fd(fd) -> f`                             wrap opened file descriptor
`fs.wrap_file(FILE*) -> f`                        wrap opened `FILE*` object
`fs.fileno(FILE*) -> fd`                          get stream's file descriptor
__memory mapping__
`fs.map(...) -> map`                              create a memory mapping
`map.addr`                                        a `void*` pointer to the mapped memory
`map.size`                                        size of the mapped memory in bytes
`map:flush([async, ][addr, size])`                flush (parts of) the mapping to disk
`map:free()`                                      release the memory and associated resources
`fs.unlink_mapfile(tagname)` \                    remove the shared memory file from disk (Linux, OSX)
`map:unlink()`
`fs.mirror_map(...) -> map`                       create a mirrored memory mapping
`fs.pagesize() -> bytes`                          get allocation granularity
`fs.aligned_size(bytes[, dir]) -> bytes`          next/prev page-aligned size
`fs.aligned_addr(ptr[, dir]) -> ptr`              next/prev page-aligned address
------------------------------------------------- -------------------------------------------------

__NOTE:__ The `deref` arg is `true` by default, meaning that by default,
symlinks are followed recursively and transparently where this option is
available.

__NOTE:__ All functions can fail, in which case they return
`nil, error_message, error_code`. Functions which are listed as having no
return value actually return `true` for indicating success. Some error
messages are normalized, eg. `not_found` (see full list below).

## File attributes

__name__         __win__ __osx__ __linux__ __description__
---------------- ------- ------- --------- ---------------------------------------
`type         `  r       r       r         file type (see below)
`size         `  r       r       r         file size
`atime        `  rw      rw      rw        last access time (seldom correct)
`mtime        `  rw      rw      rw        last contents-change time
`btime        `  rw      r                 creation (aka "birth") time
`ctime        `  rw      r       r         last metadata-or-contents-change time
`target       `  r       r       r         symlink's target (nil if not symlink)
`dosname      `  r                         8.3 filename (Windows)
`archive      `  rw                        archive bit (for backup programs)
`hidden       `  rw                        hidden bit (don't show in Explorer)
`readonly     `  rw                        read-only bit (can't open in write mode)
`system       `  rw                        system bit
`temporary    `  rw                        writes need not be commited to storage
`not_indexed  `  rw                        exclude from indexing
`sparse_file  `  r                         file is sparse
`reparse_point`  r                         has a reparse point or is a symlink
`compressed   `  r                         file is compressed
`encrypted    `  r                         file is encrypted
`perms        `          rw      rw        permissions
`uid          `          rw      rw        user id
`gid          `          rw      rw        group id
`dev          `          r       r         device id containing the file
`inode        `          r       r         inode number (int64_t)
`volume       `  r                         volume serial number
`id           `  r                         file id (int64_t)
`nlink        `  r       r       r         number of hard links
`rdev         `          r       r         device id (if special file)
`blksize      `          r       r         block size for I/O
`blocks       `          r       r         number of 512B blocks allocated

On the table above, `r` means that the attribute is read/only and `rw` means
that the attribute can be changed. Attributes can be queried and changed
from different contexts via `f:attr()`, `fs.attr()` and `d:attr()`.

__NOTE__: File sizes and offsets are Lua numbers not 64bit ints, so they can
hold at most 8KTB. This will change when that becomes a problem.

## File types

__name__       __win__ __osx__ __linux__ __description__
-------------- ------- ------- --------- ---------------------------------------
`file`         *       *       *         file is a regular file
`dir`          *       *       *         file is a directory
`symlink`      *       *       *         file is a symlink
`dev`          *                         file is a Windows device
`blockdev`             *       *         file is a block device
`chardev`              *       *         file is a character device
`pipe`                 *       *         file is a pipe
`socket`               *       *         file is a socket
`unknown`              *       *         file type unknown


## Normalized error messages

__message__          __description__
-------------------- -----------------------------------------------------------
`not_found`          file/dir/path not found
`access_denied`      access denied
`already_exists`     file/dir already exists
`not_empty`          dir not empty (eg. for remove())
`io_error`           I/O error
`disk_full`          no space left on device
-------------------- -----------------------------------------------------------


## File Objects

### `fs.open(path[, mode|opt]) -> f`

Open/create a file for reading and/or writing. The second arg can be a string:

------- ------------------------------------------------------------------------
`r`     open; allow reading only (default)
`w`     open and truncate or create; allow writing only
`r+`    open or create; allow reading and writing
`w+`    open and trucate or create; allow reading and writing
------- ------------------------------------------------------------------------

... or an options table with platform-specific options which represent
OR-ed bitmask flags which must be given either as `'foo bar ...'`,
`{foo=true, bar=true}` or `{'foo', 'bar'}`, eg. `{sharing = 'read write'}`
sets the `dwShareMode` argument of `CreateFile()` to
`FILE_SHARE_READ | FILE_SHARE_WRITE` on Windows.
All fields and flags are documented in the code.

__field__      __OS__     __reference__                              __default__
-------------- ---------- ------------------------------------------ ------------------
`access      ` Windows    `CreateFile() / dwDesiredAccess`           `'file_read'`
`sharing     ` Windows    `CreateFile() / dwShareMode`               `'file_read'`
`creation    ` Windows    `CreateFile() / dwCreationDisposition`     `'open_existing'`
`attrs       ` Windows    `CreateFile() / dwFlagsAndAttributes`      `''`
`flags       ` Windows    `CreateFile() / dwFlagsAndAttributes`      `''`
`flags       ` Linux, OSX `open() / flags`                           `'rdonly'`
`mode        ` Linux, OSX `octal or symbolic perms`                  `'0666'` / `'rwx'`
-------------- ---------- ------------------------------------------ ------------------

The `mode` arg is passed to [unixperms.parse()][unixperms].

### `f:close()`

Close file.

### `f:closed() -> true|false`

Check if file is closed.

### `fs.isfile(f) -> true|false`

Check if `f` is a file object.


## Stdio Streams

### `f:stream(mode) -> fs`

Open a `FILE*` object from a file. The file should not be used anymore
and `fs:close()` should be called to close the file.

### `fs:close()`

Close the `FILE*` object and the underlying file object.


## File I/O

### `f:read(buf, len) -> readlen`

Read data from file.

### `f:write(buf, len) -> writelen`

Write data to file.

### `f:flush()`

Flush buffers.

### `f:seek([whence] [, offset]) -> pos`

Get/set the file pointer. Same semantics as standard `io` module seek
i.e. `whence` defaults to `'cur'` and `offset` defaults to `0`.

### `f:truncate([opt])`

Truncate file to current file pointer.

`opt` is an optional string for Linux which can contain any combination of
the words `fallocate` (call `fallocate()`), `emulate` (fill the file with
zeroes if the filesystem doesn't support `fallocate()`), and `fail` (do not
call `ftruncate()` if `fallocate()` fails: return the error `'not_supported'`
instead). The problem with calling `ftruncate()` if `fallocate()` fails is
that on most filesystems that creates a sparse file, hence the `fail` option.
The default is `'fallocate emulate'` which should never create a sparse file.

### `f:buffered_read([ctype], [bufsize]) -> read()`

Returns a `read(buf, sz) -> sz` function which reads ahead from file. The
optional `ctype` and `bufsize` specify the buffer's C type and size and
default to `char` and `4096` respectively.

## Open file attributes

### `f:attr([attr]) -> val|t`

Get/set attribute(s) of open file. `attr` can be:

  * nothing/nil: get the values of all attributes in a table.
  * string: get the value of a single attribute.
  * table: set some attributes.


## Directory listing

### `fs.dir([dir], [dot_dirs]) -> d, next`

Directory contents iterator. `dir` defaults to `'.'`. `dot_dirs=true` means
include `.` and `..` entries (default is to exclude them).

Usage:

~~~{.lua}
for name, d in fs.dir() do
	if not name then
		print('error: ', d)
		break
	end
	print(d:attr'type', name)
end
~~~

Always include the `if not name` condition when iterating. The iterator
doesn't raise any errors. Instead it returns `false, err, errcode` as the
last iteration when encountering an error. Initial errors from calling
`fs.dir()` (eg. `'not_found'`) are passed to the iterator also, so the
iterator must be called at least once to see them.

### `d:next() -> name, d | false, err, errcode | nil`

Call the iterator explicitly.

### `d:close()`

Close the iterator. Always call `d:close()` before breaking the for loop!

### `d:closed() -> true|false`

Check if the iterator is closed.

### `d:name() -> s`

The name of the current file or directory being iterated.

### `d:dir() -> s`

The directory that was passed to `fs.dir()`.

### `d:path() -> s`

The full path of the current dir entry (`d:dir()` combined with `d:name()`).

### `d:attr([attr, ][deref]) -> t|val`

Get/set dir entry attribute(s).

`deref` means return the attribute(s) of the symlink's target if the file is
a symlink (`deref` defaults to `true`!). When `deref=true`, even the `'type'`
attribute is the type of the target, so it will never be `'symlink'`.

Some attributes for directory entries are free to get (but not for symlinks
when `deref=true`) meaning that they don't require a system call for each
file, notably `type` on all platforms, `atime`, `mtime`, `btime`, `size`
and `dosname` on Windows and `inode` on Linux and OSX.

### `d:is(type, [deref]) -> true|false`

Check if dir entry is of type.


## File attributes

### `fs.attr(path, [attr, ][deref]) -> t|val`

Get/set a file's attribute(s) given its path in utf8.

### `fs.is(path, [type], [deref]) -> true|false`

Check if file exists or if it is of a certain type.


## Filesystem operations

### `fs.mkdir(path, [recursive], [perms])`

Make directory. `perms` can be a number or a string passed to
[unixperms.parse()][unixperms].

### `fs.cd([path]) -> path`

Get/set current directory.

### `fs.remove(path, [recursive])`

Remove a file or directory (recursively if `recursive=true`).

### `fs.move(path, newpath, [opt])`

Rename/move a file on the same filesystem. On Windows, `opt` represents
the `MOVEFILE_*` flags and defaults to `'replace_existing write_through'`.

This operation is atomic on all platforms.

## Symlinks & hardlinks

### `fs.mksymlink(symlink, path, is_dir)`

Create a symbolic link for a file or dir. The `is_dir` arg is required
for Windows for creating symlinks to directories. It's ignored on Linux
and OSX.

### `fs.mkhardlink(hardlink, path)`

Create a hard link for a file.

### `fs.readlink(path) -> path`

Dereference a symlink recursively. The result can be an absolute or
relative path which can be valid or not.


## Common paths

### `fs.homedir() -> path`

Get current user's home directory.

### `fs.tmpdir() -> path`

Get temporary directory.

### `fs.exedir() -> path`

Get the directory of the running executable.


## Low level

### `fs.wrap_handle(HANDLE) -> f`

Wrap opened HANDLE (Windows) (not tied to gc).

### `fs.wrap_fd(fd) -> f`

Wrap opened file descriptor (not tied to gc).

### `fs.wrap_file(FILE*) -> f`

Wrap opened `FILE*` object (not tied to gc).

### `fs.fileno(FILE*) -> fd`

Get a stdio stream's file descriptor.


## Memory Mapping

Features:

  * file-backed and pagefile-backed (anonymous) memory maps
  * read-only, read/write and copy-on-write access modes plus executable flag
  * name-tagged memory maps for sharing memory between processes
  * mirrored memory maps for using with [lock-free ring buffers][lfrb]
  * synchronous and asynchronous flushing

Limitations:

  * I/O errors from accessing mmapped memory cause a crash.

### `fs.map(args_t) -> map` <br> `fs.map(path, [access], [size], [offset], [addr], [tagname]) -> map` <br> `f:map([access], [size], [offset], [addr])`

Create a memory map object. Args:

* `path`: the file to map: optional; if nil, a portion of the system pagefile
will be mapped instead.
* `access`: can be either:
	* '' (read-only, default)
	* 'w' (read + write)
	* 'c' (read + copy-on-write)
	* 'x' (read + execute)
	* 'wx' (read + write + execute)
	* 'cx' (read + copy-on-write + execute)
* `size`: the size of the memory segment (optional, defaults to file size).
	* if given it must be > 0 or an error is raised.
	* if not given, file size is assumed.
		* if the file size is zero the mapping fails with `'file_too_short'`.
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
* `addr`: address to use (optional; an error is raised if zero).
* `tagname`: name of the memory map (optional; cannot be used with `file`;
must not contain slashes or backslashes): using the same name in two
different processes (or in the same process) gives access to the same memory.

Returns an object with the fields:

* `addr` - a `void*` pointer to the mapped memory
* `size` - the actual size of the memory block

If the mapping fails, returns `nil,err,errcode` where `errcode` can be:

* `'no_file'` - file not found.
* `'file_too_short'` - the file is shorter than the required size.
* `'disk_full'` - the file cannot be extended because the disk is full.
* `'out_of_mem'` - size or address too large or specified address in use.
* an OS-specific numeric error code.

#### NOTE:

* when mapping or resizing a `FILE` that was written to, the write buffers
should be flushed first.
* after mapping an opened file handle of any kind, that file handle should
not be used anymore except to close it after the mapping is freed.
* attempting to write to a memory block that wasn't mapped with write
or copy-on-write access results in a crash.
* changes done externally to a mapped file may not be visible immediately
(or at all) to the mapped memory.
* access to shared memory from multiple processes must be synchronized.

### `map:free()`

Free the memory and all associated resources and close the file
if it was opened by `fs.map()`.

### `map:flush([async, ][addr, size]) -> true | nil,err,errcode`

Flush (part of) the memory to disk. If the address is not aligned,
it will be automatically aligned to the left. If `async` is true,
perform the operation asynchronously and return immediately.

### `fs.unlink_mapfile(tagname)` <br> `map:unlink()`

Remove a (the) shared memory file from disk. When creating a shared memory
mapping using a tagname, a file is created on the filesystem on Linux
and OS X (not so on Windows). That file must be removed manually when it is
no longer needed. This can be done anytime, even while mappings are open and
will not affect said mappings.

### `fs.mirror_map(args_t) -> map` <br> `fs.mirror_map(file, size[, times[, addr]]) -> map`

Create a mirrored memory mapping to use with a [lock-free ring buffer][lfrb].

Args:

  * `file`: the file to map: required (the access is 'w').
  * `size`: the size of the memory segment: required, automatically aligned
  to the next page size.
  * `times`: how many times to mirror the segment (optional, default: 2)
  * `addr`: address to use (optional; can be anything convertible to `void*`).

The result is a table with `addr` and `size` fields and all the mirror map
objects in its array part (freeing the mirror will free all the maps).
The memory block at `addr` is mirrored such that
`(char*)addr[o1*i] == (char*)addr[o2*i]` for any `o1` and `o2` in
`0..times-1` and for any `i` in `0..size-1`.

### `fs.aligned_size(bytes[, dir]) -> bytes`

Get the next larger (dir = 'right', default) or smaller (dir = 'left') size
that is aligned to a page boundary. It can be used to align offsets and sizes.

### `fs.aligned_addr(ptr[, dir]) -> ptr`

Get the next (dir = 'right', default) or previous (dir = 'left') address that
is aligned to a page boundary. It can be used to align pointers.

### `fs.pagesize() -> bytes`

Get the current page size. Memory will always be allocated in multiples
of this size and file offsets must be aligned to this size too.


## Programming Notes

### Filesystem operations are non-atomic

Most filesystem operations are non-atomic (unless otherwise specified) and
thus prone to race conditions. This library makes no attempt at fixing that
and in fact it ignores the issue entirely in order to provide a simpler API.
For instance, in order to change _only_ the "archive" bit of a file on
Windows, the file attribute bits need to be read first (because WinAPI doesn't
take a mask there). That's a TOCTTOU. Resolving a symlink or removing a
directory recursively in userspace has similar issues. So never work on the
(same part of the) filesystem from multiple processes without proper locking
(watch Niall Douglas's "Racing The File System" presentation for more info).

### Flushing does not protect against power loss

Flushing does not protect against power loss on consumer hard drives because
they usually don't have non-volatile write caches (and disabling the write
cache is generally not possible nor feasible). Also, most Linux distros do
not mount ext3 filesystems with the "barrier=1" option by default which means
no power loss protection there either, even when the hardware works right.

### File locking doesn't always work

File locking APIs only work right on disk mounts and are buggy or non-existent
on network mounts (NFS, Samba).
