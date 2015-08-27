gcc -c -O2 $C `./files.sh` -Icustom -Iinclude -DFT2_BUILD_LIBRARY
gcc *.o -shared -o ../../bin/$P/$D $L
ar rcs ../../bin/$P/$A *.o
rm *.o
