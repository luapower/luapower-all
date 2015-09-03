---
tagline:   native windows
platforms: mingw32, mingw64, osx32, osx64
---

<warn>NOTE: work-in-progress (to-be-released soon)</warn>

## `local nw = require'nw'`

Cross-platform library for accessing windows, graphics and input
in a consistent manner across Windows, Linux and OS X.

Supports transparent windows, bgra8 bitmaps everywhere, drawing via [cairo]
and [opengl], edge snapping, fullscreen mode, multiple displays, hi-dpi,
key mappings, triple-click events, timers, cursors, native menus,
notification icons, all text in utf8, and more.

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
`app:autoquit() -> t|f`								get app autoquit flag (true)
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
`app:window_count([filter]) -> n`				number of windows
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
*`fullscreenable`*									allow fullscreen mode (true)
*`activable`*											allow activation (true); only for 'toolbox' frames
*`autoquit`*											quit the app on closing (false)
*`edgesnapping`*										magnetized edges ('screen')
*__menu__*
*`menu`*													menu bar
__closing__
`win:close([force])`									close the window and destroy it
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
`win:activate()`										activate the window
`win:was_activated()`								event: window was activated
`win:was_deactivated()`								event: window was deactivated
`win:activable() -> t|f`							activable flag (for 'toolbox' windows)
__app visibility (OSX)__
`app:hidden() -> t|f`								check if app is hidden
`app:hidden(t|f)`										change if the app is hidden
`app:hide()`											hide the app
`app:unhide()`											unhide the app
`app:was_hidden()`									event: app was hidden
`app:was_unhidden()`									event: app was unhidden
__window visibility__
`win:visible() -> t|f`								check if the window is visible
`win:visible(t|f)`									show or hide the window
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
__restoring__
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
`win:cursor() -> name`								get the mouse cursor
`win:cursor(name)`									set the mouse cursor
__frame flags__
`win:frame() -> frame`								window's frame: 'normal', 'none', 'toolbox'
`win:transparent() -> t|f`							transparent flag
__child windows__
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
`view:visible() -> t|f`								check if the view is visible
`view:visible(t|f)`									show or hide the view
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
__menus__
`app:menu() -> menu`									create a menu (or menu bar)
`app:menubar() -> menu`								get app's menu bar (OSX)
`win:menubar() -> menu`								get window's menu bar (Windows, Linux)
`win/view:popup(menu, cx, cy)`					pop up a menu relative to a window or view
`menu:popup(win/view, cx, cy)`					pop up a menu relative to a window or view
`menu:add(...)`
`menu:set(...)`
`menu:remove(index)`
`menu:get(index[, prop])`
`menu:item_count() -> n`
`menu:items([prop]) -> {item1, ...}`
`menu:checked(index) -> t|f`
`menu:checked(index, t|f)`
__notification icons__
`app:notifyicon(t) -> icon`
`icon:free()`
`app:notifyicon_count() -> n`
`app:notifyicons() -> {icon1, ...}`				list notification icons
`icon:bitmap() -> bmp`								get a bgra8 [bitmap] object
`icon:invalidate()`									request bitmap redrawing
`icon:repaint()`										event: bitmap needs redrawing
`icon:free_bitmap(bmp)`								event: bitmap needs freeing
`icon:tooltip() -> s`								get tooltip
`icon:tooltip(s)`										set tooltip
`icon:menu() -> menu`								get menu
`icon:menu(menu)`										set menu
`icon:text() -> s`									get text (OSX)
`icon:text(s)`											set text (OSX)
`icon:length() -> n`									get length (OSX)
`icon:length(n)`										set length (OSX)
__window icon (Windows)__
`win:icon([which]) -> icon`						window's icon ('big'); which can be: 'big', 'small'
`icon:bitmap() -> bmp`								icon's bitmap
`icon:invalidate()`									request icon redrawing
`icon:repaint()`										event: icon needs redrawing
__dock icon (OSX)__
`app:dockicon() -> icon`
`icon:bitmap() -> bmp`								icon's bitmap
`icon:invalidate()`									request icon redrawing
`icon:repaint()`										event: icon needs redrawing
`icon:free_bitmap(bmp)`								event: bitmap needs to be freed
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

