---
tagline:   native windows
platforms: mingw32, mingw64, osx32, osx64
---

<warn>NOTE: work-in-progress (to-be-released soon)</warn>

## `local nw = require'nw'`

Cross-platform library for displaying and manipulating native windows,
drawing in their client area using [cairo] or [opengl], and accessing
input devices in a consistent and well-specified manner across Windows,
Linux and OS X.

## API

<div class=small>
-------------------------------------------- -----------------------------------------------------------------------------
__app__
`nw:app() -> app`										the application object (singleton)
__app loop__
`app:run()`												run the loop
`app:stop()`											stop the loop
`app:running() -> true|false`						check if the loop is running
__app quitting__
`app:quit()`											close all windows and stop the loop
`app:autoquit(true|false)`							quit when the last window is closed
`app:autoquit() -> true|false`					autoquit enabled
`app:quitting() -> [false]`						quitting event/query
__timers__
`app:runevery(seconds, func)`						run a function on a timer (timer stops if func returns false)
`app:runafter(seconds, func)`						run a function on a timer once
`app:run(func)`										(star the loop and) run a function on a zero-second timer once
`app:sleep(seconds)`									sleep without blocking inside a function run with app:run()
__displays__
`app:displays() -> iter() -> display`			get displays in no specific order
`app:main_display() -> display`					get the display whose screen rect starts at (0,0)
`app:screen_rect([display]) -> x, y, w, h`	display's screen rectangle
`app:desktop_rect([display]) -> x, y, w, h`	display's screen rectangle excluding the taskbar
__time__
`app:time() -> time`									get an opaque time object representing a hi-resolution timestamp
`app:timediff(time1, time2) -> ms`				get the difference between two time objects
__windows__
`app:windows() -> iter() -> win`					iterate app's windows in creation order
`app:active_window() -> win`						get the active window, if any
`app:window(t) -> win`								create a window (fields of t below)
__state options__
`t.x, t.y, t.w, t.h` (required)					window's frame rectangle
`t.visible` (true)									window is visible
`t.title` (empty) 									window title
`t.state` ('normal')									window state: 'normal', 'maximized', 'minimized'
`t.fullscreen` (false)								fullscreen mode (orthogonal to state)
`t.topmost` (false)									always stay on top of all other windows
__frame options__
`t.frame` (true)										window has a frame, border and title bar
`t.transparent` (false)								window is transparent, has no frame and is not directly resizeable
`t.minimizable` (true)								enable the minimize button
`t.maximizable` (true)								enable the maximize button
`t.closeable` (true)									enable the close button / allow closing the window
`t.resizeable` (true)								window is user-resizeable
__window lifetime__
`win:free()`											close the window and destroy it
`win:dead() -> true|false`							check if the window was destroyed
`win:closing()`										event: closing; return false to prevent it
`win:closed()`											event: closed (but not dead yet)
__window focus__
`win:activate()`										activate the window
`win:active() -> true|false`						check if the window is active
`win:activated()`										event: window was activated
`win:deactivated()` 									event: window was deactivated
__window state__
`win:show([state])`									show it, in its current state or in a new state
`win:hide()`											hide it (orthogonal to state)
`win:visible([visible]) -> true|false`			get/set visibility
`win:state([state]) -> state`						get/set state: 'normal', 'maximized', 'minimized'
`win:topmost([true]) -> topmost`					get/set the topmost flag
`win:fullscreen([on]) -> true|false`			get/set fullscreen mode (orthogonal to state)
`win:frame_rect([x, y, w, h]) -> x, y, w, h`	get/set the frame rect of the 'normal' state
`win:display() -> display`							the display the window is on
`win:frame_changing(how, x, y, w, h)`			event: moving (how = 'move'), or resizing (how = 'left', 'right', 'top', 'bottom', 'topleft', 'topright', 'bottomleft', 'bottomright'); return different (x, y, w, h) to constrain
`win:frame_changed()`								event: window was moved, resized or state changed
`win:title([title]) -> title`						get/set the window's title
`win:save() -> t`										save user-changeable state
`win:load(t)`											load user-changeable state
__window frame__
`win:frame(flag) -> value`							get frame flags: 'frame', 'transparent', 'minimizable', 'maximizable', 'closeable', 'resizeable'
__keyboard events__
`win:key(keyname) -> down[, toggled]`			get key and toggle state (see source for key names, or print keys on keydown)
`win:keydown(key)`									event: a key was pressed
`win:keyup(key)`										event: a key was depressed
`win:keypress(key)`									event: sent on each key down, including repeats
`win:keychar(char)`									event: sent after key_press for displayable characters; char is utf-8
__mouse events__
`win:hover()`											event: mouse entered the client area of the window
`win:leave()`											event: mouse left the client area of the window
`win:mousemove(x, y)`								event: mouse move
`win:mousedown(button)`								event: a mouse button was pressed: 'left', 'right', 'middle', 'ex1', 'ex2'
`win:mouseup(button)`								event: a mouse button was depressed
`win:click(button, count)`							event: a mouse button was pressed (see notes for double-click)
`win:wheel(delta)`									event: mouse wheel was moved
`win:hwheel(delta)`									event: mouse horizontal wheel was moved
__mouse state__
`win.mouse`												a table with fields: x, y, left, right, middle, xbutton1, xbutton2, inside
__rendering__
`win:render(cr)`										event: redraw the window client area using the given [cairo] context
`win:invalidate()`									request window redrawing
`win:client_rect() -> x, y, w, h`				get the client area rect (relative to itself)
__events__
`obj:on(event, func)`								call `func` when `event` happens
`obj:events(enabled) -> prev_state`				enable/disable events
__lifetime__
`obj:dead() -> true|false`							check if an object was freed
__version checks__
`app:ver(query) -> true|false`					check OS version eg. app:ver'OSX 10.8' == true on OSX 10.8+
__extending__
`nw.backends -> {os -> module_name}`			default backend modules for each OS
`nw:init([backend_name])`							init `nw` with a specific backend (can be called only once)
-------------------------------------------- -----------------------------------------------------------------------------
</div>

