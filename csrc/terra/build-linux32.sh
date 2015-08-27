<<<<<<< HEAD
P=linux32 ./build.sh
=======
export L="-s -static-libgcc -static-libstdc++ -Wl,--version-script=../../terra.version"
P=linux32 D=terra.so A=libterra.a ./build.sh
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
