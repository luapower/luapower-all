---
tagline: in-memory bitmaps
---

## `local bitmap = require'bitmap'`

## Features

  * multiple pixel formats, color spaces, channel layouts, scanline orderings,
  row strides, and bit depths.
    * arbitrary row strides, including sub-byte strides.
    * top-down and bottom-up scanline order.
  * conversion between most formats.
  * reading and writing pixel data in a uniform way, independent of the pixel
  format.
  * dithering, pixel effects, filters.
  * fast (see benchmarks).

## Limitations

  * only packed formats, no separate plane formats
    * but: custom conversions to gray8 and gray16 can be used to separate the
	 channels of any format into separate bitmaps.
  * only expanded formats, no palette formats
    * but: custom formats with a custom reader and writer can be easily made
	 to use a palette which itself can be a one-row bitmap.
  * no conversions to cmyk (would need color profiling)
  * no conversions to ycc and ycck

## What's a bitmap?

A bitmap is an interface, i.e. any table with the following fields is a bitmap:

  * `w`, `h` - bitmap dimensions, in pixels.
  * `stride` - row stride in bytes. must be at least `w * bpp / 8`
  (can be fractional for < 8bpp formats).
  * `bottom_up` - if `true`, the rows are are arranged bottom-up instead of top-down.
  * `data` - the pixel buffer (string or a cdata buffer). the pixels must be
  packed in `stride`-long rows, top-down or bottom-up.
  * `size` - size of the pixel buffer, in bytes.
  * `format` - the pixel format, either a string naming a predefined format
  (below table), or a table specifying a custom format (see customization).

### Predefined formats

**name**                          **colortype**       **channels**       **bits/channel**   **bits/pixel**
--------------------------------- ------------------- ------------------ ------------------ ---------------
rgb8, bgr8                        rgba8               RGB                8                  24
rgb16, bgr16                      rgba16              RGB                16                 48
rgbx8, bgrx8, xrgb8, xbgr8        rgba8               RGB                8                  32
rgbx16, bgrx16, xrgb16, xbgr16    rgba16              RGB                16                 64
rgba8, bgra8, argb8, abgr8        rgba8               RGB+alpha          8                  32
rgba16, bgra16, argb16, abgr16    rgba16              RGB+alpha          16                 64
rgb565                            rgba8               RGB                5/6/5              16
rgb555                            rgba8               RGB                5                  16
rgb444                            rgba8               RGB                4                  16
rgba4444                          rgba8               RGB+alpha          4                  16
rgba5551                          rgba8               RGB+alpha          5/5/5/1            16
ga8, ag8                          ga8                 GRAY+alpha         8                  16
ga16, ag16                        ga16                GRAY+alpha         16                 32
g1                                ga8                 GRAY               1                  1
g2                                ga8                 GRAY               2                  2
g4                                ga8                 GRAY               4                  4
g8                                ga8                 GRAY               8                  8
g16                               ga16                GRAY               16                 16
cmyk8                             cmyk8               inverse CMYK       8                  32
ycc8                              ycc8                JPEG YCbCr 8       8                  24
ycck8                             ycck8               JPEG YCbCrK 8      8                  32
rgbaf                             rgbaf               RGB+alpha          32                 128
rgbad                             rgbaf               RGB+alpha          64                 256


### Predefined colortypes

**name**       **channels**      **value type**        **value range**
-------------- ----------------- --------------------- -----------------
rgba8          r, g, b, a        integer               0..0xff
rgba16         r, g, b, a        integer               0..0xffff
ga8            g, a              integer               0..0xff
ga16           g, a              integer               0..0xffff
cmyk8          c, m, y, k        integer               0..0xff
ycc8           y, c, c           integer               0..0xff
ycck8          y, c, c, k        integer               0..0xff
rgbaf          r, g, b, a        float or double       0..1


## Quick API Reference

