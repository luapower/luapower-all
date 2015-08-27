export C="-arch i386 -mmacosx-version-min=10.6"
P=osx32 L="$C -install_name @rpath/libhunspell.dylib" \
	D=libhunspell.dylib A=libhunspell.a ./build.sh
