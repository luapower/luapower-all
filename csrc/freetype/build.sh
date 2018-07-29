[ "$NO_HARFBUZZ" ] || C="$C -I../harfbuzz/src -DFT_CONFIG_OPTION_USE_HARFBUZZ"
${X}gcc -c -O2 $C `./files.sh` -Icustom -Iinclude -I../libpng -DFT2_BUILD_LIBRARY
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lpng -lharfbuzz $L
rm ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
