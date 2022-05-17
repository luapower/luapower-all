# TODO: detect the right make.exe to use instead of hardcoding the path.
export PATH="/x/tools/msys/usr/bin:$PATH"

build_dir="$PWD/build" M="MSYS Makefiles" \
DI=libjpeg-62.dll D=jpeg.dll AI=libjpeg.a A=jpeg.a \
P=mingw64 ./build.sh
