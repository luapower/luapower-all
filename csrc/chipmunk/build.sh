${X}gcc -c -O2 $C src/*.c src/constraints/*.c -Iinclude/chipmunk \
	-std=gnu99 -Wall -ffast-math -DNDEBUG -DCHIPMUNK_FFI
${X}gcc *.o $L -shared -o ../../bin/$P/$D
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
