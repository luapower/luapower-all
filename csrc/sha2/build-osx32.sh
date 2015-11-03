[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libsha2.dylib" \
	D=libsha2.dylib A=libsha2.a ./build.sh
