<<<<<<< HEAD
P=linux64 ./build.sh
=======
export C="-fPIC" L="-s -static-libgcc -static-libstdc++ -Wl,--version-script=../../terra.version"
P=linux64 D=terra.so A=libterra.a ./build.sh
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
