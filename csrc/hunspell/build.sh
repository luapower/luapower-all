files="
	src/affentry.cxx
	src/affixmgr.cxx
	src/csutil.cxx
	src/dictmgr.cxx
	src/hashmgr.cxx
	src/hunspell.cxx
	src/suggestmgr.cxx
	src/phonet.cxx
	src/filemgr.cxx
	src/hunzip.cxx
	src/replist.cxx
	extras.cxx
"
g++ -c -O2 $C $files -DHAVE_CONFIG_H -DBUILDING_LIBHUNSPELL=1 -Isrc -fvisibility=hidden
g++ *.o -shared -o ../../bin/$P/$D -L../../bin/$P $L
ar rcs ../../bin/$P/$A *.o
rm *.o
