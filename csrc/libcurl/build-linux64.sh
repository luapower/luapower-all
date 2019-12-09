P=linux64 C="-fPIC -include ../config-linux64.h" \
	L="-s -static-libgcc -lssl -lcrypto" \
	D=libcurl.so A=libcurl.a ./build.sh
