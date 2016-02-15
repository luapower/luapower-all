[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 NOAVX=1 C="-arch i386" L="-arch i386 -install_name @rpath/libblake2.dylib" \
	D=libblake2.dylib A=libblake2.a ./build.sh
