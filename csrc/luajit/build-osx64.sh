[ `uname` = Linux ] && { export CROSS=x86_64-apple-darwin11-; export TARGET_SYS=Darwin; }
P=osx64 TARGET_CFLAGS="-arch x86_64" TARGET_LDFLAGS="-arch x86_64" ./build-osx.sh
