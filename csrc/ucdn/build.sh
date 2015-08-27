#TODO: remove the MINGW32 hack
gcc -c -O2 $C ucdn.c  -D__MINGW32__
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
