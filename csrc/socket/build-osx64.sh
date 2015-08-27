files="$(ls -1 src/*.c | grep -v "wsocket\|serial\|mime")" \
	P=osx64 C="-arch x86_64 -DLUASOCKET_API=extern" \
	L="-arch x86_64 -undefined dynamic_lookup" \
	SD=core.so MD=core.so SA=libsocket_core.a MA=libmime_core.a ./build.sh
