export L="-s -static-libgcc -static-libstdc++ -Wl,--version-script=../../terra.version"
P=linux32 D=terra.so A=libterra.a ./build.sh
