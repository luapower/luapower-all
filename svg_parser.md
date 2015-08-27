---
tagline: SVG parser
---

## `local svg_parser = require'svg_parser'`

A SVG 1.1 parser implemented in Lua.

Unlike other parsers, this one generates a [cairo sceen graph object][sg_cairo] instead of directly rendering
the SVG file on a canvas, which allows for manipulation of the graphics objects.

Included in the package is a handy collection of SVG files to test the parser with.

Some notable features are not yet implemented:

  * patterns
  * radial gradient has issues
  * text
  * markers
  * constrained transforms: ref(svg,[x,y])
  * external references
  * use tag

Low-priority missing features:

  * icc colors
  * css language

### `svg_parser.parse(source) -> object`

Parses a SVG into a cairo scene graph object that can be rendered with [sg_cairo].

  * `source` is an [expat] source.

