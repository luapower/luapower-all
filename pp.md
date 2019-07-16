---
tagline: table serialization
---

## `local pp = require'pp'`

Fast, compact serialization producing portable Lua source code.

## Input

  * all Lua types except coroutines, userdata, cdata and C functions.
  * the ffi `int64_t` and `uint64_t` types.
  * values featuring `__tostring` or `__pwrite` metamethods (eg. [tuple]s).


## Output

  * **compact**: no spaces, dot notation for identifier keys, minimal
  quoting of strings, implicit keys for the array part of tables.
  * **portable** between LuaJIT 2, Lua 5.1, Lua 5.2: dot key notation only
  for ascii identifiers, numbers are in decimal, NaN and ±Inf are written
  as 0/0, 1/0 and -1/0 respectively.
  * **portable** between Windows, Linux, Mac: quoting of `\n` and `\r`
  protects binary integrity when opening in text mode.
  * **embeddable**: can be copy-pasted into Lua source code: quoting
  of `\0` and `\t` and all other control characters protects binary integrity
  with code editors.
  * **human readable**: indentation (optional, configurable); array part
  printed separately with implicit keys.
  * **stream-based**: the string bits are written with a writer function
  to minimize the amount of string concatenation and memory footprint.
  * **deterministic**: table keys can be optionally sorted, so that the
  output is usable with diff and checksum.
  * **non-identical**: object identity is not tracked and is not
  preserved (table references are dereferenced).

## Limitations

  * object identity is not preserved.
  * recursive: table nesting depth is stack-bound.
  * some fractions are not compact eg. the fraction 5/6 takes 19 bytes
  vs 8 bytes in its native double format.
  * strings need escaping which could become noticeable with large strings
  featuring many newlines, tabs, zero bytes, apostrophes, backslashes
  or control characters.
  * loading back the output with the Lua interpreter is not safe.

## API

### `pp(v1, ...)`

Print the arguments to standard output.
Only tables are pretty-printed, everything else gets printed raw.
Cycle detection, indentation and sorting of keys are enabled in this mode.
Unserializable values get a comment in place.
Functions are skipped entirely.

### `pp.write(write, v, options...)`

Pretty-print a value using a supplied write function that takes a string.
The options can be given in a table or as separate args:

  * `indent` - enable indentation eg. `'\t'` indents by one tab
  (default is compact output with no whitespace)
  * `parents` - enable cycle detection by passing `{}` or true
  * `quote` - string quoting to use eg. `'"'` (default is "'")
  * `line_term` - line terminator to use (default is `'\n'`)
  * `onerror` - enable error handling eg. `function(err_type, v, depth)
  error(err_type..': '..tostring(v)) end`
  * `sort_keys` - sort keys to get deterministic output.
  * `filter` - filter keys, values or key/value combinations:
  `filter(v[, k]) -> v|nil`

__Example:__

~~~{.lua}
local function chunks(t)
	return coroutine.wrap(function()
		return pp.write(coroutine.yield, t)
	end)
end

for s in chunks(t) do
	socket:send(s)
end
~~~

### `pp.save(path, v, options...)`

Pretty-print a value to a file.

### `pp.stream(f, v, options...)`

Pretty-print a value to an opened file.

### `pp.print(v, options...)`

Pretty-print a value to `io.stdout`.

### `pp.format(v, options...) -> s`

Pretty-print a value to a string.
