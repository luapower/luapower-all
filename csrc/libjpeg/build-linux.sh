[ "$P" ] || exit 1
cd src || exit 1
make clean
./configure
make
cp -f .libs/libjpeg.so ../../../bin/$P/
cp -f .libs/libjpeg.a ../../../bin/$P/
make clean
