[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -install_name @rpath/libnanojpeg2.dylib" \
	D=libnanojpeg2.dylib A=libnanojpeg2.a ./build.sh
