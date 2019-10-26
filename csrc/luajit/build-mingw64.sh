export LUA_PATH=".\\\\?.lua;!\\\\?.lua;!\\\\?\\\\init.lua;!\\\\..\\\\..\\\\?.lua;!\\\\..\\\\..\\\\?\\\\init.lua"
export LUA_CPATH=".\\\\?.dll;!\\\\clib\\\\?.dll;!\\\\loadall.dll"
MAKE=mingw32-make P=mingw64 LDFLAGS=-static-libgcc \
	X=luajit.exe D=lua51.dll A=luajit.a .\\\\build.sh
