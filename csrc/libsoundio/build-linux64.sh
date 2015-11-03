P=linux64 C="-fPIC -DSOUNDIO_HAVE_ALSA src/alsa.cpp" \
	L="-s -static-libgcc -pthread -lasound -fno-exceptions -fno-rtti -fvisibility=hidden" \
	D=libsoundio.so A=libsoundio.a ./build.sh
