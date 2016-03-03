---
tagline: JPEG encoding & decoding
---

## `local libjpeg = require'libjpeg'`

A ffi binding for the [libjpeg][libjpeg-home] 6.2 API.
Supports progressive loading, yielding from the reader function,
partial loading, fractional scaling and multiple pixel formats.
Comes with [libjpeg-turbo] binaries.

## API

### `libjpeg.open(options_t | read) -> image`

Read and decode a JPEG image. `options_t` is a table containing at least
the read function and possibly other options.

#### 1. The read function:

  * it has the form `read(buf, size) -> readsize`, it can yield and it must
  signal I/O errors by raising an error.

#### 2. Decoding options:

  * `accept.<pixel_format>: true/false` specify one or more accepted
    pixel formats: rgb8, bgr8, rgba8, bgra8, argb8, abgr8, rgbx8, bgrx8, xrgb8,
    xbgr8, g8, ga8, ag8, ycc8, ycck8, cmyk8.
  * `accept.top_down`: true/false (default is true)
  * `accept.bottom_up`: true/false
  * `accept.padded`: true/false (default is false) - specify that the row
    stride should be a multiple of 4.
  * `scale_num`, `scale_denom`: scale down the image by the fraction
    scale_num/scale_denom. Currently, the only supported scaling ratios are
    M/8 with all M from 1 to 16, or any reduced fraction thereof
    (such as 1/2, 3/4, etc.) Smaller scaling ratios permit significantly
    faster decoding since fewer pixels need be processed and a simpler
    IDCT method can be used.
  * `dct_method`: 'accurate', 'fast', 'float' (default is 'accurate')
  * `fancy_upsampling`: true/false (default is false); use a fancier upsampling
    method.
  * `block_smoothing`: true/false (default is false); smooth out large pixels
    of early progression stages for progressive JPEGs.
  * `partial_loading`: true/false (default is true); display broken images
    partially or break with an error.
  * `render_scan`: a function to be called as
    `render_scan(image, is_last_scan, scan_number)` for each progressive scan
    of a multi-scan JPEG. It can used to implement progressive display of images.
    * also called once for single-scan images.
    * also called on error, as `render_scan(nil, true, scan_number, error)`,
    where `scan_number` is the scan number that was supposed to be rendering
    next and `error` the error message.
  * `warning`: a function to be called as `warning(msg, level)` on non-fatal errors.
  * `read_buffer`: optional, read buffer to use.
  * `read_buffer_size`: read buffer size.
  * `suspended_io`: use suspended I/O, i.e. yieldable callbacks (default is true).
    note that arithmetic decoding doesn't work with suspended I/O
    (browsers don't support arithmetic decoding either).

> __NOTE__: Not all conversions are possible with libjpeg-turbo,
so always check the image's `format` field to get the actual format.
Use [bitmap] to further convert the image if necessary.

For more info on the decoding process and options read the [libjpeg-turbo doc].

#### 3. The return value:

The return value is a [bitmap] with extra fields:

  * `file`: a table describing the source file, with the following attributes:
	  * `w`, `h`, `format`, `progressive`, `jfif`, `adobe`.
  * `partial`: true if the image was found to be truncated and it was
  partially loaded.

NOTE:

  * the number of bits per channel in the output bitmap is always 8.
  * the bitmap fields are not present with the `header_only` option.
  * unknown JPEG formats are loaded but the `format` field is missing.


### `libjpeg.save(options_t) -> string | chunks_t | nil`

Save a [bitmap] as JPEG. `options_t` is a table containing at least
the source bitmap and destination, and possibly other options.

#### 1. The source bitmap:

  * `bitmap`: a [bitmap] in an accepted format (see above).

#### 2. The output:

  * `path`: write data to a file.
  * `stream`: write data to an opened `FILE *` stream.
  * `chunks`: append data chunks to a list (which is also returned).
  * `write`: write data to a sink of the form:
		`write(buf, size)`
  * `finish`: optional function to be called after all the data is written.

If no output option is specified, the jpeg binary is returned as a Lua string.

#### 3. Encoding options:

  * `format`: output format (see list of supported formats above).
  * `quality`: 0..100 range. you know what that is.
  * `progressive`: true/false (default is false). make it progressive.
  * `dct_method`: 'accurate', 'fast', 'float' (default is 'accurate').
  * `optimize_coding`: optimize huffmann tables.
  * `smoothing`: 0..100 range. smoothing factor.
  * `bufsize`: internal buffer size (default is 4096).


----
See also: [nanojpeg]

[libjpeg-home]:       http://libjpeg.sourceforge.net/
[libjpeg-turbo]:      http://www.libjpeg-turbo.org/
[libjpeg-turbo doc]:  http://sourceforge.net/p/libjpeg-turbo/code/HEAD/tree/trunk/libjpeg.txt
