C="
-DHAVE_STRSEP
-DHAVE_STPCPY
-DHAVE_EXPLICIT_BZERO
" P=linux64 L="-s -static-libgcc" \
	D=libtls_bearssl.so A=libtls_bearssl.a ./build.sh
