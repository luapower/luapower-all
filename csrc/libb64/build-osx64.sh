[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64" L="-arch x86_64 -install_name @rpath/libb64.dylib" \
	D=libb64.dylib A=libb64.a ./build.sh
