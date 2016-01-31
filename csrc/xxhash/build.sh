${X}gcc -c -O3 $C *.c -I. \
	-std=c99 -Wall -Wextra -Wshadow -Wcast-qual -Wcast-align \
	-Wstrict-prototypes -Wstrict-aliasing=1 -Wswitch-enum -Wundef -pedantic
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
