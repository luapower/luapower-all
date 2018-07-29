${X}gcc -c -O2 $C sha2.c -I. -DSHA2_USE_INTTYPES_H -DBYTE_ORDER -DLITTLE_ENDIAN
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
