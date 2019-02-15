---
tagline: EXIF reader & writer
---

## `local libexif = require'libexif'`

A ffi binding of [libexif][libexif site], the library for reading and writing
EXIF information from/to image files.

## API

------------------------------------ -----------------------------------------
`exif.C`                             the libexif ffi clib object/namespace
`exif.read(data) -> exif_data`       open file and get EXIF information
`exif_data:get_tags() -> table`      return table of written tags
`exif_data:free()`                   free the exif_data
`exif_data.raw -> cdata`             return cdata of exif_data
------------------------------------ -----------------------------------------

### `exif.read(data) -> exif_data`

Read data and parse EXIF data from it.
`data` is byte-data of file.
Will return `false` if `data` is not a string, not valid path or no EXIF data was found.
Return exif_data as an lua object. The cdata object stored in `exif_data.raw`.

### `exif_data:get_tags() -> table`

Return table of tags from exif_data.
Internally calls a foreach for all ExifContent in `exif_data`, fixes them then calls a foreach for all ExifEntry in ExifContent, fixes them and converts tags names and values to printable strings.
Fixing ExifContent and ExifEntry allows you to get at least some EXIF tags if JPEG was corrupted.

### `exif_data:free()`

Free the exif_data.

## Help needed

Currently there's the binary, sanitized header and the module stub that
returns the `clib` object so the library is usable at ffi level with the aid
of [libexif docs]. A Lua-ized API is made only for reading EXIF tags, but the library is otherwise usable without it.

[libexif site]:   http://libexif.sourceforge.net/
[libexif docs]:   http://libexif.sourceforge.net/api/
