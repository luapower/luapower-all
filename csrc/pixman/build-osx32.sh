P=osx32 \
	C="-arch i386 -mmacosx-version-min=10.6 -DHAVE_PTHREADS -DPIXMAN_NO_TLS" \
	L="-arch i386 -mmacosx-version-min=10.6 -install_name @rpath/libpixman.dylib " \
	D=libpixman.dylib A=libpixman.a ./build.sh
