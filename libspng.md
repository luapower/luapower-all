
## `local spng = require'libspng'`

A ffi binding of [libspng](https://libspng.org/).

## API

------------------------------------ -----------------------------------------
`spng.open(opt | read) -> png`       open a PNG image for decoding
`png:load([opt]) -> bmp`             load the image into a bitmap
`png:free()`                         free the image
`spng.save(opt)`                     encode a bitmap into a PNG image
------------------------------------ -----------------------------------------

### `spng.open(opt) -> png`

Open a PNG image and read its header. `opt` is a table containing at least
the read function and possibly other options.

The read function has the form `read(buf, len) -> readlen`, **it cannot yield**
and it must signal I/O errors by returning `nil`. It will only be asked
to read a positive number of bytes and it can return less bytes than asked,
including zero which signals EOF.

The `opt` table has the fields:

  * `read`: the read function (required).

The returned `png` object contains information about the file and can be used
to load/decode the actual image. Its fields are:

* `format`, `w`, `h`: image native format and dimensions
* `interlaced`, `indexed`: format flags.

__TIP__: Use `tcp:recvall_read()` from [sock] to read from a TCP socket.

__TIP__: Use `f:buffered_read()` from [fs] to read from a file.

### `png:load(opt) -> bmp`

The `opt` table has the fields:

* `accept`: a table with the fields:
  * `FORMAT = true` specify one or more accepted formats:
  `'bgra8', 'rgba8', 'rgba16', 'rgb8', 'g8', 'ga8', 'ga16'`.
  * `bottom_up`: bottom-up bitmap (false).
  * `stride_aligned`: align stride to 4 bytes (false).
* `gamma`: decode and apply gamma (only for RGB(A) output formats; false).
* `premultiply_alpha`: premultiply the alpha channel (true).

If no `accept` option is given or no conversion is possible, the image
is returned in the native format, transparency not decoded, gamma not decoded
palette not expanded. To avoid this from happening, accept at least one RGB(A)
output format (conversion is always possible to those, see [table]).

[table]: https://github.com/randy408/libspng/blob/master/docs/decode.md#supported-format-flag-combinations

The returned bitmap has the fields:
* standard [bitmap] fields `format`, `bottom_up`, `stride`, `data`, `size`, `w`, `h`.
* `partial`: image wasn't fully read (`read_error` contains the error).

### `spng.save(opt)`

Encode a [bitmap] as PNG. `opt` is a table containing at least the source
bitmap and an output write function, and possibly other options:

* `bitmap`: a [bitmap] in an accepted format: `'g1', 'g2', 'g4', 'g8', 'g16',
'ga8', 'ga16', 'rgb8', 'rgba8', 'bgra8', 'rgba16', 'i1', 'i2', 'i4', 'i8'`.
* `write`: write data to a sink of form `write(buf, len) -> true | nil,err`
(cannot yield).
* `chunks`: list of PNG chunks to encode.
