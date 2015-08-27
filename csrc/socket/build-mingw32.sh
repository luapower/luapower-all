files="$(ls -1 src/*.c | grep -v "usocket\|unix\|serial\|mime")" \
	P=mingw32 C="-DWINVER=0x0501 -DLUASOCKET_INET_PTON" \
	L="-s -static-libgcc -L../../bin/mingw32 -llua51 -lws2_32" \
	SD=core.dll MD=core.dll SA=socket_core.a MA=mime_core.a ./build.sh
