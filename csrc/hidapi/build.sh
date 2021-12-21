${X}gcc -c -O2 $C
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f ../../bin/$P/$A
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
