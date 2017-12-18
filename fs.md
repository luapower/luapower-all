---
tagline: portable filesystem support
---

<warn>Work in progress!</warn>

## `local fs = require'fs'`

Filesystem API for Windows, Linux and OSX. Features:

  * utf8 filenames on all platforms
  * symlinks and hard links on all platforms
  * unified error codes for common error cases
  * memory mapping on all platforms
  * cdata buffer-based I/O

## API

------------------------------------------------- -------------------------------------------------
__file objects__
`fs.open(path[, mode|opt]) -> f`                  open file
`f:close()`                                       close file
`f:closed() -> true|false`                        check if file is closed
`fs.isfile(f) -> true|false`                      check if `f` is a file object
__file i/o__
`f:read(buf, len) -> readlen`                     read data from file
`f:write(buf, len) -> writelen`                   write data to file
`f:flush()`                                       flush buffers
`f:seek([whence] [, offset]) -> pos`              get/set file pointer
`f:truncate()`                                    truncate file to current file pointer
`f:size([newsize]) -> size`                       get/set byte size of file
`f:time([t]) -> t`                                get mtime, atime, ctime, btime; set mtime, atime
`f:stream() -> fs`                                open a `FILE*` object
`fs:close()`                                      close the `FILE*` object
__directory listing__
`fs.dir(dir, [dot_dirs]) -> d, next`              directory contents iterator
`d:next(last) -> name, d`                         call the iterator explicitly
`d:close()`                                       close iterator
`d:closed() -> true|false`                        check if iterator is closed
__directory entry attributes__
`d:name() -> s`                                   dir entry's name
`d:dir() -> s`                                    dir that was passed to `fs.dir()`
`d:path() -> s`                                   full path of the dir entry
`d:attr([attr], [deref]) -> t|val`                dir entry attribute(s)
`d:type([deref]) -> s`                            dir entry type: 'dir', 'file', 'symlink', ...
`d:is(type, [deref]) -> true|false`               check if dir entry is of type
__file attributes__
`fs.attr(path, [attr], [deref]) -> t|val`         file attribute(s)
`fs.type(path, [deref]) -> s`                     file type: 'dir', 'file', 'symlink', ...
`fs.is(path, type, [deref]) -> true|false`        check if file is of type
__filesystem operations__
`fs.mkdir(path, [recursive], [perms])`            make directory
`fs.rmdir(path, [recursive])`                     remove empty directory
`fs.pwd([newpwd]) -> path`                        get current directory
`fs.remove(path, [recursive])`                    remove file (or directory recursively)
`fs.move(path, newpath, [opt])`                   rename/move file on the same filesystem
`fs.touch(path, [atime], [mtime])`                (create a file and) update modification time
__symlinks & hardlinks__
`fs.mksymlink(symlink, path, is_dir)`             create a symbolic link for a file or dir
`fs.mkhardlink(hardlink, path)`                   create a hard link for a file
`fs.readlink(path)`                               dereference a symlink recursively
`fs.realpath(path) -> path`                       dereference all symlinks
__common paths__
`fs.homedir() -> path`                            get current user's home directory
`fs.tmpdir() -> path`                             get temporary directory
`fs.exedir() -> path`                             get the directory of the running executable
------------------------------------------------- -------------------------------------------------

__NOTE:__ `deref` arg is `true` by default, meaning that by default, symlinks are followed
recursively and transparently when listing directories and when getting or setting
file attributes.
