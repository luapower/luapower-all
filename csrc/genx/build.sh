gcc -c -O2 $C genx.c charProps.c -Wall -pedantic
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
