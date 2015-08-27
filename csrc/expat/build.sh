gcc -c -O2 $C src/*.c -Isrc -DHAVE_EXPAT_CONFIG_H
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
