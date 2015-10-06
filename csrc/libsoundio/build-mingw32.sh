P=mingw32 C="-DSOUNDIO_HAVE_WASAPI src/wasapi.cpp" \
	L="-s -static-libgcc -lole32" \
	D=soundio.dll A=soundio.a ./build.sh
