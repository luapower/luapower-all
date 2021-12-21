---
project: codedit
title: codedit_cursor
tagline: text navigation
---

## `local cursor = require'codedit_cursor'`

Cursor object, providing caret-based navigation and editing.

## Properties

~~~{.lua}
--navigation options
restrict_eol = true --don't allow caret past end-of-line
restrict_eof = true --don't allow caret past end-of-file
land_bof = true --go at bof if cursor goes up past it
land_eof = true --go at eof if cursor goes down past it
word_chars = '^[a-zA-Z]' --for jumping between words
move_tabfuls = 'indent' --'indent', 'never'; where to move the cursor between tabfuls instead of individual spaces.
--editing state
insert_mode = true --insert or overwrite when typing characters
--editing options
auto_indent = true --pressing enter copies the indentation of the current line over to the following line
insert_tabs = 'indent' --never, indent, always: where to insert a tab instead of enough spaces that make up a tab.
insert_align_list = true --insert whitespace up to the next word on the above line
insert_align_args = true --insert whitespace up to after '(' on the above line
--view overrides
thickness = nil
color = nil
line_highlight_color = nil
~~~

### Methods

-------------------------------------------------- --------------------------------------------------
`cursor:new(buffer, [view], visible) -> cur`			create a cursor object

__navigation__

`cur:move(line, col, [keep_vcol])`						move to a wanted position, restricting the final
																	position according to navigation policies.
																	also store the visual col of the cursor to be
																	used as the wanted landing col by `move_vert()`,
																	unless `keep_vcol` is true


`cur:move_vert(lines)`										navigate vertically, using the visual column
																	that resulted from horizontal navigation,
																	as target column

`cur:prev_pos() -> line, col` \							position before or after the cursor
`cur:next_pos([restrict_eol]) -> line, col`

`cur:move_prev_pos()` \										horizontal navigation
`cur:move_next_pos()`

`cur:move_up()` \												vertical navigation
`cur:move_down()`

`cur:move_home()` \											navigation to document boundaries
`cur:move_end()`

`cur:move_bol()` \											navigation to line boundaries
`cur:move_eol()`

`cur:move_up_page()` \										navigation to view boundaries
`cur:move_down_page()`

`cur:move_prev_word_break()` \							navigation to word boundaries
`cur:move_next_word_break()`

`cur:move_to_selection(sel)`								navigation to selection boundaries

`cur:move_to_coords(x, y)`									navigation to view coordinates

__editing__

`cur:insert_string(s)`										insert a string at cursor and move the cursor
																	to after the string

`cur:insert_block(s) -> line2, col2`					insert a string block at cursor. does not move
																	the cursor, but returns the position after the text.

`cur:insert_char(c)`											insert or overwrite a char at cursor,
																	depending on the insert mode

`cur:delete_pos(restrict_eol)`							delete the text up to the next cursor position

`cur:insert_newline()`										add a new line, optionally copying the indent
																	of the current line, and carry the cursor over

`cur:insert_tab()`											insert a tab character, expanding it according
																	to tab expansion policies

`cur:outdent_line()`											outdent current line

`cur:move_line_up()`	\										move the contents of the current line up and down
`cur:move_line_down()`										in the text

__scrolling__

`cur:make_visible()`											scroll the text into view to make
																	the cursor visible

-------------------------------------------------- --------------------------------------------------
