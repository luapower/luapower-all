#!/bin/bash
# preprocess multiple C header files into a single Lua file

usage() {
	echo "USAGE: CFLAGS=... mgit precompile [-m32] [-posix] FILE1.h ..."
	exit 1
}

[ "x$1" = "x-m32" ] && { CFLAGS="$CFLAGS -m32"; shift; }
[ "x$1" = "x-posix" ] && { CFLAGS="$CFLAGS -D_POSIX_C_SOURCE=200112L"; shift; }
[ "$1" ] || usage

inc_headers() {
	if [ "x$1" = "x-" ]; then
		cat
	else
		for h in $@; do
			if [ -f "$h" ]; then
				echo "#include \"$h\""
			else
				echo "#include <$h>"
			fi
		done
	fi
}

inc_headers "$@" | gcc $CFLAGS -E -dD -xc - \
	| grep -v '^$' \
	| grep -v '#undef' \
	| sed 's/__asm\(.*\)//g' \
	| "./luajit" .mgit/precompile.lua
