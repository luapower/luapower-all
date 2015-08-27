MAKE=make P=osx32 CFLAGS="-arch i386" LDFLAGS="-arch i386" \
	X0=luajit X=luajit-bin D0=libluajit.so D=libluajit.dylib A=libluajit.a ./build.sh

install_name_tool -id @rpath/libluajit.dylib ../../bin/osx32/libluajit.dylib
install_name_tool -add_rpath @loader_path/ ../../bin/osx32/luajit-bin
