${X}gcc -c -O3 -std=c99 -pedantic $C *.c -I. -I../xxhash
${X}gcc *.o -shared -lxxhash -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
