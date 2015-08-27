P=linux64 C="-fPIC -include _memcpy.h -DHAVE_PTHREADS -DTLS=__thread" L="-s -static-libgcc" \
	D=libpixman.so A=libpixman.a ./build.sh
