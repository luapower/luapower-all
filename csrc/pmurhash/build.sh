gcc -c -O2 $C PMurHash.c
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
