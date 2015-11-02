[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libgenx.dylib" \
	D=libgenx.dylib A=libgenx.a ./build.sh
