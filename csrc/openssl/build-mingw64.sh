cd src || exit 1

make clean
perl Configure mingw64 shared
sed -e 's|-1_1-x64||g' -i Makefile  # remove `-1_1-x64` suffix in lib names.
patch -N -p1 < ../mkdef.util.patch  # remove `-1_1-x64` suffix in lib names in .def files.
make

d=../../../bin/mingw64
cp -f libcrypto.dll    $d/
cp -f libcrypto.dll.a  $d/libcrypto.a
cp -f libssl.dll       $d/
cp -f libssl.dll.a     $d/libssl.a

cp -f include/openssl/opensslconf.h ../include-mingw64/openssl/opensslconf.h
