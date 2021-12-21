export C="-fPIC" L="-s -static-libgcc -static-libstdc++ -Wl,--version-script=../../terra.version"
P=linux64 D=terra.so A=libterra.a ./build.sh
