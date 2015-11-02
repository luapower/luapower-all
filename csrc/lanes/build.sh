mkdir -p ../../bin/$P/clib/lanes
${X}gcc -c -O2 $C src/*.c -I../lua-headers -DNDEBUG
${X}gcc *.o -shared -o ../../bin/$P/clib/lanes/$D -L../../bin/$P $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
