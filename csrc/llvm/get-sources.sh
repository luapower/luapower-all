#!/bin/sh

VER=3.5.0

download() {
	which wget >/dev/null || { 
		echo "wget not found."
		echo "download this yourself: $1"
		exit 1
	}
	wget "$1"
}

get() {
	[ -f $1 ] || download http://llvm.org/releases/$VER/$1
	[ -d $2 ] || {
		mkdir -p $2
		if [ "$OSTYPE" = "msys" ]; then
			./xzdec.exe $1 | tar xfv - -C $2 --strip-components=1
		else
			tar xfv $1 -C $2 --strip-components=1
		fi
	}
}

get_llvm() { get llvm-$VER.src.tar.xz llvm.src; }
get_clang() { get cfe-$VER.src.tar.xz clang.src; }

get_llvm
get_clang
