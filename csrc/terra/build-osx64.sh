<<<<<<< HEAD
LP=osx P=osx64 ./build.sh
=======
export C="-arch x86_64 -stdlib=libc++ -mmacosx-version-min=10.7"
export L="-arch x86_64 -stdlib=libc++ -mmacosx-version-min=10.7 -lcurses -undefined dynamic_lookup -exported_symbols_list ../../terra.exp"
P=osx64 D=terra.so A=libterra.a ./build.sh
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
