P=linux64 C="-fPIC -DSOUNDIO_HAVE_ALSA src/alsa.cpp" \
	L="-s -static-libgcc" \
	D=libsoundio.so A=libsoundio.a ./build.sh
