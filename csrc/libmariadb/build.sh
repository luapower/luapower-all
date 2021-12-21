WARN="
-Wunused -Wlogical-op -Wno-uninitialized -Wall -Wextra -Wformat-security
-Wno-init-self -Wwrite-strings -Wshift-count-overflow
-Wdeclaration-after-statement -Wno-undef -Wno-unknown-pragmas
"
${X}gcc -c -O3 $C *.c  -I../zlib -I. -DHAVE_TLS $WARN
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P $L -lz
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
