#!/bin/bash
# check install_name on osx dylibs

[ "${OSTYPE#darwin}" = "$OSTYPE" ] && { echo "This script is for OSX"; exit 1; }

check() {
    echo "checking $1..."
    (cd bin/$1
    otool -L *.dylib | grep -v System | grep -v "++" | grep -v "dylib:" | grep -v "libgcc" | grep -v "@rpath/"
    )
}

check osx64
