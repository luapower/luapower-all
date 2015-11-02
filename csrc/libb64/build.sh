${X}gcc -c -O2 $C *.c -Wall -I.
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
