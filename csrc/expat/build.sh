${X}gcc -c -O2 $C src/*.c -Isrc -DHAVE_EXPAT_CONFIG_H
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
