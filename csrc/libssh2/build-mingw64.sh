P=mingw64 C="-I../include/mingw -DLIBSSH2_WINCNG -DLIBSSH2_WIN32" L="-s -static-libgcc -lws2_32 -lbcrypt -lcrypt32" \
	D=ssh2.dll A=ssh2.a ./build.sh
