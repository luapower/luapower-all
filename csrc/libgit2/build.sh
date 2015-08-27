# build with included hash generator, included regex, included http parser,
# dynamic bind to zlib; no ssl, no ssh, no iconv, no tracing, no threads.
[ "$C" ] || exit
gcc -c -O2 $C \
	src/*.c -Isrc -Iinclude \
	src/xdiff/*.c -Isrc/xdiff \
	src/hash/hash_generic.c -Isrc/hash \
	src/transports/*.c -Isrc/transports \
	deps/regex/regex.c -Ideps/regex \
	deps/http-parser/http_parser.c -Ideps/http-parser \
	-I../zlib
gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz $L
ar rcs ../../bin/$P/$A *.o
rm *.o
