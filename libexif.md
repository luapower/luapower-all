---
tagline: EXIF reader & writer
---

## `local libexif = require'libexif'`

A ffi binding of [libexif][libexif site], the library for reading and writing EXIF information from/to image files.

## Help needed

Currently there's the binary, sanitized header and the module stub that returns the `clib` object
so the library is usable at ffi level with the aid of [libexif docs].
A Lua-ized API is missing, but the library is otherwise usable without it.


[libexif site]:   http://libexif.sourceforge.net/
[libexif docs]:   http://libexif.sourceforge.net/api/
