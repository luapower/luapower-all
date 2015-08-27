gcc -c -O2 $C nanojpeg2.c -DNJ_USE_LIBC -std=c99 -Wall -Wextra -pedantic -Werror
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
