${X}gcc -c -O2 $C genx.c charProps.c -Wall -pedantic
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
