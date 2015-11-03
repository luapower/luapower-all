${X}gcc -c -O2 $C vararg.c -ansi -I../lua-headers
${X}gcc *.o -shared -o ../../bin/$P/clib/$D -L../../bin/$P $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
