./get-it.sh
[ "$P" ] || exit 1
cd src || exit 1
cmake -G "MSYS Makefiles" .
make clean
make jpeg && strip sharedlib/libjpeg-62.dll
cp sharedlib/libjpeg-62.dll ../../../bin/$P/jpeg.dll
make jpeg-static
cp -f libjpeg.a ../../../bin/$P/jpeg.a
make clean
