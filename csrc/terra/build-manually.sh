#!/bin/bash

die() { echo "$@" >&2; exit 1; }
verbose() { echo; echo "$@"; "$@"; }
llvm_config() { "../../../llvm/install.$P/bin/llvm-config" "$@"; }

[ "$P" ] || die "don't run this directly."
[ -d terra ] || die "get terra sources"
[ -d ../llvm ] || die "get llvm package"

cd terra/src || exit 1

cx() {
	verbose "$@" $C -c -Wall -fno-common \
		-DTERRA_LUAPOWER_BUILD -DLLVM_VERSION=35 -D_GNU_SOURCE \
		$(llvm_config --cppflags) \
		-I../.. \
		-I../release/include \
		-I../../../luajit/src/src \
		-I"$(llvm_config --includedir)"
}

cc() { cx gcc "$@"; }

cxx() {
	cx g++ "$@" -std=c++11 \
		-fno-rtti \
		-fvisibility-inlines-hidden \
		-Woverloaded-virtual \
		-Wno-cast-qual \
		-Wno-return-type \
		-Wno-sign-compare \
		-Wno-unused-but-set-variable
}

compile() {
	rm -f *.o
	cc treadnumber.c
	cxx \
		tkind.cpp \
		tcompiler.cpp \
		tllvmutil.cpp \
		tcwrapper.cpp \
		tinline.cpp \
		terra.cpp \
		lparser.cpp \
		lstring.cpp \
		lobject.cpp \
		lzio.cpp \
		llex.cpp \
		lctype.cpp \
		tcuda.cpp \
		tdebug.cpp
}

addlibs() { 
	local dir="$(llvm_config --prefix)"
	for o in "$@"; do
		o="ADDLIB $dir/lib/lib${o#-l}.a"
		echo $o
	done
}

addmods() { for m in "$@"; do echo "ADDMOD $m"; done; }

libs() {
	echo \
		-lclangFrontend \
		-lclangDriver \
		-lclangSerialization \
		-lclangCodeGen \
		-lclangParse \
		-lclangSema \
		-lclangAnalysis \
		-lclangEdit \
		-lclangAST \
		-lclangLex \
		-lclangBasic \
		$(llvm_config --libs)
}

ALIB=../../../../bin/$P/terra.a

slink() {
	rm -f $ALIB
	echo "
CREATE $ALIB
$(addmods *.o)
$(addlibs $(libs))
SAVE
END
	" | ar -M
	ranlib $ALIB
}

dx() {
	verbose g++ -shared -s \
		-o ../../../../bin/$P/clib/$D \
		-L../../../../bin/$P \
		$(llvm_config --ldflags) \
		-Wl,--version-script=../../terra.version \
		*.o $ALIB \
		-lz \
		"$@" \
		-static-libgcc -static-libstdc++ \
		-Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic
}

dlink_mingw() {
	dx -llua51 -lshlwapi -ldbghelp -lshell32 -lpsapi -limagehlp
}
dlink_mingw32() { dlink_mingw; }
dlink_mingw64() { dlink_mingw; }

dlink_osx() {
	dx -dynamiclib -single_module -fPIC \
		-install_name @rpath/libterra.dylib \
		-lluajit -lcurses
}
dlink_osx32() { dlink_osx; }
dlink_osx64() { dlink_osx; }

dlink_linux() {
	dx -dynamiclib -single_module -fPIC \
		-install_name @rpath/libterra.dylib \
		-lluajit -lcurses
}
#dlink_linux32 { dlink_linux; }
#dlink_linux64 { dlink_linux; }

dlink() { dlink_$P; }

install() {
	cp -f terralib.lua                 ../../../../
	cp -f cudalib.lua                  ../../../../
	cp -f ../release/include/parsing.t ../../../../terra_parsing.t
	cp -f ../release/include/std.t     ../../../../terra_std.t
}

compile
slink
dlink
install
