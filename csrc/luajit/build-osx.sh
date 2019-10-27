export LUA_PATH_DEFAULT="./?.lua;!/lua/?.lua;!/lua/?/init.lua;!/../../?.lua;!/../../?/init.lua"
export LUA_CPATH_DEFAULT="./?.so;!/clib/?.so;!/loadall.so"
MAKE=make X0=luajit X=luajit D0=libluajit.so D=libluajit.dylib A=libluajit.a ./build.sh
${CROSS}install_name_tool -id @rpath/libluajit.dylib ../../bin/$P/libluajit.dylib
${CROSS}install_name_tool -add_rpath @loader_path/ ../../bin/$P/luajit
