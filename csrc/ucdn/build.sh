#TODO: remove the MINGW32 hack
${X}gcc -c -O2 $C ucdn.c  -D__MINGW32__
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
