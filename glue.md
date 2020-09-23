---
tagline: assorted lengths of wire
---

## `local glue = require'glue'`

## API Summary
------------------------------------------------------------------ ---------------------------------------------------------
__math__
`glue.round(x[, p]) -> y`                                          round x to nearest integer or multiple of `p` (half up)
`glue.snap(x[, p]) -> y`                                           synonym for glue.round
`glue.floor(x[, p]) -> y`                                          round x down to nearest integer or multiple of `p`
`glue.ceil(x[, p]) -> y`                                           round x up to nearest integer or multiple of `p`
`glue.clamp(x, min, max) -> y`                                     clamp x in range
`glue.lerp(x, x0, x1, y0, y1) -> y`                                linear interpolation
`glue.nextpow2(x) -> y`                                            next power-of-2 number
__varargs__
`glue.pack(...) -> t`                                              pack varargs
`glue.unpack(t, [i] [,j]) -> ...`                                  unpack varargs
__tables__
`glue.count(t[, maxn]) -> n`                                       number of keys in table
`glue.index(t) -> dt`                                              switch keys with values
`glue.keys(t[,sorted|cmp]) -> dt`                                  make a list of all the keys
`glue.sortedpairs(t [,cmp]) -> iter() -> k, v`                     like pairs() but in key order
`glue.update(dt, t1, ...) -> dt`                                   merge tables - overwrites keys
`glue.merge(dt, t1, ...) -> dt`                                    merge tables - no overwriting
`glue.attr(t, k1 [,v])[k2] = v`                                    autofield pattern
__arrays__
`glue.extend(dt, t1, ...) -> dt`                                   extend an array
`glue.append(dt, v1, ...) -> dt`                                   append non-nil values to an array
`glue.shift(t, i, n) -> t`                                         shift array elements
`glue.map(t, field|f,...) -> t`                                    map f over t or select a column from an array of records
`glue.indexof(v, t, [i], [j]) -> i`                                scan array for value
`glue.binsearch(v, t, [cmp], [i], [j]) -> i`                       binary search in sorted array
`glue.reverse(t, [i], [j]) -> t`                                   reverse array in place
__strings__
`glue.gsplit(s,sep[,start[,plain]]) -> iter() -> e[,captures...]`  split a string by a pattern
`glue.lines(s[, opt]) -> iter() -> s`                              iterate the lines of a string
`glue.trim(s) -> s`                                                remove padding
`glue.esc(s [,mode]) -> pat`                                       escape magic pattern characters
`glue.tohex(s|n [,upper]) -> s`                                    string to hex
`glue.fromhex(s) -> s`                                             hex to string
`glue.starts(s, prefix) -> t|f`                                    find if string `s` starts with string `prefix`
`glue.ends(s, suffix) -> t|f`                                      find if string `s` ends with string `suffix`
`glue.subst(s, t) -> s`                                            string interpolation of `{foo}` occurences
__iterators__
`glue.collect([i,] iterator) -> t`                                 collect iterated values into an array
__stubs__
`glue.pass(...) -> ...`                                            does nothing, returns back all arguments
`glue.noop(...)`                                                   does nothing, returns nothing
__caching__
`glue.memoize(f[, narg]) -> f`                                     memoize pattern
`glue.memoize_multiret(f[, narg]) -> f`                            memoize for multiple-return-value functions
`glue.tuples([narg]) -> f(...) -> t`                               tuple pattern
__objects__
`glue.inherit(t, parent) -> t`                                     set or clear inheritance
`glue.object([super][, t], ...) -> t`                              create a class or object (see description)
`glue.before(class, method_name, f)`                               call f at the beginning of a method
`glue.after(class, method_name, f)`                                call f at the end of a method
`glue.override(class, method_name, f)`                             override a method
`glue.gettersandsetters([getters], [setters], [super]) -> mt`      create a metatable that supports virtual properties
__i/o__
`glue.canopen(filename[, mode]) -> filename | nil`                 check if a file exists and can be opened
`glue.readfile(filename[, format][, open]) -> s | nil, err`        read the contents of a file into a string
`glue.readpipe(cmd[,format][, open]) -> s | nil, err`              read the output of a command into a string
`glue.writefile(filename, s|t|read, [format], [tmpfile])`          write data to file safely
`glue.printer(out[, format]) -> f`                                 virtualize the print() function
__time__
`glue.time([utc, ][t]) -> ts`                                      like `os.time()` with optional UTC and date args
`glue.time([utc, ][y, [m], [d], [h], [min], [s], [isdst]]) -> ts`  like `os.time()` with optional UTC and date args
`glue.utc_diff() -> seconds`                                       seconds to UTC
`glue.day([utc, ][ts], [plus_days]) -> ts`                         timestamp at day's beginning from `ts`
`glue.month([utc, ][ts], [plus_months]) -> ts`                     timestamp at month's beginning from `ts`
`glue.year([utc, ][ts], [plus_years]) -> ts`                       timestamp at year's beginning from `ts`
__errors__
`glue.assert(v [,message [,format_args...]]) -> v`                 assert with error message formatting
`glue.protect(func) -> protected_func`                             wrap an error-raising function
`glue.pcall(f, ...) -> true, ... | false, traceback`               pcall with traceback
`glue.fpcall(f, ...) -> result | nil, traceback`                   coding with finally and except
`glue.fcall(f, ...) -> result`
__modules__
`glue.module([name, ][parent]) -> M`                               create a module
`glue.autoload(t, submodules) -> M`                                autoload table keys from submodules
`glue.autoload(t, key, module|loader) -> t`                        autoload table keys from submodules
`glue.bin`                                                         get the script's directory
`glue.luapath(path [,index [,ext]])`                               insert a path in package.path
`glue.cpath(path [,index])`                                        insert a path in package.cpath
__allocation__
`glue.freelist([create], [destroy]) -> alloc, free`                freelist allocation pattern
`glue.buffer(ctype) -> alloc(minlen) -> buf,capacity`              auto-growing buffer
`glue.dynarray(ctype) -> alloc(minlen|false) -> buf, minlen`       auto-growing buffer that preserves data
__ffi__
`glue.addr(ptr) -> number | string`                                store pointer address in Lua value
`glue.ptr([ctype, ]number|string) -> ptr`                          convert address to pointer
`glue.getbit(val, mask) -> true|false`                             get the value of a single bit from an integer
`glue.setbit(val, mask, bitval) -> val`                            set the value of a single bit from an integer
`glue.bor(flags, bits, [strict]) -> mask`                          `bit.bor()` that takes a string or table
------------------------------------------------------------------ ---------------------------------------------------------

