LL="-install_name @rpath/libvorbis.dylib"     DL=libvorbis.dylib     AL=libvorbis.a \
LF="-install_name @rpath/libvorbisfile.dylib" DF=libvorbisfile.dylib AF=libvorbisfile.a \
LE="-install_name @rpath/libvorbisenc.dylib"  DE=libvorbisenc.dylib  AE=libvorbisenc.a \
./build.sh
