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
`app:running() -> t|f`								check if the loop is running
__app quitting__
`app:quit()`											quit app, i.e. close all windows and stop the loop
`app:autoquit(t|f)`									flag: quit the app when the last window is closed
`app:autoquit() -> t|f`								get app autoquit flag
`app:quitting() -> [false]`						event: quitting (return false to refuse)
`win:autoquit(t|f)`									flag: quit the app when the window is closed
`win:autoquit() -> t|f`								get window autoquit flag
__timers__
`app:runevery(seconds, func)`						run a function on a timer (timer stops if func returns false)
`app:runafter(seconds, func)`						run a function on a timer once
`app:run(func)`										(star the loop and) run a function on a zero-second timer once
`app:sleep(seconds)`									sleep without blocking inside a function run with app:run()
__window list__
`app:windows() -> {win1, ...}`					all windows in creation order
`app:window_count([top_level]) -> n`			number of (top-level) windows
`app:window_created(win)`							event: a window was created
`app:window_closed(win)`							event: a window was closed
__window creation__
`app:window(t) -> win`								create a window (fields of _t_ below)
*__position__*
*`x`, `y`*		 										frame position (nil, nil)
*`w`, `h`*												frame size (this or cw,ch required)
*`cx`, `cy`*											client area position (nil, nil)
*`cw`, `ch`*											client area size (this or w,h required)
*`min_cw`, `min_ch`*									min client rect size
*`max_cw`, `max_ch`*									max client rect size
*__state__*
*`visible`*												start visible (true)
*`minimized`*											start minimized (false)
*`maximized`*											start maximized (false)
*`enabled`*												start enabled (true)
*__frame__*
*`title`* 												initial title ('')
*`transparent`*										make it transparent (false)
*__behavior__*
*`parent`*												parent window (nil)
*`sticky`*												moves with parent (false)
*`topmost`*												stays on top of other windows (false)
*`minimizable`*										allow minimization (true)
*`maximizable`*										allow maximization (true)
*`closeable`*											allow closing (true)
*`resizeable`*											allow resizing (true)
*`fullscreenable`*									allow full screen mode (true)
*`activable`*											allow activation (true); only for 'toolbox' frames
*`autoquit`*											quit the app on closing (false)
*`edgesnapping`*										magnetized edges ('screen')
*__menu__*
*`menu`*													menu bar
__window closing__
`win:close()`											close the window and destroy it
`win:dead() -> t|f`									check if the window was destroyed
`win:closing()`										event: closing (return false to refuse)
`win:was_closed()`									event: closed (but not dead yet)
`win:closeable() -> t|f`							closeable flag
__app activation__
`app:active() -> t|f`								check if the app is active
`app:activate()`										activate the app
`app:was_activated()`								event: app was activated
`app:was_deactivated()`								event: app was deactivated
__window activation__
`app:active_window() -> win`						the active window, if any
`win:active() -> t|f`								check if window is active
`win:was_activated()`								event: window was activated
`win:was_deactivated()`								event: window was deactivated
`win:activable() -> t|f`							activable flag (for 'toolbox' windows)
__app visibility (OSX)__
`app:hidden() -> t|f`								check if app is hidden
`app:hidden(t|f)`										change app visibility
`app:hide()`											hide the app
`app:unhide()`											unhide the app
`app:was_hidden()`									event: app was hidden
`app:was_unhidden()`									event: app was unhidden
__window visibility__
`win:visible() -> t|f`								check if window is visible
`win:visible(t|f)`									change window's visibility
`win:show()`											show window (in its previous state)
`win:hide()`											hide window
`win:was_shown()`										event: window was shown
`win:was_hidden()`									event: window was hidden
__minimization__
`win:minimizable() -> t|f`							minimizable flag
`win:minimized() -> t|f`							check if the window is minimized
`win:minimize()`										minimize the window
`win:was_minimized()`								event: window was minimized
`win:was_unminimized()`								event: window was unminimized
__maximization__
`win:maximizable() -> t|f`							maximizable flag
`win:maximized() -> t|f`							check if the window is maximized
`win:maximize()`										maximize the window
`win:was_maximized()`								event: window was maximized
`win:was_unmaximized()`								event: window was unmaximized
__fullscreen mode__
`win:fullscreenable() -> t|f`						fullscreenable flag
`win:fullscreen() -> t|f`							check if the window is in fullscreen state
`win:fullscreen(t|f)`								enter/exit fullscreen state
`win:entered_fullscreen()`							event: entered fullscreen state
`win:exited_fullscreen()`							event: exited fullscreen state
__window restoring__
`win:restore()`										restore from minimized or maximized state
`win:shownormal()`									show in normal state
__state strings__
`win:state() -> state`								full window state string
`app:state() -> state`								full app state string
__enabled state__
`win:enabled(t|f)`									enable/disable the window
`win:enabled() -> t|f`								check if the window is enabled
__client/screen conversion__
`win:to_screen(x, y) -> x, y`						client space -> screen space conversion
`win:to_client(x, y) -> x, y`						screen space -> client space conversion
__frame/client conversion__
`app:client_to_frame(frame, has_menu,`			client rect -> window frame rect conversion
	`x, y, w, h) -> x, y, w, h`
