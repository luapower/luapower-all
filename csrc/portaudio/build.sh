gcc -c -O2 $C src/common/*.c -Iinclude -Isrc/common
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
