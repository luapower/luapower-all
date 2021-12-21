${X}gcc -c -O2 $C *.c -I. -I../lua-headers -Wall -pedantic
${X}gcc *.o -shared -o ../../bin/$P/clib/$D -L../../bin/$P $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
