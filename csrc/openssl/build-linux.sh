[ "$P" ] || exit 1
cd src || exit 1

make clean
./config $C shared
make

d=../luapower/bin/$P
cp -f libcrypto.so.1.0.0  $d/libcrypto.so
cp -f libcrypto.a         $d/
cp -f libssl.so.1.0.0     $d/libssl.so
cp -f libssl.a            $d/

cd ..
./copy-headers.sh
