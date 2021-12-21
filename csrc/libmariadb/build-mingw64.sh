P=mingw64 C="
    -DWINVER=0x600
    -D_WIN32_WINNT=0x600
    tls-schannel/*.c
    win-iconv/*.c
    -Iwin-iconv
    -DSIZEOF_LONG=4
    -DSIZEOF_ULONG=4
    -DHAVE_SCHANNEL=1
    -DHAVE_SOCKET_H=1
    -DMARIADB_SYSTEM_TYPE=\"Windows\"
    -DMARIADB_MACHINE_TYPE=\"AMD64\"
    -DSOCKET_SIZE_TYPE=int
" L="-s -static-libgcc -lws2_32 -lcrypt32 -lbcrypt -lsecur32 -lshlwapi
    -Wl,--version-script=libmariadb.version" \
    D=mariadb.dll A=mariadb.a ./build.sh
