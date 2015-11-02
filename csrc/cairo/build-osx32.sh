export IMAGE_SURFACE=1
export PNG_FUNCTIONS=1
export RECORDING_SURFACE=1
export SVG_SURFACE=1
export PS_SURFACE=1
export PDF_SURFACE=1
export FT_FONT=1
export QUARTZ_SURFACE=1

[ `uname` = Linux ] && export X=i386-apple-darwin11-
P=osx32 C="
	-arch i386 -mmacosx-version-min=10.6
	-DCAIRO_HAS_PTHREAD=1 -DHAVE_INT128_T" \
L="
	-arch i386 -mmacosx-version-min=10.6
	-install_name @rpath/libcairo.dylib
	-Wno-enum-conversion
	-Wno-attributes
" D=libcairo.dylib A=libcairo.a ./build.sh
