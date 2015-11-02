set -e
cd src/src
bindir=../../../../bin/$P

make clean
mkdir -p "$bindir/../../jit"
cp -f jit/*.lua "$bindir/../../jit/"

[ "$HOST_CC" ] || HOST_CC=gcc
"$MAKE" HOST_CC="$HOST_CC" amalg Q=" "

[ "$X0" ] || X0=$X; cp -f $X0 "$bindir/$X"
[ "$D0" ] || D0=$D; cp -f $D0 "$bindir/$D"
mkdir -p "$bindir/lua/jit"
cp -f jit/vmdef.lua "$bindir/lua/jit/vmdef.lua"

[ "$MAKE" = "mingw32-make" ] && {
	make clean
	"$MAKE" BUILDMODE="static"
}

cp -f libluajit.a "$bindir/$A"

make clean
