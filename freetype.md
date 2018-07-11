---
tagline: freetype font engine
---

## `local freetype = require'freetype'`

A ffi binding of [FreeType 2].

![screenshot]

## API

Look at the bottom of the source file for method names for each object type.
Use the demo and test files for usage examples.

Use the [FreeType docs] for knowledge about fonts and rasterization.

## Binary

The included freetype binary is a *stripped* build of freetype.
Only CFF/OpenType, TrueType and SFNT fonts are supported. Also, it depends
on [libpng] for embedded bitmaps and on [harfbuzz] for the autohinter.

[FreeType 2]:    http://freetype.org/freetype2/
[FreeType docs]: http://www.freetype.org/freetype2/docs/documentation.html
[screenshot]:    /files/luapower/media/www/freetype_demo.png
