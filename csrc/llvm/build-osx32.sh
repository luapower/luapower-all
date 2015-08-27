P=osx32 M="
    -DCMAKE_OSX_ARCHITECTURES=i386
    -DLLVM_ENABLE_LIBCXX=ON
    -DCMAKE_CXX_FLAGS=-mmacosx-version-min=10.7
    " ./build.sh
