gcc -c -O2 $C md5.c -Wall -I.
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
