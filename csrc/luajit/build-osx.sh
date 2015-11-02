MAKE=make X0=luajit X=luajit-bin D0=libluajit.so D=libluajit.dylib A=libluajit.a ./build.sh
${CROSS}install_name_tool -id @rpath/libluajit.dylib ../../bin/$P/libluajit.dylib
${CROSS}install_name_tool -add_rpath @loader_path/ ../../bin/$P/luajit-bin
