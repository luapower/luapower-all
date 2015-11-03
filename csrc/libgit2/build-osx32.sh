[ `uname` = Linux ] && export X=i386-apple-darwin11-
C="-arch i386 src/unix/*.c" P=osx32 \
    L="-arch i386 -install_name @rpath/libgit2.dylib" \
    D=libgit2.dylib A=libgit2.a ./build.sh
