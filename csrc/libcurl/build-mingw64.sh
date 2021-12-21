P=mingw64 C="$C
	-D_AMD64_ -D_WIN32_WINNT=0x0601
	-DUSE_WIN32_IDN -DWANT_IDN_PROTOTYPES idn_win32.c
	-DUSE_WINDOWS_SSPI -DUSE_SCHANNEL vtls/schannel*.c
	-DCURL_DEFAULT_SSL_BACKEND=\"schannel\"
	" L="$L -s -static-libgcc -Xlinker --no-insert-timestamp
		-lws2_32 -lnormaliz -lcrypt32 -llibssl -llibcrypto
	" D=curl.dll A=curl.a ./build.sh
