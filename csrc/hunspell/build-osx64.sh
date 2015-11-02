[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
export C="-arch x86_64 -mmacosx-version-min=10.6"
P=osx64 L="$C -install_name @rpath/libhunspell.dylib" \
	D=libhunspell.dylib A=libhunspell.a ./build.sh
