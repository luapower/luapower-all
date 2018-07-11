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
hb-buffer-serialize.cc
hb-buffer.cc
hb-common.cc
hb-face.cc
hb-font.cc
hb-map.cc
hb-ot-tag.cc
hb-set.cc
hb-shape.cc
hb-shape-plan.cc
hb-shaper.cc
hb-static.cc
hb-unicode.cc
hb-warning.cc

-DHAVE_OT
hb-ot*.cc

-DHAVE_FREETYPE
hb-ft.cc

-DHAVE_FALLBACK
hb-fallback-shape.cc

-DHAVE_UCDN
hb-ucdn.cc
"

${X}gcc -c -O2 $C -DHAVE_INTEL_ATOMIC_PRIMITIVES -DUCDN_EXPORT \
	-I. -I../../freetype/include -I../../ucdn \
	-fno-exceptions -fno-rtti
${X}gcc *.o -shared -o ../../../bin/$P/$D -L../../../bin/$P $L -lfreetype -lucdn
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
