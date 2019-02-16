---
tagline: LuaJIT binary
---

## What

LuaJIT binaries (frontend, static library, dynamic library).

Comes bundled with the `luajit` and `luajit32` commands, which are simple
shell scripts that find and load the appropriate luajit executable for
your platform/arch, so that typing `./luajit` or `./luajit32`
(that's `luajit` and `luajit32` on Windows) always works.

LuaJIT was compiled using its original makefile.

__NEW!__ You can now browse the [LuaJIT source code](/files/htags/luajit)
and the [DynASM source code](/files/htags/dynasm) online.
The html is updated daily from the
[github mirror](https://github.com/capr/luajit)
which is updated hourly.

## Making portable apps

To make a portable app that can run from any directory without needing
Installing, every subsystem of the app that needs to open a file must
look for that file in a location relative to the app's directory. This
means at least three things:

 * Lua's require() must look in exe-relative dirs first,
 * the OS's shared library loader must look in exe-relative dirs first,
 * the app itself must look for assets, config files, etc. in exe-relative
 dirs first.

The solutions for the first two problems are platform-specific and
are described below. As for the third problem, you can extract the exe's
path from arg[-1]. To get the location of the _running script_,
as opposed to that of the executable, use [glue.bin]. To add more paths
to package.path and package.cpath at runtime, use [glue.luapath]
and [glue.cpath].

### Finding Lua modules

#### Windows

`!\..\..\?.lua;!\..\..\?\init.lua` was added to the default package.path
in luaconf.h. This allows luapower modules to be found regardless of what
the current directory is, making the distribution portable.

The default `package.cpath` was also modified from `!\?.dll` to `!\clib\?.dll`.
This is to distinguish between Lua/C modules and other binary dependencies.

#### Linux and OSX

In Linux and OSX, luajit is a shell wrapper script that sets LUA_PATH
and LUA_CPATH to acheive the same effect and assure isolation from
system libraries.

#### The current directory

Lua modules (including Lua/C modules) are searched for in the current directory
___first___ (on any platform), so the isolation from the host system
is not absolute.

This is the Lua's default setting and although it's arguably a security risk,
it's convenient for when you want to have a single luapower tree, possibly
added to the system PATH, to be shared between many apps. In this case,
starting luajit in the directory of the app makes the app's modules
accessible automatically.

### Finding shared libraries

#### Windows

Windows looks for dlls in the directory of the executable first by default,
and that's where the luapower dlls are, so isolation from system libraries
is acheived automatically in this case.

#### Linux

Linux binaries are built with `rpath=$ORIGIN` which makes ldd look for
shared objects in the directory of the exe first.

#### OSX

OSX binaries are built with `rpath=@loader_path` which makes the
dynamic loader look for dylibs in the directory of the exe first.

#### The current directory

The current directory is _not used_ for finding shared libraries
on Linux and OSX. It's only used on Windows, but has lower priority
than the exe's directory (except on WinXP before SP2 where it has
higher priority).

### Finding [terra] modules

The luajit executable was modified to call `require'terra'` before trying
to run `.t` files at the command line. It also loads the file by calling the
global `loadfile` instead of the C function `lua_loadfile`. `loadfile` is
overriden in `terralib.lua` to load `.t` files as Terra source code.

#### Windows

TODO

#### Linux and OSX

The luajit wrapper sets TERRA_PATH just like it sets LUA_PATH,
so terra files are searched for in the same directories as Lua files.


[glue.bin]:     glue#bin
[glue.luapath]: glue#luapath
[glue.cpath]:   glue#cpath

