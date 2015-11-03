[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libmd5.dylib" \
	D=libmd5.dylib A=libmd5.a ./build.sh