## Math

### `glue.round(x[, p]) -> y` <br> `glue.snap(x[, p]) -> y`

Round a number towards nearest integer or multiple of `p`.
Implemented as `math.floor(x / p + .5) * p`.
Rounds half-up (i.e. it returns `-1` for `-1.5`).
Works with numbers up to `+/-2^52`.
It's not dead accurate as it returns eg. `1` instead of `0`
for `0.49999999999999997` (the number right before `0.5`) which is < `0.5`.

## `glue.floor(x[, p]) -> y`

Round a number towards nearest smaller integer or multiple of `p`.
Implemented as `math.floor(x / p) * p`.

## `glue.ceil(x[, p]) -> y`

Round a number towards nearest larger integer or multiple of `p`.
Implemented as `math.ceil(x / p) * p`.

### `glue.clamp(x, min, max)`

Clamp a value in range. Implemented as `math.min(math.max(x, min), max)`,
so if `max < min`, the result is `max`.

### `glue.lerp(x, x0, x1, y0, y1) -> y`

Linear interpolation, i.e. linearly project `x` in `x0..x1` range to
the `y0..y1` range.

### `glue.nextpow2(x) -> y`

Find the smallest `n` for which `x <= 2^n`.

------------------------------------------------------------------------------

## Varargs

### `glue.pack(...) -> t`

Pack varargs. Implemented as `n = select('#', ...), ...}`.

### `glue.unpack(t,[i][,j]) -> ...`

Unpack varargs. Implemented as `unpack(t, i or 1, j or t.n or #t)`.

------------------------------------------------------------------------------

## Tables

### `glue.count(t[, maxn]) -> n`

Count the keys in a table, optionally up to `maxn`.

------------------------------------------------------------------------------

### `glue.index(t) -> dt`

Switch table keys with values.

#### Examples

Extract a rfc850 date from a string. Use lookup tables for weekdays and months.

