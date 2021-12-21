[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64 -DSOUNDIO_HAVE_COREAUDIO src/coreaudio.cpp" \
	L="-arch x86_64 -framework AudioUnit -framework CoreAudio -framework CoreFoundation -install_name @rpath/libsoundio.dylib" \
	D=libsoundio.dylib A=libsoundio.a ./build.sh
