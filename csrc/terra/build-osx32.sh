export C="-arch i386 -stdlib=libc++ -mmacosx-version-min=10.7"
export L="-arch i386 -stdlib=libc++ -mmacosx-version-min=10.7 -lcurses -undefined dynamic_lookup -exported_symbols_list ../../terra.exp"
P=osx32 D=terra.so A=libterra.a ./build.sh
