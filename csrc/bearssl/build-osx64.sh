[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64 mz_crypt_apple.c mz_strm_os_posix.c mz_os_posix.c" \
	L="-arch x86_64 -install_name @rpath/libminizip2.dylib
		-framework CoreFoundation -framework Security -liconv" \
	D=libminizip2.dylib A=libminizip2.a ./build.sh
