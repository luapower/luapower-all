gcc -c -O2 $C *.c -DSTRUCT_INT="long long" -Wno-long-long -I. -I../lua-headers -ansi -Wall -pedantic
gcc *.o -shared -o ../../bin/$P/clib/$D -L../../bin/$P $L
ar rcs ../../bin/$P/$A *.o
rm *.o
