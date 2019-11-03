S="$PWD"
cd /x/tools/mingw64 && cat "$S/schannel.h.patch" | patch -N -p0
