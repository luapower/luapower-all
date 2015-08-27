gcc -c -O2 $C sha2.c -I. -DSHA2_USE_INTTYPES_H -DBYTE_ORDER -DLITTLE_ENDIAN
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
