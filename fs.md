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
`fs.open(path[, mode|opt]) -> f`
`f:close()`
`f:closed() -> true|false`
`fs.isfile(f) -> true|false`
__file i/o__
`f:read(buf, len) -> readlen`
`f:write(buf, len) -> writelen`
`f:flush()`
`f:seek([whence] [, offset]) -> pos`
`f:truncate()`
`f:size() -> size`
`f:stream() -> fs`
`fs:close()`
__filesystem operations__
`fs.dir() -> dir, next
`dir:next() -> name`
`dir:close()`
`dir:closed() -> true|false`
`fs.mkdir(path, [recursive][, perms])`
`fs.rmdir(path, [recursive])`
`fs.pwd([newpwd]) -> path`
`fs.remove(path)`
`fs.move(path, newpath[, opt])`
__file attributes__
`fs.filetype(path) -> type`
`fs.drive(path) -> drive_letter`
`fs.dev(path) -> device_path`
`fs.inode(path) -> inode`
`fs.linknum(path) -> n`
`fs.uid(path[, newuid]) -> uid`
`fs.gid(path[, newgid]) -> gid`
`fs.devtype(path) -> ?`
`fs.atime(path[, newatime]) -> atime`
`fs.mtime(path[, newmtime]) -> mtime`
`fs.ctime(path[, newctime]) -> ctime`
`fs.size(path[, newsize]) -> size`
`fs.perms(path[, newperms]) -> perms`
`fs.blocks(path) -> n`
`fs.blksize(path) -> size`
`fs.touch(path[, atime[, mtime]])`
__symlinks & hardlinks__
`fs.hardlink(target, path)`
`fs.symlink(target, path)`
`fs.link(target, patn[, symbolic])`
__paths__
`fs.path(path|t[, dirsep]) -> path`
`fs.basename(path) -> name`
`fs.dirname(path) -> path`
`fs.extname(path) -> ext`
`fs.dirsep() -> s`
`fs.abspath(path[, pwd]) -> path`
`fs.relpath(path[, pwd]) -> path`
`fs.realpath(path) -> path`
`fs.readlink(path) -> path`
__common paths__
`fs.homedir() -> path`
`fs.tmpdir() -> path`
`fs.exedir() -> path`
-------------------------------------------- -----------------------------------------------
