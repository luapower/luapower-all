---
tagline: standard I/O
---

## `local stdio = require'stdio'`

__Rationale:__ although the standard `io` library exposes `FILE*` handles,
there's no API extension to work with buffers and avoid creating Lua strings.
Also, functions of this API return `nil, err, errno` on failure.

## API

---------------------------------------------------------------- ----------------------------------------------------------------
`stdio.reopen(f, path[, mode]) -> f | nil,err,errno`             close/open a different file
__i/o__
`stdio.read(f, buf, sz) -> szread | nil,err,errno`               read more data from the file
`stdio.write(f, buf, sz) -> true | nil,err,errno`                write more data to the file
`stdio.avail(f) -> sz | nil,err`                                 how many bytes to EOF
`stdio.readfile(f[, 't']) -> data, sz`                           read entire file to a buffer
`stdio.writefile(f, data, sz[, 't']) -> true |nil,err,errno`     write a buffer to a file
__file descriptors__
`stdio.fileno(f) -> n | nil,err,errno`                           get fileno of file
`stdio.dopen(fileno) -> f | nil,err,errno`                       open file based on fileno
__error reporting__
`stdio.error(f) -> errno`                                        errno of last operation on file
`stdio.clearerr(f)`                                              clear last errno
`stdio.strerror(errno) -> s | nil`                               errno to string
---------------------------------------------------------------- ----------------------------------------------------------------

