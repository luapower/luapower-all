${X}gcc -c -O2 $C zip.c unzip.c ioapi.c -I. -I../zlib
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
