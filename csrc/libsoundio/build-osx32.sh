P=osx32 C="-arch i386 -DSOUNDIO_HAVE_COREAUDIO src/coreaudio.cpp" \
	L="-arch i386 -framework AudioUnit -framework CoreAudio -framework CoreFoundation -install_name @rpath/libsoundio.dylib" \
	D=libsoundio.dylib A=libsoundio.a ./build.sh
