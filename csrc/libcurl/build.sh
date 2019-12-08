C="$C
*.c
vtls/vtls.c
vquic/*.c
vssh/*.c
vauth/*.c

-I. -I../include
-DHAVE_LIBZ -DHAVE_ZLIB_H -I../../zlib
-DENABLE_IPV6
-DCURL_DISABLE_LDAP
-DCURL_WITH_MULTI_SSL
-DUSE_OPENSSL vtls/openssl.c
-I../../openssl/src/include
-I../../openssl/include-$P
"
cd lib || exit 1
rm -f *.o
${X}gcc -c -O2 -Wall -fno-strict-aliasing -DBUILDING_LIBCURL $C
${X}gcc *.o -shared -o ../../../bin/$P/$D $L -L../../../bin/$P -lz
rm -f      ../../../bin/$P/$A
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
