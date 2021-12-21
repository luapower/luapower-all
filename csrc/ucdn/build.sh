${X}gcc -c -O2 $C -DUCDN_EXPORT ucdn.c
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
