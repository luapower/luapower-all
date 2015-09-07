export C="-arch x86_64 -stdlib=libc++ -mmacosx-version-min=10.7"
export L="-arch x86_64 -stdlib=libc++ -mmacosx-version-min=10.7 -lcurses -undefined dynamic_lookup -exported_symbols_list ../../terra.exp"
P=osx64 D=terra.so A=libterra.a ./build.sh
