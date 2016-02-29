---
tagline: BMP file loading and saving
---

## `local bmp = require'bmp'`

BMP file loading and saving module. Supports all file header versions,
color depths and pixel formats and encodings except very rare ones
(embedded JPEGs, embedded PNGs, OS/2 headers, RLE deltas). Supports
progressive loading, coroutine-based readers, and saving in bgra8 format.

## API

--------------------------------------- ---------------------------------------
`bmp.open(read) -> b|nil,err`           open a BMP file and read it's header
`b.w`                                   width
`b.h`                                   height
`b.bpp`                                 bits per pixel
`b:load(dst_bmp[, x, y]) -> ok|nil,err` load the pixels into a [bitmap]
`bmp.save(bmp, write) -> ok|nil,err`    save a [bitmap] using a write function
--------------------------------------- ---------------------------------------

### `bmp.open(read) -> b|nil,err`

Open a bmp file using a `read(buf, bufsize) -> readsize` function
to get the bytes.

### `bmp.save(bmp, write) -> true | nil, err`

Save bmp file using a `write(buf, size)` function to write the bytes.


## Low-level API

--------------------------------------- ---------------------------------------
`b.bottom_up`                           bottom up?
`b.compression`                         encoding type
`b.transparent`                         uses alpha?
`b.palettized`                          uses palette?
`b.bitmasks`                            RGBA bitmasks (BITFIELDS encoding)
`b.rle -> t|f`                          uses RLE encoding
`b:load_pal() -> ok|nil,err`            load the palette
`b:pal_entry(index) -> r, g, b, a`      palette lookup (loads the palette)
`b.pal_count -> n`                      palette color count
--------------------------------------- ---------------------------------------
