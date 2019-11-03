P=mingw64 C="
    tls-schannel/*.c
    -DSIZEOF_LONG=4
    -DSIZEOF_ULONG=4
    -DHAVE_SCHANNEL=1
    -DMARIADB_SYSTEM_TYPE=\"Windows\"
    -DMARIADB_MACHINE_TYPE=\"AMD64\"
    -DSOCKET_SIZE_TYPE=int
" L="-s -static-libgcc" D=mariadb.dll A=mariadb.a ./build.sh
