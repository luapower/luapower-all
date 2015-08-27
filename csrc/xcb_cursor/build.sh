gperf --includes --struct-type --language=ANSI-C --switch=1 shape_to_id.gperf > shape_to_id.c

gcc -c -O2 -std=c99 -D_GNU_SOURCE $C *.c -I.
gcc *.o -shared -o ../../bin/$P/$D $L -lxcb-render -lxcb-render-util -lxcb-image
ar rcs ../../bin/$P/$A *.o
rm *.o
