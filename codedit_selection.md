---
tagline: text selection
---

## `local selection = require'codedit_selection'`

Selecting contiguous text between two char positions, (line1, col1, line2, col2), where:

  * (line1, col1) is the first selected char
  * (line2, col2) is the char immediately after the last selected char.

As far as the API for changing the selection, one on the end points is considered
to be the "anchor point", and the other the "free point".

### Properties

~~~{.lua}
--view overrides
background_color = nil
text_color = nil
line_rect = nil --line_rect(line) -> x, y, w, h
~~~

### Methods

-------------------------------------------------- --------------------------------------------------
`selection:new(buffer, [view], visible) -> sel`		create a selection object

__boundaries__

`sel:isempty() -> true | false`							check if it's empty

`sel:isforward() -> true | false`						does it go top-down and left-to-rigth?

`sel:endpoints() -> line1, col1, line2, col2`		endpoints, ordered

`sel:cols(line) -> col1, col2`							column range of one selection line

`sel:next_line(line) -> line+1, col1, col2`			next line boundaries

`sel:lines() -> iter() -> line, col1, col2`			iterate over the boundaries

`sel:line_range() -> line1, line2`						the range of lines that the selection covers fully or partially

`sel:select() -> lines_t`									select text as a list of lines

`sel:contents() -> s`										select text using buffer's line terminator setting

__changing the selection__

`sel:reset(line, col)`										empty and re-anchor to a position

`sel:extend(line, col)`										move selection's free endpoint

`sel:reverse()`												reverse selection's direction

`sel:set(line1, col1, line2, col2, forward)`			set selection endpoints, preserving or setting its direction

`sel:select_all()`											extend selection to span the entire document

`sel:reset_to_cursor(cur)`									reset to a cursor position

`sel:extend_to_cursor(cur)`								extend to a cursor position

`sel:set_to_selection(sel)`								set to match another selection

`sel:set_to_line_range()`									extend to contain all its lines in full

__selection-based editing__

`sel:remove()`													remove selected text from the buffer

`sel:indent(use_tab)`										extend to line range and indent

`sel:outdent()`												extend to line range and outdent

`sel:move_up()`	\											extend to line range and move up/down in buffer
`sel:move_down()`

`sel:reflow(line_width, tabsize, align, wrap)`		reflow text in selection

__hit testing__

`sel:hit_test(x, y) -> true | false`					hit test

__TODO__

`sel:invalidate()`

-------------------------------------------------- --------------------------------------------------

## Block Selections

## `local block_selection = require'codedit_blocksel'`

Extended selection object for selecting vertically aligned text between two arbitrary cursor
positions (line1, col1, line2, col2), where line1,line2 are the horizontal boundaries and col1,col2
are the vertical boundaries of the rectangle.

The methods are the same as for normal selections, except that operate on blocks.
Also, indenting and outdenting doesn't extend the selection to line range.
Other differences are as follows:

-------------------------------------------------- --------------------------------------------------
`block_selection:new(buffer, view, visible)			create a new block selection object
	-> blocksel`

`blocksel.block -> true` 									this is to distinguish from a normal selection

`blocksel:extend_to_last_col()`							extend selection to the right to contain
																	all the available text
-------------------------------------------------- --------------------------------------------------

