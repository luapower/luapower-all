C="mz_os_win32.c mz_strm_os_win32.c mz_crypt_win32.c
-D_WIN32_WINNT=0x601 -DWINVER=0x601" P=mingw64 L="-s -static-libgcc -lcrypt32" \
	D=minizip2.dll A=minizip2.a ./build.sh
