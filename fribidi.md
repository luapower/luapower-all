---
tagline: unicode BiDi algorithm
---

## `local fribidi = require'fribidi'`

A ffi binding of [fribidi][fribidi lib].

## API

### `fb.bidi(s, [len], [charset], [buffers], [flags]) -> s, len, buffers`

Convert a string according to the Unicode BiDi algorithm. Returns the output
string, its length and a set of buffers with additional info.

  * `s` can be a string or a cdata buffer, in which case the output is also
  a cdata buffer
  * `charset` can be: 'ucs4', 'utf-8', 'iso8859-6', 'iso8859-8', 'cp1255',
  'cp1256' (defaults to 'utf8')
  * `buffers` returned from the last call can be passed on to the next call
  to avoid reallocation.

__NOTE:__ line breaking is NYI (the function assumes that the input is a
single line of text).

[fribidi lib]: http://fribidi.org/
