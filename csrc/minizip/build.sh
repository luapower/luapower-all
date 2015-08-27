gcc -c -O2 $C zip.c unzip.c ioapi.c -I. -I../zlib
gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz $L
ar rcs ../../bin/$P/$A *.o
rm *.o
