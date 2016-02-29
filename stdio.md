---
tagline: standard I/O
---

## `local stdio = require'stdio'`

__Rationale:__ Even though standard file objects in LuaJIT are `FILE*`
handles, there's no API to work with cdata buffers on those handles
and avoid creating Lua strings. This module fixes that.

> __NOTE__: `io`-opened file objects are _compatible_ with cdata `FILE*`
objects but they're not fully equivalent. For this reason, use `f:close()`
on all files instead of `io.close()` or `stdio.close()` which will
automatically choose the right method.

> __NOTE:__ files larger than 4 Petabytes are not supported.

## API

---------------------------------------------------------------- ----------------------------------------------------------------
`stdio.reopen(f, path[, mode]) -> true | nil,err,errno`          close file/open a different file
__i/o__
`stdio.read(f, buf, sz) -> szread | nil,err,errno`               read more data from the file
`stdio.write(f, s[, sz]) -> true | nil,err,errno`                write more data to the file
`stdio.avail(f) -> sz | nil,err`                                 how many bytes to EOF
`stdio.readfile(f[, 't']) -> data, sz`                           read entire file to a buffer
`stdio.writefile(f, s[, sz[, 't']]) -> true |nil,err,errno`      write a string or cdata to a file
__i/o streams__
`stdio.reader(f) -> read(buf, sz)`                               make a reader function
`stdio.writer(f) -> write(s[, sz])`                              make a writer function
__file descriptors__
`stdio.fileno(f) -> n | nil,err,errno`                           get fileno of file
`stdio.dopen(fileno) -> f | nil,err,errno`                       open file based on fileno
`stdio.close(f) -> true | nil,err,errno`                         close file
__error reporting__
`stdio.error(f) -> errno`                                        errno of last operation on file
`stdio.clearerr(f)`                                              clear last errno
`stdio.strerror(errno) -> s | nil`                               errno to string
---------------------------------------------------------------- ----------------------------------------------------------------

