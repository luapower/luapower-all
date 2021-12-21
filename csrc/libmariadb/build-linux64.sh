P=linux64 C="
    tls-openssl/*.c
    -I../openssl/src/include
    -I../openssl/include-linux64
    -fPIC
    -DSIZEOF_LONG=8
    -DSIZEOF_ULONG=8
    -DHAVE_LINUXTHREADS=1
    -DHAVE_OPENSSL=1
    -DHAVE_POLL=1
    -DHAVE_SYS_SOCKET_H=1
    -DHAVE_PWD_H=1
    -DHAVE_GETPWUID=1
    -DHAVE_CUSERID=1
    -DHAVE_UCONTEXT_H=1
    -DMARIADB_SYSTEM_TYPE=\"Linux\"
    -DMARIADB_MACHINE_TYPE=\"AMD64\"
    -DSOCKET_SIZE_TYPE=uint
" L="-s -static-libgcc -Wl,--version-script=libmariadb.version
    -lpthread -lssl -lcrypto -ldl -Wl,--no-undefined
" D=libmariadb.so A=libmariadb.a ./build.sh
