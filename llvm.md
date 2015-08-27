---
tagline: LLVM + Clang binaries
---

This package contains:

 * scripts to download and build LLVM + Clang
 * LLVM + Clang binaries, released [separately] because they are huge.

[separately]: https://github.com/luapower/llvm/releases

## Binaries

Binaries should be unpacked in `csrc/llvm`:

	cd csrc/llvm
	wget https://github.com/luapower/llvm/releases/download/3.5.0/install.linux64.zip
	unzip install.linux64

LLVM binaries are as backwards compatible as the rest of luapower.
Clang is built without ncurses on Linux for maximum portability. 
Note that MinGW-w64 is not yet fully supported by LLVM, so consider
the mingw32/64 builds experimental for now (if problems are found, 
I'll switch to a VS2013 build).

## Building

LLVM has additional requirements besides the [base toolchain][building]:

#### Windows
	
Python must be in your PATH.

#### Linux

CMAKE 2.8.8+ is needed (Ubuntu 10 has 2.8.0). 
Here's a quick way to add it:
	
	wget http://www.cmake.org/files/v2.8/cmake-2.8.10.2-Linux-i386.sh
	chmod +x cmake-2.8.10.2-Linux-i386.sh
	sudo ./cmake-2.8.10.2-Linux-i386.sh --prefix=/usr/local
