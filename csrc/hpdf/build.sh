gcc -c -O2 $C src/*.c -Iinclude -I../libpng -I../zlib
gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz -lpng $L
ar rcs ../../bin/$P/$A *.o
rm *.o
