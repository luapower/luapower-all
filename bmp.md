---
tagline: BMP file loading and saving
---

## `local bmp = require'bmp'`

BMP file loading and saving module. Supports all file header versions,
color depths and pixel formats and encodings except very rare ones
(embedded JPEGs, embedded PNGs, OS/2 headers, RLE deltas). Supports
progressive loading, yielding from the reader and writer functions
and saving in bgra8 format.

## API

---------------------------------------------------- ----------------------------------------------------
`bmp.open(read) -> b|nil,err`                        open a BMP file and read it's header
`b.w`                                                width
`b.h`                                                height
`b.bpp`                                              bits per pixel
`b:load(bmp[, x, y]) -> bmp | nil,err`               load/paint the pixels into a given [bitmap]
`b:load(format, ...) -> bmp | nil,err`               load the pixels into a new bitmap
`b:rows(bmp | format,...) -> iter() -> i, bmp`       iterate the rows over a 1-row bitmap
`bmp.save(bmp, write) -> ok | nil,err`               save a bitmap using a write function
---------------------------------------------------- ----------------------------------------------------

### `bmp.open(read) -> b|nil,err`

Open a BMP file. The read function has the form `read(buf, len) -> readlen`,
it can yield and it can signal I/O errors by returning `nil, err`. It will
only be asked to read a positive number of bytes and it can return less bytes
than asked, including zero which signals EOF.

### `b:load(bmp[, x, y]) -> bmp | nil,err`

Load and paint the bmp's pixels into a given [bitmap], optionally at a specified
position within the bitmap. All necessary format conversions and clipping
are done via the [bitmap] module.

### `b:load(format, ...) -> bmp | nil,err`

Load the bmp's pixels into a new bitmap of a specified format.
Extra arguments are passed to `bitmap.new()`.

### `b:rows(bmp | format,...) -> iter() -> i, bmp`

Iterate the bmp's rows over a new or provided 1-row bitmap. The row index
is decreasing if the bitmap is bottom-up. Unlike `b:load()`, this method
and the returned iterator are not protected (they raise errors).

### `bmp.save(bmp, write) -> true | nil, err`

Save bmp file using a `write(buf, size)` function to write the bytes.
The write function should accept any size >= 0 and it should raise an error
if it can't write all the bytes.


## Low-level API

--------------------------------------- ---------------------------------------
`b.bottom_up`                           are the rows stored bottom up?
`b.compression`                         encoding type
`b.transparent`                         does it use the alpha channel?
`b.palettized`                          does it use a palette?
`b.bitmasks`                            RGBA bitmasks (BITFIELDS encoding)
`b.rle`                                 is it RLE-encoded?
`b:load_pal() -> ok|nil,err`            load the palette
`b:pal_entry(index) -> r, g, b, a`      palette lookup (loads the palette)
`b.pal_count -> n`                      palette color count
--------------------------------------- ---------------------------------------
