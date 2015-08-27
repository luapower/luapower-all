P=osx64 \
	C="-arch x86_64 -mmacosx-version-min=10.6 -DHAVE_PTHREADS -DPIXMAN_NO_TLS" \
	L="-arch x86_64 -mmacosx-version-min=10.6 -install_name @rpath/libpixman.dylib " \
	D=libpixman.dylib A=libpixman.a ./build.sh
