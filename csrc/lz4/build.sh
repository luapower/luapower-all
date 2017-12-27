${X}gcc -c -O3 -std=c99 -pedantic $C *.c -I.
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
