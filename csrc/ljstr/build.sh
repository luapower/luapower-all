${X}gcc -c -O2 $C lj_strscan.c lj_char.c lj_char_func.c
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
