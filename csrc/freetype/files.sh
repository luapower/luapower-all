#!/bin/bash
# freetype 2.5 input file list
# features: truetype format, cff format, truetype bytecode hinter, autohinter,
# non-aa rasterizer, smooth rasterizer, stroker, lcd filtering.

echo src/base/ftsystem.c
echo src/base/ftinit.c
echo src/base/ftdebug.c

echo src/base/ftbase.c

echo src/base/ftbbox.c       #recommended, see <freetype/ftbbox.h>
echo src/base/ftglyph.c      #recommended, see <freetype/ftglyph.h>

#echo src/base/ftbdf.c        #optional, see <freetype/ftbdf.h>
echo src/base/ftbitmap.c     #optional, see <freetype/ftbitmap.h>
#echo src/base/ftcid.c        #optional, see <freetype/ftcid.h>
#echo src/base/ftfstype.c     #optional
#echo src/base/ftgasp.c       #optional, see <freetype/ftgasp.h>
#echo src/base/ftgxval.c      #optional, see <freetype/ftgxval.h>
echo src/base/ftlcdfil.c     #optional, see <freetype/ftfil.h>
#echo src/base/ftmm.c         #optional, see <freetype/ftmm.h>
#echo src/base/ftotval.c      #optional, see <freetype/ftotval.h>
#echo src/base/ftpatent.c     #optional
#echo src/base/ftpfr.c        #optional, see <freetype/ftpfr.h>
echo src/base/ftstroke.c     #optional, see <freetype/ftstroke.h>
#echo src/base/ftsynth.c      #optional, see <freetype/ftsynth.h>
#echo src/base/fttype1.c      #optional, see <freetype/t1tables.h>
#echo src/base/ftwinfnt.c     #optional, see <freetype/ftwinfnt.h>
#echo src/base/ftxf86.c       #optional, see <freetype/ftxf86.h>

#echo src/base/ftmac.c        #only on the Macintosh

# font drivers (optional; at least one is needed)

#echo src/bdf/bdf.c           #BDF font driver
echo src/cff/cff.c           #CFF/OpenType font driver
#echo src/cid/type1cid.c      #Type 1 CID-keyed font driver
#echo src/pcf/pcf.c           #PCF font driver
#echo src/pfr/pfr.c           #PFR/TrueDoc font driver
echo src/sfnt/sfnt.c         #SFNT files support (TrueType & OpenType)

echo src/truetype/truetype.c #TrueType font driver
#echo src/type1/type1.c       #Type 1 font driver
#echo src/type42/type42.c     #Type 42 font driver
#echo src/winfonts/winfnt.c   #Windows FONT / FNT font driver

# rasterizers (optional; at least one is needed for vector formats)

echo src/raster/raster.c     #monochrome rasterizer
echo src/smooth/smooth.c     #anti-aliasing rasterizer

# auxiliary modules (optional)

echo src/autofit/autofit.c   #auto hinting module
#echo src/cache/ftcache.c     #cache sub-system (in beta)
#echo src/gzip/ftgzip.c       #support for compressed fonts (.gz)
#echo src/lzw/ftlzw.c         #support for compressed fonts (.Z)
#echo src/bzip2/ftbzip2.c     #support for compressed fonts (.bz2)
#echo src/gxvalid/gxvalid.c   #TrueTypeGX/AAT table validation
#echo src/otvalid/otvalid.c   #OpenType table validation
echo src/psaux/psaux.c       #PostScript Type 1 parsing
echo src/pshinter/pshinter.c #PS hinting module
echo src/psnames/psnames.c   #PostScript glyph names support


: << COMMENT

Notes:

    ftcache.c  needs ftglyph.c
    ftfstype.c needs fttype1.c
    ftglyph.c  needs ftbitmap.c
    ftstroke.c needs ftglyph.c
    ftsynth.c  needs ftbitmap.c

    cff.c      needs sfnt.c, pshinter.c, and psnames.c
    truetype.c needs sfnt.c and psnames.c
    type1.c    needs psaux.c pshinter.c, and psnames.c
    type1cid.c needs psaux.c, pshinter.c, and psnames.c
    type42.c   needs truetype.c

    To use ftbzip2.c, an application must be linked with a library
    which implements bzip2 support (and the bzip2 header files must
    be available also during compilation).

COMMENT
