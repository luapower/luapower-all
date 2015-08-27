mkdir -p ../../bin/$P/clib/lanes
gcc -c -O2 $C src/*.c -I../lua-headers -DNDEBUG
gcc *.o -shared -o ../../bin/$P/clib/lanes/$D -L../../bin/$P $L
ar rcs ../../bin/$P/$A *.o
rm *.o
