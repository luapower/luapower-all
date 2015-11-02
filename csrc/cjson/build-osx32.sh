[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 D=cjson.so A=libcjson.a C="-arch i386" \
	L="-arch i386 -undefined dynamic_lookup -Wno-static-in-inline" ./build.sh