----------------------------------------------------- --------------------------------------------
__format conversion__
`bitmap.new(w, h, ...) -> dst`                        create a bitmap
`bitmap.copy(src[, format], ...) -> dst`              copy and convert a bitmap
`bitmap.paint(src, dst, dstx, dsty, conv) -> dst`     paint a bitmap on another
__cropping__
`bitmap.sub(src, x, y, w, h) -> dst`                  make a sub-bitmap
__pixel access__
`bitmap.pixel_interface(src) -> getpixel, setpixel`   get a pixel interface
`bitmap.channel_interface(bmp, n) -> getval, setval`  get a channel interface
__dithering__
`bitmap.dither.fs(bmp, rN, gN, bN, aN)`               apply dithering
`bitmap.dither.ordered(bmp, rN, gN, bN, aN)`          apply dithering
__effects__
`bitmap.invert(bmp)`                                  invert colors (in place)
`bitmap.grayscale(bmp)`                               desaturate (in place)
`bitmap.convolve(src, kernel, [edge]) -> dst`         convolve
`bitmap.sharpen(src[, threshold]) -> dst`             sharpen
`bitmap.mirror(src)`                                  mirror horizontally (in place)
__alpha blending__
`bitmap.blend(src, dst, [operator], [x], [y])`        blend source into dest bitmap
__resizing__
`bitmap.resize.nearest|bilinear(src, w, h) -> dst`    resize to new
`bitmap.resize.nearest|bilinear(src, dst) -> dst`     resize to dest
__utilities__
`bitmap.min_stride(format, width) -> min_stride`      minimum stride for width
`bitmap.aligned_stride(stride) -> aligned_stride`     minimum stride that is aligned
`bitmap.row_size(bmp) -> size`                        row size in bytes
----------------------------------------------------- --------------------------------------------


## Bitmap operations

### `bitmap.new(w, h, format, [bottom_up], [stride_aligned], [stride]) -> new_bmp`

Create a bitmap object. If `stride_aligned` is `true` and no specific `stride`
is given, the stride will be a multiple of 4 bytes.

### `bitmap.copy(bmp, [format], [bottom_up], [stride_aligned], [stride]) -> new_bmp`

Copy a bitmap, optionally to a new format, orientation and stride. If `format`
is not specified, stride and orientation default to those of source bitmap's,
otherwise they default to top-down, minimum stride.

### `bitmap.paint(source_bmp, dest_bmp[, dstx, dsty][, convert_pixel]) -> dest_bmp`

Paint a source bitmap into a destination bitmap, with all the necessary
clipping and pixel and colortype conversions.

The optional `convert_pixel` is a pixel conversion function to be called for
each pixel as `convert_pixel(a, b, c, ...) -> x, y, z, ...`. It receives
the channel values of the source bitmap according to its colortype and
must return the converted channel values for the destination bitmap
according to its colortype.

In some cases, the destination bitmap is allowed to have the same data buffer
as the source bitmap. Specifically, it must have the same orientation,
smaller or equal stride and smaller or equal pixel size. The destination
bitmap can also be the source bitmap itself, which is useful for performing
custom transformations via the `convert_pixel` callback.

### `bitmap.sub(bmp, [x], [y], [w], [h]) -> sub_bmp`

Crop a bitmap without copying the pixels (the `data` field of the sub-bitmap
is a pointer into the `data` buffer of the parent bitmap). The parent bitmap
is pinned in the `parent` field of the sub-bitmap to prevent garbage
collection of the data buffer. Other than that, the sub-bitmap behaves exactly
like a normal bitmap (it can be further sub'ed for instance). The coordinates
default to `0, 0, bmp.w, bmp.h` respectively. The coordinates are adjusted
to fit the parent bitmap. If they result in zero width or height,
nothing is returned.

To get real cropping, just copy the bitmap, specifying the format and
orientation to reset the stride:

	sub = bitmap.copy(sub, sub.format, sub.bottom_up)

> NOTE: For 1, 2, 4 bpp formats, the coordinates must be such that the
data pointer points to the beginning of a byte (that is, is not fractional).
For a non-fractional stride, this means the `x` coordinate must be a multiple
of 8, 4, 2 respectively. For fractional strides don't even bother.


## Pixel interface

### `bitmap.pixel_interface(bitmap[, colortype]) -> getpixel, setpixel`

Return an API for getting and setting individual pixels of a bitmap object:

  * `getpixel(x, y) -> a, b, c, ...`
  * `setpixel(x, y, a, b, c, ...)`

where a, b, c are the individual color channels, converted to the specified
colortype or in the colortype of the bitmap (i.e. r, g, b, a for the 'rgba'
colortype, etc.).

#### Example:

~~~{.lua}
local function darken(r, g, b, a)
	return r / 2, g / 2, b / 2, a / 2) --make 2x darker
end

local getpixel, setpixel = bitmap.pixel_interface(bmp)
for y = 0, bmp.h-1 do
	for x = 0, bmp.w-1 do
		setpixel(x, y, darken(getpixel(x, y)))
	end
end

--the above has the same effect as:
bitmap.convert(bmp, bmp, darken)
~~~


## Channel interface

### `bitmap.channel_interface(bitmap, channel) -> getvalue, setvalue`

Return an API for getting and setting values for a single color channel:

  * `getvalue(x, y) -> v`
  * `setvalue(x, y, v)`


