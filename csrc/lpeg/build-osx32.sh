[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386" L="-arch i386 -undefined dynamic_lookup" \
	D=lpeg.so A=liblpeg.a ./build.sh
