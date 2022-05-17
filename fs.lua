--[=[

	Portable filesystem API (Windows, Linux and OSX).
	Written by Cosmin Apreutesei. Public Domain.

FEATURES
  * utf8 filenames on all platforms
  * symlinks and hard links on all platforms
  * memory mapping on all platforms
  * some error code unification for common error cases
  * cdata buffer-based I/O
  * platform-specific functionality exposed

FILE OBJECTS
	fs.open(path[, mode|opt]) -> f                open file
	f:close()                                     close file
	f:closed() -> true|false                      check if file is closed
	fs.isfile(f) -> true|false                    check if f is a file object
	f.handle -> HANDLE                            Windows HANDLE (Windows platforms)
	f.fd -> fd                                    POSIX file descriptor (POSIX platforms)
PIPES
	fs.pipe() -> rf, wf                           create an anonymous pipe
	fs.pipe({path=,<opt>=} | path[,options]) -> pf   create a named pipe (Windows)
	fs.pipe({path=,mode=} | path[,mode]) -> true  create a named pipe (POSIX)
STDIO STREAMS
	f:stream(mode) -> fs                          open a FILE* object from a file
	fs:close()                                    close the FILE* object
MEMORY STREAMS
	fs.open_buffer(buf, [size], [mode]) -> f      create a memory stream
FILE I/O
	f:read(buf, len) -> readlen                   read data from file
	f:readn(buf, n) -> true                       read exactly n bytes
	f:readall() -> buf, len                       read until EOF into a buffer
	f:write(s | buf,len) -> true                  write data to file
	f:flush()                                     flush buffers
	f:seek([whence] [, offset]) -> pos            get/set the file pointer
	f:truncate([opt])                             truncate file to current file pointer
	f:buffered_read([bufsize]) -> read(buf, sz)   get a buffered read function
OPEN FILE ATTRIBUTES
	f:attr([attr]) -> val|t                       get/set attribute(s) of open file
DIRECTORY LISTING
	fs.dir(dir, [dot_dirs]) -> d, next            directory contents iterator
	d:next() -> name, d                           call the iterator explicitly
	d:close()                                     close iterator
	d:closed() -> true|false                      check if iterator is closed
	d:name() -> s                                 dir entry's name
	d:dir() -> s                                  dir that was passed to fs.dir()
	d:path() -> s                                 full path of the dir entry
	d:attr([attr, ][deref]) -> t|val              get/set dir entry attribute(s)
	d:is(type, [deref]) -> t|f                    check if dir entry is of type
FILE ATTRIBUTES
	fs.attr(path, [attr, ][deref]) -> t|val       get/set file attribute(s)
	fs.is(path, [type], [deref]) -> t|f           check if file exists or is of a certain type
FILESYSTEM OPS
	fs.mkdir(path, [recursive], [perms])          make directory
	fs.cwd([path]) -> path                        get/set current working directory
	fs.cd([path]) -> path                         get/set current working directory
	fs.remove(path, [recursive])                  remove file or directory (recursively)
	fs.move(path, newpath, [opt])                 rename/move file on the same filesystem
SYMLINKS & HARDLINKS
	fs.mksymlink(symlink, path, is_dir)           create a symbolic link for a file or dir
	fs.mkhardlink(hardlink, path)                 create a hard link for a file
	fs.readlink(path) -> path                     dereference a symlink recursively
COMMON PATHS
	fs.homedir() -> path                          get current user's home directory
	fs.tmpdir() -> path                           get temporary directory
	fs.exepath() -> path                          get the full path of the running executable
	fs.exedir() -> path                           get the directory of the running executable
	fs.scriptdir() -> path                        get the directory of the main script
LOW LEVEL
	fs.wrap_handle(HANDLE) -> f                   wrap opened HANDLE (Windows)
	fs.wrap_fd(fd) -> f                           wrap opened file descriptor
	fs.wrap_file(FILE*) -> f                      wrap opened FILE* object
	fs.fileno(FILE*) -> fd                        get stream's file descriptor
MEMORY MAPPING
	fs.map(...) -> map                            create a memory mapping
	f:map([offset],[size],[addr],[access]) -> map   create a memory mapping
	map.addr                                      a void* pointer to the mapped memory
	map.size                                      size of the mapped memory in bytes
	map:flush([async, ][addr, size])              flush (parts of) the mapping to disk
	map:free()                                    release the memory and associated resources
	fs.unlink_mapfile(tagname)                    remove the shared memory file from disk (Linux, OSX)
	map:unlink()
	fs.mirror_buffer([size], [addr]) -> map       create a mirrored memory-mapped ring buffer
	fs.pagesize() -> bytes                        get allocation granularity
	fs.aligned_size(bytes[, dir]) -> bytes        next/prev page-aligned size
	fs.aligned_addr(ptr[, dir]) -> ptr            next/prev page-aligned address

The `deref` arg is true by default, meaning that by default, symlinks are
followed recursively and transparently where this option is available.

All functions raise on user error and unrecoverable OS error, but return
`nil,err` on recoverable failure. Functions which are listed as having no
return value actually return true for indicating success. Recoverable errors
are normalized and made portable, eg. 'not_found' (see full list below).

FILE ATTRIBUTES

 attr          | Win    | OSX    | Linux    | Description
 --------------+--------+--------+----------+--------------------------------
 type          | r      | r      | r        | file type (see below)
 size          | r      | r      | r        | file size
 atime         | rw     | rw     | rw       | last access time (seldom correct)
 mtime         | rw     | rw     | rw       | last contents-change time
 btime         | rw     | r      |          | creation (aka "birth") time
 ctime         | rw     | r      | r        | last metadata-or-contents-change time
 target        | r      | r      | r        | symlink's target (nil if not symlink)
 dosname       | r      |        |          | 8.3 filename (Windows)
 archive       | rw     |        |          | archive bit (for backup programs)
 hidden        | rw     |        |          | hidden bit (don't show in Explorer)
 readonly      | rw     |        |          | read-only bit (can't open in write mode)
 system        | rw     |        |          | system bit
 temporary     | rw     |        |          | writes need not be commited to storage
 not_indexed   | rw     |        |          | exclude from indexing
 sparse_file   | r      |        |          | file is sparse
 reparse_point | r      |        |          | has a reparse point or is a symlink
 compressed    | r      |        |          | file is compressed
 encrypted     | r      |        |          | file is encrypted
 perms         |        | rw     | rw       | permissions
 uid           |        | rw     | rw       | user id
 gid           |        | rw     | rw       | group id
 dev           |        | r      | r        | device id containing the file
 inode         |        | r      | r        | inode number (int64_t)
 volume        | r      |        |          | volume serial number
 id            | r      |        |          | file id (int64_t)
 nlink         | r      | r      | r        | number of hard links
 rdev          |        | r      | r        | device id (if special file)
 blksize       |        | r      | r        | block size for I/O
 blocks        |        | r      | r        | number of 512B blocks allocated

On the table above, `r` means that the attribute is read/only and `rw` means
that the attribute can be changed. Attributes can be queried and changed
from different contexts via `f:attr()`, `fs.attr()` and `d:attr()`.

NOTE: File sizes and offsets are Lua numbers not 64bit ints, so they can
hold at most 8KTB. This will change when that becomes a problem.

FILE TYPES

 name         | Win    | OSX    | Linux    | description
 -------------+--------+--------+----------+---------------------------------
 file         | *      | *      | *        | file is a regular file
 dir          | *      | *      | *        | file is a directory
 symlink      | *      | *      | *        | file is a symlink
 dev          | *      |        |          | file is a Windows device
 blockdev     |        | *      | *        | file is a block device
 chardev      |        | *      | *        | file is a character device
 pipe         |        | *      | *        | file is a pipe
 socket       |        | *      | *        | file is a socket
 unknown      |        | *      | *        | file type unknown


NORMALIZED ERROR MESSAGES

	not_found          file/dir/path not found
	io_error           I/O error
	access_denied      access denied
	already_exists     file/dir already exists
	is_dir             trying this on a directory
	not_empty          dir not empty (for remove())
	io_error           I/O error
	disk_full          no space left on device

File Objects -----------------------------------------------------------------

fs.open(path[, mode|opt]) -> f

Open/create a file for reading and/or writing. The second arg can be a string:

	'r'  : open; allow reading only (default)
	'r+' : open; allow reading and writing
	'w'  : open and truncate or create; allow writing only
	'w+' : open and truncate or create; allow reading and writing
	'a'  : open and seek to end or create; allow writing only
	'a+' : open and seek to end or create; allow reading and writing

	... or an options table with platform-specific options which represent
	OR-ed bitmask flags which must be given either as 'foo bar ...',
	{foo=true, bar=true} or {'foo', 'bar'}, eg. {sharing = 'read write'}
	sets the `dwShareMode` argument of CreateFile() to
	`FILE_SHARE_READ | FILE_SHARE_WRITE` on Windows.
	All fields and flags are documented in the code.

 field     | OS           | reference                              | default
 ----------+--------------+----------------------------------------+----------
 access    | Windows      | `CreateFile() / dwDesiredAccess`       | 'file_read'
 sharing   | Windows      | `CreateFile() / dwShareMode`           | 'file_read'
 creation  | Windows      | `CreateFile() / dwCreationDisposition` | 'open_existing'
 attrs     | Windows      | `CreateFile() / dwFlagsAndAttributes`  | ''
 flags     | Windows      | `CreateFile() / dwFlagsAndAttributes`  | ''
 flags     | Linux, OSX   | `open() / flags`                       | 'rdonly'
 mode      | Linux, OSX   | `octal or symbolic perms`              | '0666' / 'rwx'

The `mode` arg is passed to `unixperms.parse()`.

Pipes ------------------------------------------------------------------------

fs.pipe() -> rf, wf

	Create an anonymous (unnamed) pipe. Return two files corresponding to the
	read and write ends of the pipe.

	NOTE: If you're using async anonymous pipes in Windows _and_ you're
	also creating multiple Lua states _per OS thread_, make sure to set a unique
	`fs.lua_state_id` per Lua state to distinguish them. That is because
	in Windows, async anonymous pipes are emulated using named pipes.

fs.pipe({path=,<opt>=} | path[,options]) -> pf

	Create or open a named pipe (Windows). Named pipes on Windows cannot
	be created in any directory like on POSIX systems, instead they must be
	created in the special directory called `\\.\pipe`. After creation,
	named pipes can be opened for reading and writing like normal files.

	Named pipes on Windows cannot be removed and are not persistent. They are
	destroyed automatically when the process that created them exits.

fs.pipe({path=,mode=} | path[,mode]) -> true

	Create a named pipe (POSIX). Named pipes on POSIX are persistent and can be
	created in any directory as they are just a type of file.

Stdio Streams ----------------------------------------------------------------

f:stream(mode) -> fs

	Open a `FILE*` object from a file. The file should not be used anymore while
	a stream is open on it and `fs:close()` should be called to close the file.

fs:close()

	Close the `FILE*` object and the underlying file object.

Memory Streams ---------------------------------------------------------------

fs.open_buffer(buf, [size], [mode]) -> f

	Create a memory stream for reading and writing data from and into a buffer
	using the file API. Only opening modes 'r' and 'w' are supported.

File I/O ---------------------------------------------------------------------

f:read(buf, len, [expires]) -> readlen

	Read data from file. Returns (and keeps returning) 0 on EOF or broken pipe.

f:readn(buf, len, [expires]) -> true

	Read data from file until `len` is read.
	Partial reads are signaled with `nil, err, readlen`.

f:readall([expires]) -> buf, len

	Read until EOF into a buffer.

f:write(s | buf,len) -> true

	Write data to file.
	Partial writes are signaled with `nil, err, writelen`.

f:flush()

	Flush buffers.

f:seek([whence] [, offset]) -> pos

	Get/set the file pointer. Same semantics as standard `io` module seek
	i.e. `whence` defaults to `'cur'` and `offset` defaults to `0`.

f:truncate(size, [opt])

	Truncate file to given `size` and move the current file pointer to `EOF`.
	This can be done both to shorten a file and thus free disk space, or to
	preallocate disk space to be subsequently filled (eg. when downloading a file).

	On Linux

		`opt` is an optional string for Linux which can contain any of the words
		`fallocate` (call `fallocate()`) and `fail` (do not call `ftruncate()`
		if `fallocate()` fails: return an error instead). The problem with calling
		`ftruncate()` if `fallocate()` fails is that on most filesystems, that
		creates a sparse file which doesn't help if what you want is to actually
		reserve space on the disk, hence the `fail` option. The default is
		`'fallocate fail'` which should never create a sparse file, but it can be
		slow on some file systems (when it's emulated) or it can just fail
		(like on virtual filesystems).

		Btw, seeking past EOF and writing something there will also create a sparse
		file, so there's no easy way out of this complexity.

	On Windows

		On NTFS truncation is smarter: disk space is reserved but no zero bytes are
		written. Those bytes are only written on subsequent write calls that skip
		over the reserved area, otherwise there's no overhead.

f:buffered_read([bufsize]) -> read(buf, sz)

	Returns a `read(buf, sz) -> read_sz` function which reads ahead from file
	in order to lower the number of syscalls. `bufsize` specifies the buffer's
	size (default is `4096`).

Open file attributes ---------------------------------------------------------

f:attr([attr]) -> val|t

	Get/set attribute(s) of open file. `attr` can be:
	* nothing/nil: get the values of all attributes in a table.
	* string: get the value of a single attribute.
	* table: set one or more attributes.

Directory listing ------------------------------------------------------------

fs.dir([dir], [dot_dirs]) -> d, next

	Directory contents iterator. `dir` defaults to `'.'`. `dot_dirs=true` means
	include `.` and `..` entries (default is to exclude them).

	USAGE

		for name, d in fs.dir() do
			if not name then
				print('error: ', d)
				break
			end
			print(d:attr'type', name)
		end

	Always include the `if not name` condition when iterating. The iterator
	doesn't raise any errors. Instead it returns `false, err` as the
	last iteration when encountering an error. Initial errors from calling
	`fs.dir()` (eg. `'not_found'`) are passed to the iterator also, so the
	iterator must be called at least once to see them.

d:next() -> name, d | false, err | nil

	Call the iterator explicitly.

d:close()

	Close the iterator. Always call `d:close()` before breaking the for loop
	except when it's an error (in which case `d` holds the error message).

d:closed() -> true|false

	Check if the iterator is closed.

d:name() -> s

	The name of the current file or directory being iterated.

d:dir() -> s

	The directory that was passed to `fs.dir()`.

d:path() -> s

	The full path of the current dir entry (`d:dir()` combined with `d:name()`).

d:attr([attr, ][deref]) -> t|val

	Get/set dir entry attribute(s).

	`deref` means return the attribute(s) of the symlink's target if the file is
	a symlink (`deref` defaults to `true`!). When `deref=true`, even the `'type'`
	attribute is the type of the target, so it will never be `'symlink'`.

	Some attributes for directory entries are free to get (but not for symlinks
	when `deref=true`) meaning that they don't require a system call for each
	file, notably `type` on all platforms, `atime`, `mtime`, `btime`, `size`
	and `dosname` on Windows and `inode` on Linux and OSX.

d:is(type, [deref]) -> true|false

	Check if dir entry is of type.

File attributes --------------------------------------------------------------

fs.attr(path, [attr, ][deref]) -> t|val

	Get/set a file's attribute(s) given its path in utf8.

fs.is(path, [type], [deref]) -> true|false

	Check if file exists or if it is of a certain type.

Filesystem operations --------------------------------------------------------

fs.mkdir(path, [recursive], [perms])

	Make directory. `perms` can be a number or a string passed to `unixperms.parse()`.

	NOTE: In recursive mode, if the directory already exists this function
	returns `true, 'already_exists'`.

fs.cd([path]) -> path

	Get/set current directory.

fs.remove(path, [recursive])

	Remove a file or directory (recursively if `recursive=true`).

fs.move(path, newpath, [opt])

	Rename/move a file on the same filesystem. On Windows, `opt` represents
	the `MOVEFILE_*` flags and defaults to `'replace_existing write_through'`.

	This operation is atomic on all platforms.

Symlinks & hardlinks ---------------------------------------------------------

fs.mksymlink(symlink, path, is_dir)

	Create a symbolic link for a file or dir. The `is_dir` arg is required
	for Windows for creating symlinks to directories. It's ignored on Linux
	and OSX.

fs.mkhardlink(hardlink, path)

	Create a hard link for a file.

fs.readlink(path) -> path

	Dereference a symlink recursively. The result can be an absolute or
	relative path which can be valid or not.

Memory Mapping ---------------------------------------------------------------

	FEATURES
	  * file-backed and pagefile-backed (anonymous) memory maps
	  * read-only, read/write and copy-on-write access modes plus executable flag
	  * name-tagged memory maps for sharing memory between processes
	  * mirrored memory maps for using with lock-free ring buffers.
	  * synchronous and asynchronous flushing

	LIMITATIONS
	  * I/O errors from accessing mmapped memory cause a crash (and there's
	  nothing that can be done about that with the current ffi), which makes
	  this API unsuitable for mapping files from removable media or recovering
	  from write failures in general. For all other uses it is fine.

fs.map(args_t) -> map
fs.map(path, [access], [size], [offset], [addr], [tagname], [perms]) -> map
f:map([offset], [size], [addr], [access])

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
			* if write access is not given, the mapping fails with `'not_found'` error.
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
		* it's best to provide an address that is above 4 GB to avoid starving
		LuaJIT which can only allocate in the lower 4 GB of the address space.
	* `tagname`: name of the memory map (optional; cannot be used with `file`;
		must not contain slashes or backslashes).
		* using the same name in two different processes (or in the same process)
		gives access to the same memory.

	Returns an object with the fields:

	* `addr` - a `void*` pointer to the mapped memory
	* `size` - the actual size of the memory block

	If the mapping fails, returns `nil,err` where `err` can be:

	* `'not_found'` - file not found.
	* `'file_too_short'` - the file is shorter than the required size.
	* `'disk_full'` - the file cannot be extended because the disk is full.
	* `'out_of_mem'` - size or address too large or specified address in use.
	* an OS-specific error message.

NOTES

	* when mapping or resizing a `FILE` that was written to, the write buffers
	should be flushed first.
	* after mapping an opened file handle of any kind, that file handle should
	not be used anymore except to close it after the mapping is freed.
	* attempting to write to a memory block that wasn't mapped with write
	or copy-on-write access results in a crash.
	* changes done externally to a mapped file may not be visible immediately
	(or at all) to the mapped memory.
	* access to shared memory from multiple processes must be synchronized.

map:free()

	Free the memory and all associated resources and close the file
	if it was opened by the `fs.map()` call.

map:flush([async, ][addr, size]) -> true | nil,err

	Flush (part of) the memory to disk. If the address is not aligned,
	it will be automatically aligned to the left. If `async` is true,
	perform the operation asynchronously and return immediately.

fs.unlink_mapfile(tagname)` <br> `map:unlink()

	Remove a (the) shared memory file from disk. When creating a shared memory
	mapping using `tagname`, a file is created on the filesystem on Linux
	and OS X (not so on Windows). That file must be removed manually when it is
	no longer needed. This can be done anytime, even while mappings are open and
	will not affect said mappings.

fs.mirror_buffer([size], [addr]) -> map  (OSX support is NYI)

	Create a mirrored buffer to use with a lock-free ring buffer. Args:
	* `size`: the size of the memory segment (optional; one page size
	  by default. automatically aligned to the next page size).
	* `addr`: address to use (optional; can be anything convertible to `void*`).

	The result is a table with `addr` and `size` fields and all the mirror map
	objects in its array part (freeing the mirror will free all the maps).
	The memory block at `addr` is mirrored such that
	`(char*)addr[i] == (char*)addr[size+i]` for any `i` in `0..size-1`.

fs.aligned_size(bytes[, dir]) -> bytes

	Get the next larger (dir = 'right', default) or smaller (dir = 'left') size
	that is aligned to a page boundary. It can be used to align offsets and sizes.

fs.aligned_addr(ptr[, dir]) -> ptr

	Get the next (dir = 'right', default) or previous (dir = 'left') address that
	is aligned to a page boundary. It can be used to align pointers.

fs.pagesize() -> bytes

	Get the current page size. Memory will always be allocated in multiples
	of this size and file offsets must be aligned to this size too.

Async I/O --------------------------------------------------------------------

Named pipes can be opened with `async = true` option which opens them
in async mode, which uses the [sock](sock.md) scheduler to multiplex the I/O
which means all I/O then must be performed inside sock threads.
In this mode, the `read()` and `write()` methods take an additional `expires`
arg that behaves just like with sockets.

Programming Notes ------------------------------------------------------------

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

### Async disk I/O

Async disk I/O is a complete afterthought on all major Operating Systems.
If your app is disk-bound just bite the bullet and make a thread pool.
Read Arvid Norberg's article[1] for more info.

[1] https://blog.libtorrent.org/2012/10/asynchronous-disk-io/

]=]

if not ... then require'fs_test'; return end

local ffi = require'ffi'
setfenv(1, require'fs_common')

if win then
	require'fs_win'
elseif linux or osx then
	require'fs_posix'
else
	error'platform not Windows, Linux or OSX'
end

ffi.metatype(stream_ct, {__index = stream})
ffi.metatype(dir_ct, {__index = dir})

return fs
