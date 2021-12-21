cp -f curl_config.h.$P lib/curl_config.h
cp -f curlbuild.h.$P include/curl/curlbuild.h
[ `uname` = Linux ] && export X=$A-apple-darwin11-
C="-arch $A -DHAVE_CONFIG_H vtls/darwinssl.c" \
L="-arch $A -install_name @rpath/libcurl.dylib -framework CoreFoundation -framework Security" \
D=libcurl.dylib A=libcurl.a ./build.sh
