[ "$P" ] || exit 1
cd src || exit 1
BIN=../../../bin/$P
export ZLIB_BIN=$BIN
export PCRE_BIN=$BIN
export OPENSSL_BIN=$BIN
export OPENSSL_PLATFORM_INCLUDE=../include-mingw64
C="$C
--prefix=.
--sbin-path=$E
--modules-path=bin/$P
--conf-path=nginx.conf

--http-client-body-temp-path=tmp/client_body
--http-proxy-temp-path=tmp/proxy
--http-fastcgi-temp-path=tmp/fastcgi
--http-scgi-temp-path=tmp/scgi
--http-uwsgi-temp-path=tmp/uwsgi

--with-pcre=../../pcre
--with-zlib=../../zlib
--with-openssl=../../openssl/src

--with-http_ssl_module
--with-http_v2_module
--with-http_sub_module
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_slice_module
--with-http_addition_module
--with-http_auth_request_module
--with-http_stub_status_module
--with-http_secure_link_module
--with-mail
--with-stream
--with-mail_ssl_module
--with-stream_ssl_module
--with-stream_ssl_preread_module
"
auto/configure $C \
	--with-cc=gcc \
	--with-cc-opt='-Wno-cast-function-type -s -O2 -fno-strict-aliasing -pipe' \
	--with-ld-opt='-s -Wl,--build-id=none'

make
cp objs/$E $BIN/
