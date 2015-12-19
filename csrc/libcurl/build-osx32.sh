cp -f curl_config.h.osx32 lib/curl_config.h
cp -f curlbuild.h.osx32 include/curl/curlbuild.h
[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="-arch i386 -DHAVE_CONFIG_H vtls/darwinssl.c" \
	L="-arch i386 -install_name @rpath/libcurl.dylib -framework CoreFoundation -framework Security" \
	D=libcurl.dylib A=libcurl.a ./build.sh
