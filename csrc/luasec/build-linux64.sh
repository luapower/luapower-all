P=linux64 C="
    -fPIC -DWITH_LUASOCKET
    -I../openssl/include-linux64
    config.c context.c ec.c ssl.c x509.c
    luasocket/buffer.c luasocket/io.c luasocket/timeout.c luasocket/usocket.c
" L="-s -static-libgcc -lluajit" D=ssl.so A=ssl.a ./build.sh
