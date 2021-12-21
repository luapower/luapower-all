P=mingw64 C="-D_WIN32_WINNT=0x601 -DWINVER=0x601" \
	L="-s -static-libgcc -lws2_32 -Wl,-Bstatic -lpthread" \
	D=tls_bearssl.dll A=tls_bearssl.a ./build.sh
