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
In particular, font formats other than ttf and cff are not supported.
Also, the **patent-encumbered LCD filtering is enabled**, so it may well be
illegal to use this binary in your country. If unsure, compile your own.


[FreeType 2]:    http://freetype.org/freetype2/
[FreeType docs]: http://www.freetype.org/freetype2/docs/documentation.html
[screenshot]:    /files/luapower/media/www/freetype_demo.png
