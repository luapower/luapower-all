[ "$P" ] || exit 1
cd src || exit 1
cmake -G "MSYS Makefiles" .
make clean
make jpeg && strip libjpeg-62.dll
cp libjpeg-62.dll ../../../bin/$P/jpeg.dll
make jpeg-static
cp -f libjpeg.a ../../../bin/$P/jpeg.a
make clean
