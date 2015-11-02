# harfbuzz build with opentype, ucdn, freetype. dynamically links to ucdn and freetype.
cd src || exit 1

# pre-processing step: convert *.rl -> *.hh with ragel
for f in `ls *.rl`; do
	if [ ! -f "${f%.*}.hh" ]; then
		ragel "$f" -e -F1 -o "${f%.*}.hh"
	fi
done

C="$C
hb-blob.cc
hb-buffer.cc
hb-buffer-serialize.cc
hb-common.cc
hb-set.cc
hb-font.cc
hb-face.cc
hb-fallback-shape.cc
hb-shape-plan.cc
hb-shape.cc
hb-shaper.cc
hb-tt-font.cc
hb-unicode.cc
hb-warning.cc

-DHAVE_OT
hb-ot*.cc

-DHAVE_UCDN
hb-ucdn.cc

-DHAVE_FREETYPE
hb-ft.cc
"

# TODO: remove the __MINGW32__ hack
${X}gcc -c -O2 $C -DHAVE_INTEL_ATOMIC_PRIMITIVES -D__MINGW32__ \
	-I. -I../../freetype/include -I../../ucdn \
	-fno-exceptions -fno-rtti
${X}gcc *.o -shared -o ../../../bin/$P/$D -L../../../bin/$P -lfreetype -lucdn $L
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