~~~{.lua}
local weekdays = glue.index{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'}
local months = glue.index{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}

--weekday "," SP 2DIGIT "-" month "-" 2DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
--eg. Sunday, 06-Nov-94 08:49:37 GMT
function rfc850date(s)
   local w,d,mo,y,h,m,s = s:match'([A-Za-z]+), (%d+)%-([A-Za-z]+)%-(%d+) (%d+):(%d+):(%d+) GMT'
   d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
   w = assert(weekdays[w])
   mo = assert(months[mo])
   if y then y = y + (y > 50 and 1900 or 2000) end
   return {wday = w, day = d, year = y, month = mo, hour = h, min = m, sec = s}
end

for k,v in pairs(rfc850date'Sunday, 06-Nov-94 08:49:37 GMT') do
   print(k,v)
end
~~~

Output

	day	6
	sec	37
	wday	1
	min	49
	year	1994
	month	11
	hour	8


Copy-paste a bunch of defines from a C header file and create an inverse
lookup table to find the name of a value at runtime.

~~~{.lua}
--from ibase.h
info_end_codes = {
   isc_info_end             = 1,  --normal ending
   isc_info_truncated       = 2,  --receiving buffer too small
   isc_info_error           = 3,  --error, check status vector
   isc_info_data_not_ready  = 4,  --data not available for some reason
   isc_info_svc_timeout     = 64, --timeout expired
}
info_end_code_names = glue.index(info_end_codes)
print(info_end_code_names[64])
~~~

Output

	isc_info_svc_timeout

------------------------------------------------------------------------------

### `glue.keys(t[,sorted|cmp]) -> dt`

Make an array of all the keys of `t`, optionally sorted. The second arg
can be `true`, `'asc'`, `'desc'` or a comparison function.

#### Examples

An API expects an array of things but you have them as keys in a table because
you are indexing something on them.

For instance, you have a table of the form `{socket = thread}` but
`socket.select` wants an array of sockets.

------------------------------------------------------------------------------

### `glue.sortedpairs(t[,cmp]) -> iter() -> k,v`

Like pairs() but in key order.

The implementation creates a temporary table to sort the keys in.

------------------------------------------------------------------------------

### `glue.update(dt,t1,...) -> dt`

Update a table with elements of other tables, overwriting any existing keys.

  * falsey arguments are skipped.

#### Examples

Create an options table by merging the options received as an argument
(if any) over the default options.

~~~{.lua}
function f(opts)
   opts = glue.update({}, default_opts, opts)
end
~~~

Shallow table copy:

~~~{.lua}
t = glue.update({}, t)
~~~

Static multiple inheritance:

~~~{.lua}
C = glue.update({}, A, B)
~~~

------------------------------------------------------------------------------

### `glue.merge(dt,t1,...) -> dt`

Update a table with elements of other tables skipping on any existing keys.

  * falsey arguments are skipped.

#### Examples

Normalize a data object with default values:

~~~{.lua}
glue.merge(t, defaults)
~~~

------------------------------------------------------------------------------

### `glue.attr(t,k1[,v])[k2] = v`

Idiom for `t[k1][k2] = v` with auto-creating of `t[k1]` if not present.

------------------------------------------------------------------------------

## Arrays

### `glue.extend(dt,t1,...) -> dt`

Extend an array with the elements of other arrays.

  * falsey arguments are skipped.
  * array elements are the ones from 1 to `#dt`.

#### Uses

Accumulating values from multiple array sources.

------------------------------------------------------------------------------

### `glue.append(dt,v1,...) -> dt`

Append non-nil arguments to an array.

#### Uses

Appending an object to a flattened array of arrays (eg. appending a path
element to a 2d path).

------------------------------------------------------------------------------

### `glue.shift(t,i,n) -> t`

Shift all the array elements starting at index `i`, `n` positions to the left
or further to the right.

For a positive `n`, shift the elements further to the right, effectively
creating room for `n` new elements at index `i`. When `n` is 1, the effect
is the same as for `table.insert(t, i, t[i])`. The old values at index `i`
to `i+n-1` are preserved, so `#t` still works after the shifting.

For a negative `n`, shift the elements to the left, effectively removing
`n` elements at index `i`. When `n` is -1, the effect is the same as for
`table.remove(t, i)`.

#### Uses

Removing a portion of an array or making room for more elements inside the array.

------------------------------------------------------------------------------

### `glue.map(t, field|f,...) -> t`

Map function `f(v, ...) -> v1` over the array elements of `t` or, if the array
part is empty, map `f(k, v, ...) -> v1` over the pairs of `t`.

If `f` is not a function, then the values of `t` must be themselves tables,
in which case `f` is a key to pluck from those tables. Plucked functions
are called as methods and their result is selected instead (this allows eg.
calling a method for each element in an array or map of objects and collecting
the results in an array/map).

------------------------------------------------------------------------------

### `glue.indexof(v, t, [i], [j]) -> i`

Scan an array for a value and if found, return the index.

__NOTE:__ Works on ffi arrays too if `i` and `j` are provided.

------------------------------------------------------------------------------

### `glue.binsearch(v, t, [cmp], [i], [j]) -> i`

Return the smallest index whereby inserting the value `v` in sorted array `t`
will keep `t` sorted i.e. `t[i-1] < v` and `t[i] >= v`. Return `nil` if `v`
is larger than the largest value or if `t` is empty.

The comparison function `cmp` is called as `cmp(t, i, v)` and must return
`true` when `t[i] < v`. Built-in functions are also available by passing
one of `'<'`, `'>'`, `'<='`, `'>='`.

__TIP:__ Use a `cmp` that returns `true` when `t[i] > v` to search in a
reverse-sorted array (i.e. use `'>'`).

__TIP:__ Use a `cmp` that returns `true` when `t[i] <= v` to get the *largest*
index (as opposed to the *smallest* index) that will keep `t` sorted when
inserting `v`, i.e. `t[i-1] <= v` and `t[i] > v`.

__NOTE:__ Works on ffi arrays too if `i` and `j` are provided.

------------------------------------------------------------------------------

### `glue.reverse(t, [i], [j]) -> t`

Reverse an array in-place and return the input arg.

__NOTE:__ Works on ffi arrays too if `i` and `j` are provided.

------------------------------------------------------------------------------

## Strings

### `glue.gsplit(s,sep[,start[,plain]]) -> iter() -> e[,captures...]`

Split a string by a separator pattern (or plain string) and iterate over
the elements.

  * if sep is "" return the entire string in one iteration
  * if s is "" return s in one iteration
  * empty strings between separators are always returned,
  eg. `glue.gsplit(',', ',')` produces 2 empty strings
  * captures are allowed in sep and they are returned after the element,
    except for the last element for which they don't match (by definition).

#### Examples

~~~{.lua}
for s in glue.gsplit('Spam eggs spam spam and ham', '%s*spam%s*') do
   print('"'..s..'"')
end

> "Spam eggs"
> ""
> "and ham"
~~~

------------------------------------------------------------------------------

### `glue.lines(s[, opt]) -> iter() -> s`

Iterate the lines of a string.

  * the lines are split at `\r\n`, `\r` and `\n` markers.
  * the line ending markers are included or excluded depending on the second
  arg, which can be `*L` (include line endings; default) or `*l` (exclude).
  * if the string is empty or doesn't contain a line ending marker, it is
  iterated once.
  * if the string ends with a line ending marker, one more empty string is
  iterated.

------------------------------------------------------------------------------

### `glue.trim(s) -> s`

Remove whitespace (defined as Lua pattern `"%s"`) from the beginning and end of a string.

------------------------------------------------------------------------------

### `glue.esc(s[,mode]) -> pat`

Escape magic characters of the string `s` so that it can be used as a pattern
to string matching functions.

  * the optional argument `mode` can have the value `"*i"` (for case
  insensitive), in which case each alphabetical character in `s` will also be
  escaped as `"[aA]"` so that it matches both its lowercase and uppercase
  variants.
  * escapes embedded zeroes as the `%z` pattern.

#### Uses

  * workaround for lack of pattern syntax for "this part of a match is an
  arbitrary string"
  * workaround for lack of a case-insensitive flag in pattern matching
  functions

------------------------------------------------------------------------------

### `glue.tohex(s|n[,upper]) -> s`

Convert a binary string or a Lua number to its hex representation.

  * lowercase by default
  * uppercase if the arg `upper` is truthy
  * numbers must be in the unsigned 32 bit integer range

------------------------------------------------------------------------------

### `glue.fromhex(s) -> s`

Convert a hex string to its binary representation.

------------------------------------------------------------------------------

### `glue.starts(s, prefix) -> t|f`

Find if string `s` starts with `prefix`. Implemented as `s:sub(1, #p) == p`
which is 5x faster than `s:find'^...'` in LuaJIT 2.1 with JIT on (and about
the same with jit off).

------------------------------------------------------------------------------

### `glue.ends(s, suffix) -> t|f`

Find if string `s` ends with `suffix`.

------------------------------------------------------------------------------

### `glue.subst(s, t) -> s`

Replace all `{foo}` occurences within `s` with `t.foo`.

------------------------------------------------------------------------------

## Iterators

### `glue.collect([i,]iterator) -> t`

Iterate an iterator and collect its i'th return value of every step into an array.

  * i defaults to 1

#### Examples

Implementation of `keys()` and `values()` in terms of `collect()`

~~~{.lua}
keys = function(t) return glue.collect(pairs(t)) end
values = function(t) return glue.collect(2,pairs(t)) end
~~~

Collecting string matches:

~~~{.lua}
s = 'a,b,c,'
t = glue.collect(s:gmatch'(.-),')
for i=1,#t do print(t[i]) end

> a
> b
> c
~~~

------------------------------------------------------------------------------

## Stubs

### `glue.pass(...) -> ...`

The identity function. Does nothing, returns back all arguments.

#### Uses

Default value for optional callback arguments:

~~~{.lua}
function urlopen(url, callback, errback)
   callback = callback or glue.pass
   errback = errback or glue.pass
   ...
   callback()
end
~~~

### `glue.noop()`

Does nothing. Returns nothing.

------------------------------------------------------------------------------

## Caching

### `glue.memoize(f[, narg]) -> f`

### `glue.memoize_multiret(f[, narg]) -> f`

Memoization for functions with any number of arguments. `memoize()` supports
functions with _one return value_. `memoize_multiret()` supports any function.
Both support `nil` and `NaN` args and retvals.

Memoization guarantees to only call the original function _once_ for the same
combination of arguments.

Special attention is given to the vararg part of the function, if any. For
instance, for a function `f(x, y, ...)`, calling `f(1)` is considered to be
the same as calling `f(1, nil)`, but calling `f(1, nil)` is not the same as
calling `f(1, nil, nil)`.

The optional `narg` fixates the function to always take exactly `narg` args
regardless of how the function was defined.

### `glue.tuples([narg]) -> f(...) -> t`

Create a tuple space, which is a function that returns the same identity `t`
for the same list of arguments. It is implemented as:

```lua
local tuple_mt = {__call = glue.unpack}
function glue.tuples(narg)
	return glue.memoize(function(...)
		return setmetatable(glue.pack(...), tuple_mt)
	end)
end
```

The result tuple can be expanded back by calling it: `t() -> args...`.

------------------------------------------------------------------------------

## Objects

### `glue.inherit(t, parent) -> t` <br> `glue.inherit(t, nil) -> t`

Set a table to inherit attributes from a parent table, or clear inheritance.

If the table has no metatable and inheritance has to be set, not cleared,
then make it one.

#### Examples

Logging mixin:

~~~{.lua}
AbstractLogger = glue.inherit({}, function(t,k) error('abstract '..k) end)
NullLogger = glue.inherit({log = function() end}, AbstractLogger)
PrintLogger = glue.inherit({log = function(self,...) print(...) end}, AbstractLogger)

HttpRequest = glue.inherit({
   perform = function(self, url)
      self:log('Requesting', url, '...')
      ...
   end
}, NullLogger)

LoggedRequest = glue.inherit({log = PrintLogger.log}, HttpRequest)

LoggedRequest:perform'http://lua.org/'

> Requesting	http://lua.org/	...
~~~

Defining a module in Lua 5.2

~~~{.lua}
_ENV = glue.inherit({},_G)
...
~~~

To get the effect of static (single or multiple) inheritance, use `glue.update`.

When setting inheritance, you can pass in a function.

Unlike `glue.object`, this doesn't add any keys to the object.

------------------------------------------------------------------------------

### `glue.object([super][, t], ...) -> t`

Create a class or object from `t` (which defaults to `{}`) by setting `t`
as its own metatable, setting `t.__index` to `super` and `t.__call` to
`super.__call`. Extra args are passed to `glue.update(self, ...)`.
This simple object model has the following qualities:

  * the implementation is only 4 LOC (14 LOC if extra args are used) and can
  thus be copy-pasted into any module to avoid a dependency on the glue library.
  * funcall-style instantiation with `t(...)` which calls `t:__call(...)`.
  * small memory footprint (3 table slots and no additional tables).
  * subclassing from instances is allowed (prototype-based inheritance).
  * `glue.object` can serve as a stub class/instance constructor:
  `t.__call = glue.object` (`t.new = glue.object` works too).
  * a separate constructor to be used only for subclassing can be made with
  the same pattern: `t.subclass = glue.object`.
  * virtual classes (aka dependency injection, aka nested inner classes
  whose fields and methods can be overridden by subclasses of the outer
  class): composite objects which need to instantiate other objects can be
  made extensible by exposing those objects' classes as fields of the
  container class with `container_class.inner_class = inner_class` and
  instantiating with `self.inner_class(...)` so that replacing `inner_class`
  in a sub-class of `container_class` is possible. Moreso, instantiation with
  `self:inner_class(...)` (so with a colon) passes the container object to
  `inner_class`'s constructor automatically which allows referencing the
  container object from the inner object.
  * overriding syntax sugar so that the super class need not be referenced
  explicitly when overriding can be incorporated into the base class with
  `base.override = glue.override`.

------------------------------------------------------------------------------

### `glue.before(class, method_name, f)`

Modify a method such that it calls `f` at the beginning. `f` receives all
the arguments passed to the method. `f`'s results are discarded.

Usage:

```lua
glue.before(foo, 'bar', function(self, ...)
    ...
end)
```

Alternatively,

```lua
foo.before = glue.before
foo:before('bar', function(self, ...)
  ...
end)
```
------------------------------------------------------------------------------

### `glue.after(class, method_name, f)`

Modify a method such that it calls `f` at the end. `f` receives all the
arguments passed to the method. The modified method returns what `f` returns.

Usage:

```lua
glue.after(foo, 'bar', function(self, ...)
    ...
end)
```

Alternatively,

```lua
foo.after = glue.after
foo:after('bar', function(self, ...)
  ...
end)
```
------------------------------------------------------------------------------

### `glue.override(class, method_name, f)`

Override a method such that the new implementation only calls `f` as
`f(inherited, self, ...)` where `inherited` is the old implementation.
`f` receives all the method arguments and the method returns what `f` returns.

Usage:

```lua
glue.override(foo, 'bar', function(inherited, self, ...)
  ...
  local ret = inherited(self, ...)
  ...
end)
```

Alternatively,

```lua
foo.override = glue.override
foo:override('bar', function(inherited, self, ...)
  ...
  local ret = inherited(self, ...)
  ...
end)
```
------------------------------------------------------------------------------

### `glue.gettersandsetters([getters], [setters], [super]) -> mt`

Return a metatable that supports virtual properties with getters and setters.
Can be used with setmetatable() and ffi.metatype(). `super` is for preserving
the functionality of `__index` while `__index` is being used for getters.

------------------------------------------------------------------------------

## I/O

### `glue.canopen(file[, mode]) -> filename | nil`

Checks whether a file exists and it's available for reading or writing.
The `mode` arg is the same as for [io.open] and defaults to 'rb'.

------------------------------------------------------------------------------

### `glue.readfile(filename[,format][,open]) -> s | nil, err`

Read the contents of a file into a string.

  * `format` can be `"t"` in which case the file will be read in text mode
  (default is binary mode).
  * `open` is the file open function which defaults to `io.open`.

------------------------------------------------------------------------------

### `glue.readpipe(cmd[,format][,open]) -> s | nil, err`

Read the output of a command into a string.
The options are the same as for `glue.readfile`.

------------------------------------------------------------------------------

### `glue.replacefile(oldpath, newpath)`

Move or rename a file. If `newpath` exists and it's a file, it is replaced
by the old file atomically. The operation can still fail under many
circumstances like if `newpath` is a directory or if the files are
in different filesystems or if `oldpath` is missing or locked, etc.

For consistent behavior across OSes, both paths should be absolute paths
or just filenames.

On LuaJIT, this is implemented based on `MoveFileExA` on Windows.

------------------------------------------------------------------------------

### `glue.writefile(filename,s|t|read,[format],[tmpfile]) -> ok, err`

Write the contents of a string, table or iterator to a file.

  * the contents can be given as a string, an array of strings, or a function
  that returns a string or `nil` to signal end-of-stream.
  * `format` can be `"t"` in which case the file will be written in text mode
   (default is binary mode).
  * if writing fails and `tmpfile` is not given, the file is removed; if
  `tmpfile` is given then the data is written to that file first which is
  then renamed to `filename` and if writing or renaming fails the temp file
  is removed and `filename` is not touched.

------------------------------------------------------------------------------

### `glue.printer(out[, format]) -> f`

Create a `print()`-like function which uses the function `out` to output
its values and uses the optional `format` to format each value. For instance
`glue.printer(io.write, tostring)` returns a function which behaves like
the standard `print()` function.

------------------------------------------------------------------------------

### `glue.time([utc, ][t]) -> ts` <br> `glue.time([utc, ][year, [month], [day], [hour], [min], [sec], [isdst]]) -> ts`

Like `os.time()` but considers the time to be in UTC if either `utc`
or `t.utc` is `true`.

__NOTE:__ You should only use `os.date()` and `os.time()` and therefore
`glue.time()` for current dates and use something else for historical dates
because these functions don't work with negative timestamps because
apparently time didn't exist before UNIX. At least they don't suffer from
Y2038 so that's that.

__NOTE:__ `os.time()` has second accuracy (so those timestamps are integers).
For sub-second accuracy use the [time] module.

------------------------------------------------------------------------------

### `glue.utc_diff() -> seconds`

Difference between local time and UTC in seconds.

------------------------------------------------------------------------------

### `glue.day([utc, ][ts], [plus_days]) -> ts`

Timestamp at day's beginning from `ts`, plus/minus some days.

------------------------------------------------------------------------------

### `glue.month([utc, ][ts], [plus_months]) -> ts`

Timestamp at month's beginning from `ts`, plus/minus some months.

------------------------------------------------------------------------------

### `glue.year([utc, ][ts], [plus_years]) -> ts`

Timestamp at year's beginning from `ts`, plus/minus some years.

------------------------------------------------------------------------------

## Errors

### `glue.assert(v[,message[,format_args...]])`

Like `assert` but supports formatting of the error message using
`string.format()`.

This is better than `assert(v, string.format(message, format_args...))`
because it avoids creating the message string when the assertion is true.

__CAVEAT__: Unlike standard `assert()`, this only returns its first argument
even when no message is given, to avoid returning the error message and its
args when a message is given and the assertion is true. So the pattern
`a, b = glue.assert(f())` doesn't work.

#### Example

~~~{.lua}
glue.assert(depth <= maxdepth, 'maximum depth %d exceeded', maxdepth)
~~~

------------------------------------------------------------------------------

### `glue.protect(func) -> protected_func`

In Lua, API functions conventionally signal errors by returning nil and
an error message instead of raising errors.
In the implementation however, using assert() and error() is preferred
to coding explicit conditional flows to cover exceptional cases.
Use this function to convert error-raising functions to nil,err-returning
functions:

~~~{.lua}
protected_function = glue.protect(function()
	...
	assert(...)
	...
	error(...)
	...
	return result_value
end)

local ret, err = protected_function()
~~~

------------------------------------------------------------------------------

### `glue.pcall(f,...) -> true,... | false,traceback`

With Lua's pcall() you lose the stack trace, and with usual uses of pcall()
you don't want that. This variant appends the traceback to the error message.

> __NOTE__: Lua 5.2 and LuaJIT only.

------------------------------------------------------------------------------

### `glue.fpcall(f,...) -> result | nil,traceback`

### `glue.fcall(f,...) -> result`

These constructs bring the try/finally/except idiom to Lua. The first variant
returns nil,error when errors occur while the second re-raises the error.

#### Example

~~~{.lua}
local result = glue.fpcall(function(finally, except, ...)
  local temporary_resource = acquire_resource()
  finally(function() temporary_resource:free() end)
  ...
  local final_resource = acquire_resource()
  except(function() final_resource:free() end)
  ... code that might break ...
  return final_resource
end, ...)
~~~

------------------------------------------------------------------------------

## Modules

### `glue.module([name, ][parent]) -> M, P`

### `glue.module([parent, ][name]) -> M, P`

Create a module with a public and private namespace and set the environment
of the calling function (not the global one!) to the module's private
namespace and return the namespaces. Cross-references between the namespaces
are also created at `M._P`, `P._M`, `P._P` and `M._M`, so both `_P` and `_M`
can be accessed directly from the new environment.

`parent` controls what the namespaces will inherit and it can be either
another module, in which case `M` inherits `parent` and `P` inherits
`parent._P`, or it can be a string in which case the module to inherit is
first required. `parent` defaults to `_M` so that calling `glue.module()`
creates a submodule of the current module. If there's no `_M` in the current
environment then `P` inherits `_G` and `M` inherits nothing.

Specifying a `name` for the module either returns `package.loaded[name]`
if it is set or creates a module, sets `package.loaded[name]` to it and
returns that. This is useful for creating and referencing shared namespaces
without having to make a Lua file and require that.

Naming the module also sets `P[name] = M` so that public symbols can be
declared in `foo.bar` style instead of `_M.bar`.

Setting `foo.module = glue.module` makes module `foo` directly extensible
by calling `foo:module'bar'` or `require'foo':module'bar'`.

_This function is 27 LOC._

### `glue.autoload(t, submodules) -> t` <br> `glue.autoload(t, key, module|loader) -> t`

Assign a metatable to `t` (or override an existing metatable's `__index`) such
that when a missing key is accessed, the module said to contain that key is
require'd automatically.

The `submodules` argument is table of form `{key = module_name | load_function}`
specifying the corresponding Lua module (or load function) that make each key
available to `t`. The alternative syntax allows specifying the key - submodule
associations one by one.

#### Motivation

Module autoloading allows splitting the implementation of a module in many
submodules containing optional, self-contained functionality, without having
to make this visible in the user API. This effectively disconnects how an API
is modularized from how its implementation is modularized, allowing the
implementation to be refactored at a later time without changing the API.

#### Example

**main module (foo.lua):**

~~~{.lua}
local function bar() --function implemented in the main module
  ...
end

--create and return the module table
return glue.autoload({
   ...
   bar = bar,
}, {
   baz = 'foo_extra', --autoloaded function, implemented in module foo_extra
})
~~~

**submodule (foo_extra.lua):**

~~~{.lua}
local foo = require'foo'

function foo.baz(...)
  ...
end
~~~

**in usage:**

~~~{.lua}
local foo = require'foo'

foo.baz(...) -- foo_extra was now loaded automatically
~~~

------------------------------------------------------------------------------

### `glue.bin`

Get the script's directory. This allows finding files in the script's
directory regardless of the directory that Lua is started in.

For executables created with [bundle], this is the executable's directory.

#### Example

~~~{.lua}
local foobar = glue.readfile(glue.bin .. '/' .. file_near_this_script)
~~~

#### Caveats

This only works if glue itself can already be found and required
(chicken/egg problem). Also, the path is relative to the current directory,
so this stops working as soon as the current directory is changed.
Also, depending on how the process was started, this information might be
missing or wrong since it's set by the parent process. Better use
[fs].exedir which has none of these problems.

------------------------------------------------------------------------------

### `glue.luapath(path[,index[,ext]])`

Insert a Lua search pattern in `package.path` such that `require` will be able
to load Lua modules from that path. The optional `index` arg specifies the
insert position (default is 1, that is, before all existing paths; can be
negative, to start counting from the end; can be the string 'after', which is
the same as 0). The optional `ext` arg specifies the file extension to use
(default is "lua").

------------------------------------------------------------------------------

### `glue.cpath(path[,index])`

Insert a Lua search pattern in `package.cpath` such that `require` will be
able to load Lua/C modules from that path. The `index` arg has the same
meaning as with `glue.luapath`.

#### Example

~~~{.lua}
glue.luapath(glue.bin)
glue.cpath(glue.bin)

require'foo' --looking for `foo` in the same directory as the running script first
~~~

------------------------------------------------------------------------------

## Allocation

### `glue.freelist([create], [destroy]) -> alloc, free`

Returns `alloc() -> e` and `free(e)` functions to allocate and deallocate
Lua objects. The allocator returns the last freed object or calls `create()`
to create a new one if the freelist is empty. `create` defaults to
`function() return {} end`; `destroy` defaults to `glue.noop`.

------------------------------------------------------------------------------

### `glue.buffer(ctype) -> alloc(minlen|false) -> buf, capacity`

(LuaJIT only) Return an allocation function that reuses or reallocates
an internal buffer based on the `len` argument.

  * `ctype` must be a VLA: the returned buffer will have that type.
    this makes `glue.buffer(ctype)` compatible with `ffi.typeof(ctype)`.
  * the buffer only grows, it never shrinks and it only grows in
    powers of two steps.
  * the allocation function returns the buffer's current capacity which
    can be equal or greater than the requested length.
  * the returned buffer is anchored by the allocation function. calling
    `alloc(false)` unanchores the buffer.
  * the contents of the buffer _are not preserved_ between allocations
    but you _are allowed_ to access both buffers between two consecutive
    allocations in order to do that yourself.

------------------------------------------------------------------------------

### `glue.dynarray(ctype) -> alloc(minlen|false) -> buf, minlen`

Like `glue.buffer()` but preserves data between reallocations, and always
returns `minlen` instead of capacity.

------------------------------------------------------------------------------

## FFI

### `glue.addr(ptr) -> number | string`

Convert the address of a pointer into a Lua number (or possibly string
on 64bit platforms). This is useful for:

  * hashing on pointer values (i.e. using pointers as table keys)
  * moving pointers in and out of Lua states when using [luastate]

### `glue.ptr([ctype,]number|string) -> ptr`

Convert an address value stored as a Lua number or string to a cdata pointer,
optionally specifying a ctype for the pointer (defaults to `void*`).

------------------------------------------------------------------------------

### `glue.getbit(val, mask) -> true|false`

Get the value of a single bit from an integer.

### `glue.setbit(val, mask, bitval) -> val`

Set the value of a single bit from an integer.

### `glue.bor(flags, bits, [strict]) -> mask`

`bit.bor()` that takes its arguments as a string of form `'opt1 opt2 ...'`,
a list of form `{'opt1', 'opt2', ...}` or a map of form `{opt->true}`
and performs `bit.bor()` on the numeric values of those arguments where
the numeric values are given as the `bits` table of form `{opt->bitvalue}`.

Useful for Luaizing C functions that take bitmask flags.

Example: `glue.bor('a c', {a=1, b=2, c=4}) -> 5`.

------------------------------------------------------------------------------

## Tips

String functions are also in the `glue.string` table.
You can extend the Lua `string` namespace:

	`glue.update(string, glue.string)`

so you can use them as string methods:

	`s:trim()`

## Design

[glue_design]

