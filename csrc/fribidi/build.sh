gcc -c -O2 $C src/*.c src/charset/*.c -Isrc -Isrc/charset -Wall -ansi -DHAVE_CONFIG_H
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
