---
title:   build scripts
tagline: how to write build scripts for multiple platforms
---

The build scripts assume the [luapower toolchain][building].
This means that the same gcc/g++ frontend is used on every platform,
which greatly reduces what you need to know for writing them.

## Build scripts

Create a separate script for each supported platform:

	csrc/foo/build-mingw64.sh
	csrc/foo/build-linux64.sh
	csrc/foo/build-osx64.sh

Use only relative paths in the scripts. Build scripts must be run
from their own directory so use `../../bin/<platform>` to reference
the output directory.

## Build output

The build scripts must generate binaries as follows:

	bin/mingw64/foo.dll               C library, Windows
	bin/mingw64/foo.a                 C library, Windows, static version
	bin/mingw64/clib/foo.dll          Lua/C library, Windows
	bin/mingw64/foo.a                 Lua/C library, Windows, static version
	bin/linux64/libfoo.so             C library, Linux
	bin/linux64/libfoo.a              C library, Linux, static version
	bin/linux64/clib/foo.so           Lua/C library, Linux
	bin/linux64/libfoo.a              Lua/C library, Linux, static version
	bin/osx64/libfoo.dylib            C library, OSX
	bin/osx64/libfoo.a                C library, OSX, static version
	bin/osx64/clib/foo.so             Lua/C library, OSX
	bin/osx64/libfoo.a                Lua/C library, OSX, static version

> So prefix everything with `lib` except for Windows and except for dynamic
Lua/C libs; on OSX use `.dylib` for C libs but use `.so` for dynamic Lua/C
libs; put dynamic Lua/C libs in the `clib` subdirectory but put static Lua/C
libs in the platform directory along with the normal C libs.

## Building with GCC

Building with gcc is a 2-step process, compilation and linking,
because we want to build both static and dynamic versions the libraries.

