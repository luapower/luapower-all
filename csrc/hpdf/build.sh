${X}gcc -c -O2 $C src/*.c -Iinclude -I../libpng -I../zlib
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz -lpng $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