`app:frame_to_client(frame, has_menu,`			window frame rect -> client rect conversion
	`x, y, w, h) -> x, y, w, h`
`app:frame_extents(frame, has_menu)`			frame extents for a frame type
	`-> left, top, right, bottom`
__size and position__
`win:frame_rect() -> x, y, w, h`					get frame rect in current state
`win:frame_rect(x, y, w, h)`						set frame rect (and change state to normal)
`win:normal_frame_rect() -> x, y, w, h`		get frame rect in normal state
`win:client_rect() -> cx, cy, cw, ch`			get client rect in current state
`win:client_rect(cx, cy, cw, ch)`				set client rect (and change state to normal)
`win:client_size() -> cw, ch`						get client rect size
`win:client_size(cw, ch)`							set client rect size
`win:sizing(when, how, x, y, w, h)`				event: window size/position is about to change
	`-> [x, y, w, h]`
`win:was_moved(cx, cy)`								event: window was moved
`win:was_resized(cw, ch)`							event: window was resized
__size constraints__
`win:resizeable() -> t|f`							resizeable flag
`win:minsize() -> cw, ch`							get min client rect size
`win:minsize(cw, ch)`								set min client rect size
`win:maxsize() -> cw, ch`							get max client rect size
`win:maxsize(cw, ch)`								set max client rect size
__window edge snapping__
`win:edgesnapping() -> mode`						get edge snapping mode
`win:edgesnapping(mode)`							set edge snapping mode
`win:magnets(which) -> {r1, ...}`				event: get edge snapping rectangles
__window z-order__
`win:topmost() -> t|f`								get the topmost flag
`win:topmost(t|f)`									set the topmost flag
`win:raise([rel_to_win])`							raise above all windows/specific window
`win:lower([rel_to_win])`							lower below all windows/specific window
__window title__
`win:title() -> title`								get title
`win:title(title)`									set title
__displays__
`app:displays() -> {disp1, ...}`					get displays (in no specific order)
`app:display_count() -> n`							number of displays
`app:main_display() -> disp	`					get the display whose screen rect starts at (0,0)
`app:active_display() -> disp`					get the display which has keyboard focus
`disp:screen_rect() -> x, y, w, h`				display's screen rectangle
`disp.x, disp.y, disp.w, disp.h`
`disp:client_rect() -> x, y, w, h`				display's screen rectangle minus the taskbar
`disp.cx, disp.cy, disp.cw, disp.ch`
`app:displays_changed()`							event: displays changed
`win:display() -> disp`								the display the window is on
__cursors__
`win:cursor() -> name`								get the cursor
`win:cursor(name)`									set the cursor
__frame flags__
`win:frame() -> frame`								window's frame: 'normal', 'none', 'toolbox'
`win:transparent() -> t|f`							transparent flag
__parent/child rel.__
`win:parent() -> win|nil`							window's parent
`win:children() -> {win1, ...}`					window's children
`win:sticky() -> t|f`								sticky flag
__keyboard__
`app:key(query) -> t|f`								get key pressed and toggle states
`win:keydown(key)`									event: a key was pressed
`win:keyup(key)`										event: a key was depressed
`win:keypress(key)`									event: sent after each keydown, including repeats
`win:keychar(char)`									event: sent after keypress for displayable characters; char is utf-8
__hi-dpi support__
`app:autoscaling() -> t|f`							check if autoscaling is enabled
`app:autoscaling(t|f)`								enable/disable autoscaling
`disp.scalingfactor`									display's scaling factor
`win:scalingfactor_changed()`						a window's display scaling factor changed
__views__
`win:views() -> {view1, ...}`						list views
`win:view_count() -> n`								number of views
`win:view(t) -> view`								create a view (fields of _t_ below)
*`x`, `y`, `w`, `h`*									view's position (in window's client space) and size
*`visible`*												start visible (true)
*`anchors`*												resizing anchors ('lt'); can be 'ltrb'
`view:free()`											destroy the view
`view:dead() -> t|f`									check if the view was freed
`view:visible() -> t|f`								get visibility
`view:visible(t|f)`									set visibility
`view:show()`											show the view
`view:hide()`											hide the view
`view:rect() -> x, y, w, h`						get view's position (in window's client space) and size
`view:rect(x, y, w, h)`								set view's position and/or size
`view:size() -> w, h`								get view's size
`view:size(w, h)`										set view's size
`view:anchors() -> anchors`						get anchors
`view:anchors(anchors)`								set anchors
`view:rect_changed(x, y, w, h)`					event: view's size and/or position changed
`view:was_moved(x, y)`								event: view was moved
`view:was_resized(w, h)`							event: view was resized
__mouse__
`win/view:mouse() -> t`								mouse state: _x, y, inside, left, right, middle, ex1, ex2_
`win/view:mouseenter()`								event: mouse entered the client area of the window
`win/view:mouseleave()`								event: mouse left the client area of the window
`win/view:mousemove(x, y)`							event: mouse was moved
`win/view:mousedown(button, x, y)`				event: mouse button was pressed; button is _'left', 'right', 'middle', 'ex1', 'ex2'_
`win/view:mouseup(button, x, y)`					event: mouse button was depressed
`win/view:click(button, count, x, y)`			event: mouse button was clicked
`win/view:wheel(delta, x, y)`						event: mouse wheel was moved
`win/view:hwheel(delta, x, y)`					event: mouse horizontal wheel was moved
__rendering__
`win/view:repaint()`									event: window needs redrawing
`win/view:invalidate()`								request window redrawing
`win/view:bitmap() -> bmp`							get a bgra8 [bitmap] object to draw on
`bmp:clear()`											fill the bitmap with zero bytes
`bmp:cairo() -> cr`									get a cairo context on the bitmap
`win/view:free_cairo()`								event: cairo context needs freeing
`win/view:free_bitmap()`							event: bitmap needs freeing
`win/view:gl() -> gl`								get an OpenGL API for the window
__events__
`app/win/view:on(event, func)`					call _func_ when _event_ happens
`app/win/view:events(enabled) -> prev_state`	enable/disable events
`app/win/view:event(name, args...)`				meta-event fired on every other event
__version checks__
`app:ver(query) -> t|f`								check OS _minimum_ version (eg. 'OSX 10.8')
__extending__
`nw.backends -> {os -> module_name}`			default backend modules for each OS
`nw:init([backend_name])`							init with a specific backend (can be called only once)
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



