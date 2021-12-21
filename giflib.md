---
tagline: GIF reader
---

## `local giflib = require'giflib'`

Lightweight ffi binding of the antique [GIFLIB][giflib lib].

### `giflib.load(path | t) -> gif`

Read and decode a GIF image.

  * `t` is a table specifying where to read the data from and other options:
    * `path`: read data from a file given its filename
    * `string:` read data from a string
    * `cdata`, `size`: read data from a buffer of size `N`
    * `fileno`: read data from a low level file descriptor as returned
	 by `C open()`
    * `opaque`: if `true`, prevents converting the gif transparent color
	 to transparent black.

The returned `gif` object is a table with the fields:

* `w`, `h`: the gif dimensions.
  * `frames = {image1, ...}`: the list of gif frames, in order, where each
  frame is an image object with the fields:
    * `format`, `stride`, `data`, `size`, `w`, `h`: image format, dimensions
	 and pixel data.
      * the frames are always in top-down `bgra8` format; use [bitmap]
		to convert them to other formats.
    * `delay_ms`: gif frame delay in milliseconds, for animated gifs.
    * `x`, `y`: frame position relative to the top-left corner of the virtual
	 canvas into which to paint the frame. gif frames can have different
	 sizes and different positions than (0,0) but this feature is almost
	 never used.



[giflib lib]: http://sourceforge.net/projects/giflib/
