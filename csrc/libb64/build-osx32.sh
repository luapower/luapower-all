[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libb64.dylib" \
	D=libb64.dylib A=libb64.a ./build.sh
