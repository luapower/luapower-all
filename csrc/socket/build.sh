mkdir -p "$(dirname ../../bin/$P/clib/socket/$SD)"
gcc -c -O2 $C $files -I. -I../lua-headers
gcc *.o -shared -o ../../bin/$P/clib/socket/$SD $L
ar rcs ../../bin/$P/$SA *.o
rm *.o

mkdir -p "$(dirname ../../bin/$P/clib/mime/$MD)"
gcc -c -O2 $C src/mime.c -I. -I../lua-headers
gcc mime.o -shared -o ../../bin/$P/clib/mime/$MD $L
ar rcs ../../bin/$P/$MA mime.o

rm *.o
