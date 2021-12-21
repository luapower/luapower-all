${X}gcc -std=c11 -pedantic -Wall -O3 -c $C lx.c
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
