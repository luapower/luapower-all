set -e
cd src/src || exit 1
bindir=../../../../bin/$P

CFLAGS="$CFLAGS \
-DLUAPOWER_BUILD \
-DLUAJIT_ENABLE_GC64 \
-DLUAJIT_ENABLE_LUA52COMPAT \
-DLUA_PATH_DEFAULT='\"$LUA_PATH_DEFAULT\"'  \
-DLUA_CPATH_DEFAULT='\"$LUA_CPATH_DEFAULT\"' \
"

[ "$HOST_CC" ] || HOST_CC=gcc

"$MAKE" clean
"$MAKE" HOST_CC="$HOST_CC" amalg Q=" " CFLAGS="$CFLAGS"

[ "$X0" ] || X0=$X; cp -f $X0 "$bindir/$X"
[ "$D0" ] || D0=$D; cp -f $D0 "$bindir/$D"

mkdir -p $bindir/../../jit
cp -f jit/*.lua $bindir/../../jit/
cp -f jit/vmdef.lua $bindir/../../jit/vmdef_$P.lua
cp -f ../../vmdef.lua $bindir/../../jit/vmdef.lua

[ "$MAKE" = "mingw32-make" ] && {
	"$MAKE" clean
	"$MAKE" HOST_CC="$HOST_CC" amalg Q=" " BUILDMODE=static CFLAGS="$CFLAGS"
}

cp -f libluajit.a $bindir/$A

"$MAKE" clean
