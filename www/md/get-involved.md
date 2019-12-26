---
title:   get involved
tagline: how to create luapower packages
---

## Anatomy of a package

There are 6 types of luapower packages:

  * __Lua module__: written in Lua
  * __Terra module__: written in Terra
  * __Lua/C module__: written in C using the Lua C API (*)
  * __Lua+ffi module__: written in Lua using the LuaJIT ffi extension (*)
  * __C module__: binary dependency or support library for other module (*)
  * __other__: none of the above: media/support files, etc.

(*) binaries and C source code included.

### TL;dr: Template packages

  * [Lua module](https://github.com/luapower/template-lua)
  * [Lua+ffi module](https://github.com/luapower/template-lua-ffi)


### Directory layout

__NEW:__ You can now [browse the whole source tree](/tree) online where
each file and directory is described!

	foo.lua               main module
	foo_bar.lua           submodule, for small packages
	foo/bar.lua           submodule, for large packages
	foo_h.lua             ffi.cdef module (ffi.load is in foo.lua, not here)
	foo_test.lua          test program: for tests that can be automated
	foo_demo.lua          demo program: anything goes
	foo.md                main doc: markdown with pandoc extensions
	foo_bar.md            submodule doc: optional, for large submodules
	.mgit/foo.exclude     the .gitignore file: optional, see below

C libs must also include their source code, build scripts and binaries:

	csrc/foo/*                           C sources
	csrc/foo/WHAT                        WHAT file (see below)
	csrc/foo/build-<platform>.sh         build scripts
	bin/<platform>/*.dll|.so|.dylib|.a   binaries

These conventions allow packages to be safely unzipped over a common
directory and the result look sane, and it makes it possible to extract
package information and build the package database and this website.

### The docs

In order to appear on the website, docs should start with a yaml header:

	---
	tagline: foobars
	platforms: linx64, mingw64
	license: MIT
	---

Take your time to write a good, short tagline. This is important for figuring
out what the module does when browsing the module list.

The `platforms` line is only needed for Lua packages that are
platform-specific but do not have a C component (very rare case). In all
other cases, do not specify the platforms.

The `license` line is only if needed for Lua modules that are not
`Public Domain`.

You don't have to make a doc for each submodule if you don't have much to
document for it, a single doc matching the package name would suffice.

### The WHAT file

The WHAT file is for packages that have a C component (i.e. Lua/C, C
and Lua+ffi packages that bind on 3rd-party libs), and it's used to describe
that C component (pure Lua packages don't need a WHAT file). It should look
like this:

	cairo 1.12.16 from http://cairographics.org/releases/ (MPL/LGPL license)
	requires: pixman, freetype, zlib, libpng

The first line should contain "`<name> <version> from <browse-url>
(<license>)`". The second line should contain "`requires: package1, package2,
...`" and should only list the binary dependencies of the library, if there
are any. After the first two lines and an empty line, you can type in
additional notes, whatever, they aren't parsed. In the rare case that a
dependency is only available on some platforms, specify the platforms after
the dependency name like this: `pthread (linux64 mingw64)`.

The WHAT file can also be used to describe Lua modules that are developed
outside of luapower (eg. [lexer]).

### The exclude file

__NOTE:__ This file is entirely optional and rarely used.

This is the .gitignore file used for excluding files between packages so that
files in one packages don't show as untracked files in other package. Another
way to think of it is the file used for reserving name-space in the luapower
directory layout.

Example:

	*                    ; exclude all files
	!/foo*               ; include files in root that start with `foo`
	!/foo/               ; include the directory in root named `foo`
	!/foo/**             ; include the contents of the directory named `foo`, recursively

### The code

Check out the info on [coding style][coding-style].

### The build scripts

Check out the info on [build scripts][build-scripts].

### The License

__NOTE:__ This only concerns Lua modules that are _not in Public Domain_.

  * add `license: ...` to the header of your main doc
  * put the full license file in csrc/foo/LICENSE|COPYING[.*]
  * the default license in absence of a license tag is Public Domain.

### Versioning

All modules should work together from the master branch at any time.
Each package has to keep up with the others. If you introduce breaking
changes on a package, you have to upgrade all its dependants immediately.
Work on a dev branch until you do so.

Conventions that I follow (you can of course use semantic versioning too):

  * tag everything with just the major version (i.e. start with `mgit tag foo r1`)
  * increment the tag on breaking changes (i.e. `mgit foo bump`)

## Publishing packages on luapower.com

> Refer to [luapower-git] for the actual procedure.

Before publishing a luapower module, please consider:

  * what name you plan to use for your module
  * how your module relates to other modules

Choosing a good name is important if you want people to find your module
and understand (from the name alone) what it does. Likewise, it's a good idea
to be sure that your module is doing something new or at least different
(and hopefully better) than something already on luapower.com.

Ideally, your module has:

  * __distinction__ - focused problem domain
  * __completeness__ - exhaustive of the problem domain
  * __API documentation__ - so it can be browsed online
  * __test and/or demo__ - so it can be seen to work
  * __a non-viral license__ - so it doesn't impose restrictions on _other_ modules

Of course, few modules (in any language) qualify on all fronts, so
luapower.com is necessarily an eclectic mix. In any case, if your module
collection is too specialized to be added to luapower.com or you simply don't
want to mix it in with the others, remember that you can always fork
[luapower-repos] and make your own module collections. And ultimately, you
can fork the website too.

## Forking luapower.com

The luapower website is composed of:

  * [luapower-repos], a meta repository which contains the
  list of packages to be cloned with multigit.
  * [luapower], a Lua module for collecting package metadata.
  * [website][website-src], an [open-resty]-based app, with
  very simple css, mustache-based templates and table-based layout.
  * [pandoc], for converting the docs to html.
  * a bunch of Windows, Linux and OSX machines set up to collect package
  dependency information and run automated tests.

If you want to put this together but get stuck on the details,
ask away on the [forum](/forum), we'll help you
seeing it through.


[website-src]:        https://github.com/luapower/website
[open-resty]:         http://openresty.org
[pandoc]:             http://johnmacfarlane.net/pandoc/
