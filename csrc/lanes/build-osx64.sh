[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64" L="-arch x86_64 -undefined dynamic_lookup" \
	D=core.so A=liblanes_core.a ./build.sh
