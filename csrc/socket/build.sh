mkdir -p "$(dirname ../../bin/$P/clib/socket/$SD)"
${X}gcc -c -O2 $C $files -I. -I../lua-headers
${X}gcc *.o -shared -o ../../bin/$P/clib/socket/$SD $L
${X}ar rcs ../../bin/$P/$SA *.o
rm *.o

mkdir -p "$(dirname ../../bin/$P/clib/mime/$MD)"
${X}gcc -c -O2 $C src/mime.c -I. -I../lua-headers
${X}gcc mime.o -shared -o ../../bin/$P/clib/mime/$MD $L
${X}ar rcs ../../bin/$P/$MA mime.o

rm *.o
