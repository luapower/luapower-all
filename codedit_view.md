---
tagline: layouting and rendering
---

## `local view_class = require'codedit_view'`

Codedit views deal with measuring, layouting, rendering and hit testing of codedit buffers.
Rendering is done in terms of a set of primitive drawing methods, which in codedit_view are just stubs.
You'll have to subclass codedit_view and implement these methods in order to have a working view
(for subclassing you can use [glue.inherit](glue.html#inherit) or [glue.update](glue.html#update)).

__NOTE:__ codedit_view assumes a monospace font and a fixed line height.

## Properties

~~~{.lua}
--tab expansion
tabsize = 3
--font metrics
line_h = 16
char_w = 8
char_baseline = 13
--cursor metrics
cursor_xoffset = -1     --cursor x offset from a char's left corner
cursor_xoffset_col1 = 0 --cursor x offset for the first column
cursor_thickness = 2
--scrolling
cursor_margins = {top = 16, left = 0, right = 0, bottom = 16},
--rendering
highlight_cursor_lines = true
lang = nil --lexer to use for syntax highlighting. nil means no highlighting.
--reflowing
line_width = 72
~~~

## Methods

-------------------------------------------- -------------------------------------------
`view_class:new(buffer) -> view`					create a view for a buffer

__rendering__

`view:add_selection(sel)`							add a selection to the set of objects to render

`view:add_cursor(cur)`								add a cursor to the set of objects to render

`view:add_margin(margin, pos)`					add a margin to the set of objects to render

`view:render()`										render the added objects

__rendering stubs__

`view:draw_char(x, y, s, i, color)`				draw a colored utf-8 char.
															the char to be drawn is the utf-8 codepoint
															at byte index `i` in string `s`

`view:draw_rect(x, y, w, h, color)`				draw a colored rectangle

`view:clip(x, y, w, h)`								create a clipping rectangle so that
															all subsequent drawing operations
															will be clipped by it

`view:draw_scrollbox(x, y, w, h,					draw a scrollbox widget with (x, y, w, h) outside rect
	cx, cy, cw, ch) -> cx, cy, 				 	and (cx, cy, cw, ch) client rect.
	clip_x, clip_y, clip_w, clip_h`				return the new cx, cy, adjusted from user input and other
															scrollbox constraints, followed by the clipping rect.
															the client rect is relative to the clipping rect of
															the scrollbox (which can be different than it's outside rect).
															this stub implementation is equivalent to a scrollbox that
															takes no user input, has no margins, and has invisible scrollbars.

__hit testing__

`view:selection_hit_test(sel, x, y)				hit test a selection
	-> true | false`

`view:margin_hit_test(margin, x, y)				hit test a margin
	-> true | false`

`view:client_hit_test(x, y) 						hit test the client area
	-> true | false`


__scrolling__[^scrolling]


`view:scroll_by(x, y)`								scroll the view, in pixels

`view:scroll_up()` \									scroll one screen up or down
`view:scroll_down()`

`view:make_rect_visible(x, y, w, h)`			scroll to make a specific rectangle visible

`view:cursor_make_visible(cur)`					scroll to make the char under cursor visible

__measurements in text space__[^text-space]

`view:char_coords(line, vcol) -> x, y`			visual char position in text space

`view:char_at(x, y) -> line, vcol`				visual char at text space coordinates

`view:char_rect(line1, vcol1,
	line2, vcol2) -> x, y, w, h`					the rectangle surrounding a block of text

`view:selection_line_rect(sel, line) 			selection line shape in text space
	-> x, y, w, h`

`view:cursor_rect(cursor) -> x, y, w, h`		cursor shape in text space

`view:pagesize() -> n`								how many lines of text are in the clipping rect

__measurements in screen space__

`view:client_size() -> w, h`						size of the text space (also called client rectangle
															in the context of layouting) as limited by the available
															text and any out-of-text cursors.

`view:margins_width() -> w` 						width of all margins combined

`view:margin_x(margin) -> x`						x coord of a margin in screen space

__clipping rectangles__

`view:clip_rect() -> x, y, w, h` 				clip rect of the client area, in screen space,
															as obtained from drawing the scrollbox

`view:margin_clip_rect(margin)					clip rect of a margin area, in screen space
	-> x, y, w, h`

`view:line_clip_rect(line) -> x, y, w, h`		clip rect of a line of text, in screen space

__clipping in visual char space__

`view:visible_lines() -> line1, line2`			which lines are partially or entirely visibile

`view:visible_cols() -> col1, col2`				which visual columns are partially or entirely visibile

`view:line_is_visible(line) -> true | false`	is line visibile?

`view:screen_to_client(x, y)` \					point translation from screen space to client (text) space and back
`view:client_to_screen(x, y)` \
`view:screen_to_margin_client(margin, x, y)` \
`view:margin_client_to_screen(margin, x, y)`

-------------------------------------------- -------------------------------------------



[^scrolling]: scrolling means adjusting the position of the client rectangle relative to the clipping rectangle
[^text-space]: coordinates in text space are relative to the client rectangle
