---
tagline: JPEG reader
---

## `local nanojpeg = require'nanojpeg'`

A ffi binding of [NanoJPEG][nanojpeg lib], a very small JPEG decoder suitable for embedded applications.

## Limitations

  * no support for arithmetic coding (rarely used)
  * no support for progressive jpeg (not-so-rarely used)
  * slow (compared to [libjpeg-turbo][libjpeg])
  * no option to only read the headers

## API

### `nanojpeg.load(path | t) -> image`

Read and decode a JPEG image.

  * `t` is a table specifying:
    * where to read the data from (one of the following):
      * `path`: read data from a file given its filename
      * `string`: read data from a string
      * `cdata`, `size`: read data from a buffer

The returned image object is a table with the fields:

  * `data`, `size`, `format`, `stride`, `w`, `h`: image format, data and dimensions.
    * depending on the input file, the format can be either `rgb8` or `g8`,
	   that is 24bit RGB or 8bit gray; use [bitmap] to convert to other formats.

----
See also: [libjpeg]


[nanojpeg lib]:    http://keyj.emphy.de/nanojpeg/
