touch config.h

echo "
pixman.c
pixman-access.c
pixman-access-accessors.c
pixman-bits-image.c
pixman-combine32.c
pixman-combine-float.c
pixman-conical-gradient.c
pixman-filter.c
pixman-x86.c
pixman-mips.c
pixman-arm.c
pixman-ppc.c
pixman-edge.c
pixman-edge-accessors.c
pixman-fast-path.c
pixman-glyph.c
pixman-general.c
pixman-gradient-walker.c
pixman-image.c
pixman-implementation.c
pixman-linear-gradient.c
pixman-matrix.c
pixman-noop.c
pixman-radial-gradient.c
pixman-region16.c
pixman-region32.c
pixman-solid-fill.c
pixman-timer.c
pixman-trap.c
pixman-utils.c
"

echo "
pixman-mmx.c
pixman-sse2.c
pixman-ssse3.c
-mmmx -msse2 -mssse3 -mfpmath=sse
-DUSE_X86_MMX
-DUSE_SSE2
-DUSE_SSSE3
-DUSE_GCC_INLINE_ASM
-DPACKAGE=pixman
"
