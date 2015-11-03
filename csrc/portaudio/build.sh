${X}gcc -c -O2 $C src/common/*.c -Iinclude -Isrc/common
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
