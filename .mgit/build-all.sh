#!/bin/bash
# build packages and their dependencies in the right order.
# needs the `luapower` package to get the build order.

packages="$1"  # comma separated without spaces
platform="$2"

[ "$packages" ] || {
	echo "USAGE: mgit build-all REPO,...|--all [platform]"
	exit 1
}

[ -f "lp" ] || {
	echo
	echo "ERROR: luapower package is needed to get the build order."
	echo "To get it, run:"
	echo
	echo "   mgit clone luapower glue lfs luajit tuple"
	echo
	exit 1
}

[ "$platform" ] || platform="$(./lp platform)" || exit 1
packages="$(./lp build-order $packages $platform)"

echo "Will build: ${packages//$'\n'/, }."
echo "Press any key to continue, Ctrl+C to quit."
read

for pkg in $packages; do
    echo
    echo "-----------------------------------------------------------"
    echo
    echo "*** Building $pkg for $platform ***"
    echo
    (cd csrc/$pkg && ./build-$platform.sh)
done
