P=linux32 L="-s -static-libgcc" D=libucdn.so A=libucdn.a ./build.sh

nm -D ../../bin/linux32/libucdn.so
