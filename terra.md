---
tagline: the Terra language
---

## `local terra = require'terra'`

This is a slightly modified build of the [Terra][terralang] library
which allows the Terra runtime to be loaded from Lua as a Lua/C module.
The terra module exposes the complete Terra Lua API and installs
a require() loader for loading .t files from the same locations
that are used for loading Lua files.

__NOTE:__ Terra only runs on x86-64!

__NOTE:__ On Windows Terra is compiled with luapower's mingw64 toolchain
so there's no need to install Visual Studio to use standard C headers.
Instead, mingw64 headers are provided in the [mingw64-headers] package.

__NOTE:__ The CUDA backend is not available in this build.

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

  * the `terra` dynamic lib does not bundle luajit and is instead exposed as
  a normal Lua/C module that must be included with `require'terra'` from Lua.
  * LuaJIT was modified to `require'terra'` if loading a `*.t` file, and to
  load the file via `_G.loadfile` instead of `lua_loadfile`.
  * `terralib.lua` was changed to load `terralib_luapower.lua` at the end of
  the file, which changes the following:
    * `loadfile` is overloaded to call `terra.loadfile` for `*.t` files.
    * `terralib.terrahome` is set to `package.exedir`.
    * `package.terrapath` is set to match `package.path`.
    * `terralib.linklibrary` is modified to also accept `foo` for `libfoo.so`
    and `libfoo.dylib` respectively, just like `ffi.load` does.
  * `terralib.lua`, `asdl.lua` and `terralist.lua` are not bundled into the
  binary and are provided separately.
  * `strict.lua` is not loaded and not included (it's included with [luajit]
  and must be loaded manually as needed).
  * `std.t` and `parsing.t` were renamed `terra/std.t` and `terra/parsing.t`
  respectively and are now in the luapower dir along with all Lua files.
  * the system include paths for Windows are set for [mingw64-headers] so
  building binaries with Terra's API works out-of-the-box providing the
  [luapower toolchain][building] is installed (needed for linking).

[source code changes]: https://github.com/luapower/terra_fork/compare/0a11f98...luapower:master
[upstream changes]:    https://github.com/luapower/terra_fork/compare/0a11f98...zdevito:master
