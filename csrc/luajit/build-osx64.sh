export CROSS="x86_64-apple-darwin11-"
#export HOST_SYS="Linux"
#export TARGET_SYS="Darwin"
MAKE=make P=osx64 CFLAGS="-arch x86_64" LDFLAGS="-arch x86_64" \
	X0=luajit X=luajit-bin D0=libluajit.so D=libluajit.dylib A=libluajit.a ./build.sh

install_name_tool -id @rpath/libluajit.dylib ../../bin/osx64/libluajit.dylib
install_name_tool -add_rpath @loader_path/ ../../bin/osx64/luajit-bin
