---
tagline: the Terra language
---

## `local terra = require'terra'`

<<<<<<< HEAD
This is a modified build of the [Terra][terralang] library which allows 
the Terra runtime to be loaded from Lua as a Lua/C module. 
The terra module exposes the complete Terra Lua API and installs 
a require() loader for loading .t files from the same locations 
that are used for loading Lua files.

[terralang]: http://terralang.org

## Binaries

Because binaries are huge, they are released [separately].

[separately]: https://github.com/luapower/terra/releases

## Building

Building terra requires [llvm].
=======
This is a slightly modified build of the [Terra][terralang] library
which allows the Terra runtime to be loaded from Lua as a Lua/C module.
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
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545

## Changes to terra

The [source code changes] made to terra were kept to a minimum to make it
easy to to merge [upstream changes] back into the luapower terra fork.
This is similar to how [dynasm] was modified for luapower. 
Anyway, the changelist:

  * the `terra` dynamic lib does not bundle luajit and is exposed as a Lua/C module.
<<<<<<< HEAD
  * the `terra` static lib bundles LLVM + Clang so that the llvm package
  is not needed to [bundle] Terra, only to build it.
  * `terralib.lua` and `cudalib.lua` are not bundled into the binary.
=======
  * `terralib.lua` and `cudalib.lua` are not bundled into the binary, 
  and are provided separately.
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
  * `strict.lua` is not loaded and not included (it's included with [luajit]
  and must be loaded manually as needed).
  * `std.t` and `parsing.t` were renamed `terra_std.t` and `terra_parsint.t`.
  respectively and are now in the luapower dir along with all Lua files.
<<<<<<< HEAD
  * `libterra.so` was renamed `libterra.dylib` on OSX.
  * clang's `resource_dir` is `bin/<platform>/include`.
=======
  * the location of clang's `resource_dir` is yet to be determined.
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545


[source code changes]: https://github.com/luapower/terra_fork/compare/aa9501...luapower:master
[upstream changes]:    https://github.com/luapower/terra_fork/compare/aa9501...zdevito:master
