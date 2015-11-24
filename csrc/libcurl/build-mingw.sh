C="$C -D_WIN32_WINNT=0x0501 -DUSE_WINDOWS_SSPI -DUSE_SCHANNEL
	-DUSE_WIN32_IDN -DWANT_IDN_PROTOTYPES" \
	L="-s -static-libgcc -lws2_32 -lnormaliz" \
	D=curl.dll A=curl.a ./build.sh
