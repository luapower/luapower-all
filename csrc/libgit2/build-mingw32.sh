C="-DWINVER=0x501 src/win32/*.c" \
	P=mingw32 L="-s -static-libgcc -lws2_32" D=git2.dll A=git2.a ./build.sh
