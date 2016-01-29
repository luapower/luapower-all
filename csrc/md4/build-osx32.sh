[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libmd4.dylib" \
	D=libmd4.dylib A=libmd4.a ./build.sh
