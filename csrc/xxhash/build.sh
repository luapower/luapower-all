${X}gcc -c -O3 -DXXH_VECTOR=XXH_SSE2 $C *.c -I. \
	-std=c99 -Wall -Wextra -Wshadow -Wcast-qual -Wcast-align \
	-Wstrict-prototypes -Wstrict-aliasing=1 -Wswitch-enum -Wundef -pedantic
${X}gcc *.o -shared -o ../../bin/$P/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
