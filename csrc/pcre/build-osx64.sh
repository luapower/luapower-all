[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-DHAVE_STDINT_H -arch x86_64 -mmacosx-version-min=10.7" \
	L="-arch x86_64 -mmacosx-version-min=10.7 -install_name @rpath/libpcre.dylib" \
	D=libpcre.dylib A=libpcre.a ./build.sh