### Compiling with gcc/g++

	gcc -c options... files...
	g++ -c options... files...

  * `-c`                         : compile only (don't link; produce .o files)
  * `-O2`                        : enable code optimizations
  * `-I<dir>`                    : search path for headers (eg. `-I../lua`)
  * `-D<name>`                   : set a `#define`
  * `-D<name>=<value>`           : set a `#define` with a value
  * `-U<name>`                   : unset `#define`
  * `-fpic` or `-fPIC`           : generate position-independent code (required for linux64)
  * `-D_WIN32_WINNT=0x601`       : Windows: set API level to Windows 7 (set WINVER too)
  * `-DWINVER=0x601`             : Windows: set API level to Windows 7
  * `-mmacosx-version-min=10.7`  : OSX: set API level to 10.7
  * `-D_POSIX_SOURCE`            : Linux and MinGW: enable POSIX 1003.1-1990 APIs
  * `-D_XOPEN_SOURCE=700`        : Linux: enable POSIX.1 + POSIX.2 + X/Open 7 (SUSv4) APIs
  * `-arch x86_64`               : OSX: create 64bit x86 binaries
  * `-U_FORTIFY_SOURCE=1`        : gcc: enable some runtime checks
  * `-std=c++11`                 : for C++11 libraries
  * `-stdlib=libc++ -mmacosx-version-min=10.7` : for all C++ libraries on OSX

### Dynamic linking with gcc/g++

	gcc -shared options... files...
	g++ -shared options... files...

  * `-shared`                    : create a shared library
  * `-s`                         : strip debug and private symbols (not for OSX)
  * `-o <output-file>`           : output file path (eg. `-o ../../bin/mingw64/z.dll`)
  * `-L<dir>`                    : search path for library dependencies (eg. `-L../../bin/mingw64`)
  * `-l<libname>`                : library dependency (eg. `-lz` looks for `z.dll`/`libz.so`/`libz.dylib` or `libz.a`)
  * `-Wl,--no-undefined`         : do not allow unresolved symbols in the output library.
  * `-static-libstdc++`          : link libstdc++ statically (for C++ libraries; not for OSX)
  * `-static-libgcc`             : link the GCC runtime library statically (for C and C++ libraries; not for OSX)
  * `-pthread`                   : enable pthread support (not for Windows)
  * `-arch x86_64`               : OSX: create 64bit x86 binaries
  * `-undefined dynamic_lookup`  : for Lua/C modules on OSX (don't link them to luajit!)
  * `-mmacosx-version-min=10.9`  : set OSX 10.9 API level
  * `-install_name @rpath/<libname>.dylib` : for OSX, to help the dynamic linker find the library near the exe
  * `-stdlib=libc++ -mmacosx-version-min=10.7` : for all C++ libraries on OSX
  * `-Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic` : statically link the winpthread library (for C++ libraries on mingw64)
  * `-fno-exceptions`            : avoid linking to libstdc++ if the code doesn't use exceptions
  * `-fno-rtti`                  : make the binary smaller if the code doesn't use dynamic_cast or typeid
  * `-fvisibility=hidden`        : make the symbol table smaller if the code is explicit about exports

__IMPORTANT__: The order in which `-l` options appear is significant!
Always place all object files _and_ all dependent libraries _before_
all dependency libraries.

### Static linking with ar

	ar rcs ../../bin/<platform>/static/<libname>.a *.o

### Stripping private symbols on OSX

Huge libraries bloat the symbol table with private symbols that you don't need
at runtime. The OSX linker doesn't support `-s`, but you can use `strip`:

	strip -x foo.dylib

### Example: compile and link lpeg 0.10 for linux64

	gcc -c -O2 lpeg.c -fPIC -I. -I../lua
	gcc -shared -s -static-libgcc -o ../../bin/linux64/clib/lpeg.so
	ar rcs ../../bin/linux64/static/liblpeg.so

In some cases it's going to be more complicated than that.

  * sometimes you won't get away with specifying `*.c` -- some libraries rely
  on the makefile to choose which .c files need to be compiled for a
  specific platform or set of options as opposed to using platform defines
  (eg. [socket])
  * some libraries actually do use one or two of the myriad of defines
  generated by the `./configure` script -- you might have to grep for those
  and add appropriate `-D` switches to the command line.
  * some libraries have parts written in assembler or other language.
  At that point, maybe a simple makefile is a better alternative, YMMV
  (if the package has a clean and simple makefile that doesn't add more
  dependencies to the toolchain, use that instead)

After compilation, check your builds against the minimum supported platforms.
Also, you may want to check the following:

  * on Linux, run `mgit check-glibc-symvers` to check that you don't have
  any symbols that require GLIBC > 2.7. Also run `mgit check-other-symvers`
  to check for other dependencies that contain versioned symbols.
  * on OSX, run `mgit check-osx-rpath` to check that all library paths
  contain the `@rpath/` prefix.

## Backwards compatibility

### Windows

WinXP compatibility is the default with MinGW-w64 which links against
msvcrt.dll and doesn't use newer WinAPIs itself.

### Linux

GLIBC has multiple implementations of its functions inside, which can be
selected in the C code using a pragma (.symver). Of course nobody
uses that pragma, and the default behavior is to to link against
the latest versions of the symbols that you happen to have on your machine
at the time of linking, and those will be the _minimum_ versions that
your binary will require on _any_ machine, which makes that binary
potentially incompatible with an older Linux. Because whoever introduced
that insanity didn't bother to make a linker option to select the minimum
GLIBC version when linking, the only option left is to build on the _oldest_
Linux which can still run a _recent enough gcc_ (good luck),  and check
the symvers on the compiled binaries with `mgit check-glibc-symvers`.

### OSX

Backwards compatibility on OSX is entirely in the hands of the
`-mmacosx-version-min` option, which is actually a much better deal
than with gcc/Linux (of course, for actually testing the binary
you still need the hardware, because running OSX in a VM is hard
and painful and illegal).

## The C++ situation

Because there doesn't seem to be any hope of getting rid of this
language yet, we have to address the problem of the standard C++ library.
The luapower answer to that is to bundle it (i.e. link it statically
in every C++ library) as opposed to linking it dynamically and shipping it
(or linking it dynamically and not shipping it), except on OSX which
doesn't (and will not) support that. Here's why:

### Windows

Shipping libstdc++ on Windows could work, but it would drag along
libwinpthread and libgcc with it, and libwinpthread is already shipped
with the [pthread] package because it has a binding.

### Linux

Shipping libstdc++ (and its dependency libgcc) with your app
on Linux is not a good idea if the app is using other external libraries
that happen to dlopen libstdc++ themselves and expect to get a different
version of it than the one that the app just loaded. Such is the case with
OpenGL with Radeon drivers (google "steam libstdc++" to see the drama).
In that case it's better to either
a) link libstdc++ statically to each C++ library (the luapower way), or
b) link it dynamically, but check at runtime which libstdc++ is newer
(the one that you ship or the one on the host), and then ffi.load
the newer one _before_  loading that external C library so that _it_
doesn't load the older one.

### OSX

OSX has two stdc++es: GNU's libstdc++ and the newer libc++ from LLVM.
Only libc++ implements C++11 but it comes with OSX 10.7+.

On OSX 10.8+, libc++ is pulled in by libSystem (via libdispatch) anyway,
so linking against libstdc++ on these platforms is a net loss when libc++
is already loaded, and C++11 libs (eg. terra) need to link to
libc++ anyway. OTOH, libc++ is 10.7+, so this means leaving 10.6 users
in the cold, unless you ship libc++ for them (and only load it for them).
Because the [objc] binding requires OSX 10.7+ anyway (for reasons unrelated
to C++), I chose to drop 10.6 support altogether and stick with libc++.
