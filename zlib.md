---
tagline: deflate & gzip
---

## `local zlib = require'zlib'`

## API

### `zlib.version() -> s`

Returns the zlib version.

### `zlib.deflate(read, write[, bufsize][, format][, level][, windowBits][, memLevel][, strategy])`

  * `read` is a reader function `read() -> s[,size] | cdata,size | nil`,
  but it can also be a string or a table of strings.
  * `write` is a writer function `write(cdata, size)`, but it can also be an
  empty string (in which case a string with the output is returned) or
  an output table (in which case a table with output chunks is returned).
  * `bufsize` determines the frequency and size of the writes
  * `format` can be:
    * 'zlib' - wrap the deflate stream with a zlib header and trailer (default)
    * 'gzip' - wrap the deflate stream with a gzip header and trailer
    * 'deflate' - write a raw deflate stream with no header or trailer
  * `level` controls the compression level (0-9 from none to best)
  * for `windowBits`, `memLevel` and `strategy` refer to the [zlib manual].
    * note that `windowBits` is always in the positive range 8..15.

Compress a data stream using the DEFLATE algorithm. The data is read from the
`read` function which should return the next string or `cdata, size` pair
every time it is called, until EOF when it should return `nil` or nothing.
The compressed data is written in chunks using the `write` function.

For convenience, `read` can also be a string or a list of strings, and `write`
can be a list to which to add the output chunks, or the empty string, in which
case the output is returned as a string.

### `zlib.inflate(read, write[, bufsize][, format][, windowBits])`

Uncompress a data stream that was compressed using the DEFLATE algorithm.
The arguments have the same meaning as for `deflate`.

### `zlib.compress(s, [size][, level]) -> s`
### `zlib.compress(cdata, size[, level]) -> s`
### `zlib.compress_tobuffer(s, [size], [level], out_buffer, out_size) -> bytes_written`
### `zlib.compress_tobuffer(data, size, [level], out_buffer, out_size) -> bytes_written`

Compress a string or cdata using the DEFLATE algorithm.

### `zlib.uncompress(s, [size], out_size) -> s`
### `zlib.uncompress(cdata, size, out_size) -> s`
### `zlib.uncompress_tobuffer(s, [size], out_buffer, out_size) -> bytes_written`
### `zlib.uncompress_tobuffer(cdata, size, out_buffer, out_size) -> bytes_written`

Uncompress a string or cdata using the DEFLATE algorithm. The size of the uncompressed data must have been saved previously by the application and transmitted to the decompressor by some mechanism outside the scope of this library.

### `zlib.open(filename[, mode][, bufsize]) -> gzfile`

Open a gzip file for reading or writing.

### `gzfile:close()`

Close the gzip file flushing any pending updates.

### `gzfile:flush(flag)`

Flushes any pending updates to the file. The flag can be `'none'`, `'partial'`, `'sync'`, `'full'`, `'finish'`, `'block'` or `'trees'`. Refer to the [zlib manual] for their meaning.

### `gzfile:read_tobuffer(buf, size) -> bytes_read`
### `gzfile:read(size) -> s`

Read the given number of uncompressed bytes from the compressed file. If the input file is not in gzip format, copy the bytes as they are instead.

### `gzfile:write(cdata, size) -> bytes_written`
### `gzfile:write(s[, size]) -> bytes_written`

Write the given number of uncompressed bytes into the compressed file. Return the number of uncompressed bytes actually written.

### `gzfile:eof() -> true|false`

Returns true if the end-of-file indicator has been set while reading, false otherwise. Note that the end-of-file indicator is set only if the read tried to go past the end of the input, but came up short. Therefore, `eof()` may return false even if there is no more data to read, in the event that the last read request was for the exact number of bytes remaining in the input file. This will happen if the input file size is an exact multiple of the buffer size.

### `gzfile:seek([whence][, offset])`

Set the starting position for the next `read()` or `write()`. The offset represents a number of bytes in the uncompressed data stream. `whence` can be "cur" or "set" ("end" is not supported).

If the file is opened for reading, this function is emulated but can be extremely slow. If the file is opened for writing, only forward seeks are supported: `seek()` then compresses a sequence of zeroes up to the new starting position.

If the file is opened for writing and the new starting position is before the current position, an error occurs.

Returns the resulting offset location as measured in bytes from the beginning of the uncompressed stream.

### `gzfile:offset() -> n`

Return the current offset in the file being read or written. When reading, the offset does not include as yet unused buffered input. This information can be used for a progress indicator.

### `zlib.adler32(cdata, size[, adler]) -> n`
### `zlib.adler32(s, [size][, adler]) -> n`

Start or update a running Adler-32 checksum of a string or cdata buffer and return the updated checksum.

An Adler-32 checksum is almost as reliable as a CRC32 but can be computed much faster, as it can be seen by running the hash benchmark.

### `zlib.crc32(cdata, size[, crc]) -> n`
### `zlib.crc32(s, [size][, crc]) -> n`

Start or update a running CRC-32B of a string or cdata buffer and return the updated CRC-32. Pre- and post-conditioning (one's complement) is performed within this function so it shouldn't be done by the application.


[zlib manual]: http://www.zlib.net/manual.html
