[ `uname` = Linux ] && export X=x86_64-apple-darwin11-
C="-arch x86_64 src/unix/*.c" P=osx64 \
    L="-arch x86_64 -install_name @rpath/libgit2.dylib" \
    D=libgit2.dylib A=libgit2.a ./build.sh
