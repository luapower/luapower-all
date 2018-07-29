${X}gcc -c -O2 $C src/*.c -Isrc -DHAVE_EXPAT_CONFIG_H
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
