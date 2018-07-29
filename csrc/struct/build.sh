${X}gcc -c -O2 $C *.c -DSTRUCT_INT="long long" -Wno-long-long -I. -I../lua-headers -ansi -Wall -pedantic
${X}gcc *.o -shared -o ../../bin/$P/clib/$D -L../../bin/$P $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
