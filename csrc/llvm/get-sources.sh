#!/bin/sh

VER=6.0.1

which wget >/dev/null && alias download=wget || alias download="curl -O --retry 999 --retry-max-time 0 -L -C -"

get() {
	[ -f $1 ] || download http://llvm.org/releases/$VER/$1
	[ -d $2 ] || {
		mkdir -p $2
		if [ "$OSTYPE" = "msys" ]; then
			./xzdec.exe $1 | tar xfv - -C $2 --strip-components=1
		else
			tar xf $1 -C $2 --strip-components=1
		fi
	}
}

get_llvm() { get llvm-$VER.src.tar.xz llvm.src; }
get_clang() { get cfe-$VER.src.tar.xz clang.src; }

get_llvm
get_clang

