${X}gcc -c -O3 -DSPNG_SSE=4 $C *.c -I../zlib
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
