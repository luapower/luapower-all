[ "$P" ] || exit 1
cd src || exit 1

make clean
./config $C shared
cat ../*.patch | patch -N -p1
make

d=../../../bin/$P
cp -f libcrypto.so.1.1    $d/libcrypto.so
cp -f libcrypto.a         $d/
cp -f libssl.so.1.1       $d/libssl.so
cp -f libssl.a            $d/

make clean
rm src/Makefile src/configdata.pm
