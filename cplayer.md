---
tagline: procedural graphics & IMGUI toolkit
platforms: mingw32, mingw64
---

## `local player = require'cplayer'`

CPlayer is a procedural graphics player with an IMGUI toolkit.
It can be used for anything from quick demos, prototyping graphics apps, to full-fledged apps and games.

## Features

  * single rendering event receiving a cairo context to draw the frame on
  * simplified access to keyboard and mouse state
  * a bunch of very easy to use immediate mode GUI widgets for making interactive demos
  * user-selectable color themes

## How it works

1. You define the function `player:on_render(cr)` in which you draw your frame using the `cr` argument
which is a [cairo] context. The function gets called continuously on a `1 ms` timer.
The current framerate is displayed on the title bar.

2. You call `player:play()` to display the player's main window and enter the Windows message loop.
The function returns after the user has closed the window.

#### Quick example:

~~~{.lua}
local player = require'cplayer'

function player:on_render(cr)
    --draw a red square
    cr:rgb(1, 0, 0)
    cr:rectangle(100, 100, 100, 100)
    cr:fill()
end

player:play()
~~~

### Mouse state

---------------------------------------------- ----------------------------------------------
`self.mousex`                                  mouse coordinates in device space.
`self.mousey`                                  use `cr:device_to_user()` to translate them.
`self.clicked`                                 true if the left mouse button was clicked (one-shot)
`self.rightclick`                              true if the right mouse button was clicked (one-shot)
`self.doubleclicked`                           true if the left mouse button was double-clicked (one-shot)
`self.lbutton`                                 true if the left mouse button is down
`self.rbutton`                                 true if the right mouse button is down
`self.wheel_delta`                             mouse wheel movement as number of scroll pages (one-shot)
`self:hotbox(x, y, w, h) -> true | false`      check if the mouse hovers a rectangle
---------------------------------------------- ----------------------------------------------

### Keyboard state

---------------------------------------------- ----------------------------------------------
`self.key`                                     set if a key was pressed (one-shot); values are 'left', 'right', etc. (see source for complete list of key names; one-shot)
`self.char`                                    set if a key combination representing a unicode character was pressed (one-shot); value is the character in utf-8
`self.shift`                                   true if shift key is pressed; only check it when `self.key` is set
`self.ctrl`                                    true if alt key is pressed; only check it when `self.key` is set
`self.alt`                                     true if control key is pressed; only check it when `self.key` is set
`self:keypressed(keyname) -> true | false`     check if a key is pressed
---------------------------------------------- ----------------------------------------------

> One-shot means that the value is only available for the current frame, then it is cleared.
With very slow framerates, some mouse or key events could be lost (for simplicity, there's no event queue).

### Wall clock

A wall clock in milliseconds is available as `self.clock`. Interpolating your animations over clock deltas will
result in framerate-independent animations. Currently, it is used to blink the editbox caret.

### Mouse cursor

	self.cursor = <name>

Changes the mouse pointer to one of the standard pointers: 'link', 'text', 'busy', etc.
Look at the `cursors` table for the full list. The variable is not retained between frames,
so it must be set every time to keep the mouse pointer changed otherwise the pointer will revert back to normal.

### Theme-aware API

--------------------------------------------------------------
`self:setcolor(color)`
`self:fill(color)`
`self:stroke(color[, line_width])`
`self:fillstroke([fill_color], [stroke_color][, line_width])`
--------------------------------------------------------------

The color argument can be either a color name from the current theme, a hex color in `#rrggbb` or `#rrggbbaa` format,
or a table of form `{r, g, b, a}` where each channel is in the `0..1` range.
Look at `player.themes.*` tables for available themes and color names.
To change the current theme just set `self.theme` to a different theme table. Controls also have a `theme` parameter.

### Drawing helpers

--------------------------------------------------------------
`self:dot(x, y, r, [fill_color], [stroke_color][, line_width])`
`self:rect(x, y, w, h, [fill_color], [stroke_color][, line_width])`
`self:circle(x, y, r, [fill_color], [stroke_color][, line_width])`
`self:line(x1, y1, x2, y2, [stroke_color][, line_width])`
`self:curve(x1, y1, x2, y2, x3, y3, x4, y4, [stroke_color][, line_width])`
`self:text(text, font_size, color, halign, valign, x, y, w, h)`
`self:text_path(text, font_size, halign, valign, x, y, w, h)`
 `* halign = 'center', 'left', 'right'`
 `* valign = 'middle', 'top', 'bottom'`
--------------------------------------------------------------

### GUI widgets

The GUI Widgets are implemented in `cplayer/*.lua`. The modules are loaded automatically as needed.
For the full list of available widgets and the module where each is implemented in, look for `autoload` in the code.
The player demo should also include a usage example for each widget.

#### Quick example:

~~~{.lua}
if self:button{id = 'ok', x = 100, y = 100, w = 100, h = 24, text = 'Okay'} then
  print'button pressed'
end
~~~

### Additional windows

You can create and show additional windows from the main window with `self:window()`.
Windows are not like other widget methods: each invocation of `self:window()` creates a new window on screen
that doesn't close when the frame ends, but persists until the user closes it
(I'll probably change that in the future and have a unique window per id and activate it when invoked and
set `self.active` or something).

~~~{.lua}
local window = self:window{
   w = 500, h = 300, title = 'Ima window',
   on_render = function(cr)
      ...
   end}
~~~
