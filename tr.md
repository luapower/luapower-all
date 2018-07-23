
## `local tr = require'tr'`

Text shaping and rendering engine for combined multi-language Unicode text
using exclusively portable technologies for pixel-perfect consistent output
across platforms. Supports complex text shaping based on [harfbuzz]
and [fribidi] and glyph caching and rasterization based on [freetype].

### Features

  * subpixel positioning
  * OMG color emoticons!
  * rich text markup lanugage
  * word wrapping
  * cursor positioning information for editing
  * control over OpenType features
  * font database for font selection
  * OpenType-assisted auto-hinter enabled in freetype

Note: this is a support lib for [ui] but can be used standalone.
