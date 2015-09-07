---
tagline: the Terra language
---

## `local terra = require'terra'`

This is a modified build of the [Terra][terralang] library which allows
the Terra runtime to be loaded from Lua as a Lua/C module.
The terra module exposes the complete Terra Lua API and installs
a require() loader for loading .t files from the same locations
that are used for loading Lua files.

__NOTE:__ 32bit platforms are not yet supported (the included binaries
work but there's no interfacing between Terra and Lua and no debug support).

[terralang]: http://terralang.org

## Building

Building terra requires [llvm].

## Bundling

[Bundling](/bundle) terra requires bunding in the [llvm] static libraries.
There's a script documenting what these are that can be used with bundle
directly:

	bundle ... -a terra -a "$(csrc/terra/bundle-libs)"

## Changes to terra

The [source code changes] made to terra were kept to a minimum to make it
easy to to merge [upstream changes] back into the luapower terra fork.
This is similar to how [dynasm] was modified for luapower.
Anyway, the changelist:

  * the `terra` dynamic lib does not bundle luajit and is exposed as a Lua/C module.
  * `terralib.lua` and `cudalib.lua` are not bundled into the binary,
  and are provided separately.
  * `strict.lua` is not loaded and not included (it's included with [luajit]
  and must be loaded manually as needed).
  * `std.t` and `parsing.t` were renamed `terra_std.t` and `terra_parsint.t`.
  respectively and are now in the luapower dir along with all Lua files.
  * `libterra.so` was renamed `libterra.dylib` on OSX.
  * clang's `resource_dir` is `bin/<platform>/include`.


[source code changes]: https://github.com/luapower/terra_fork/compare/aa9501...luapower:master
[upstream changes]:    https://github.com/luapower/terra_fork/compare/aa9501...zdevito:master
