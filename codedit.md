---
tagline: code editor engine in Lua
---

<warn>WORK IN PROGRESS / NOTHING TO SEE HERE (YET)</warn>

## `local codedit = require'codedit'`

Codedit is a source code editor engine written in Lua.
Codedit exposes the logic of source code editing with all its intricacies
in a set of highly compartimentalized APIs, making it easy to explore, understand and extend.

Being made in pure Lua, it runs on all the platforms that Lua runs on.
If, inside your Lua environment, you have the means to:

  * display a character at certain coordinates
  * display a filled rectangle at certain coordinates
  * rectangle clipping
  * process keyboard and mouse events

then you can hook up codedit and add code editing capabilities to your app.

Codedit comes with a minimalist code editor based on [cplayer].

## Highlights

  * utf8-ready, using a small [string module][codedit_str.lua] over [utf8].
  * cross-platform: written in Lua and with no dependencies
  * [simple interface][code_editor.lua] for integrating with rendering and input APIs
  * highly modular, with separate buffer, cursor, selection, view and controller objects,
  allowing multiple cursors and multiple selections.

## Features

  * [Buffers][codedit_buffer]
    * *File format autodetection* ([code](https://github.com/luapower/codedit/blob/master/codedit_detect.lua))
      * loading files with mixed line endings
      * detecting the most common line ending used in the file and using that when saving the file
    * *Normalization* ([code](https://github.com/luapower/codedit/blob/master/codedit_normal.lua))
      * removing spaces past end-of-line before saving
      * removing empty lines at end-of-file before saving, or ensuring that the file ends with at least one empty line before saving
    * undo/redo stack ([code](https://github.com/luapower/codedit/blob/master/codedit_undo.lua))
  * *Selections* ([code](https://github.com/luapower/codedit/blob/master/codedit_selction.lua))
    * block (column) selection mode ([code](https://github.com/luapower/codedit/blob/master/codedit_blocksel.lua))
    * indent/outdent (also for block selections)
  * *Cursors* ([code](https://github.com/luapower/codedit/blob/master/codedit_cursor.lua))
    * insert and overwrite insert modes, with wide overwrite caret
    * smart tabs: use tabs only when indenting, and use spaces inside the lines
    * option to allow or restrict the cursor past end-of-line
    * option to allow or restrict the cursor past end-of-file
    * auto-indent: copy the indent of the line above when pressing enter
    * moving through words
  * *Rendering* ([code](https://github.com/luapower/codedit/blob/master/codedit_render.lua))
    * syntax highlighting using [scintillua](http://foicica.com/scintillua/) lexers
    * simple rendering and measuring API for monospace fonts ([code](https://github.com/luapower/codedit/blob/master/codedit_metrics.lua))
    * user-defined margins ([code](https://github.com/luapower/codedit/blob/master/codedit_margin.lua))
      * line numbers margin ([code](https://github.com/luapower/codedit/blob/master/codedit_line_numbers.lua))
  * *Controller* ([code](https://github.com/luapower/codedit/blob/master/codedit_editor.lua))
    * configurable key bindings and commands ([code](https://github.com/luapower/codedit/blob/master/codedit_keys.lua))
    * simple clipboard API (stubbed to an in-process clipboard)
    * scrolling, one line/char at a time or smooth scrolling ([code](https://github.com/luapower/codedit/blob/master/codedit_scroll.lua))
    * selecting with the mouse


## Limitations

  * fixed char width (monospace fonts only)
  * fixed line height
  * no incremental repaint
  * mixed line terminators are not preserved

## Usage


[codedit_str.lua]:   https://github.com/luapower/codedit/blob/master/codedit_str.lua
[code_editor.lua]:   https://github.com/luapower/cplayer/blob/master/cplayer/code_editor.lua
