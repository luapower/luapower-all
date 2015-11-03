[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64" L="-arch x86_64 -install_name @rpath/libmd5.dylib" \
	D=libmd5.dylib A=libmd5.a ./build.sh
