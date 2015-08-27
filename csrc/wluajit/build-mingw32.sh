LUAJIT_SRC=../luajit/src/src
BIN_DIR=../../bin/mingw32
windres luajit.rc luajit.o
gcc -O2 -s -static-libgcc wmain.c luajit.o $LUAJIT_SRC/luajit.c -o $BIN_DIR/wluajit.exe -mwindows -llua51 -I$LUAJIT_SRC -L$BIN_DIR
rm luajit.o
