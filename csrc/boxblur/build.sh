${X}gcc -ansi -pedantic -Wall -msse2 -O3 -c $C boxblur.c
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
