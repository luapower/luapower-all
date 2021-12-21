${X}gcc -c *.c compat/*.c -I. -I../bearssl -O2 -fPIC $C \
	-Wall -D_GNU_SOURCE -D_POSIX_SOURCE
${X}gcc *.o -g -shared -o ../../bin/$P/$D -L../../bin/$P -lbearssl $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
