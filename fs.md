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
`f:size() -> n`                                   byte size of file
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
`d:atime([deref]) -> atime`                       dir entry access time
`d:mtime([deref]) -> mtime`                       dir entry modification time
`d:ctime([deref]) -> ctime`                       dir entry creation time
`d:size ([deref]) -> size`                        dir entry size
`d:inode([deref]) -> inode|false`                 dir entry inode (false on Windows)
__file attributes__
`fs.attr(path, [attr], [deref]) -> t|val`         file attribute(s)
`fs.type(path, [deref]) -> s`                     file type: 'dir', 'file', 'symlink', ...
`fs.is(path, type, [deref]) -> true|false`        check if file is of type
`fs.atime(path, [newtime], [deref]) -> atime`     get/set access time
`fs.mtime(path, [newtime], [deref]) -> mtime`     get/set modification time
`fs.ctime(path, [newtime], [deref]) -> ctime`     get/set creation time
`fs.size (path, [newsize], [deref]) -> size`      get/set file size
`fs.inode(path, [deref]) -> inode|false`          get file inode (false on Windows)
__todo__
`fs.dev(path) -> device_path`                     get device path
`fs.linknum(path) -> n`                           get number of hard links
`fs.uid(path[, newuid]) -> uid`                   get/set UID
`fs.gid(path[, newgid]) -> gid`                   get/set GID
`fs.perms(path[, newperms]) -> perms`             get/set file permissions
`fs.blocks(path) -> n`                            get number of blocks in file
`fs.blksize(path) -> size`                        get block size for file's filesystem
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
`fs.readlink(path, [recursive=true])`             dereference a symlink
`fs.realpath(path) -> path`                       dereference all symlinks
__common paths__
`fs.homedir() -> path`                            get current user's home directory
`fs.tmpdir() -> path`                             get temporary directory
`fs.exedir() -> path`                             get the directory of the running executable
------------------------------------------------- -------------------------------------------------

__NOTE:__ `deref` arg is `true` by default, meaning that by default, symlinks are followed
recursively and transparently when listing directories and when getting or setting
file attributes.
