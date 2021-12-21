C="$C
-DHAVE_STDINT_H
-DHAVE_ZLIB
-DHAVE_WZAES
-DHAVE_PKCRYPT
-DMZ_ZIP_SIGNING
mz_crypt.c
mz_os.c
mz_strm.c
mz_strm_buf.c
mz_strm_mem.c
mz_strm_pkcrypt.c
mz_strm_split.c
mz_strm_wzaes.c
mz_strm_zlib.c
mz_zip.c
mz_zip_rw.c
"
${X}gcc -c -msse3 -msse4.1 -O3 $C -I. -Ibrg -I../zlib
${X}gcc *.o -shared -o ../../bin/$P/$D -L../../bin/$P -lz $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
