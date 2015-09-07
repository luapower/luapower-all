#!/bin/bash

die() { echo "$@" >&2; exit 1; }
verbose() { echo; echo "$@"; "$@"; }
LLVM_CONFIG="../llvm/install.$P/bin/llvm-config" 
llvm_config() { "../../$LLVM_CONFIG" "$@"; }

[ "$P" ] || die "don't run this directly."
[ -d terra ] || die "get terra sources."
[ -f "$LLVM_CONFIG" ] || die "get llvm binaries."

cd terra/src || die "run this from csrc/terra."

echo "LLVM PREFIX    : $(llvm_config --prefix)"
echo "LLVM CPP FLAGS : $(llvm_config --cppflags)"
echo "LLVM LD FLAGS  : $(llvm_config --ldflags)"

cx() {
	verbose "$@" $C -c -O2 -fno-common \
		-DTERRA_LUAPOWER_BUILD -DTERRA_LLVM_HEADERS_HAVE_NDEBUG -DLLVM_VERSION=35 -D_GNU_SOURCE \
		$(llvm_config --cppflags) \
		-I../.. \
		-I../release/include \
		-I../../../luajit/src/src
}
cc()  { cx gcc "$@"; }
cxx() { cx g++ "$@" -std=c++11 -fno-rtti -fvisibility-inlines-hidden; }

compile() {
	rm -f *.o
	cc treadnumber.c
	cxx tdebug.cpp tkind.cpp tcompiler.cpp tllvmutil.cpp tcwrapper.cpp tinline.cpp terra.cpp tcuda.cpp \
		lparser.cpp lstring.cpp lobject.cpp lzio.cpp llex.cpp lctype.cpp
}

libs() {
	echo "
	-lclangFrontend
	-lclangDriver
	-lclangSerialization
	-lclangCodeGen
	-lclangParse
	-lclangSema
	-lclangAnalysis
	-lclangEdit
	-lclangAST
	-lclangLex
	-lclangBasic
	" $(llvm_config --libs)
}

slink() {
	local alib=../../../../bin/$P/$A
	verbose rm -f $alib
	verbose ar cq $alib *.o
}

dlink() {
	local dlib=../../../../bin/$P/clib/$D
	verbose g++ -shared \
		-o $dlib \
		-L../../../../bin/$P \
		$(llvm_config --ldflags) \
		*.o $(libs) -lz $L
	# for OSX, Linux and Windows already stripped with -s
	verbose strip -x $dlib
}

install() {
	cp -f terralib.lua                 ../../../../
	cp -f cudalib.lua                  ../../../../
	cp -f ../release/include/parsing.t ../../../../terra_parsing.t
	cp -f ../release/include/std.t     ../../../../terra_std.t
}

libfiles() {
	local dir="$(llvm_config --prefix)"
	for lib in $(libs); do
		echo "$dir/lib/lib${lib#-l}.a"
	done
}

[ "$1" = libs ] && { libfiles; exit; }

compile
slink
dlink
install
