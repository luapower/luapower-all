P=mingw32 C="-DWINVER=0x0501 -D_WIN32_WINNT=0x0501" \
	L="-s -static-libgcc -llua51" D=core.dll A=lanes_core.a ./build.sh
