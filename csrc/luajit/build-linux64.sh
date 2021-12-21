export LUA_PATH_DEFAULT="./?.lua;!/../../?.lua;!/../../?/init.lua"
export LUA_CPATH_DEFAULT="./?.so;!/clib/?.so;!/loadall.so"
MAKE=make P=linux64 CFLAGS="-pthread" \
	LDFLAGS="-pthread -s -static-libgcc -Wl,--disable-new-dtags -Wl,-rpath,'\$\$ORIGIN'" \
	X=luajit D=libluajit.so A=libluajit.a ./build.sh
