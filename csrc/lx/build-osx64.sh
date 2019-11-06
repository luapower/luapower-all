[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64" L="-arch x86_64 -install_name @rpath/liblx.dylib" \
	D=liblx.dylib A=liblx.a ./build.sh
