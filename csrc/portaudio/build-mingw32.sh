P=mingw32 \
	C="src/hostapi/dsound/*.c \
		src/os/win/pa_win_util.c \
		src/os/win/pa_win_coinitialize.c \
		src/os/win/pa_win_hostapis.c \
		src/os/win/pa_win_waveformat.c \
		src/os/win/pa_win_wdmks_utils.c \
		-Iinclude -Isrc/common -Isrc/hostapi/dsound -Isrc/os/win" \
	L="-s -static-libgcc -lwinmm -lole32 -luuid" D=portaudio.dll A=portaudio.a ./build.sh
