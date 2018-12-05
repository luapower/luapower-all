
## `local tr = require'tr'`

Text shaping and rendering engine for Unicode text using portable technologies
exclusively for pixel-perfect consistent output across platforms. Uses
[harfbuzz] for complex text shaping, [fribidi] for bidirectional text,
[libunibreak] for line breaking and [freetype] for glyph rasterization.
Used by [ui] for all text rendering.

Supports subpixel positioning, color bitmap fonts (emoticons!), word
wrapping, alignments, hit testing, clipping, cursors, selections, editing,
control over OpenType features, moving, coloring and editing inside ligatures,
OpenType-assisted auto-hinter.

## Status

See [issues](https://github.com/luapower/tr/issues)
and [milestones](https://github.com/luapower/tr/milestones).

### API

---------------------------------------------------- ------------------------------------
`tr() -> tr`                                         create a render object
`tr:free()`                                          free the render object
__font management__
`tr:add_font_file(file, ...)`                        add a font file
`tr:add_mem_font(buf, sz, ...)`                      add a font file from a buffer
__shaping & layouting__
`tr:flatten(text_tree) -> text_runs`                 flatten a text tree
`tr:shape(text_tree | text_runs) -> segs`            shape a text tree / text runs
`segs:min_w() -> min_w`                              minimum wrapping width
`segs:max_w() -> max_w`                              maximum wrapping width
`segs:wrap(w) -> segs`                               wrap shaped text
`segs:align(x, y, [w], [h], [ax], [ay]) -> segs`     align wrapped text in a box
`segs:layout(x, y, [w], [h], [ax], [ay]) -> segs`    wrap and align shaped text
`segs:bounding_box() -> x, y, w, h`                  bounding box of laid out text
__rendering__
`segs:paint(cr) -> segs`                             paint laid out text
`segs:clip([x, y, w, h]) -> segs`                    mark outside segments as invisible
`segs:reset_clip() -> segs`                          mark all segments as visible
`tr:textbox(text_tree, cr, x, y, w, h, [ax], [ay])`  shape, layout and paint text
__hit testing__
`segs:hit_test(x, y, ...) -> seg, i`                 hit test the laid out text
__cursors__
`segs:cursor([offset]) -> cursor`                    create a cursor
`cursor:set(cursor | seg,i[,x]) -> changed`          update a cursor
`cursor:get() -> seg, i, x`                          cursor segment and offset in segment
`cursor:changed()`                                   event: cursor changed
`cursor:pos() -> x, y`                               cursor position
`cursor:size() -> w, h, rtl`                         cursor size and direction
`cursor:find(...) -> seg, i, [positions_left]`       find a relative cursor position
`cursor:move(...) -> changed`                        set cursor to a relative position
__selections__
`segs:selection() -> sel`                            create a selection
`sel:empty() -> true|false`                          check if selection is empty
`sel.cursor1`, `sel.cursor2`                         selection cursors
`sel:cursors() -> c1, c2, forward`                   selection cursors in text-order
`sel:offsets() -> o1, o2, forward`                   selection text offsets in order
`sel:select_all()`                                   select all
`sel:reset()`                                        select none
`sel:select_word()`                                  select the word around cursor1
`sel:rectangles(write_func, ...)`                    get selection rectangles
`sel:hit_rectangles(write_func, ...)`                get selection rectangles without line gaps
`sel:hit_test(x, y) -> true|false`                   hit test the selection rectangles
__editing__
`sel:codepoints() -> buf, offset, len`               selected text in utf-32 buffer
`sel:string() -> s`                                  selected text as utf-8 string
`sel:replace(s, [len], [charset], [maxlen]) -> t|f`  replace selection with text
__rasterizer config__
`tr.rs.glyph_cache_size`                             `10MB`
`tr.rs.font_size_resolution`                         `1/8`
`tr.rs.subpixel_x_resolution`                        `1/16` (max is `1/64` with Freetype)
`tr.rs.subpixel_y_resolution`                        `1` because vertical hinting enabled
---------------------------------------------------- ------------------------------------

## Font management

### `tr:add_font_file(file, name, [slant], [weight])`

Register a font file, associating it with a name, slant and weight.
The name can contain the slant and/or weight and you can add/override these
qualifiers as separate args.

Multiple combinations of (name, weight, slant) can be registered with the
same font. See [freetype] for supported font formats.

The font is not loaded immediately, but it's loaded and unloaded on demand.

Registering fonts is a necessary step before trying to shape anything.

### `tr:add_mem_font(buf, sz, [slant], [weight])`

Add a font file from a memory buffer.

## Shaping & layouting

### `tr:flatten(text_tree) -> text_runs`

Convert a tree of nested text nodes into a flat array of codepoints and
an accompanying flat list of *text runs* containing metadata for each piece
of text contained in the tree.

The text tree is a list whose elements can be either Lua strings containing
utf-8 text or other text trees. Text tree nodes also contain attributes which
describe how the text should be rendered. All attributes are automatically
inherited from parent nodes and can be overriden in child nodes.

Attributes can be:

  * `font` or `font_name`: font specified as `'family [weight] [slant][, size]'`.
  * `font_size`: font size override.
  * `font_weight`: font weight override: `'bold'`, `'thin'` etc. or a weight
  number between `100` and `900`.
  * `font_slant`: font slant override: `'italic'`, `'normal'`.
  * `bold`, `b`, `italic`, `i`: boolean `font_weight` and `font_slant` overrides.
  * `features`: OpenType features specified as `'[+|-]feat[=val] ...'`,
  eg. `'+kern -liga smcp'`.
  * `script`: an [ISO-15924] script tag (the default is auto-detected).
  * `lang`: a [BCP-47] language-country code (the default is auto-detected).
  * `dir`: `'ltr'`, `'rtl'`, `'auto'`: bidi direction for current and
  subsequent paragraphs.
  * `line_spacing`: line spacing multiplication factor
  (defaults to `1`).
  * `hardline_spacing`: line spacing multiplication factor for lines
  terminated by a hard line break (defaults to `1`).
  * `paragraph_spacing`: paragraph spacing multiplication factor
  (defaults to `2`).
  * `nowrap`: disable word wrapping.
  * `color`: a color in format `'#rrggbb'`, `'hsv(h, s, v)'`, etc.
  (see [color] for supported formats; defaults to `tr.rs.default_color`
  which is `'#888'`).
  * `operator`: the cairo operator (defaults to `tr.rs.default_operator`
  which is `'over'`).

[ISO-15924]: https://www.unicode.org/iso15924/iso15924-codes.html

[BCP-47]: https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry

The resulting table contains the text runs in its array part, plus:

  * `codepoints` - the `uint32_t[?]` array of codepoints.
  * `len` - text length in codepoints.

The text runs are set up to inherit their corresponding text tree node,
and also contain the fields:

  * `offset` - offset in the flattened text, in codepoints, __counting from 0!__.
  * `len` - text run length in codepoints.
  * `font`, `font_size` - resolved font object and font size.

NOTE: A text run is created for each source node, even when the node has
no text, in order to preserve the text attributes at that text position.
Invalid text runs are discarded though, so flattening _can_ result in an
empty array.

NOTE: When flattening, each text node is set up to inherit its parent node
(this might change in a future version since it's not ok to modify user
input in general).

### `tr:shape(text_tree | text_runs) -> segs`

Shape a text tree (flattened or not) into a list of segments.

The segments can be laid out multiple times and must be laid out at least
once in order to be rendered. Changing the text tree in any way except
for styling attributes (color) requires reshaping and relayouting.

  * the segments keep a reference to the text runs in the `text_runs` field.
  * segments are _not created_ for text runs for which font loading fails.

### `segs:min_w() -> min_w`

Get the minimum width that the text can be wrapped to, which is the width
of the longest non-breakable text sequence.

### `segs:max_w() -> max_w`

Get the width of the unwrapped text, which is the width of its longest line.

### `segs:wrap(w) -> segs`

Line-wrap shaped text to a maximum width. Some of the resulting lines can be
wider than the given width because of nowrap or long non-breakable words.
Use `min_w()` to correct for that if needed.

Creates the `segs.lines` table with the following fields:

  * `max_ax`: text's maximum x-advance (equivalent to text's width).
  * `h`: text's wrapped height.
  * `spaced_h`: text's wrapped height including line and paragraph spacing.

and with a list of lines in its array part, with the fields:

  * `advance_x`: x-advance of the last segment.
  * `ascent`: maximum ascent.
  * `descent`: maximum descent.
  * `spacing`: maximum line spacing factor for this line.
  * `spaced_ascent`: maximum ascent including line or paragraph spacing.
  * `spaced_descent`: maximum descent including line or paragraph spacing.
  * `visible`: true if line is not clipped.
  * `x`: line's unaligned x-offset (0).
  * `y`: line's y-offset relative to the first line's baseline.
  * `first`: first segment in logical order.
  * `first_vis`: first segment in visual order.

Each segment also has the following fields set:

  * `x`: segment's x-position.
  * `advance_x`: segment's x-advance.
  * `next`: next segment on the line, in logical order.
  * `next_vis`: next segment on the line, in visual order.
  * `line`: segment's line object.
  * `wrapped`: true if the segment is the last segment on a wrapped line.
  * `visible`: true if segment is not clipped.

NOTE: The `lines` table _can_ contain zero lines if the `segs` table has
zero segments, which happens when there are errors.

### `segs:align(x, y, [w], [h], [align_x], [align_y]) -> segs`

Align wrapped text so that it fits into the box described by `x, y, w, h`.

  * `w`, `h` default to wrapped text's bounding box, including line spacing.
  * `align_x` can be `'left'`, `'right'`, `'center'` (defaults to `'left'`).
  * `align_y` can be `'top'`, `'bottom'`, `'center'` (defaults to `'top'`).

Sets the following fields in `segs.lines`:

  * `x`, `y`: textbox's position: can be changed freely without the need
  to call `align()` again.
  * `min_x`: x-offset of the leftmost line relative to the textbox's origin.
  * `baseline`: first line's baseline relative to the textbox's origin.

Also sets the following fields on each line:

  * `x`: line's aligned x-offset relative to textbox's origin.

Once the text is aligned, it can be clipped and painted multiple times
without the need to call `align()` again.

### `segs:layout(x, y, [w], [h], [align_x], [align_y]) -> segs`

Wrap and align shaped text.

### `segs:bounding_box() -> x, y, w, h`

Return the bounding-box of laid out text.

## Rendering

### `segs:paint(cr) -> segs`

Paint the shaped and laid out text into a graphics context.

When the `tr` object is created, a rasterizer object is created by calling
`tr:create_rasterizer()` which loads the module pointed out by
`tr.rasterizer_module` which defaults to `tr_raster_cairo` which implements
a simple rasterizer which can paint glyphs into a [cairo] context. To paint
glyphs using other graphics APIs you need to implement a new rasterizer.
Glyph caching and the actual rasterization is done in `tr_raster_ft` using
[freetype], so your rasterizer can subclass that and then it only needs to
handle blitting of (clipped portions of) 8-bit gray and 32-bit BGRA bitmaps
and also bitmap scaling if you use bitmap fonts, since freetype doesn't handle
that.

### `segs:clip([x, y, w, h]) -> segs`

Mark all lines and segments which are completely outside the given rectangle
as invisible, and everything else as visible. If a rectangle is not given,
the rectangle from the last call to `align()` is used.

### `segs:reset_clip() -> segs`

Mark all lines and segments as visible.

### `tr:textbox(text_tree, cr, x, y, w, h, [align_x], [align_y]) -> segs`

Shape, wrap, align, clip and paint text in one call.

## Hit testing

### `segs:hit_test(x, y, ...) -> seg, i`

Hit test for a cursor position. Extra args are the same as for
`cursor:find('pos', ...)`.

## Cursors

### `segs:cursor([offset]) -> cursor`

Create a cursor, optionally placing it at a text offset (which defaults to `0`).
Returns `nil` if the segments table contain no segments.

Cursor configuration fields:

  * `park_home` (`true`): if trying to go above the topmost line, go to the first offset.
  * `park_end` (`true`): if trying to go below the bottommost line, go to the last offset.
  * `unique_offsets` (`false`): jump-through same-text-offset cursors like most editors do.
  * `wrapped_space` (`false`): keep a cursor after the last space char on a wrapped line.

Cursor state fields:

  * `segments` - a reference to the segments table.
  * `seg` - the segment.
  * `i` - position in text relative to the segment, __counting from 0!__.
  * `x` - x-position set by horizontal movement to be recalled by vertical movement.

### `cursor:set(cursor | seg,i[,x]) -> changed`

Update the cursor. If the cursor changed, call `changed()` and return true.

### `cursor:get() -> seg, i, x`

Get the cursor segment and offset in segment.

### `cursor:pos() -> x, y`

Get cursor position.

### `cursor:size() -> w, h, rtl`

Get cursor size and direction.

### `cursor:find(...) -> seg, i, [positions_left]`

Find a cursor position. Possible argument combinations:

------------------------------------------------- ----------------------------
`'offset', offset, [which]`                       position at offset in text
`'cursor', seg, i, [dir], [mode], [which]`        position relative to other position
`'rel_cursor', [dir], [mode], [which]`            position relative to cursor
`'line', line_num, [x]`                           position on a specific line
`'rel_line', [lines_away], [x]`                   position some lines away from the cursor
`'pos', [x], y`                                   position at point (hit test)
`'page', page_num, [x]`                           position at the first line of a specific page
`'rel_page', [pages_away], [x]`                   position some pages away from the cursor
------------------------------------------------- ----------------------------

In the table above:

  * `*_away` can be negative or positive and defaults to `0`.
  * `dir` (`'this'`): search direction `'next', 'prev', 'this'`.
  * `mode` (`'pos'`): what to find: `'pos', 'char', 'word', 'line'`.
  * `which` (`'first'`): what cursor to return when there are multiple
  cursors that satisfy the search criteria: `'first', 'last'`.

Example: `segs:find('rel_cursor', 'this', 'word', 'last')` returns the cursor
position at the end of the word that the cursor is currently inside of.

### `cursor:move(...) -> changed`

Move the cursor to a new position. Implemented as
`return self:set(self:find(...))`.

### `cursor:changed()`

Stub method called when the cursor changed position.

## Selections

### `segs:selection() -> sel`

Create a selection.
Returns `nil` if the segments table contain no segments.

### `sel:empty() -> true|false`

Check if the selection is empty.

### `sel.cursor1`, `sel.cursor2`

Selection cursors in no order.

### `sel:cursors() -> cursor1, cursor2, forward`

Selection cursors in logical text order and whether `sel.cursor1` comes
before `sel.cursor2` in the logical text.

### `sel:offsets() -> offset1, offset2, forward`

Selection text offsets in order (`forward` is the same as for `cursors()`).

### `sel:select_all()`

Select all.

### `sel:reset()`

Select none.

### `sel:select_word()`

Select the word around `cursor1`.

### `sel:rectangles(write_func, ...)`

Get the selection rectangles.

### `sel:hit_rectangles(write_func, ...)`

Get the selection rectangles without line gaps (useful for hit-testing).

### `sel:hit_test(x, y) -> true|false`

Hit test the selection rectangles.

## Editing

### `sel:codepoints() -> buf, offset, len`

Selected text in utf-32 buffer.

### `sel:string() -> s`

Selected text as utf-8 string.

### `sel:replace(s, [len], [charset], [maxlen]) -> t|f`

Replace selection with text. The text is re-shaped, re-wrapped (if it was
previously wrapped), re-aligned (if it was previously aligned), and the clip
rectangle (if any) is invalidated.

## Rendering stages

#### 1. Text tree flattening

The text comes into the engine in the most convenient form for the user,
which is a tree of nested text nodes, similar to HTML. It is first converted
into a flat array of codepoints and an accompanying list of *text runs*
containing metadata for each piece of text contained in the tree.

#### 2. Itemization and shaping

The flattened text is broken into paragraphs following the `U+2029`
Paragraph Separator marker. The Unicode Bidirectional Algorithm (UBA) is run
for each paragraph, resulting in a series of segments with different
bidirectional *embedding levels* with alternating directionality.

The text is also analyzed for *script* and *language*. The script is
auto-detected from the Unicode General Category class of each character and
the language is auto-detected from the script property of each character.
In addition, text nodes can override these properties for arbitrary portions
of the text using the `script` and `lang` attributes.

The Unicode Line Breaking Algorithm is run for each segment with a different
language (because the algorithm depends on language), resulting in a series of
segments which end at each soft wrap opportunity (whitespace, newline, etc.).

Segments also break whenever the font, font size or OpenType feature list
change.

In the end, segments are formed at the boundaries that result from all of the
above segmentation rules and each segment is shaped separately with harfbuzz
resulting in a *glyph run*.

A glyph run is a list of glyph indices, positions and advances from a single
font which can be passed directly to a glyph rasterizer for display. Glyph
runs also contain cursor positions (more on that later).

Glyph runs are cached so that the same word with the same combination of font,
size, script, language, direction and OpenType feature list is not shaped
multiple times unnecessarily because shaping is expensive.

The segments can also contain sub-segments. Segments are formed at the
boundaries of property combinations which require separate shaping.
But text nodes don't necessarily create new segments all by themselves.
In fact it's possible to have two adjacent text nodes together forming a
single word but with a different color for each part of the word. In this
case a single segment with two sub-segments are created. Sub-segments are
created whenever the text node changes, regardless of whether any relevant
attributes actually change.

The end result of segmentation is thus a list of segments, each with its
own glyph run (which may be reused across multiple segments) and its own
list of sub-segments.

#### 3. Layouting

Layouting is the process of fitting and aligning the list of shaped segments
inside a box. First word wrapping is performed on the segments, in logical
order, resulting in a list of *lines*, each containing a list of segments.
Then BiDi reordering (the last part of the UBA) is performed on each line
based on each segment's embedding level, resulting in the segments to
possibly change their order in the line. The last step is horizontal and
vertical alignment of lines as a whole.

A list of segments can be laid out multiple times for different box dimensions
and alignments in O(n). Changing `segments.lines.x` and `segments.lines.y`
can also be done without re-layouting.

#### 4. Rendering

Rendering is the process of rasterizing the glyphs of the glyph runs
individually and then blitting the resulting bitmaps onto a raster surface
at the right positions. The parsing of font files for glyph outlines and the
actual rasterization is done by freetype, with the caveat that bitmap fonts
(emoticons) must be scaled separately because freetype doesn't handle that.
Rasterized/scaled glyphs are cached using a global LRU cache with a
configurable byte-size limit. Scaling and blitting depends on the target
surface and it's thus separated in a subclass of the freetype rasterizer
so that blitters can be created with minimum effort (the current cairo-based
blitter is under 200 LOC).

Rendering can be performed multiple times in O(n).

### Cursors

Cursor positions are stored in `seg.glyph_run` in two arrays: `cursor_offsets`
and `cursor_xs`. Both arrays are indexed by codepoint offset (relative to the
start of the glyph run), so a cursor position and its corresponding codepoint
offset can be found for any text offset in O(1). Unique cursors are created
at *cluster* boundaries (a term which means indivisible unit of text from
harfbuzz's point of view) but additional cursors are also created at
*grapheme boundaries* for clusters/glyphs that cover multiple graphemes like
ligated "fi" pairs. Some OpenType fonts contain cursor positions for such
ligatures which are used in this case if available.

Duplicate cursors are not pruned, and there are many of those:

  * the last cursor of the glyph run of any segment is the same as the first
  cursor of the glyph run of the next segment.
  * the last cursor position on a wrapped line is the same as the first
  cursor position on the next line.
  * lines with mixed LTR/RTL contain cursors pointing at the same offset in
  the logical text, but having different on-screen positions and direction
  of movement.
  * the secondary codepoints of a grapheme duplicate the cursor at the start
  of the grapheme.

It is left to the cursor navigation API to skip duplicate cursors according
to various options and parameters.

### Subtle points

#### Word wrapping and whitespace

The Unicode Line Breaking algorithm breaks the text into words such that the
whitespace between two words is always considered to be part of the first
word and not the second word. Thus whitespace is always trailing and never
leading. Even whitespace at the beginning of the text is standalone and not
tied to the first word.

When word-wrapping, the whitespace at the end of the last word on a line must
be ignored when computing the width of that line (another subtle point is that
this ignoring must happen only if the line is to be soft-wrapped, i.e. only
if a hard break like a newline character or end-of-text doesn't directly
follow the word's trailing whitespace). This is how most rich text editors
and browsers behave. The downside of ignoring the entire trailing whitespace
of the last word as opposed to only the last space character is that when
there's multiple trailing space characters, editing that whitespace will place
the cursor beyond the text box boundaries, which depending on the context
might even render the cursor invisible. Because of that, I have chosen to
only collapse the last space character and not the entire whitespace when
doing line-wrapping.

Another subtle point is that in RTL runs, this logically-trailing whitespace
is visually at the beginning of the word, thus the glyph run that contains it
(along with its cursor positions) must be shifted one space-character to the
left. The segment's `x` field contains this adjustment.

The cursor position following the space character on a wrapped line can be
enabled by setting `cursor.wrapped_space = true`. If you do that, make sure
to provide enough non-clipped margins on both sides of the text box so that
the cursor is not clipped at that position.

