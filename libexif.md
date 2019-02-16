---
tagline: EXIF reader & writer
---

## `local libexif = require'libexif'`

A ffi binding of [libexif][libexif site], the library for reading and writing
EXIF information from/to image files.

## API

------------------------------------ -----------------------------------------
`exif.C`                             the libexif ffi clib object/namespace
`exif.read_file(path) -> exit_data`  read data and get EXIF information
`exit_data:get_tags() -> table`      return table of written tags
`exit_data:free()`                   free the exit_data
------------------------------------ -----------------------------------------

### `exif.read(data) -> exit_data`

Read data and parse EXIF data from it.
`data` is byte-data of file.
Will return `false` if `data` is not a string or no EXIF data was found.
Return `exit_data` as an cdata object with lua metatable.

### `exit_data:get_tags() -> table`

Return table of tags from `exit_data`.
Internally calls a foreach for all ExifContent in `exit_data`, fixes them then calls a foreach for all ExifEntry in ExifContent, fixes them and converts tags names and values to printable strings.
Fixing ExifContent and ExifEntry allows you to get at least some EXIF tags if file was corrupted.

### `exit_data:free()`

Free the exit_data.

## Help needed

Currently there's the binary, sanitized header and the module stub that
returns the `clib` object so the library is usable at ffi level with the aid
of [libexif docs]. A Lua-ized API is made only for reading EXIF tags, but the library is otherwise usable without it.

[libexif site]:   http://libexif.sourceforge.net/
[libexif docs]:   http://libexif.sourceforge.net/api/