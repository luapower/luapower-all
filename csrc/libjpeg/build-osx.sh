./get-it.sh
cd src
FLAGS=""
make clean
[ $X ] && X="--host $X" || X="--host $A-apple-darwin"
./configure $X \
	NASM=/opt/local/bin/nasm \
	CFLAGS="-O3 $M -mmacosx-version-min=10.6" \
	LDFLAGS="$M -mmacosx-version-min=10.6"
make
cp -f .libs/libjpeg.dylib ../../../bin/$P/
${X}install_name_tool -id @rpath/libjpeg.dylib ../../../bin/$P/libjpeg.dylib
cp -f .libs/libjpeg.a ../../../bin/$P/
make clean
