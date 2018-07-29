${X}gcc -c -O2 $C dasm_x86.c -DDASM_CHECKS
${X}gcc *.o -shared $L -o ../../bin/$P/$D
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
