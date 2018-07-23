---
tagline: code editor engine in Lua
---

<warn>Work in progress</warn>

## `local codedit = require'codedit'`

Codedit is a source code editor engine written in Lua.
Codedit exposes the logic of source code editing with all its intricacies
in a set of highly compartimentalized APIs, making it easy to explore,
understand and extend.

Being made in pure Lua, it runs on all the platforms that Lua runs on.
If, inside your Lua environment, you have the means to:

  * display characters at certain coordinates
  * display filled rectangles at certain coordinates
  * do rectangle clipping
  * process keyboard and mouse events
  * access the OS's clipboard

then you can hook up codedit with those APIs and add code editing
capabilities to your app.

## Highlights

  * Unicode-ready.
  * cross-platform: written in Lua with no dependencies.
  * simple interface for integrating with rendering and input APIs.
  * highly modular, with separate buffer, cursor, selection, view and
  controller objects, allowing multiple cursors, multiple selections
  and multiple views over the same file buffer.

## Features

  * preserves mixed line terminators and mixed tab styles in the same files.
  * multiple selections, block selections and editing with multiple cursors.
  * configurable cursor movement policies.
  * syntax highlighting with [scintillua](http://foicica.com/scintillua/) lexers.
  * user-defined margins.
  * configurable key bindings and commands.
  * smart tabs: use tabs only when indenting, and use spaces inside the lines.
