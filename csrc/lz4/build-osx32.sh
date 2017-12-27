[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/liblz4.dylib" \
	D=liblz4.dylib A=liblz4.a ./build.sh