## Dithering

### `bitmap.dither.fs(bmp, rbits, gbits, bbits, abits)`

Dither a bitmap using the [Floyd-Steinberg dithering] algorithm. `*bits`
specify the number of bits of color to keep for each channel (eg.
`bitmap.dither.fs(bmp, 5, 6, 5, 0)` dithers a bitmap so that its colors fit
into the `rgb565` format). Only implemented for 4-channel colortypes.

### `bitmap.dither.ordered(bmp, mapsize)`

Dither a bitmap using the [ordered dithering] algorithm. `mapsize` specifies
the threshold map to use and can be 2, 3, 4 or 8. Use the demo to see how
this parameter affects the output quality depending on the output format
(it's not a clear-cut choice). Implemented for 2-channel and 4-channel
colortypes. Note that actual clipping of the low bits is not done, it
will be done naturally when converting the bitmap to a lower bit depth.

[Floyd-Steinberg dithering]: http://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
[ordered dithering]:         http://en.wikipedia.org/wiki/Ordered_dithering


## Pixel effects

### `bitmap.invert(bmp)`

Invert colors.

### `bitmap.grayscale(bmp)`

Convert pixels to grayscale, without changing the format.

### `bitmap.convolve(bmp, kernel, [edge]) -> new_bmp`

Convolve a bitmap using a kernel matrix (a Lua array of arrays of the same
length). `edge` can be `crop`, `wrap` or `extend` (default is `extend`).

### `bitmap.sharpen(bmp[, threshold]) -> new_bmp`

Sharpen a bitmap.


## Alpha Blending

### `bitmap.blend(source_bmp, dest_bmp, [operator], [x], [y])`

Blend `source_bmp` into `dest_bmp` using a blending operator at `x,y`
coordinates in the target bitmap (default is `0,0`).
Operators are in the `bitmap.blend_op` table for inspection.


## Resizing

### `bitmap.resize.nearest|bilinear(bmp, w, h) -> new_bmp` <br> `bitmap.resize.nearest|bilinear(source_bmp, dest_bmp) -> dest_bmp`

Resize a bitmap.


## Utilities

### `bitmap.min_stride(format, width) -> min_stride`

Return the minimum stride in bytes given a format and width.
A bitmap data buffer should never be smaller than `min_stride * height`.

### `bitmap.aligned_stride(stride) -> aligned_stride`

Given a stride, return the smallest stride that is a multiple of 4 bytes.

### `bitmap.row_size(bmp) -> size`

Bitmap's row size, in bytes, i.e. bitmap's minimum stride.

## Introspection

### `bitmap.conversions(source_format) -> iter() -> name, def`

Given a source bitmap format, iterate through all the formats that the source
format can be converted to. `name` is the format name and `def` is
the format definition which is a table with the fields `bpp`, `ctype`,
`colortype`, `read`, `write`.

### `bitmap.dumpinfo()`

Print the list of supported pixel formats and the list of supported
colortype conversions.

## Extending

Extending the `bitmap` module with new colortypes, formats, conversions
and module functions is easy. Look at the `bitmap_rgbaf` sub-module for
an example on how to do that. For the submodule to be loaded automatically
you need to reference it in the `bitmap` module too in a few key spots.
Again, look at how `rgbaf` does it.

### Custom formats

A custom pixel format definition is a table with the following fields:

  * `bpp` - pixel size, in bits (must be an even number of bits).
  * `ctype` - C type to cast `data` to when reading and writing pixels (see below).
  * `colortype` - a string naming a standard color type or a table specifying
  a custom color type. The channel values that `read` and `write` refer to
  depend on the colortype, eg. for the 'rgba8' colortype, the read function
  must return 4 numbers in the 0-255 range corresponding to the R, G, B, A
  channels.
  * `read` - a function to be called as `read(data, i) -> a, b, c, ...`;
  the function must decode the pixel at `data[i]` and return its channel
  values according to colortype.
  * `write` - a function to be called as `write(data, i, a, b, c, ...)`;
  the function must encode the given channel values according to colortype
  and write the pixel at `data[i]`.
	 * for formats that have bpp < 8, the index i is fractional and the bit
	 offset of the pixel is at `bit.band(i * 8, 7)`.

### Custom colortypes

A custom colortype definition is a table with the following fields:

  * `channels` - a string with each letter a channel name, eg. 'rgba',
  so that `#channels` indicates the number of channels.
  * `max` - maximum value to which the channel values need to be clipped.
  * `bpc` - bits/channel - same meaning as `max` but in bits.

## TODO

  * premuliply / unpremultiply alpha
