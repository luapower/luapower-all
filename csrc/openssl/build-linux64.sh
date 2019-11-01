cd src || exit 1

make clean
./config -fPIC shared
sed -e 's|-Wl,-soname=libssl$(SHLIB_EXT)||g' -i Makefile
make

d=../../../bin/linux64
cp -f libcrypto.so.1.1    $d/libcrypto.so
cp -f libcrypto.a         $d/
cp -f libssl.so.1.1       $d/libssl.so
cp -f libssl.a            $d/

cp -f include/openssl/opensslconf.h ../opensslconf.h.linux64
