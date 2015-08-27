#!/bin/bash
# dump symbols from dynamic libraries

LANG=C # for sort

P=$(.mgit/platform.sh)
O=$(.mgit/platform.sh -o)
[ "$O" ] || exit 1

[ $O = mingw ] && { PREFIX=;    SUFFIX=.dll;   CSUFFIX=.dll; }
[ $O = linux ] && { PREFIX=lib; SUFFIX=.so;    CSUFFIX=.so; }
[ $O = osx   ] && { PREFIX=lib; SUFFIX=.dylib; CSUFFIX=.so; }

DEF=d

usage() {
	echo
	echo " USAGE: mgit syms [-d|-u|-l|-lu|-f] LIBNAME1|LIBFILE1$SUFFIX ..."
	echo
	echo "   -d       dump defined symbols (default)"
	echo "   -u       dump undefined symbols"
	echo "   -l       dump dependent libraries"
	echo "   -lu      dump dependent libraries and symbols (Windows)"
	echo "   -f       dump dependent frameworks (OSX)"
	echo
	exit 1
}

[ -z "$1" ] && usage
if [ "x${1:0:1}" = "x-" ]; then
	if [ \
		"x$1" = "x-d" -o \
		"x$1" = "x-u" -o \
		"x$1" = "x-l" -o \
		"x$1" = "x-lu" -o \
		"x$1" = "x-f" \
	]; then
		DEF=${1:1}
		shift
	else
		usage
	fi
fi

# clean up a list of libs (remove prefix, suffix and implicit dependencies)
clean_libname() {
	while read s; do

		# show full-pathname deps as they are
		[ "${s#/}" = "$s" ] && {
			# filename -> libname
			s="$(echo "$s" | tr '[A-Z]' '[a-z]')"  # lowercase
			s=${s%.[0-9]*}                         # remove .major suffix (Linux)
			s=${s#@rpath/}                         # remove @rpath/ prefix (OSX)
			eval s=\$\{s#$PREFIX\}                 # remove platform-specific prefix
			eval s=\$\{s%$SUFFIX\}                 # remove platform-specific suffix
		}

		# skip Linux implicit deps
		[ "$s" = "linux-vdso" ] && continue
		[[ "$s" == *"/ld-linux"* ]] && continue
		[ "$s" = "linux-gate" ] && continue

		# skip semi-implicit C runtime dep
		[ $O = osx   -a "$s" = "/usr/lib/libSystem.B.dylib" ] && continue
		[ $O = mingw -a "$s" = "msvcrt" ] && continue
		[ $O = linux -a "$s" = "c" ] && continue

		echo "$s"
	done
}

syms_d_osx()   { nm -gUj "$1" | cut -c2- | sed 's/$.*//' | sort -u; }
syms_u_osx()   { nm -guj "$1" | cut -c2- | sed 's/$.*//' | sort -u; }
syms_d_linux() { nm -gD --defined-only -f posix "$1" | cut -f1 -d' ' | sed 's/@.*//' | sort -u; }
syms_u_linux() { nm -gDu               -f posix "$1" | cut -f1 -d' ' | sed 's/@.*//' | sort -u; }
syms_d_mingw() {
	local x=0
	objdump -x "$1" | while read s; do
		if [ $x = 0 ]; then
			[ "$s" = '[Ordinal/Name Pointer] Table' ] && x=1
		elif [ -z "$s" ]; then
			break
		else
			echo "${s:7}"
		fi
	done | sort -u
}
syms_u_mingw() {
	local x=0
	objdump -x "$1" | while read s; do
		if [ $x = 0 ]; then
			if [[ "$s" == *"DLL Name:"* ]]; then
				x=1
			fi
		elif [ -z "$s" ]; then
			x=0
		elif [ $x = 1 ]; then
			x=2
		elif [ $x = 2 ]; then
			echo "${s:13}"
		fi
	done
}
syms_lu_mingw() {
	local x=0
	objdump -x "$1" | while read s; do
		if [ $x = 0 ]; then
			if [[ "$s" == *"DLL Name:"* ]]; then
				echo "${s:10}" | clean_libname
				x=1
			fi
		elif [ -z "$s" ]; then
			x=0
		elif [ $x = 1 ]; then
			x=2
		elif [ $x = 2 ]; then
			echo " ${s:13}"
		fi
	done
}
syms_l_mingw() {
	objdump -x "$1" | grep "DLL Name:" | cut -f3 -d' ' | clean_libname
}
syms_l_linux() {
	ldd "$1" | cut -f1 -d' ' | clean_libname | sort
}
syms_l_osx() {
	otool -L "$1" | tail -n +2 | cut -f1 -d' ' | grep -v '\.framework' | clean_libname | sort
}
syms_f_osx() {
	otool -L "$1" | tail -n +2 | cut -f1 -d' ' | grep '\.framework' | while read s; do
		s="${s#/System/Library/Frameworks/}"
		s="${s%.framework*}"
		echo "$s"
	done | sort
}
syms_one() {
	local fn="$1"
	local f="$fn"
	[ -f "$f" ] || f="bin/$P/$PREFIX$fn$SUFFIX"
	[ -f "$f" ] || f="bin/$P/clib/$fn$CSUFFIX"
	syms_${DEF}_${O} "$f"
}

while [ "$1" ]; do
	syms_one "$1"
	shift
done
