gcc -c -O2 $C strbuf.c lua_cjson.c fpconv.c -I../lua-headers \
	-Wall -pedantic -DDISABLE_INVALID_NUMBERS
gcc *.o -shared -o ../../bin/$P/clib/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
