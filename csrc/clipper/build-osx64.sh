P=osx64 C="-arch x86_64 -mmacosx-version-min=10.6" \
	L="-arch x86_64 -install_name @rpath/libclipper.dylib -mmacosx-version-min=10.6" \
	D=libclipper.dylib A=libclipper.a ./build.sh
