---
title:    building
tagline:  how to build binaries
---

## What you need to know first

 * Building is based on trivial [shell scripts][build-scripts]
 that invoke gcc directly (no makefiles).
 * Each supported package/platform/arch combination has a separate build
 script in `csrc/<package>/build-<platform>.sh`.
 * C sources are included so you can start right away.
 * Dependent packages are listed on the website (under the section
 "Binary Dependencies") and in `csrc/<package>/WHAT`. Build those first.
 * The only sure way to get a binary on the first try is to use the exact
 toolchain as described here for each platform.
 The good news is that you _will_ get a binary.
 * For building Lua/C modules you need [lua-headers].
 * For building Lua/C modules on Windows you also need [luajit].
 * You will get both dynamic libraries (stripped) and static libraries.
 * libgcc and libstdc++ will be statically linked, except on OSX which
 doesn't support that and where libc++ is used.
 * Binaries on Windows are linked to msvcrt.dll.
 * Lua/C modules on Windows are linked to lua51.dll (which is why you need luajit).
 * OSX libs set their install_name to `@rpath/<libname>.dylib`
 * the luajit exe on OSX sets `@rpath` to `@loader_path`
 * the luajit exe on Linux sets `rpath` to `$ORIGIN`
 * all listed tools are mirrored at
 [luapower.com/files](http://luapower.com/files)
 (but please report broken links anyway)

## Building on Windows for Windows

	cd csrc/<package>
	sh build-mingw64.sh

These scripts assume that both MSYS and MinGW-w64 bin dirs (in this order)
are in your PATH.

Here's MSYS:

[MSYS-2019-05-24](https://sourceforge.net/projects/msys2/files/Base/x86_64/msys2-base-x86_64-20190524.tar.xz/download)

You also need to install make, nasm and cmake: from the msys2 shell, type: `pacman -S make nasm cmake`.

Here's the MinGW-w64 package used to build the current luapower stack:

----
[MinGW-W64 GCC-8.1.0 (64bit, posix threads, SEH exception model)](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z)
----

The resulted binaries are linked to msvcrt.dll and should be compatible
down to Windows 7.

## Building on Linux for Linux

	cd csrc/<package>
	sh build-linux64.sh

The current luapower stack is built on an **Ubuntu 18.04 x64 Desktop**
and it's the only supported way to build it. If you need binaries for older
Linuxes, keep reading.

## Building for older Linuxes

In general, to get binaries that will work on older Linuxes, you want to
build on the _oldest_ Linux that you care to support, but use
the _newest_ GCC that you can install on that system. In particular,
if you link against GLIBC 2.14+ your binary will not be backwards compatible
with an older GLIBC (google "memcpy glibc 2.14" to see the drama).

Here's a fast and easy way to build binaries that are compatible
down to GLIBC 2.7:

  * install an Ubuntu 10.04 in a VM
  * add the "test toolchain" PPA to aptitude
  * install the newest gcc and g++ from it

Here's the complete procedure on a fresh Ubuntu 10.04:

	sudo sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
	sudo apt-get update
	sudo apt-get install -y python-software-properties
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test
	sudo apt-get update
	sudo apt-get install -y gcc-4.8 g++-4.8
	sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 20
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 20
	sudo apt-get install -y nasm cmake

Note that the above setup contains EGLIBC 2.11 so it's not guaranteed that
_anything_ you compile on it will be compatible down to GLIBC 2.7. It just
so happens that the _current_ luapower libraries don't use any symbols that
have a newer implementation on that version of glibc. Compiling on Ubuntu 8.04
might solve the issue but the newest gcc that can run on that system is too
old.

### Running Ubuntu 10 on Ubuntu 14

An easy and runtime-cheap way to get Ubuntu 10 environments
on an Ubuntu 14 machine is with LXC:

	sudo apt-get update
	sudo apt-get install -y lxc
	export MIRROR="http://old-releases.ubuntu.com/ubuntu"
	export SECURITY_MIRROR="$MIRROR"
	sudo -E lxc-create -n u10_64 -t ubuntu -- -r lucid
	sudo rm /var/lib/lxc/u10_64/rootfs/dev/shm    # hack to make it work
	sudo lxc-start -n u10_64 -d
	sudo lxc-ls --running         # should print: u10_64

To get a shell into a container, type:

	sudo lxc-attach -n u10_64

Once inside, use the same instructions for Ubuntu 10 above. To get
the compiled binaries out of the VMs check out `/var/lib/lxc/u10_XX/rootfs`
which is where the containers' root filesystems are.

## Building on OSX for OSX

	cd csrc/<package>
	sh build-osx64.sh

Current OSX builds are based are done on an OSX 10.2 using OSX SDK 10.12.

The generated binaries are compatible down to OSX 10.9.

## Building on Linux for OSX

__NOTE:__ This is experimental, lightly tested and not available
for all packages (but available for most).

You can build for OSX on a Linux box using the [osxcross] cross-compiler.
You can build osxcross (both clang and gcc) yourself (you need the
OSX 10.7 SDK for that) or you can use a [pre-built osxcross]
that was compiled on and is known to work on an x64 Ubuntu 14.04 LTS.

To use the cross-compiler, just add the `osxcross/target/bin` dir
to your PATH and run the same `build-osxXX.sh` scripts that you
would run for a native OSX build. Remember: not all packages
support cross-compilation. If you get errors, check the scripts
to see if they are written to invoke `x86_64-apple-darwin11-gcc`
and family.

[osxcross]: https://github.com/tpoechtrager/osxcross
[pre-built osxcross]: http://luapower.com/files/osxcross.tgz

## Building with multigit

	./mgit build <package>

which is implemented as:

	cd csrc/<package> && ./build-<current-platform>.sh

## Building packages in order

You can use [luapower] so that for any package or list of packages
(or for all installed packages) you will get the full list of packages
that need to be compiled _in the right order_, including
all the dependencies:

	./lp build-order pkg1,...|--all [platform]

Again, you can use mgit to leverage that and actually build the packages:

	./mgit build-all pkg1,...|--all [platform]

To build all installed packages on the current platform, run:

	./mgit build-all --all
