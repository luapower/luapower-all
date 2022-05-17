---
tagline: GIF reader
---

## `local giflib = require'giflib'`

Lightweight ffi binding of the antique [GIFLIB][giflib lib].

[giflib lib]: http://sourceforge.net/projects/giflib/

## API

------------------------------------ -----------------------------------------
`giflib.open(opt | read) -> gif`     open a GIF image for decoding
`gif:load([opt]) -> bmp`             load the image into a bitmap
`gif:free()`                         free the image
------------------------------------ -----------------------------------------

### `giflib.open(opt | read) -> gif`

Open a GIF image and read its header. `opt` is a table containing at least
the read function and possibly other options.

The read function has the form `read(buf, len) -> readlen`, **it cannot yield**
and it can signal I/O errors by returning `nil, err`. It will only be asked
to read a positive number of bytes and it can return less bytes than asked,
including zero which signals EOF.

The `opt` table has the fields:

* `read`: the read function (required).

The returned `gif` object contains information about the file and can be used
to load/decode the actual image. Its fields are:

* `w`, `h`: the GIF image dimensions.
* `bg_color: `{r, g, b}` where each color component is in `0..1` range.

__TIP__: Use `tcp:recvall_read()` from [sock] to read from a TCP socket.

__TIP__: Use `f:buffered_read()` from [fs] to read from a file.

### `gif:load([opt]) -> frames`

The `opt` table has the fields:

* `accept`: a table with the fields:
  * `bottom_up`: bottom-up bitmap (false).
  * `stride_aligned`: align stride to 4 bytes (false).
* `opaque`: prevent converting the GIF transparent color to transparent black (false).

Returns an array of frames where each frame is an image object with the fields:

* `format`, `stride`, `bottom_up`, `data`, `size`, `w`, `h`: image format,
dimensions and pixel data.
* `delay_ms`: GIF frame delay in milliseconds, for animated GIFs.
* `x`, `y`: frame position relative to the top-left corner of the virtual
canvas into which to paint the frame. GIF frames can have different
sizes and different positions than (0,0) but this feature is almost
never used.

The frames are always in `bgra8` format. Use [bitmap] to convert them
to other formats.
