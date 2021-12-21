[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64 -std=c++11" L="-arch x86_64 -install_name @rpath/libharfbuzz.dylib" \
	D=libharfbuzz.dylib A=libharfbuzz.a ./build.sh
