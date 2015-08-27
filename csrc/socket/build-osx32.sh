files="$(ls -1 src/*.c | grep -v "wsocket\|serial\|mime")" \
	P=osx32 C="-arch i386 -DLUASOCKET_API=extern" \
	L="-arch i386 -undefined dynamic_lookup" \
	SD=core.so MD=core.so SA=libsocket_core.a MA=libmime_core.a ./build.sh
