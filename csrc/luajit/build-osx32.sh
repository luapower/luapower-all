[ `uname` = Linux ] && { export CROSS=i386-apple-darwin11-; export TARGET_SYS=Darwin; }
P=osx32 HOST_CC="gcc -m32" TARGET_CFLAGS="-arch i386" TARGET_LDFLAGS="-arch i386" ./build-osx.sh
