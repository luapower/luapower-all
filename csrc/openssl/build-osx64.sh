cd src || exit 1

make clean
./config shared -mmacosx-version-min=10.9
make

d=../../../bin/osx64
cp -f libcrypto.1.1.dylib  $d/libcrypto.dylib
cp -f libcrypto.a          $d/
cp -f libssl.1.1.dylib     $d/libssl.dylib
cp -f libssl.a             $d/

install_name_tool -change /usr/local/lib/libcrypto.1.1.dylib @rpath/libcrypto.dylib $d/libssl.dylib

install_name_tool -id @rpath/libcrypto.dylib $d/libcrypto.dylib
install_name_tool -id @rpath/libssl.dylib    $d/libssl.dylib

cp -f include/openssl/opensslconf.h ../include-osx64/openssl/opensslconf.h
