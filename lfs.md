---
tagline: filesystem support
---

## `local lfs = require'lfs'`

A distribution of [LuaFileSystem].

[LuaFileSystem]: http://keplerproject.github.io/luafilesystem/

## API

------------------------------------------------------------- -------------------------------------------------------------
`lfs.attributes(filepath) -> t | nil,err`                     get all file attributes (see below)

`lfs.attributes(filepath, attr) -> val | nil,err`             get a specific file attribute (see below)

`lfs.currentdir() -> s | nil,err`                             get the current working directory

`lfs.chdir(path) -> true | nil,err`                           change the current working directory

`lfs.dir(path) -> iter, dir_obj`                              get a directory iterator (to use with `for`)

`iter(dir_obj) -> dirname | nil`                              explicit iteration

`dir_obj:next() -> dirname | nil`                             explicit iteration

`dir_obj:close()`                                             close the iterator

`lfs.lock_dir(path, [timeout]) -> lf | nil,err`               check/create `lockfile.lfs` in `path`

`lf:free()`                                                   free the lockfile

`lfs.lock(file, 'r'|'w'[, start[, len]])                      lock (parts of) a file in shared ('r')
-> true | nil,err`                                            or exclusive ('w') mode

`lfs.unlock (file[, start[, len]])                            unlock (parts of) a file
-> true | nil,err`

`lfs.link(old, new[, symlink])`                               create a hard (or symbolic) link

`lfs.mkdir(dirname) -> true | nil,err`                        create a directory

`lfs.rmdir(dirname) -> true | nil,err`                        remove an empty directory

`lfs.setmode(file, mode) -> true,lastmode | nil,err`          set the writing mode ('binary' or 'text')

`lfs.symlinkattributes(filepath) -> t | nil,err`

`lfs.symlinkattributes(filepath, attr) -> val | nil,err`      like `lfs.attributes` but for the link file (not on Windows)

`lfs.touch(filepath [, atime [, mtime]]) -> true | nil,err`   set atime and mtime of file to specified or current time
------------------------------------------------------------- -------------------------------------------------------------

### file attributes:

--------------- -------------------------------------------------------------------
`dev`           device number (Unix) or drive number (Windows)
`ino`           Unix only: inode number
`mode`          protection mode: `file`, `directory`, `link`, `socket`,
                `named pipe`, `char device`, `block device`, `other`
`nlink`         number of hard links to the file
`uid`           user-id of owner (Unix only, always 0 on Windows)
`gid`           group-id of owner (Unix only, always 0 on Windows)
`rdev`          device type (Unix) or same as `dev` (Windows)
`access`        time of last access (`os.time()` semantics)
`modification`  time of last data modification (`os.time()` semantics)
`change`        time of last file status change (`os.time()` semantics)
`size`          file size, in bytes
`permissions`   file permissions string
`blocks`        block allocated for file (Unix only)
`blksize`       optimal file system I/O blocksize (Unix only)
--------------- -------------------------------------------------------------------

__NOTE:__ `lfs.attributes()` follows symlinks recursively. To obtain
information about the link itself use `lfs.symlinkattributes()`.
