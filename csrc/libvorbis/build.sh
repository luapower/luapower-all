libvorbis_files="
mdct.c
smallft.c
block.c
envelope.c
window.c
lsp.c
lpc.c
analysis.c
synthesis.c
psy.c
info.c
floor1.c
floor0.c
res0.c
mapping0.c
registry.c
codebook.c
sharedbook.c
lookup.c
bitrate.c
"
libvorbisfile_files="vorbisfile.c"
libvorbisenc_files="vorbisenc.c"

build() {
	(cd lib
	gcc -c -O2 $C -I../include -I. -I../../libogg
	gcc *.o -shared -o ../../../bin/$P/$D $L -L../../../bin/$P -logg
	ar rcs ../../../bin/$P/$A *.o
	rm *.o
	)
}

(C="$C $libvorbis_files"     L="$L $LL"          D="$DL" A="$AL" build)
(C="$C $libvorbisfile_files" L="$L $LF -lvorbis" D="$DF" A="$AF" build)
(C="$C $libvorbisenc_files"  L="$L $LE -lvorbis" D="$DE" A="$AE" build)
