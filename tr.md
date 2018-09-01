
## `local tr = require'tr'`

Text shaping and rendering engine for multi-language Unicode text using
portable technologies exclusively for pixel-perfect consistent output
across platforms. Uses [harfbuzz] for complex text shaping, [fribidi] for
bidirectional text and [freetype] for glyph rasterization.

### Features

  * subpixel positioning
  * OMG color emoticons!
  * rich text layouting
  * word wrapping and alignments
  * cursor positioning
  * control over OpenType features
  * font database for font selection
  * OpenType-assisted auto-hinter enabled in freetype

### Not-yet implemented

  * full justification
  * subscript/superscript
  * underline/strikethrough
  * glyph substitution
  * shaping across words
  * hyphenation
  * letter spacing
  * vertical layout

Note: this is a support lib for [ui] but can be used standalone.

### API

---------------------------------------------------- ------------------------------------
`tr() -> tr`                                         create a render object
`tr:free()`                                          free the render object
`tr:add_font_file(file, ...)`                        add a font file
`tr:add_mem_font(buf, sz, ...)`                      add a font file from a buffer
`tr:flatten(text_tree) -> text_runs`                 flatten a text tree
`tr:shape(text_tree | text_runs) -> segs`            shape a text tree / text runs
`segs:layout(x, y, w, h, [ha], [va]) -> segs`        layout shaped text
`segs:paint(cr)`                                     paint laid out text
`tr:textbox(text_tree, cr, x, y, w, h, [ha], [va])`  shape, layout and paint text
`segs:cursor()
---------------------------------------------------- ------------------------------------

### `tr:add_font_file(file, name, [slant], [weight])`

Register a font file, associating it with a name, slant and weight. Multiple
combinations of (name, weight, slant) can be registered with the same font.
See [freetype] for supported font formats.


### `tr:add_mem_font(buf, sz, [slant], [weight])`

Add a font file from a memory buffer.


### `tr:flatten(text_tree) -> text_runs`

Convert a tree of nested text runs into a flat array of codepoints and an
accompanying list of tables containing metadata covering all segments
of the text.

The text tree is a list whose elements can be either Lua strings containing
utf-8 text or other text trees. Text tree nodes can also contain attributes
like `font_name` and `color` which describe how the strings should be
rendered. Each node is set up to inherit all attributes from all parent nodes
in the hierarchy.

Attributes can be:

  * `font_name`: font name in the format `'family [weight] [slant][, size]'
  (parsed by `tr_font_db.lua`).
  * `font_size`: font size override.
  * `font_weight`: font weight override: `'bold'`, `'thin'` etc. or a weight
  number between 100 and 900.
  * `font_slant`: font slant override: `'italic'`, `'normal'`.
  * `bold`, `b`, `italic`, `i`: `font_weight` and `font_slant` overrides.
  * `features`: a list of OpenType features in string form:
  `feat1 +feat2 -feat3 feat4=1`
  * `script`: an ISO-15924 script tag (the default is auto-detected based on
  Unicode General Category classes, see the `tr_shape_script.lua`).
  * `lang`: an ISO-639 language-country code (the default is auto-detected
  from the script property, see `tr_shape_lang.lua`).
  * `dir`: `'ltr'`, `'rtl'`, `'auto'`: bidi direction for current and
  subsequent paragraphs.
  * `line_spacing`: line spacing multiplication factor (defaults to `1`).
  * `paragraph_spacing`: paragraph spacing multiplication factor (defaults to `2`).
  * `nowrap`: disable word wrapping.
  * `color`: a color parsed by the [color] module (`#rrggbb`, etc.).

NOTE: one text run is always created for each source table, even when there's
no text, in order to anchor the attrs to a segment and to create a cursor.


### `tr:shape(text_tree | text_runs) -> segments`

Shape a text tree (or a list of text_runs) into a list of segments.


### `segments:layout(x, y, w, h, [halign], [valign]) -> segments`

Layout the shaped text using word wrapping so that it fits into the box
described by `x, y, w, h`.

  * `halign` can be `'left'`, `'right'`, `'center'` (defaults to `'left'`).
  * `valign` can be `'top'`, `'bottom'`, `'middle'` (defaults to `'top'`).
  * returns `segments` for chain calling.
  * sets `segments.x` and `segments.y` which can be changed without the need
  to call `layout()` again.
  * sets `text_runs`
  * once the text is laid out, it can be painted many times with `paint()`.


### `segments:paint(cr)`

Paint the shaped and laid out text into a graphics context.

When the `tr` object is created, a rasterizer object is created by calling
`tr:create_rasterizer()` which loads the module pointed out by
`tr.rasterizer_module` which defaults to `tr_raster_cairo` which implements
a simple rasterizer which can paint glyphs into a [cairo] context. In order
to paint the text using other graphics libraries you need to implement a
new rasterizer. Glyph caching and the actual rasterization is done in
`tr_raster_ft` using [freetype], so your rasterizer can subclass that and
then it only needs to handle blitting of 8-bit gray and bgra8 bitmaps and
also bitmap scaling if you use bitmap fonts, since freetype doesn't handle
that.