local app = nw:app()        --get the app singleton

local win = app:window{     --create a new window
	w = 400, h = 200,        --specify window's frame size
	title = 'hello',         --specify window's title
	visible = false,         --don't show it yet
}

function win:click(button, count) --this is one way to bind events
	if button == 'left' and count == 3 then --triple click
		app:quit()
	end
end

--this is another way to bind events which allows setting multiple
--handlers for the same event type.
function win:on('keydown', function(key)
	if key == 'F11' then
		self:fullscreen(not self:fullscreen()) --toggle fullscreen state
	end
end)

function win:repaint()        --called when window needs repainting
	local bmp = win:bitmap()   --get the window's bitmap
	local cr = bitmap:cairo()  --get a cairo drawing context
	cr:set_source_rgb(0, 1, 0) --make it green
	cr:paint()
end

app:run() --start the message loop
~~~

## Status

See [issues](https://github.com/luapower/nw/issues)
and [milestones](https://github.com/luapower/nw/milestones).

## Backends

  * cocoa: OSX 10.7+
  * winapi: Windows XP/2000+
  * xlib: Ubuntu/Unity 10.04+

## API Documentation

### App

#### `nw:app() -> app`

Get the singleton application object. This calls `nw:init()` which
initializes nw with the default backend for the current platform.

### App loop

#### `app:run()`

Run the loop.

Calling run() when the loop is already running does nothing.

#### `app:stop()`

Stop the loop.

Calling stop() when the loop is not running does nothing.

#### `app:running() -> t|f`

Check if the loop is running.

### App quitting

#### `app:quit()`

Quit app, i.e. close all windows and stop the loop.

Quitting is a multi-phase process:

	1. the `app:quitting()` event is fired. If it returns false,
	quitting is aborted.
	2. the `win:closing()` event is fired on all top-level
	(i.e. without a parent) windows. If any of them returns false,
	quitting is aborted.
	3. `win:close(true)` is called on all windows. If new windows are
	created during this process, quitting is aborted.
	4. the app loop is stopped.

Calling quit() when the loop is not running or if quitting
is in progress does nothing.

#### `app:autoquit(t|f)` <br/> `app:autoquit() -> t|f`

Get/set the app autoquit flag (default: true).
Enabling it causes the app to quit when the last window is closed.

#### `app:quitting() -> [false]`

Event: quitting. Return false from this event to refuse.

#### `win:autoquit(t|f)`
#### `win:autoquit() -> t|f`

Get/set the window autoquit flag (default: false).
Enabling it causes the app when this window is closed.
This flag can be used on the app's main window if there is such thing.

### Timers

#### `app:runevery(seconds, func)`

Run a function on a recurrent timer. The timer can be stopped from inside
the function by returning false.

#### `app:runafter(seconds, func)`

Run a function on a timer once.

#### `app:run(func)`

Run a function on a zero-second timer once. This allows calling
`app:sleep()` inside the function (see below).

If the loop is not already started, it is started and then stopped after
the function finishes.

#### `app:sleep(seconds)`

Sleep without blocking inside a function run with app:run(). While this
function is sleeping (can you say "coroutine"?), other timers
and events continue to be processed.

This is poor man's multi-threading based on timers and coroutines.
It can be used to create complex temporal sequences (eg. animation)
withoug having to chain timer callbacks.

Calling sleep() outside an app:run() function raises an error.

### Window list

#### `app:windows() -> {win1, ...}`

Get all windows in creation order.

#### `app:window_count([filter]) -> n`

Get the number of windows (dead or alive). `filter` can be 'top-level'
which returns the number of top-level (i.e. non-parented) windows.

#### `app:window_created(win)`

Event: a window was created.
Fired right after the window's `was_created` event is fired.

#### `app:window_closed(win)`

Event: a window was closed.
Fired right after the window's `was_closed` event is fired.

### Window creation

#### `app:window(t) -> win`

Create a window (fields of _t_ below):

* __position__
	* `x`, `y`		 				- frame position (nil, nil)
	* `w`, `h`						- frame size (this or cw,ch required)
	* `cx`, `cy`					- client area position (nil, nil)
	* `cw`, `ch`					- client area size (this or w,h required)
	* `min_cw`, `min_ch`			- min client rect size
	* `max_cw`, `max_ch`			- max client rect size
* __state__
	* `visible`						- start visible (true)
	* `minimized`					- start minimized (false)
	* `maximized`					- start maximized (false)
	* `enabled`						- start enabled (true)
* __frame__
	* `title` 						- initial title ('')
	* `transparent`				- make it transparent (false)
* __behavior__
	* `parent`						- parent window (nil)
	* `sticky`						- moves with parent (false)
	* `topmost`						- stays on top of other windows (false)
	* `minimizable`				- allow minimization (true)
	* `maximizable`				- allow maximization (true)
	* `closeable`					- allow closing (true)
	* `resizeable`					- allow resizing (true)
	* `fullscreenable`			- allow fullscreen mode (true)
	* `activable`					- allow activation (true); only for 'toolbox' frames
	* `autoquit`					- quit the app on closing (false)
	* `edgesnapping`				- magnetized edges ('screen')
* __menu__
	* `menu`							- menu bar

### Closing

#### `win:close()`

Close the window and destroy it.
Any children are closed first.

#### `win:dead() -> t|f`

Check if the window was destroyed.

#### `win:closing()`

Event: The window is about to close.
Return false from the event handler to refuse.

#### `win:was_closed()`

Event: The window was closed.
Fired after all children are closed, but before the window itself
is destroyed (`win:dead()` still returns true).

#### `win:closeable() -> t|f`

Get the closeable flag (read-only).

### App activation

#### `app:active() -> t|f`

Check if the app is active.

#### `app:activate()`

Activate the app, which implies activating the last window that was active
before the app got deactivated.

On Windows, this only flashes the window on the taskbar instead of popping
it up in user's face. OSX and Linux don't have this feature, so calling
activate() on these platforms is very, very rude.

#### `app:was_activated()`

Event: the app was activated.

#### `app:was_deactivated()`

Event: the app was deactivated.


### Window activation

#### `app:active_window() -> win`

Get the active window, if any.

When the app is inactive, this always returns nil.

#### `win:active() -> t|f`

Check if the window is active.

When the app is inactive, this returns false for all windows.

#### `win:activate()`

Activate the window. If the app is inactive, this does not activate the app.
Instead it only marks this window to be activated when the app becomes active.
If you want to force the window to become active, call `app:activate()`
after calling this function (very rude).

#### `win:was_activated()`

Event: window was activated.

#### `win:was_deactivated()`

Event: window was deactivated.

#### `win:activable() -> t|f`

Get the activable flag (read-only; only for windows with 'toolbox' frame).

Toolbox windows can be made non-activable. It is sometimes useful to have
toolboxes that don't steal keyboard focus away from the main window when clicked.

> __NOTE:__ This [does not work](https://github.com/luapower/nw/issues/26) in Linux.

### App visibility (OSX only)

#### `app:hidden() -> t|f`

Check if the app is hidden.

#### `app:hidden(t|f)`

Show or hide the app.

#### `app:hide()`

Hide the app.

#### `app:unhide()`

Unhide the app.

#### `app:was_hidden()`

Event: app was hidden.

#### `app:was_unhidden()`

Event: app was unhidden.


### Window visibility

#### `win:visible() -> t|f`

Check if the window is visible. A minimized window is still considered visible.

#### `win:visible(t|f)`

Show or hide the window.

#### `win:show()`

Show the window in its previous state (which can include any combination
of minimized, maximized, and fullscreen states).

If the window is minimized it will not be activated, otherwise it will.

#### `win:hide()`

Hide the window from the screen and from the taskbar.

#### `win:was_shown()`

Event: window was shown.

#### `win:was_hidden()`

Event: window was hidden.


### Minimization

#### `win:minimizable() -> t|f`

Get the minimizable flag (read-only).

#### `win:minimized() -> t|f`

Get the minimized state. This flag stays true if a minimized window is hidden.

#### `win:minimize()`

Minimize the window and deactivate it. If the window is hidden,
it is shown in minimized state (and the taskbar button is not activated).

#### `win:was_minimized()`

Event: window was minimized.

#### `win:was_unminimized()`

Event: window was unminimized.


### Maximization

#### `win:maximizable() -> t|f`

Get the maximizable flag (read-only).

#### `win:maximized() -> t|f`

Get the maximized state. This flag stays true if a maximized window
is minimized, hidden or enters fullscreen mode.

#### `win:maximize()`

Maximize the window and activate it. If the window was hidden,
it is shown in maximized state and activated.

If the window is already maximized it is not activated.

#### `win:was_maximized()`

Event: window was maximized.

#### `win:was_unmaximized()`

Event: window was unmaximized.


### Fullscreen mode

#### `win:fullscreenable() -> t|f`

Check if a window is allowed to go in fullscreen mode (read-only).
This flag only affects OSX - the only platform which presents a fullscreen
button on the title bar. Fullscreen mode can always be entered programatically.

#### `win:fullscreen() -> t|f`

Get the fullscreen state.

#### `win:fullscreen(t|f)`

Enter or exit fullscreen mode and activate the window. If the window is hidden
or minimized, it is shown in fullscreen mode and activated.

If the window is already in the desired mode it is not activated.

#### `win:entered_fullscreen()`

Event: entered fullscreen mode.

#### `win:exited_fullscreen()`

Event: exited fullscreen mode.


### Restoring

#### `win:restore()`

Restore from minimized, maximized or fullscreen state, i.e. unminimize
if the window was minimized, exit fullscreen if it was in fullscreen mode,
or unmaximize it if it was maximized (otherwise do nothing).

The window is always activated unless it's in normal mode.

#### `win:shownormal()`

Show the window in normal state.

The window is always activated even when it's already in normal mode.


### State strings

#### `win:state() -> state`

Get the window's full state string, eg. 'visible maximized active'.

#### `app:state() -> state`

Get the app's full state string, eg. 'visible active'.


### Enabled state

#### `win:enabled(t|f)`
#### `win:enabled() -> t|f`

Get/set the enabled flag. A disabled window cannot receive
mouse or keyboard focus. Disabled windows are useful for implementing
modal windows: make a child window and disable the parent while showing
the child, and enable back the parent when closing the child.

> __NOTE:__ This [doesn't work](https://github.com/luapower/nw/issues/25) on Linux.


### Client/screen conversion

#### `win:to_screen(x, y) -> x, y`

Convert a point from the window's client space to screen space.

#### `win:to_client(x, y) -> x, y`

Convert a point from screen space to the window's client space.


### Frame/client conversion

#### `app:client_to_frame(frame, has_menu, x, y, w, h) -> x, y, w, h`

Given a client rectangle, return the frame rectangle for a certain
frame type. If `has_menu` is true, then the window also has a menu.

#### `app:frame_to_client(frame, has_menu, x, y, w, h) -> x, y, w, h`

Given a frame rectangle, return the client rectangle for a certain
frame type. If `has_menu` is true, then the window also has a menu.

#### `app:frame_extents(frame, has_menu) -> left, top, right, bottom`

Get the frame extents for a certain frame type.

### Size and position

#### `win:frame_rect() -> x, y, w, h`

Get the frame rect in current state (in screen coordinates).

#### `win:frame_rect(x, y, w, h)`

Set the frame rect (and change state to normal).

#### `win:normal_frame_rect() -> x, y, w, h`

Get the frame rect in normal state (in screen coordinates).

#### `win:client_rect() -> cx, cy, cw, ch`

Get the client rect in current state (in screen coordinates).

#### `win:client_rect(cx, cy, cw, ch)`

Move/resize the window to accomodate a specified client area position and size.

#### `win:client_size() -> cw, ch`

Get the size of the window's client area.

#### `win:client_size(cw, ch)`

Resize the window to accomodate a specified client area size.

#### `win:sizing(when, how, x, y, w, h) -> [x, y, w, h]`

Event: window size/position is about to change.
Return a new rectangle to affect the window's final size and position.

> __NOTE:__ This does not fire in Linux (most windows managers don't allow it).

#### `win:was_moved(cx, cy)`

Event: window was moved.

#### `win:was_resized(cw, ch)`

Event: window was resized.


### Size constraints

#### `win:resizeable() -> t|f`

Get the resizeable flag.

#### `win:minsize() -> cw, ch`

Get the minimum client rect size.

#### `win:minsize(cw, ch)`

Set the minimum client rect size.

#### `win:maxsize() -> cw, ch`

Get the maximum client rect size.

#### `win:maxsize(cw, ch)`

Set the maximum client rect size.


### Window edge snapping

#### `win:edgesnapping() -> mode`
#### `win:edgesnapping(mode)`

Get/set edge snapping mode, which can be any combination of the words
'app', 'other', 'screen', 'all' separated by spaces (eg. 'app screen').

> __NOTE:__ Edge snapping doesn't work on Linux. It is however already
(poorly) implemented by some window managers (Unity) so all is not lost.

#### `win:magnets(which) -> {r1, ...}`

Event: get edge snapping rectangles (rectangles are tables with x, y, w, h fields).


### Window z-order

#### `win:topmost() -> t|f`
#### `win:topmost(t|f)`

Get/set the topmost flag. A topmost window stays on top of other non-topmost windows.

#### `win:raise([rel_to_win])`

Raise above all windows/specific window.

#### `win:lower([rel_to_win])`

Lower below all windows/specific window.


### Window title

#### `win:title() -> title`
#### `win:title(title)`

Get/set window's title.


### Displays

In non-mirrored multi-monitor setups, the displays are mapped
on a virtual surface, with the main display at (0, 0).

#### `app:displays() -> {disp1, ...}`

Get displays (in no specific order).

#### `app:display_count() -> n`

Get the display count without wasting a table.

#### `app:main_display() -> disp	`

Get the display whose screen rect starts at (0, 0).

#### `app:active_display() -> disp`

Get the display which has keyboard focus.

#### `disp:screen_rect() -> x, y, w, h`
#### `disp.x, disp.y, disp.w, disp.h`

Display's screen rectangle.

#### `disp:client_rect() -> x, y, w, h`
#### `disp.cx, disp.cy, disp.cw, disp.ch`

Display's screen rectangle minus the taskbar.

#### `app:displays_changed()`

Event: displays changed.

#### `win:display() -> disp`

The display the window is on.


### Cursors

#### `win:cursor() -> name`

Get the mouse cursor.

#### `win:cursor(name)`

Set the mouse cursor.


### Frame flags

#### `win:frame() -> frame`

Window's frame. One of 'normal', 'none', 'toolbox'.

#### `win:transparent() -> t|f`

Transparent flag.


### Child windows

#### `win:parent() -> win|nil`

Window's parent.

#### `win:children() -> {win1, ...}`

Window's children.

#### `win:sticky() -> t|f`

Sticky flag, for child windows to move with the parent when the parent is moved.


### Keyboard

#### `app:key(query) -> t|f`

Get key pressed and toggle states. TODO

#### `win:keydown(key)`

Event: a key was pressed.

#### `win:keyup(key)`

Event: a key was depressed.

#### `win:keypress(key)`

Event: sent after each keydown, including repeats.

#### `win:keychar(char)`

Event: sent after keypress for displayable characters; char is utf-8.


### Hi-DPI support

#### `app:autoscaling() -> t|f`

Check if autoscaling is enabled.

#### `app:autoscaling(t|f)`

Enable/disable autoscaling.

#### `disp.scalingfactor`

Display's scaling factor.

#### `win:scalingfactor_changed()`

A window's display scaling factor changed or most likely the window
was moved to a screen with a different scaling factor.


### Views

#### `win:views() -> {view1, ...}`

List views.

#### `win:view_count() -> n`

Number of views.

#### `win:view(t) -> view`

Create a view (fields of _t_ below).

*`x`, `y`, `w`, `h`	- view's position (in window's client space) and size
*`visible`				- start visible (true)
*`anchors`				- resizing anchors ('lt'); can be 'ltrb'

#### `view:free()`

Destroy the view.

#### `view:dead() -> t|f`

Check if the view was destroyed.

#### `view:visible() -> t|f`

Check if the view is visible.

#### `view:visible(t|f)`

Show or hide the view.

#### `view:show()`

Show the view.

#### `view:hide()`

Hide the view. The view's position is preserved (anchors keep working).

#### `view:rect() -> x, y, w, h`

Get view's position (in window's client space) and size.

#### `view:rect(x, y, w, h)`

Set view's position and/or size.

#### `view:size() -> w, h`

Get view's size.

#### `view:size(w, h)`

Set view's size.

#### `view:anchors() -> anchors`

Get anchors.

#### `view:anchors(anchors)`

Set anchors. The anchors can be any combination of 'ltrb' characters
representing left, top, right and bottom anchors respectively.

#### `view:rect_changed(x, y, w, h)`

Event: view's size and/or position changed.

#### `view:was_moved(x, y)`

Event: view was moved.

#### `view:was_resized(w, h)`

Event: view was resized.


### Mouse

#### `win/view:mouse() -> t`

Mouse state: _x, y, inside, left, right, middle, ex1, ex2_

#### `win/view:mouseenter()`

Event: mouse entered the client area of the window.

#### `win/view:mouseleave()`

Event: mouse left the client area of the window.

#### `win/view:mousemove(x, y)`

Event: mouse was moved.

#### `win/view:mousedown(button, x, y)`

Event: mouse button was pressed; button can be 'left', 'right', 'middle', 'ex1', 'ex2'.

#### `win/view:mouseup(button, x, y)`

Event: mouse button was depressed.

#### `win/view:click(button, count, x, y)`

Event: mouse button was clicked.

#### `win/view:wheel(delta, x, y)`

Event: mouse wheel was moved.

#### `win/view:hwheel(delta, x, y)`

Event: mouse horizontal wheel was moved.


### Rendering

#### `win/view:repaint()`

Event: window needs redrawing.

#### `win/view:invalidate()`

Request window redrawing.

#### `win/view:bitmap() -> bmp`

Get a bgra8 [bitmap] object to draw on.

#### `bmp:clear()`

Fill the bitmap with zero bytes.

#### `bmp:cairo() -> cr`

Get a cairo context on the bitmap.

#### `win/view:free_cairo()`

event: cairo context needs freeing

#### `win/view:free_bitmap()`

event: bitmap needs freeing

#### `win/view:gl() -> gl`

get an OpenGL API for the window


### Menus

#### `app:menu() -> menu`

create a menu (or menu bar)

#### `app:menubar() -> menu`

get app's menu bar (OSX)

#### `win:menubar() -> menu`

get window's menu bar (Windows, Linux)

#### `win/view:popup(menu, cx, cy)`

pop up a menu relative to a window or view

#### `menu:popup(win/view, cx, cy)`

pop up a menu relative to a window or view

#### `menu:add(...)`



#### `menu:set(...)`



#### `menu:remove(index)`



#### `menu:get(index[, prop])`



#### `menu:item_count() -> n`



#### `menu:items([prop]) -> {item1, ...}`



#### `menu:checked(index) -> t|f`



#### `menu:checked(index, t|f)`




### Notification icons

#### `app:notifyicon(t) -> icon`



#### `icon:free()`



#### `app:notifyicon_count() -> n`



#### `app:notifyicons() -> {icon1, ...}`

list notification icons

#### `icon:bitmap() -> bmp`

get a bgra8 [bitmap] object

#### `icon:invalidate()`

request bitmap redrawing

#### `icon:repaint()`

event: bitmap needs redrawing

#### `icon:free_bitmap(bmp)`

event: bitmap needs freeing

#### `icon:tooltip() -> s`

get tooltip

#### `icon:tooltip(s)`

set tooltip

#### `icon:menu() -> menu`

get menu

#### `icon:menu(menu)`

set menu

#### `icon:text() -> s`

get text (OSX)

#### `icon:text(s)`

set text (OSX)

#### `icon:length() -> n`

get length (OSX)

#### `icon:length(n)`

set length (OSX)


### Window icon (Windows)

#### `win:icon([which]) -> icon`

window's icon ('big'); which can be: 'big', 'small'

#### `icon:bitmap() -> bmp`

icon's bitmap

#### `icon:invalidate()`

request icon redrawing

#### `icon:repaint()`

event: icon needs redrawing


### Dock icon (OSX)

#### `app:dockicon() -> icon`



#### `icon:bitmap() -> bmp`

icon's bitmap

#### `icon:invalidate()`

request icon redrawing

#### `icon:repaint()`

event: icon needs redrawing

#### `icon:free_bitmap(bmp)`

event: bitmap needs to be freed


### Events

#### `app/win/view:on(event, func)`

call _func_ when _event_ happens

#### `app/win/view:events(enabled) -> prev_state`

enable/disable events

#### `app/win/view:event(name, args...)`

meta-event fired on every other event


### Version checks

#### `app:ver(query) -> t|f`

check OS _minimum_ version (eg. 'OSX 10.8')


### Extending

#### `nw.backends -> {os -> module_name}`

default backend modules for each OS

#### `nw:init([backend_name])`

init with a specific backend (can be called only once)


----

## API Notes

### Coordinate systems

  * window-relative positions are relative to the top-left corner of the window's client area.
  * screen-relative positions are relative to the top-left corner of the main screen.

### State variables

State variables are independent of each other, so a window can be maximized,
maximized and hidden all at the same time. If such a window is shown, it will
show minimized. If the user unminimizes it, it will restore to maximized state.

### Common mistakes

#### Assuming that calls are blocking

The number one mistake you can make is to assume that all calls are blocking.
It's very easy to make that mistake because some of them actually are blocking
on some platforms (in order of sanity: Windows, OSX and Linux -- X11 designers
particularly confuse UI design with network protocol design so all calls are
asynchronous). In a perfect world they would all be blocking and non-failing
which would make programming with them much more robust. The real world is
an unspecified mess. So never, never mix queries with commands, i.e.
never assume that when you perform some command the state of the window
actually changed when the call returns.

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


## Getting Involved

This is one of the bigger bricks in luapower but it lends itself well
to community development IMO. The frontend uses composition rather than
inheritance to connect to the backend so the communication between the two
is always explicit. Features are well separated functionally and visually
in the code so they can be developed separately without much risk of
regressions, and there's unit tests which can help with that too.
The code follows the luapower [coding-style] and [api-design] guidelines.

All the development planning, coordination and communication is done via
github issues and milestones.

### Design Goals

  * level out platform differences for common functionality.
  * _do_ support platform idioms and platform-specific functionality.
  * minimize the need for emulation of missing features by rethinking the API.
  * take preventive measures to avoid platform behavior:
    * raise errors for parameter combinations that are not universally supported.
    * clamp values to universally supported ranges.
    * make stable iterators with specified order or better yet, return arrays.
  * seek orthogonality, but do add convenience methods where useful.

