---
tagline: text manipulation
---

## `local buffer = require'codedit_buffer'`

Buffers are the core of text editing. A buffer stores the text as a list of lines and contains methods for analyzing,
navigating, selecting and editing the text at a logical level, independent of how the text is rendered.
The buffer contains methods that deal with text at various levels of abstraction.

1. At the bottom we have lines of bytes, let's call that the binary space.

2. Over that there's the char space, the space of lines and columns, where each char has a (line, col) pair.
Since the chars are utf8 codepoints, the correspondence between char space and binary space is not linear.
We don't deal much in binary space, only in char space (we use the utf8 library to traverse the codepoints).

3. The space outside of the available text is called the unclamped char space. We cannot select text from this space,
but we can navigate it as if it was made of empty lines.

4. Higher up there's the visual space, which is how the text looks after tab expansion, for a fixed tab size.
Again, the correspondence between char space (let's call it real space) and visual space is not linear.

> Since we don't support automatic line wrapping, lines have a 1:1 correspondence between all these spaces,
only the columns are different.

## Properties

~~~{.lua}
buffer.line_terminator = nil --line terminator to use when retrieving lines as a string. nil means autodetect.
buffer.default_line_terminator = '\n' --line terminator to use when autodetection fails.
--view overrides
buffer.background_color = nil
buffer.text_color = nil
buffer.line_highlight_color = nil
~~~

## Methods

-------------------------------------------------------- -------------------------------------------------------
`buffer:new(editor, view, [text]) -> buf`						create a buffer object, optionally filled
																			with an initial text.

`buffer:detect_line_terminator(text) -> term`				get the most common line terminator in a string

`buf:detect_indent()`												detect indentation and set tabsize

__text boundaries__

`buf:last_line() -> line`											last line number (also the number of lines)

`buf:getline(line) -> s`											line contents (without line terminator)

`buf:contents([lines_t]) -> s`									array of lines to text, using current line terminator

__line-level editing__

`buf:insert_line(line, s)`											insert a line

`buf:remove_line(line)`												remove a line

`buf:set_line(line, s)`												replace a line

`buf:move_line(line1, line2)`										switch lines

__line boundaries__

`buf:last_col(line) -> col`										last column (char index) on a valid line

`buf:end_pos() -> last_line, last_col`							the position right after the last char in the text

`buf:next_char_pos(line, col, 									position after some char, unclamped
	[restrict_eol]) -> line, col`

`buf:prev_char_pos(line, col, 									position before some char, unclamped
	[restrict_eol]) -> line, col`

`buf:near_char_pos(line, col, chars,							position that is a number of chars after or
[restrict_eol]) -> line, col`										before some char, unclamped

`buf:clamp_pos(line, col) -> line, col`						clamp a position to the available text

__selecting__

`buf:sub(line, col1, col2) -> s`									line slice between two columns on a valid line

`buf:select_string(line1, col1, line2, col2) -> s`			select the string between two valid, subsequent
																			positions in the text

__editing__

`buf:extend(line, col)`												extend the buffer up to (line,col-1) with newlines
																			and spaces so we can edit there.

`buf:insert_string(line, col, s) -> line, col`				insert a multiline string at a specific position
																			in the text, returning the position after the last
																			character. if the position is outside the text, the
																			buffer is extended. return the position after the string.

`buf:remove_string(line1, col1, line2, col2)`				remove the string between two arbitrary,
																			subsequent positions in the text.
																			line2,col2 is the position after the last character
																			to be removed.

__tab expansion__

`buf:tab_width(vcol) -> w`											how many spaces till the next tabstop

`buf:next_tabstop(vcol) -> vcol`									visual col of the next tabstop

`buf:prev_tabstop(vcol) -> vcol`									visual col of the prev. tabstop

`buf:visual_col(line, col) -> vcol`								real col -> visual col. outside eof visual columns
																			have the same width as real columns.

`buf:real_col(line, vcol) -> col` 								visual col -> char col. outside eof visual columns
																			have the same width as real columns.

`buf:aligned_col(target_line, line, col) -> col`			real col on a line that is vertically aligned
																			(in the visual space) to the same col on a different line.

`buf:max_visual_col() -> vcol` 									number of columns needed to fit the entire text
																			(for computing the client area for horizontal scrolling)

`buf:istab(line, col) -> true | false`							is that a tab?

`buf:next_tabstop_col(line, col) -> col`						real col on the next tabstop

`buf:prev_tabstop_col(line, col) -> col`						real col on the prev tabstop

__selecting text based on tab expansion__

`buf:select_indent(line, [col]) -> s` 							the indent of the line, optionally up to some column

`buf:indent(line, col, use_tab) -> line, col`				insert a tab or spaces from a position up to
																			the next tabstop. return the cursor at the tabstop,
																			where the indented text is.

`buf:indent_line(line, use_tab) -> line, col`				insert a tab or spaces at col 1

`buf:tabs_and_spaces(vcol1, vcol2) -> tabs, spaces`		find the maximum number of tabs and minimum of spaces
																			that fit between two visual columns

`buf:gen_whitespace(vcol1, vcol2, use_tabs) -> s`			generate whitespace (tabs and spaces or just spaces,
																			depending on the use_tabs flag) between two vcols.


`buf:insert_whitespace(line, col, vcol2, use_tabs)`		insert whitespace on a line, from a position up to
																			(but excluding) a visual col on the same line.

`buf:next_nonspace_col(line, col)`	\							find non-space boundaries (jump any whitespace)
`buf:prev_nonspace_col(line, col)`

`buf:isempty(line)`													check if a line is either invalid,
																			empty or made entirely of whitespace

`buf:indenting(line, col) -> true | false`					check if a position is before the first non-space char,
																			that is, in the indentation area.

`buf:next_tabful_col(line, col, 									find tabful boundaries. a tabful is the whitespace
    [restrict_eol]) -> col`										between two tabstops. the tabful column after some
																			char is either the next tabstop or the first
																			non-space char after the prev. char or the char
																			after the last col, whichever comes first,
																			and if after the given char.

`buf:prev_tabful_col(line, col) -> col`						the tabful column before some char, which is either
																			the prev. tabstop or the char after the prev.
																			non-space char, whichever comes first,
																			and if before the given char.

__editing based on tabfuls__

`buf:outdent(line, col)`											remove the space up to the next tabstop or
																			non-space char, in other words, remove a tabful.

`buf:outdent_line(line)`											outdent at col 1.

__word boundaries__

`buf:next_word_break_col(line, col, 							word breaking semantics per [codedit_str]
	[word_chars]) -> col` \
`buf:prev_word_break_col(line, col,
	[word_chars]) -> col`

`buf:word_cols(line, col,											word boundaries surrounding a char position
	[word_chars]) -> col1, col2`

`buf:next_list_aligned_vcol(line, col, 						find the visual col that is aligned with the next
	[restrict_eol]) -> vcol`										word on the line above

`buf:next_args_aligned_vcol(line, col, 						find the visual col that is aligned with the
	[restrict_eol) -> vcol`											next open bracket on the line above

__paragraph boundaries__

`buf:reflow_lines(line1, line2, 									reflow the text between two lines.
	line_width, tabsize, align, wrap) -> line2, col2`		return the position after the last inserted character.
																			align can be 'left', 'right', 'justify'.
																			wrap can be 'greedy', or 'knuth'.

__saving to disk__

`buf:save_to_file(filename)`										save the buffer to disk atomically

__TODO__

`buf:invalidate()`
-------------------------------------------------------- -------------------------------------------------------

## Undo/redo stack

## `require'codedit_undo'`

Extends the buffer class with methods for undo/redo.

The undo stack is a stack of undo groups.
An undo group is a list of editor commands to be executed in reverse order,
which together perform what the user perceives as a single undo operation.
Consecutive undo groups of the same group type are merged together.
The undo commands in the group can be any editor method with any arguments.

-------------------------------------------- -------------------------------------------------------
`buf:start_undo_group(group_type)`				auto-close the current undo group and start a new one
`buf:end_undo_group()`								close and commit the current undo group
`buf:undo_command(...)`								add an undo command to the current undo group, if any
`buf:undo()`											exec the last undo group, recording a redo group
`buf:redo()`											exec the last redo group, recording a undo group
-------------------------------------------- -------------------------------------------------------

## Normalization

## `require'codedit_normal'`

Extends the buffer class with properties and methods for text normalization.

~~~{.lua}
buffer.eol_spaces = 'remove' --leave, remove.
buffer.eof_lines = 'leave' --leave, remove, ensure, or a number.
buffer.convert_indent = 'tabs' --tabs, spaces, leave: convert indentation to tabs or spaces based on tabsize
~~~

-------------------------------------------- -------------------------------------------------------
`buf:remove_eol_spaces()`                    remove any spaces past eol
`buf:ensure_eof_line()`                      add an empty line at eof if there is none
`buf:remove_eof_lines()`                     remove any empty lines at eof, except the first line
`buf:convert_indent_to_tabs()`               indent to tabs
`buf:convert_indent_to_spaces()`             indent to spaces
`buf:normalize()`                            normalize based on properties
-------------------------------------------- -------------------------------------------------------

## Text Blocks

## `require'codedit_blocks'`

Extends the buffer class with methods for selecting and editing text blocks, i.e. vertically aligned text
between two subsequent text positions.

Blocks are defined as (line1, col1, line2, col2), where line1 and line2 must be valid, subsequent lines
in the buffer, and col1 and col2 can be anything.

-------------------------------------------------------- -------------------------------------------------------
`buf:block_cols(line, line1, col1, line2, col2) -> s`		clamped line segment on a line that intersects the
																			rectangle formed by two arbitrary text positions.

`buf:select_block(line1, col1, line2, col2) -> lines_t`	select the block between two subsequent text
																			positions as a multi-line string.

`buf:insert_block(line1, col1, s) -> line2, col2`			insert a multi-line string as a block at some position
																			in the text. return the position after the string.

`buf:remove_block(line1, col1, line2, col2)`					remove the block between two subsequent positions in the text

`buf:indent_block(line1, col1,									indent the block between two subsequent positions in the text
	line2, col2, use_tab) -> n`									returns max(visual-length(added-text)).

`buf:outdent_block(line1, col1, line2, col2)`				outdent the block between two subsequent positions in the text

`buf:reflow_block(line1, col1, line2, col2,					reflow a block to its width.
	line_width, tabsize, align, wrap)`							return the position after the last inserted character.
-------------------------------------------------------- -------------------------------------------------------
