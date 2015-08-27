#!/bin/bash
# detect current platform, OS and architecture.
# supported platforms: mingw32, mingw64, linux32, linux64, osx32, osx64.
# supported OSs: mingw, linux, osx.
# supported archs: 32, 64.

[ "x$1" = "x-h" -o "$1" = "x--help" ] && \
    echo "Usage: mgit platform [-o|-a]" && exit

O=
A=
[ "$PROCESSOR_ARCHITECTURE" = "AMD64" -o "$PROCESSOR_ARCHITEW6432" = "AMD64" ] && { O=mingw; A=64; } || {
	[ "$OSTYPE" = "msys" ] && { O=mingw; A=32; } || {
		A=32; [ "$(uname -m)" = "x86_64" ] && A=64
		[ "${OSTYPE#darwin}" != "$OSTYPE" ] && O=osx || O=linux
	}
}

if [ "x$1" = x-o ]; then
	echo $O
elif [ "x$1" = x-a ]; then
	echo $A
elif [ "x$1" = x-32 ]; then
	echo ${O}32
elif [ "x$1" = x-64 ]; then
	echo ${O}64
else
	echo $O$A
fi
