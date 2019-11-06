[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="hid_osx.c -arch x86_64" L="-arch x86_64 -install_name @rpath/libhidapi.dylib" \
	D=libhidapi.dylib A=libhidapi.a ./build.sh
