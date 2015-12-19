cp -f curlbuild.h.generic include/curlbuild.h
C="$C -D_WIN32_WINNT=0x0501 -DUSE_WINDOWS_SSPI -DUSE_SCHANNEL
	-DUSE_WIN32_IDN -DWANT_IDN_PROTOTYPES idn_win32.c vtls/schannel.c" \
	L="-s -static-libgcc -lws2_32 -lnormaliz" \
	D=curl.dll A=curl.a ./build.sh
