cp -f curl_config.h.osx64 lib/curl_config.h
cp -f curlbuild.h.osx64 include/curl/curlbuild.h
[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
P=osx64 C="-arch x86_64 -DHAVE_CONFIG_H vtls/darwinssl.c" \
	L="-arch x86_64 -install_name @rpath/libcurl.dylib -framework CoreFoundation -framework Security" \
	D=libcurl.dylib A=libcurl.a ./build.sh
