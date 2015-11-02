[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386 -mmacosx-version-min=10.6" \
	L="-arch i386 -install_name @rpath/libclipper.dylib -mmacosx-version-min=10.6" \
	D=libclipper.dylib A=libclipper.a ./build.sh
