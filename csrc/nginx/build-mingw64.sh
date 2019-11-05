cd src || exit 1
BIN=../../../bin/mingw64
export ZLIB_BIN="$BIN"
export PCRE_BIN="$BIN"
C="
--with-pcre=../../pcre
--with-zlib=../../zlib
--with-cc=gcc
--with-cc-opt='-Wno-cast-function-type'
"
auto/configure $C
make
cp objs/nginx.exe "$BIN/"
