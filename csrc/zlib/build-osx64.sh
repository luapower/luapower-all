[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64 -mmacosx-version-min=10.9" \
	L="-arch x86_64 -mmacosx-version-min=10.9 -install_name @rpath/libz.dylib" \
	D=libz.dylib A=libz.a ./build.sh
