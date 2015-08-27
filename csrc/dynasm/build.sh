gcc -c -O2 $C dasm_x86.c -DDASM_CHECKS
gcc *.o -shared $L -o ../../bin/$P/$D
ar rcs ../../bin/$P/$A *.o
rm *.o
