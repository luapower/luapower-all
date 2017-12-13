---
tagline: portable filesystem API
---

<warn>Work in progress!</warn>

## `local fs = require'fs'`

Filesystem API for Windows, Linux and OSX. Features:

  * utf8 filenames
  * cdata buffer-based I/O
  * memory mapping
  * uniform error reporting

## API

-------------------------------------------- -----------------------------------------------
__file objects__
`fs.open(path[, mode|opt]) -> f`             open file
`f:close()`                                  close file
`f:closed() -> true|false`                   check if file is closed
`fs.isfile(f) -> true|false`                 check if `f` is a file object
__file i/o__
`f:read(buf, len) -> readlen`                read data from file
`f:write(buf, len) -> writelen`              write data to file
`f:flush()`                                  flush buffers
`f:seek([whence] [, offset]) -> pos`         get/set file pointer
`f:truncate()`                               truncate file to current file pointer
`f:size() -> size`                           get file size
`f:stream() -> fs`                           open a `FILE*` object
`fs:close()`                                 close the `FILE*` object
__filesystem operations__
`fs.dir(dir, [dot_dirs]) -> dirobj, next`    directory contents iterator
`dir:next(dirobj, last) -> name, dirobj`     call the iterator
`dir:close()`                                close iterator
`dir:closed() -> true|false`                 check if iterator is closed
`fs.mkdir(path, [recursive][, perms])`       make directory
`fs.rmdir(path, [recursive])`                remove empty directory
`fs.pwd([newpwd]) -> path`                   get current directory
`fs.remove(path)`                            remove file
`fs.move(path, newpath[, opt])`              rename/move file on the same filesystem
__file attributes__
`fs.filetype(path) -> type`                  get file type
`fs.drive(path) -> drive_letter`             get drive letter
`fs.dev(path) -> device_path`                get device path
`fs.inode(path) -> inode`                    get inode
`fs.linknum(path) -> n`                      get number of hard links
`fs.uid(path[, newuid]) -> uid`              get/set UID
`fs.gid(path[, newgid]) -> gid`              get/set GID
`fs.devtype(path) -> ?`                      get device type
`fs.atime(path[, newatime]) -> atime`        get/set access time
`fs.mtime(path[, newmtime]) -> mtime`        get/set modification time
`fs.ctime(path[, newctime]) -> ctime`        get/set creation time
`fs.size(path[, newsize]) -> size`           get/set file size
`fs.perms(path[, newperms]) -> perms`        get/set file permissions
`fs.blocks(path) -> n`                       get number of blocks in file
`fs.blksize(path) -> size`                   get block size for file's filesystem
`fs.touch(path[, atime[, mtime]])`           (create a file and) update modification time
__symlinks & hardlinks__
`fs.mksymlink(symlink, path, is_dir)`        create a symbolic link for a file or dir
`fs.mkhardlink(hardlink, path)`              create a hard link for a file
__paths__
`fs.realpath(path) -> path`                  dereference symlinks
__common paths__
`fs.homedir() -> path`                       get current user's home directory
`fs.tmpdir() -> path`                        get temporary directory
`fs.exedir() -> path`                        get the directory of the running executable
-------------------------------------------- -----------------------------------------------

