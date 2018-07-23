---
tagline: PNG reader
---

## `local libpng = require'libpng'`

A ffi binding of the ubiquitous [libpng][libpng lib].

## API

### `libpng.load(t) -> image`

Read and decode a PNG image. `t` is a table specifying:

* where to read the data from (one of the following):
	* `path`: read data from a file given its filename
	* `string`: read data from a string
	* `cdata`, `size`: read data from a buffer of specified size
	* `stream`: read data from an opened `FILE *` stream
	* `read`: read data from a reader function of form:
		* `read(needed_size) -> cdata, size | string | nil`
			* `needed_size` is informative, the function can return however
			many bytes it wants, as long as it returns at least 1 byte.
* loading options:
	* `accept`: if present, it is a table specifying conversion options.
	  libpng implements many of the pixel conversions itself, while other
	  conversions are supported through [bmpconv bmpconv.convert_best()].
	  If no `accept` option is given, the image is returned in a normalize
	  8 bit per channel, top down, palette expanded, 'g', 'rgb', 'rgba' or
	  'ga' format.
	* `[pixel_format] = true` - specify one or more accepted pixel formats
	  (they are all implicitly 8 bit per channel since that is the only
	  supported bit depth):
		* 'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'ga', 'ag'.
			* if no pixel format is specified, resulted bit depth will not
			  necessarily be 8 since no conversion will take place.
	* `[orientation] = true` - specify one or more accepted orientations:
		* 'top_down', 'bottom_up' (default is 'top_down')
	* `padded`: true/false (default is false) - specify that the row stride
	  should be a multiple of 4
	* `header_only`: do not decompress the image; return only the image header fields.
	* `sparkle`: true/false (default is false) - alternative render mode
	  for interlaced images.
* callbacks:
	* `warning`: a function to be called as `warning(msg)` on non-fatal errors.
	* `render_scan`: a function to be called as `render_scan(image,
	  is_last_scan, scan_number)` for each pass of an interlaced PNG. It can
	  be used to implement progressive display of images.
		* also called once for non-interlaced images.
		* also called on error, as `render_scan(nil, true, scan_number, error)`,
		  where `scan_number` is the scan number that was supposed to be
		  rendering next and `error` the error message.

For more info on decoding process and options, read the [libpng doc]
(have coffee/ibuprofen ready).

The returned image object is a table with the fields:

* `pixel`, `orientation`, `stride`, `data`, `size`, `w`, `h`: image format
  and dimensions and pixel data.
* `file.pixel`, `file.paletted`, `file.bit_depth`, `file.interlaced`,
  `file.w`, `file.h`: format of the original image before conversion.

## Help needed

  * saving API
  * jit is turned off because we can't call error() from a ffi callback called
    from C; and yet we must not return control to C on errors.
	 Is there a way around it?
  * the read callback cannot yield since it is called from C code. This means
    coroutine-based socket schedulers are out, so much for progressive loading.
	 Is there a way around it?


[libpng lib]:  http://www.libpng.org/pub/png/libpng.html
[libpng doc]:  http://www.libpng.org/pub/png/libpng-1.2.5-manual.html
