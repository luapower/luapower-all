P=mingw64 \
	C="src/hostapi/dsound/*.c src/os/win/*.c \
		-Iinclude -Isrc/common -Isrc/hostapi/dsound -Isrc/os/win\
		-DPA_USE_DS=1" \
	L="-s -static-libgcc -lwinmm -lole32 -luuid" D=portaudio.dll A=portaudio.a ./build.sh
