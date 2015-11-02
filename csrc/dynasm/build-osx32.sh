[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libdasm_x86.dylib" \
	D=libdasm_x86.dylib A=libdasm_x86.a ./build.sh