## Quick Example

~~~{.lua}
local nw = require'nw'

local app = nw:app()

local win = app:window{x = 100, y = 100, w = 400, h = 200, title = 'hello'}

function win:click(button, count)
	if button == 'left' and count == 3 then --triple click
		app:quit()
	end
end

function win:keydown(key)
	if key == 'F11' then
		self:fullscreen(not self:fullscreen())
	end
end

app:run() --start the main loop

~~~

## Features

  * frameless transparent windows
  * edge snapping
  * full screen mode
  * multi-monitor support
  * complete access to the US keyboard
  * triple-click events
  * multi-touch gestures
  * unicode

## Style

  * consistent and fully-specified behavior accross all supported platforms
  * no platform-specific features except for supporting platform idioms
  * unspecified behavior is a bug
  * unsupported parameter combinations are errors
  * properties for state are orthogonal to each other
  * iterators are stable and with specified order

## Backends

  * cocoa: OSX 10.7+
  * winapi: Windows XP/2000+

## Behavior

### State variables

State variables are independent of each other, so a window can be maximized, in full screen mode and hidden
all at the same time. Changing the state to 'minimized' won't affect the fact that the window is still hidden,
nor that it is in full screen mode. If the window is shown, it will be in full screen mode. Out of full screen
mode it will be minimized. Likewise, moving or resizing the window affects the frame rectangle of the
'normal' mode. If the window is maximized, resizing it won't have an immediate effect, but changing the state
to 'normal' will show the window in its new size.

Maximizing or restoring a window while visible has the side effect of activating the window,
if it's not active already.

### Closing windows

Closing a window destroys it by default. You can prevent that by returning false on the `closing` event.

~~~{.lua}
function win:closing()
	self:hide()
	return false --prevent destruction
end
~~~

### Closing the app

The `app:run()` call returns after the last window is destroyed. Because of that, `app:quit()`
only has to close all windows, and it tries to do that in reverse-creation order.

### Multi-clicks

When the user clicks the mouse repeatedly, with a small enough interval between clicks and over the same target,
a counter is incremented. When the interval between two clicks is larger than the threshold or the mouse is moved
too far away from the initial target, the counter is reset (i.e. the click-chain is interrupted).
Returning true on the `click` event also resets the counter (i.e. interrupts the click chain).

This allows processing of double-clicks, triple-clicks, or multi-clicks by checking the `count` argument on
the `click` event. If your app doesn't need to process double-clicks or multi-clicks, you can just ignore
the `count` argument. If it does, you must return true after processing the multi-click event so that
the counter is reset.

For instance, if your app supports double-click over some target, you must return true when count is 2,
otherwise you might get a count of 3 on the next click sometimes, instead of 1 as expected. If your app
supports both double-click and triple-click over a target, you must return true when the count is 3
to break the click chain, but you must not return anything when the count is 2, or you'll never get
a count of 3.

### Corner cases

  * calling any method on a closed window results in error, except for win:free() which does nothing.
  * calling app:run() while running is a no op.
  * app:windows() can return dead windows (but not new windows).
  * calling display functions on an invalid display object results in error (monitors can come and go too you know).



