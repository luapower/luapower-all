---
tagline: freetype font engine
---

## `local freetype = require'freetype'`

A ffi binding of [FreeType 2].

![screenshot]

## Binary

The included freetype binary is a *stripped* build of freetype.
Only CFF/OpenType, TrueType and SFNT fonts are supported. Also, it depends
on [libpng] for embedded bitmaps and on [harfbuzz] for the autohinter.

## Building

Refer to `csrc/freetype/WHAT` for how to build it.

[FreeType 2]:    http://freetype.org/freetype2/
[screenshot]:    /files/luapower/media/www/freetype_demo.png
