C="-fPIC mz_strm_os_posix.c mz_os_posix.c mz_crypt_brg.c brg/*.c -Ibrg" \
	P=linux64 L="-s -static-libgcc -Wl,--unresolved-symbols=report-all" \
	D=libminizip2.so A=libminizip2.a ./build.sh
