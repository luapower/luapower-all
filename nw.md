---
tagline: native windows
---

## `local nw = require'nw'`

Cross-platform library for accessing windows, graphics and input in a
consistent manner across Windows, Linux and OS X. Supports transparent
windows, bgra8 bitmaps everywhere, drawing via [cairo] and [opengl], edge
snapping, fullscreen mode, multiple displays, hi-dpi, key mappings,
triple-click events, timers, cursors, native menus, notification icons, all
text in utf8, and more.

## Status

See [issues](https://github.com/luapower/nw/issues)
and [milestones](https://github.com/luapower/nw/milestones).

## Backends

API        Library     Supported Platforms     Developed On
---------- ----------- ----------------------- ------------------------
WinAPI     [winapi]    Windows XP/2000+        Windows 7 x64
Cocoa      [objc]      OSX 10.7+               OSX 10.9
Xlib       [xlib]      Ubuntu/Unity 10.04+     Ubuntu/Unity 10.04 x64

## Example

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
win:on('keydown', function(self, key)
	if key == 'F11' then
		self:fullscreen(not self:fullscreen()) --toggle fullscreen state
	end
end)

function win:repaint()        --called when window needs repainting
	local bmp = win:bitmap()   --get the window's bitmap
	local cr = bmp:cairo()     --get a cairo drawing context
	cr:rgb(0, 1, 0)            --make it green
	cr:paint()
end

win:show() --show it now that it was properly set up

app:run()  --start the event loop
~~~

## API

__NOTE:__ In the table below, `foo(t|f) /-> t|f` is a shortcut for saying
that `foo(t|f)` sets the value of foo and `foo() -> t|f` gets it.
`t|f` means `true|false`.

-------------------------------------------- -----------------------------------------------------------------------------
__the app object__
`nw:app() -> app`                            the global application object
__the app loop__
`app:run()`                                  start the loop
`app:stop()`                                 stop the loop
`app:running() -> t|f`                       check if the loop is running
`app:poll([timeout]) -> t|f`                 process the next pending event (return true if there was one)
`app:maxfps(fps|false) -> fps|false`         cap the window repaint rate
__quitting__
`app:quit()`                                 quit the app, i.e. close all windows and stop the loop
`app:autoquit(t|f) /-> t|f`                  quit the app when the last window is closed (true)
`app:quitting() -> [false]`                  event: quitting (return false to refuse)
`win:autoquit(t|f) /-> t|f`                  quit the app when the window is closed (false)
__timers__
`app:runevery(seconds, func)`                run a function on a timer (return false to stop it)
`app:runafter(seconds, func)`                run a function on a timer once
`app:run(func)`                              run a function on a zero-second timer once
`app:sleep(seconds)`                         sleep without blocking an app:run() function
__window tracking__
`app:windows() -> {win1, ...}`               all windows in creation order
`app:window_created(win)`                    event: a window was created
`app:window_closed(win)`                     event: a window was closed
__window creation__
`app:window(t) -> win`                       create a window
__window closing__
`win:close([force])`                         close the window and destroy it
`win:dead() -> t|f`                          check if the window was destroyed
`win:closing()`                              event: closing (return false to refuse)
`win:closed()`                               event: closed (but not dead yet)
`win:closeable() -> t|f`                     closeable flag
__window & app activation__
`app/win:active() -> t|f`                    check if app/window is active
`app:activate([mode])`                       activate the app
`app:active_window() -> win`                 the active window, if any
`win:activate()`                             activate the window
`win:activable() -> t|f`                     activable flag
`app/win:activated()`                        event: app/window was activated
`app/win:deactivated()`                      event: app/window was deactivated
__app visibility (OSX)__
`app:visible(t|f) /-> t|f`                   get/set app visibility
`app:hide()`                                 hide the app
`app:unhide()`                               unhide the app
`app:hidden()`                               event: app was hidden
`app:unhidden()`                             event: app was unhidden
__window state__
`win:visible(t|f) /-> t|f`                   get/set window visibility
`win:show()`                                 show window (in its previous state)
`win:hide()`                                 hide window
`win:shown()`                                event: window was shown
`win:hidden()`                               event: window was hidden
`win:minimizable() -> t|f`                   minimizable flag
`win:isminimized() -> t|f`                   check if the window is minimized
`win:minimize()`                             minimize the window
`win:minimized()`                            event: window was minimized
`win:unminimized()`                          event: window was unminimized
`win:maximizable() -> t|f`                   maximizable flag
`win:ismaximized() -> t|f`                   check if the window is maximized
`win:maximize()`                             maximize the window
`win:maximized()`                            event: window was maximized
`win:unmaximized()`                          event: window was unmaximized
`win:fullscreenable() -> t|f`                fullscreenable flag
`win:fullscreen(t|f) /-> t|f`                get/enter/exit fullscreen mode
`win:entered_fullscreen()`                   event: entered fullscreen mode
`win:exited_fullscreen()`                    event: exited fullscreen mode
`win:restore()`                              restore from minimized or maximized state
`win:shownormal()`                           show in normal state
`win:changed(old_state, new_state)`          event: window state changed
`app:changed(old_state, new_state)`          event: app state changed
`win:enabled(t|f) /-> t|f`                   get/set window enabled flag
__frame extents__
`app:frame_extents(...) -> ...`              frame extents for a frame type
`app:client_to_frame(...) -> ...`            client rect -> window frame rect conversion
`app:frame_to_client(...) -> ...`            window frame rect -> client rect conversion
__size and position__
`win:client_rect(x,y,w,h) /-> x,y,w,h`       get/set client rect
`win:frame_rect(x,y,w,h) /-> x,y,w,h`        get/set frame rect
`win:client_size(cw, ch) /-> cw, ch`         get/set client rect size
`win/view:to_screen(x, y) -> x, y`           client space -> screen space conversion
`win/view:to_client(x, y) -> x, y`           screen space -> client space conversion
`win:normal_frame_rect() -> x,y,w,h`         get frame rect in normal state
`win:sizing(when, how, rect)`                event: window size/position is about to change
`win:frame_rect_changed(x, y, w, h, ...)`    event: window frame was moved and/or resized
`win:frame_moved(x, y, oldx, oldy)`          event: window frame was moved
`win:frame_resized(w, h, oldw, oldh)`        event: window frame was resized
`win:client_rect_changed(cx,cy,cw,ch,...)`   event: window client area was moved and/or resized
`win:client_moved(cx, cy, oldcx, oldcy)`     event: window client area was moved
`win:client_resized(cw, ch, oldcw, oldch)`   event: window client area was resized
`win:hittest(x, y) -> where`                 event: hit test for frameless windows
__size constraints__
`win:resizeable() -> t|f`                    resizeable flag
`win:minsize(cw, ch) /-> cw, ch`             get/set min client rect size
`win:maxsize(cw, ch) /-> cw, ch`             get/set max client rect size
__window edge snapping__
`win:edgesnapping(mode) /-> mode`            get/set edge snapping mode
`win:magnets(which) -> {r1, ...}`            event: get edge snapping rectangles
__window z-order__
`win:topmost(t|f) /-> t|f`                   get/set the topmost flag
`win:raise([rel_to_win])`                    raise above all windows/specific window
`win:lower([rel_to_win])`                    lower below all windows/specific window
__window title__
`win:title(title) /-> title`                 get/set title
__displays__
`app:displays() -> {disp1, ...}`             get displays (in no specific order)
`app:main_display() -> disp   `              the display whose screen rect starts at (0,0)
`app:active_display() -> disp`               the display which contains the active window
`disp:screen_rect() -> x, y, w, h`           display's screen rectangle
`disp.x, disp.y, disp.w, disp.h`
`disp:desktop_rect() -> cx, cy, cw, ch`      display's screen rectangle minus the taskbar
`disp.cx, disp.cy, disp.cw, disp.ch`
`app:displays_changed()`                     event: displays changed
`win:display() -> disp|nil`                  the display the window is on
__cursors__
`win:cursor(name|t|f) /-> name, t|f`         get/set the mouse cursor and visibility
`app:caret_blink_time() -> time | 1/0`       caret blink time
__frame flags__
`win:frame() -> frame`                       window's frame: 'normal', 'none', 'toolbox'
`win:transparent() -> t|f`                   transparent flag
`win:corner_radius() -> n`                   rounded corners (0)
__child windows__
`win:parent() -> win|nil`                    window's parent
`win:children() -> {win1, ...}`              child windows
`win:sticky() -> t|f`                        sticky flag
__hi-dpi support__
`app:autoscaling(t|f) /-> t|f`               get/enable/disable autoscaling
`disp.scalingfactor`                         display's scaling factor
`win:scalingfactor_changed()`                event: a window's display scaling factor changed
__views__
`win:views() -> {view1, ...}`                list views
`win:view(t) -> view`                        create a view
`view:free()`                                destroy the view
`view:dead() -> t|f`                         check if the view was freed
`view:visible(t|f) /-> t|f`                  get/set view's visibility
`view:show()`                                show the view
`view:hide()`                                hide the view
`view:rect(x, y, w, h) /-> x, y, w, h`       get/set view's position (in window's client space) and size
`view:size(w, h) /-> w, h`                   get/set view's size
`view:anchors(anchors) /-> anchors`          get/set anchors
`view:rect_changed(x, y, w, h)`              event: view's size and/or position changed
`view:moved(x, y, oldx, oldy)`               event: view was moved
`view:resized(w, h, oldw, oldh)`             event: view was resized
__keyboard__
`app:key(query) -> t|f`                      get key pressed and toggle states
`win:keydown(key)`                           event: a key was pressed
`win:keyup(key)`                             event: a key was depressed
`win:keypress(key)`                          event: sent after each keydown, including repeats
`win:keychar(s)`                             event: input char pressed; _`s`_ is utf-8
__mouse__
`app/win/view:mouse(var) -> val`             mouse state: _x, y, pos, inside, left, right, middle, x1, x2_
`win/view:mouseenter(x, y)`                  event: mouse entered the client area of the window
`win/view:mouseleave()`                      event: mouse left the client area of the window
`win/view:mousemove(x, y)`                   event: mouse was moved
`win/view:mousedown(button, x, y, count)`    event: mouse button was pressed
`win/view:mouseup(button, x, y, count)`      event: mouse button was depressed
`win/view:click(button, count, x, y)`        event: mouse button was clicked
`win/view:mousewheel(delta, x, y, pdelta)`   event: mouse wheel was moved
`win/view:hmousewheel(delta, x, y, pdelta)`  event: mouse horizontal wheel was moved
`app:double_click_time() -> time`            double click time
`app:double_click_target_area() -> w, h`     double click target area
__rendering__
`win/view:repaint()`                         event: window needs redrawing
`win/view:invalidate()`                      request window redrawing
`win/view:bitmap() -> bmp`                   get a bgra8 [bitmap] object to draw on
`bmp:clear()`                                fill the bitmap with zero bytes
`bmp:cairo() -> cr`                          get a cairo context on the bitmap
`win/view:free_cairo(cr)`                    event: cairo context needs freeing
`win/view:free_bitmap(bmp)`                  event: bitmap needs freeing
`win/view:gl() -> gl`                        get an OpenGL context to draw with
__menus__
`app:menu() -> menu`                         create a menu (or menu bar)
`app:menubar() -> menu`                      get app's menu bar (OSX)
`win:menubar(menu|nil) /-> menu|nil`         get/set/remove window's menu bar (Windows, Linux)
`win/view:popup(menu, cx, cy)`               pop up a menu relative to a window or view
`menu:popup(win/view, cx, cy)`               pop up a menu relative to a window or view
`menu:add(...)`
`menu:set(...)`
`menu:remove(index)`
`menu:get(index) -> item`                    get the menu item at index
`menu:get(index, prop) -> val`               get the value of a property of the menu item at index
`menu:items([prop]) -> {item1, ...}`
`menu:checked(index, t|f) /-> t|f`           get/set a menu item's checked state
__icons (common API)__
`icon:free()`
`icon:bitmap() -> bmp`                       get a bgra8 [bitmap] object
`icon:invalidate()`                          request bitmap redrawing
`icon:repaint()`                             event: bitmap needs redrawing
`icon:free_bitmap(bmp)`                      event: bitmap needs freeing
__notification icons__
`app:notifyicon(t) -> icon`
`app:notifyicons() -> {icon1, ...}`          list notification icons
`icon:tooltip(s) /-> s`                      get/set icon's tooltip
`icon:menu(menu) /-> menu`                   get/set icon's menu
`icon:text(s) /-> s`                         get/set text (OSX)
`icon:length(n) /-> n`                       get/set length (OSX)
__window icon (Windows)__
`win:icon([which]) -> icon`                  window's icon ('big'); which can be: 'big', 'small'
__dock icon (OSX)__
`app:dockicon() -> icon`
__file choose dialogs__
`app:opendialog(t) -> path|{path1,...}|nil`  open a standard "open file" dialog
`app:savedialog(t) -> path|nil`              open a standard "save file" dialog
__clipboard__
`app:getclipboard(format) -> data|nil`       get data in clipboard (format is 'text', 'files', 'bitmap')
`app:getclipboard() -> formats`              get data formats in clipboard
`app:setclipboard(f|data[, format])`         clear or set clipboard
__drag & drop__
`win/view:dropfiles(x, y, files)`            event: files are dropped
`win/view:dragging('enter',t,x,y) -> s`      event: mouse enter with payload
`win/view:dragging('hover',t,x,y) -> s`      event: mouse move with payload
`win/view:dragging('drop',t,x,y)`            event: dropped the payload
`win/view:dragging('leave')`                 event: mouse left with payload
__events__
`app/win/view:on(event, func)`               call _func_ when _event_ happens
`app/win/view:off(event)`                    remove event handlers
`app/win/view:fire(event, args...) -> ret`   fire an event
`app/win/view:events(enabled) -> prev_state` enable/disable events
`app/win/view:event(name, args...)`          meta-event fired on every other event
__version checks__
`app:ver(query) -> t|f`                      check OS _minimum_ version (eg. 'OSX 10.8')
__extending__
`nw.backends -> {os -> module_name}`         default backend modules for each OS
`nw:init([backend_name])`                    init with a specific backend (can be called only once)
-------------------------------------------- -----------------------------------------------------------------------------

## The app object

The global app object is the API from which everything else gets created.

### `nw:app() -> app`

Get the global application object.

This calls `nw:init()` which initializes the library with the default
backend for the current platform.

## The app loop

### `app:run()`

Start the application main loop.

Calling run() when the loop is already running does nothing.

### `app:stop()`

Stop the loop.

Calling stop() when the loop is not running does nothing.

### `app:running() -> t|f`

Check if the loop is running.

### `app:poll([timeout]) -> t|f`

Process the next pending event from the event queue.
Returns `true` if there was an event to process, `false` if there wasn't.
Returns `false, exit_code` if the application was asked to quit.
`timeout` (default=0) specifies a maximum wait time for an event to appear.

### `app:maxfps(fps|false)` <br> `app:maxfps() -> fps|false`

Get/set the maximum window repaint rate (frames per second).
`false` disables the throttling. The default is `60`.

## Quitting

### `app:quit()`

Quit the app, i.e. close all windows and stop the loop.

Quitting is a multi-phase process:

1. the `app:quitting()` event is fired. If it returns false, quitting is aborted.
2. the `win:closing()` event is fired on all non-parented windows.
   If any of them returns false, quitting is aborted.
3. `win:close(true)` is called on all windows (in reverse-creation order).
   If new windows are created during this process, quitting is aborted.
4. the app loop is stopped.

Calling `quit()` when the loop is not running or while quitting
is in progress does nothing.

### `app:autoquit() -> t|f` <br> `app:autoquit(t|f)`

Get/set the app autoquit flag (default: true).
When this flag is true, the app quits when the last window is closed.

### `app:quitting() -> [false]`

Event: the app wants to quit, but nothing was done to that effect.
Return false from this event to cancel the process.

### `win:autoquit() -> t|f` <br> `win:autoquit(t|f)`

Get/set the window autoquit flag (default: false).
When this flag is true, the app quits when the window is closed.
This flag can be used on the app's main window if there is such a thing.

## Timers

### `app:runevery(seconds, func)`

Run a function on a recurrent timer.
The timer can be stopped by returning false from the function.

### `app:runafter(seconds, func)`

Run a function on a timer once.

### `app:run(func)`

Run a function on a zero-second timer, once, inside a coroutine.
This allows calling `app:sleep()` inside the function (see below).

If the loop is not already started, it is started and then stopped after
the function finishes.

### `app:sleep(seconds)`

Sleep without blocking from inside a function that was run via app:run().
While the function is sleeping, other timers and events continue
to be processed.

This is poor man's multi-threading based on timers and coroutines.
It can be used to create complex temporal sequences withoug having to chain
timer callbacks.

Calling sleep() outside an app:run() function raises an error.

## Window tracking

### `app:windows() -> {win1, ...}` <br> `app:windows('#'[, filter]) -> n`

Get all windows in creation order.

If '#' is given, get the number of windows (dead or alive) instead.
If `filter` is 'root' the return the number of non-dead non-parented windows.

### `app:window_created(win)`

Event: a window was created.

### `app:window_closed(win)`

Event: a window was closed.

## Creating windows

### `app:window(t) -> win`

Create a window (fields of _`t`_ below with default value in parenthesis):

* __position__
	* `x`, `y`                   - frame position
	* `w`, `h`                   - frame size
	* `cx`, `cy`                 - client area position
	* `cw`, `ch`                 - client area size
	* `min_cw`, `min_ch`         - min client rect size (1, 1)
	* `max_cw`, `max_ch`         - max client rect size
* __state__
	* `visible`                  - start visible (true)
	* `minimized`                - start minimized (false)
	* `maximized`                - start maximized (false)
	* `enabled`                  - start enabled (true)
* __frame__
	* `frame`                    - frame type: 'normal', 'none', 'toolbox' ('normal')
	* `title`                    - title ('')
	* `transparent`              - transparent window (false)
	* `corner_radius`            - rounded corners (0)
* __behavior__
	* `parent`                   - parent window
	* `sticky`                   - moves with parent (false)
	* `topmost`                  - stays on top of other non-topmost windows (false)
	* `minimizable`              - allow minimization (true)
	* `maximizable`              - allow maximization (true)
	* `closeable`                - allow closing (true)
	* `resizeable`               - allow resizing (true)
	* `fullscreenable`           - allow fullscreen mode (true)
	* `activable`                - allow activation (true)
	* `autoquit`                 - quit the app on closing (false)
	* `edgesnapping`             - magnetized edges ('screen')
* __rendering__
	* `opengl`                   - enable and [configure OpenGL](#winviewgl---gl) on the window
* __menu__
	* `menu`                     - the menu bar

### Initial size and position

You can pass any combination of `x`, `y`, `w`, `h`, `cx`, `cy`, `cw`, `ch`
as long as you pass the width and the height in one way or another.
The position is optional and it defaults to OS-driven cascading.

Additionally, `x` and/or `y` can be `'center-main'` or `'center-active'`
which will center the window on the main or active display respectively.

If the size is max-constrained by either `max_cw`, `max_ch`
or `resizeable = false` then `maximizable = false` and
`fullscreenable = false` must also be set.

Expect the OS to adjust the window size and/or position in unspecified
ways for off-screen windows, windows too small to fit all titlebar buttons,
windows with zero or negative client size or windows that are very large.
Some adjustments are delayed to when the window is shown.

### The window state

The window state is the combination of multiple flags (`minimized`,
`maximized`, `fullscreen`, `visible`, `active`) plus its position, size
and frame in current state (`client_rect` and `frame_rect`), and in normal
state (`normal_frame_rect`).

State flags are independent of each other, so they can be in almost
any combination at the same time. For example, a window which starts
with `{visible = false, minimized = true, maximized = true}`
is initially hidden. If later made visible with `win:show()`,
it will show minimized. If the user then unminimizes it, it will restore
to maximized state. Throughout all these stages the `maximized` flag
is `true`.

### Coordinate systems

  * window-relative positions are relative to the top-left corner of the window's client area.
  * screen-relative positions are relative to the top-left corner of the main screen.

## Child windows

Child windows (`parent = win`) are top-level windows (so framed, not clipped)
that stay on top of their parent, minimize along with their parent,
and don't appear in the taskbar.

The following defaults are different for child windows:

  * `minimizable`: false (must be false)
  * `maximizable`: false
  * `fullscreenable`: false
  * `edgesnapping`: 'parent siblings screen'
  * `sticky`: true

Child windows can't be minimizable because they don't appear in the taskbar
(they minimize when their parent is minimized). Child windows remain
visible if their parent is hidden (or is created hidden).

### `win:parent() -> win|nil`

Get the window's parent (read-only).

### `win:children() -> {win1, ...}`

Get the window's children (those whose parent() is this window).

### Sticky windows

Sticky windows (`sticky = true`) follow their parent when their parent is moved.

__NOTE:__ Sticky windows [don't work](https://github.com/luapower/nw/issues/27) on Linux.

### `win:sticky() -> t|f`

Get the sticky flag (read-only).

### Toolbox windows

Toolbox windows (`frame = 'toolbox'`) show a thin title bar on Windows
(they show a normal frame on OSX and Linux). They must have a parent.

## Transparent windows

Transparent windows (`transparent = true`) allow using the full alpha channel
when drawing on them. They also come with serious limitations (mostly from Windows):

  * they can't be framed so you must pass `frame = 'none'`.
  * they can't have views.
  * you can't draw on them using OpenGL.

Despite these limitations, transparent windows are the only way to create
free-floating tooltips and custom-shaped notification windows.

### `win:transparent() -> t|f`

Get the transparent flag (read-only).

## Window closing

Closing the window destroys it by default.
You can prevent that by returning false in the `win:closing()` event:

~~~{.lua}
function win:closing()
	self:hide()
	return false --prevent destruction
end
~~~

### `win:close([force])`

Close the window and destroy it. Children are closed first.
The `force` arg allows closing the window without firing
the `win:closing()` event.

Calling `close()` on a closed window does nothing.
Calling any other method raises an error.

### `win:dead() -> t|f`

Check if the window was destroyed.

### `win:closing()`

Event: The window is about to close.
Return false from the event handler to refuse.

### `win:closed()`

Event: The window was closed.
Fired after all children are closed, but before the window itself
is destroyed (`win:dead()` still returns false at this point).

### `win:closeable() -> t|f`

Get the closeable flag (read-only).

## Window & app activation

Activation is about app activation and window activation. Activating a
window programatically has an immediate effect only while the app is active.
If the app is inactive, the window is not activated until the app becomes
active and the user is notified in some other less intrusive way.

If the user activates a different app in the interval between app launch
and first window being shown, the app won't be activated back (this is a good
thing usability-wise). This doesn't work on Linux (new windows always pop
in your face because there's no concept of an "app" really in X).

### `app:active() -> t|f`

Check if the app is active.

### `app:activate([mode])`

Activate the app, which activates the last window that was active
before the app got deactivated.

The _mode_ arg can be:

  * 'alert' (default; Windows and OSX only; on Linux it does nothing)
  * 'force' (OSX and Linux only; on Windows it's the same as 'alert')
  * 'info'  (OSX only; on Windows it's the same as 'alert'; on Linux it does nothing)

The 'alert' mode: on Windows, this flashes the window on the taskbar until
the user activates the window. On OSX it bounces the dock icon until the user
activates the app. On Linux it does nothing.

The 'force' mode: on Windows this is the same as the 'alert' mode.
On OSX and Linux it pops up the window in the user's face
(very rude, don't do it).

The 'info' mode: this special mode allows bouncing up the dock icon
on OSX only once. On other platforms it's the same as the default 'alert' mode.

### `app:activated()` <br> `app:deactivated()`

Event: the app was activated/deactivated.

### `app:active_window() -> win|nil`

Get the active window, if any (nil if the app is inactive).

### `win:active() -> t|f`

Check if the window is active (false for all windows if the app is inactive).

### `win:activate()`

Activate the window. If the app is inactive, this does _not_ activate the window.
Instead it only marks the window to be activated when the app becomes active.
If you want to alert the user that it should pay attention to the app/window,
call `app:activate()` after calling this function.

### `win:activated()` <br> `win:deactivated()`

Event: window was activated/deactivated.

### `win:activable() -> t|f`

Get the activable flag (read-only). This is useful for creating popup menus
that can be clicked on without stealing keyboard focus away from the main
window.

__NOTE:__ Only works with frameless windows.

__NOTE:__ This [doesn't work](https://github.com/luapower/nw/issues/26) in Linux.

## App visibility (OSX)

### `app:visible() -> t|f` <br> `app:visible(t|f)` <br> `app:hide()` <br> `app:unhide()`

Get/set app visibility.

### `app:hidden()` <br> `app:unhidden()`

Event: app was hidden/unhidden.

## Window state

### `win:show()`

Show the window in its previous state (which can include any combination
of minimized, maximized, and fullscreen state flags).

When a hidden window is shown it is also activated, except if it was
previously minimized, in which case it is shown in minimized state
without being activated.

Calling show() on a visible (which includes minimized) window does nothing.

### `win:hide()`

Hide the window from the screen and from the taskbar, preserving its full state.

Calling hide() on a hidden window does nothing.

### `win:visible() -> t|f`

Check if a window is visible (note: that includes minimized).

### `win:visible(t|f)`

Calls `show()` or `hide()` to change the window's visibility.

### `win:shown()` <br> `win:hidden()`

Event: window was shown/hidden.

### `win:minimizable() -> t|f`

Get the minimizable flag (read-only).

### `win:isminimized() -> t|f`

Get the minimized state. This flag remains true when a minimized window is hidden.

### `win:minimize()`

Minimize the window and deactivate it. If the window is hidden,
it is shown in minimized state (and the taskbar button is not activated).

### `win:minimized()` <br> `win:unminimized()`

Event: window was minimized/unminimized.

### `win:maximizable() -> t|f`

Get the maximizable flag (read-only).

### `win:ismaximized() -> t|f`

Get the maximized state. This flag stays true if a maximized window
is minimized, hidden or enters fullscreen mode.

### `win:maximize()`

Maximize the window and activate it. If the window was hidden,
it is shown in maximized state and activated.

If the window is already maximized it is not activated.

### `win:maximized()` <br> `win:unmaximized()`

Event: window was maximized/unmaximized.

### `win:fullscreenable() -> t|f`

Check if a window is allowed to go in fullscreen mode (read-only).
This flag only affects OSX - the only platform which presents a fullscreen
button on the title bar. Fullscreen mode can always be engaged programatically.

### `win:fullscreen() -> t|f`

Get the fullscreen state.

### `win:fullscreen(t|f)`

Enter or exit fullscreen mode and activate the window. If the window is hidden
or minimized, it is shown in fullscreen mode and activated.

If the window is already in the desired mode it is not activated.

### `win:entered_fullscreen()` <br> `win:exited_fullscreen()`

Event: entered/exited fullscreen mode.

### `win:restore()`

Restore from minimized, maximized or fullscreen state, i.e. unminimize
if the window was minimized, exit fullscreen if it was in fullscreen mode,
or unmaximize it if it was maximized (otherwise do nothing).

The window is always activated unless it was in normal mode.

### `win:shownormal()`

Show the window in normal state.

The window is always activated even when it's already in normal mode.

State tracking is about getting and tracking the entire user-changeable
state of a window (of or the app) as a whole.

### `win:changed(old_state, new_state)`

Event: window user-changeable state (i.e. any of the `visible`, `minimized`,
`maximized`, `fullscreen` or `active` flags) has changed.

### `app:changed(old_state, new_state)`

Event: app user-changeable state (i.e. the `visible` or `active` flag) has
changed.

### `win:enabled() -> t|f` <br> `win:enabled(t|f)`

Get/set the enabled flag (default: true). A disabled window cannot receive
mouse or keyboard focus. Disabled windows are useful for implementing
modal windows: make a child window and disable the parent while showing
the child, and enable back the parent when closing the child.

__NOTE:__ This [doesn't work](https://github.com/luapower/nw/issues/25) on Linux.

## Frame extents

### `app:frame_extents(frame, has_menu) -> left, top, right, bottom`

Get the frame extents for a certain frame type.
If `has_menu` is true, then the window also has a menu.

### `app:client_to_frame(frame, has_menu, x, y, w, h) -> x, y, w, h`

Given a client rectangle, return the frame rectangle for a certain
frame type. If `has_menu` is true, then the window also has a menu.

### `app:frame_to_client(frame, has_menu, x, y, w, h) -> x, y, w, h`

Given a frame rectangle, return the client rectangle for a certain
frame type. If `has_menu` is true, then the window also has a menu.

## Size and position

### `win:client_rect() -> cx, cy, cw, ch` <br> `win:client_rect(cx, cy, cw, ch)` <br> `win:frame_rect() -> x, y, w, h` <br> `win:frame_rect(x, y, w, h)` <br> `win:client_size() -> cw, ch` <br> `win:client_size(cw, ch)`

Get/set the client/frame rect/size in screen coordinates.

When getting: returns nothing if the window is minimized.

When setting: if any of the arguments is nil or false, it is replaced with
the current value of that argument to allow for partial changes. Does nothing
if the window is minimized, maximized, or in fullscreen mode.

### `win/view:to_screen(x, y) -> x, y` <br> `win/view:to_client(x, y) -> x, y`

Convert a point from client space to screen space and viceversa
based on client_rect().

### `win:normal_frame_rect() -> x, y, w, h`

Get the frame rect in normal state (in screen coordinates).
Unlinke client_rect() and frame_rect(), this always returns a rectangle.
This is useful for recreating a window in its previous state which
includes the normal frame rectangle, the maximized flag, and optionally
the minimized flag. It doesn't include the fullscreen flag
(you cannot create a window in fullscreen mode but you can enter fullscreen
mode afterwards).

### `win:sizing(when, how, rect) -> true|nil`

Event: window size/position is about to change. The `rect` arg is a table
with the fields _x, y, w, h_. Change these values in the table to affect
the window's final size and position (and optionally return true to stop
calling the following event handlers).

__NOTE:__ This event does not fire in Linux.

### `win:client_rect_changed(cx, cy, cw, ch, oldcx, oldcy, oldcw, oldch)` <br> `win:client_moved(cx, cy, oldcx, oldcy)` <br>  `win:client_resized(cw, ch, oldcw, oldch)` <br> `win:frame_rect_changed(x, y, w, h, oldx, oldy, oldw, oldh)` <br> `win:frame_moved(x, y, oldx, oldy)` <br> `win:frame_resized(w, h, oldw, oldh)`

Event: window was moved/resized. These events also fire when a window is
hidden or minimized in which case all args are nil, so make sure to test for that.

### `win:hittest(x, y, where) -> where`

Hit test for moving and resizing frameless windows. Return 'left', 'top',
'right', 'bottom', 'topleft', 'bottomright', 'topright' or 'bottomleft'
to specify that the window should be resized, 'move' which means the window
should be moved, false which means the coordinates are over the client area,
or nil which means that standard resizing should take place. The `where`
arg is the default response for the given coordinates.

## Size constraints

### `win:resizeable() -> t|f`

Check if the window is resizeable.

### `win:minsize() -> cw, ch` <br> `win:minsize(cw, ch)` <br> `win:minsize(false)`

Get/set/clear the minimum client rect size.

The constraint can be applied to one dimension only by passing false or nil
for the other dimension. The window is resized if it was smaller than this size.
The size is clamped to maxsize if that is set. The size is finally clamped to
the minimum (1, 1) which is also the default.

### `win:maxsize() -> cw, ch` <br> `win:maxsize(cw, ch)` <br> `win:maxsize(false)`

Get/set/clear the maximum client rect size.

The constraint can be applied to one dimension only by passing false or nil
for the other dimension. The window is resized if it was larger than this size.
The size is clamped to minsize if that is set. Trying to set this on a
maximizable or fullscreenable window raises an error.

## Edge snapping

### `win:edgesnapping() -> mode` <br> `win:edgesnapping(mode)`

Get/set edge snapping mode, which is a string containing any combination
of the following words separated by spaces:

  * 'app' - snap to app's windows
  * 'other' - snap to other apps' windows
  * 'parent' - snap to parent window
  * 'siblings' - snap to sibling windows
  * 'screen' - snap to screen edges
  * 'all' - equivalent to 'app other screen'

__NOTE:__ Edge snapping doesn't work on Linux because the `win:sizing()`
event doesn't fire there. It is however already (poorly) implemented
by some window managers (eg. Unity) so all is not lost.

### `win:magnets(which) -> {r1, ...}`

Event: get edge snapping rectangles (rectangles are tables with fields _x, y, w, h_).

## Z-Order

### `win:topmost() -> t|f` <br> `win:topmost(t|f)`

Get/set the topmost flag. A topmost window stays on top of all other
non-topmost windows.

### `win:raise([rel_to_win])`

Raise above all windows/specific window.

### `win:lower([rel_to_win])`

Lower below all windows/specific window.

## Window title

### `win:title() -> title` <br> `win:title(title)`

Get/set the window's title.

## Displays

In multi-monitor setups, the non-mirroring displays are mapped
on a virtual surface, with the main display's top-left corner at (0, 0).

### `app:displays() -> {disp1, ...}` <br> `app:displays'#' -> n`

Get displays (in no specific order). Mirroring displays are not included.
If '#' is given, get the display count instead.

### `app:main_display() -> disp`

Get the display whose screen rect is at (0, 0).

### `app:active_display() -> disp`

Get the display which contains the active window, falling back to the main
display if there is no active window.

### `disp:screen_rect() -> x, y, w, h` <br> `disp.x, disp.y, disp.w, disp.h`

Get the display's screen rectangle.

### `disp:desktop_rect() -> cx, cy, cw, ch` <br> `disp.cx, disp.cy, disp.cw, disp.ch`

Get the display's desktop rectangle (screen minus any taskbars).

__NOTE:__ This doesn't work in Linux for secondary monitors (it gives the screen rect).

### `app:displays_changed()`

Event: displays changed.

### `win:display() -> disp|nil`

Get the display the window is currently on. Returns nil if the window
is off-screen. Returns the correct display based on the window's coordinates
even if the window is hidden.

## Cursors

### `win:cursor() -> name, t|f` <br> `win:cursor(name|t|f)`

Get/set the mouse cursor and/or visibility. The name can be:

  * 'arrow' (default)
  * 'text'
  * 'hand'
  * 'cross'
  * 'forbidden'
  * 'size_diag1' (i.e. NE-SW, forward-slash-looking)
  * 'size_diag2' (i.e. NW-SE, backslash-looking)
  * 'size_h'
  * 'size_v'
  * 'move'
  * 'busy_arrow'
  * 'top', 'left', 'right', 'bottom', 'topleft', 'topright',
  'bottomleft', 'bottomright' (only different in Linux)

## Keyboard

See [nw_keyboard] for the list of key names.

### `app:key(query) -> t|f`

Get key pressed and toggle states. The query can be one or more
key names separated by spaces or by `+` eg. 'alt+f3' or 'alt f3'.
The key name can start with `^` in which case the toggle state of that key
is queried instead eg. '^capslock' returns the toggle state of the
caps lock key while 'capslock' returns its pressed state.
(only the capslock, numlock and scrolllock keys have toggle states).

### `win:keydown(key)`

Event: a key was pressed (not sent on repeat).

### `win:keyup(key)`

Event: a key was depressed.

### `win:keypress(key)`

Event: sent after keydown and on key repeat.

### `win:keychar(s)`

Event: sent after keypress for displayable characters; _`s`_ is a utf-8
string and can contain one or more code points.

## Hi-DPI support

By default, windows contents are scaled by the OS on Hi-DPI screens,
so they look blurry but they are readable even if the app is unaware
that it is showing on a dense screen. Making the app Hi-DPI-aware means
telling the OS to disable this automatic raster scaling and allow the
app to scale the UI itself (but this time in vector space) in order
to make it readable again on a dense screen.

### `app:autoscaling() -> t|f`

Check if autoscaling is enabled.

### `app:autoscaling(t|f)`

Enable/disable autoscaling.

__NOTE:__ This function must be called before the OS stretcher kicks in,
i.e. before creating any windows or calling any display APIs.
It will silently fail otherwise.

### `disp.scalingfactor`

The display's scaling factor is an attribute of display objects.
This is 1 when autoscaling is enabled and > 1 when disabled
and the display is hi-dpi.

If autoscaling is disabled, windows must check their display's
scaling factor and scale the UI accordingly.

### `win:scalingfactor_changed()`

A window's display scaling factor changed or most likely the window
was moved to a screen with a different scaling factor.

## Views

A view object defines a rectangular region within a window for drawing
and receiving mouse events.

Views allow partitioning a window's client area into multiple non-overlapping
regions that can be rendered using different technologies.
In particular, you can use OpenGL on some views, while using bitmaps
(and thus cairo) on others. This presents a simple solution to the problem
of drawing an antialiased 2D UI around a 3D scene as an alternative to
drawing on the textures of orto-projected quads. Views also allow placing
native widgets alongside custom-painted areas on the same window.

__NOTE:__ If you use views, bind all mouse events to the views.
Do not mix window and view mouse events since the behavior of window
mouse events in the presence of views is
[not consistent](https://github.com/luapower/nw/issues/54)
between platforms.

### `win:views() -> {view1, ...}` <br> `win:views'#' -> n`

Get the window's views. If '#' is given, get the view count instead.

### `win:view(t) -> view`

Create a view (fields of _`t`_ below):

* `x`, `y`, `w`, `h`	- view's position (in window's client space) and size
* `visible`				- start visible (default: true)
* `anchors`				- resizing anchors (default: 'lt'); can be 'ltrb'
* `opengl`				- enable and [configure OpenGL](#winviewgl---gl) on the view.

__NOTE:__ The width and height are clamped to the minimum (1, 1).

### `view:free()`

Destroy the view.

### `view:dead() -> t|f`

Check if the view was destroyed.

### `view:visible() -> t|f` <br> `view:visible(t|f)` <br> `view:show()` <br> `view:hide()`

Get/set the view's visibility.

The position and size of the view are preserved while hidden (anchors keep working).

### `view:rect() -> x, y, w, h` <br> `view:rect(x, y, w, h)`

Get/set the view's position (in window's client space) and size.

The view rect is valid and can be changed while the view is hidden.

### `view:size() -> w, h` <br> `view:size(w, h)`

Get/set the view's size.

### `view:anchors() -> anchors` <br> `view:anchors(anchors)`

Get/set the anchors: they can be any combination of 'ltrb' characters
representing left, top, right and bottom anchors respectively.

Anchors are a simple but effective way of doing stitched layouting.
This is how they work: there's four possible anchors which you can set,
one for each side of the view. Setting an anchor on one side fixates
the distance between that side and the same side of the window
the view is on, so that when the window is moved/resized, the view
is also moved/resized in order to preserve the initial distance
to that side of the window.

### `view:rect_changed(x, y, w, h)` <br> `view:moved(x, y)` <br> `view:resized(w, h)`

Event: view's size and/or position changed.

## Mouse

### `win/view:mouse(var) -> val`

Get the mouse state. The `var` arg can be:
'x', 'y', 'pos', 'inside', 'left', 'right', 'middle', 'x1', 'x2'.

The mouse state is not queried: it is the state at the time of the last
mouse event. Returns nothing if the window is hidden or minimized.

Mouse coordinates are relative to the window's client-area.

### `win/view:mouseenter()` <br> `win/view:mouseleave()`

Event: mouse entered/left the client area of the window.

These events do not fire while the mouse is captured (see mousedown)
but a mouseleave event _will_ fire after mouseup _if_ mouseup happens
outside the client area of the window/view that captured the mouse.

### `win/view:mousemove(x, y)`

Event: the mouse was moved.

### `win/view:mousedown(button, x, y, click_count)`

Event: a mouse button was pressed; button can be 'left', 'right', 'middle', 'x1', 'x2'.

While a mouse button is down, the mouse is _captured_ by the window/view
which received the mousedown event, which means that the same window/view
will continue to receive mousemove events even if the mouse leaves
its client area.

### `win/view:mouseup(button, x, y, click_count)`

Event: a mouse button was depressed.

### `win/view:click(button, count, x, y)`

Event: a mouse button was clicked (fires immediately after mousedown).

### Repeated clicks

#### TL;DR

~~~{.lua}
function win:click(button, count, x, y)
	if count == 2 then     --double click
		...
	elseif count == 3 then --triple click
		...
		return true         --triple click is as high as we go in this app
	end
end
~~~

#### How it works

When the user clicks the mouse repeatedly, with a small enough interval
between clicks and over the same target, a counter is incremented.
When the interval between two clicks is larger than the threshold
or the mouse is moved too far away from the initial target,
the counter is reset (i.e. the click-chain is interrupted).
Returning `true` on the `click()` event also resets the counter.

This allows processing of double-clicks, triple-clicks, or multi-clicks
by checking the `count` argument on the `click()` event. If your app
doesn't need to process double-clicks or multi-clicks, you can just ignore
the `count` argument. If it does, you must return `true` after processing
the event with the highest count so that the counter is reset.

For instance, if your app supports double-click over some target,
you must return `true` when count is 2, otherwise you might get a count of 3
on the next click sometimes, instead of 1 as expected. If your app
supports both double-click and triple-click over a target,
you must return `true` when the count is 3 to break the click chain,
but you must not return anything when the count is 2,
or you'll never get a count of 3.

The double-click time interval is from the user's mouse settings
and it is queried on every click.

### `win/view:mousewheel(delta, x, y, pixeldelta)` <br> `win/view:mousehwheel(delta, x, y, pixeldelta)`

Event: the mouse vertical or horizontal wheel was moved.
The delta represents the number of lines to scroll.

The number of lines per scroll notch is from the user's mouse settings
and it is queried on every wheel event (Windows, OSX).

The extra `pixeldelta` arg is given on OSX on devices where analog scrolling
is available, in which case that value should be used instead.

## Rendering

Drawing on a window or view must be done inside the `repaint()` event
by requesting the window/view's bitmap or OpenGL context and drawing on it.
The OS fires `repaint` whenever it loses (part of) the contents
of the window. To force a repaint anytime, use `win:invalidate()`.

__NOTE:__ You can't request a bitmap on an OpenGL-enabled window/view
and you can't request an OpenGL context on a non-OpenGL-enabled window/view.
To enable OpenGL on a window/view you must pass an `opengl` options table
to the window/view creation function (it can be an empty table or just `true`).

### `win/view:repaint()`

Event: window needs redrawing. To redraw the window, simply request
the window's bitmap or OpenGL context and draw using that.

### `win/view:invalidate()`

Request redrawing.

### `win/view:bitmap() -> bmp`

Get a bgra8 [bitmap] object to draw on. The bitmap is freed and replaced when
the window's client area changes size. The bitmap must be requested inside
the `repaint()` event for drawing purposes, but can also be requested outside
the `repaint()` event for hit-testing purposes.

The alpha channel is not used unless this is a transparent window
(note: views cannot be transparent).

### `bmp:clear()`

Fill the bitmap with zeroes.

### `bmp:cairo() -> cr`

Get a [cairo] context on the bitmap. The context lasts as long as the bitmap lasts.

### `win/view:free_cairo(cr)`

Event: cairo context needs to be freed.

### `win/view:free_bitmap(bmp)`

Event: bitmap needs to be freed.

### `win/view:gl() -> gl`

Get an OpenGL context/API to draw on the window or view. For this to work
OpenGL must be enabled on the window or view via the `opengl` options table,
which can have the fields:

  * `profile`       - OpenGL profile to use: '1.0', '3.2' ('1.0')
  * `antialiasing`  - enable antialiasing: 'supersample', 'multisample', true, false (false)
  * `samples`       - number of samples for 'multisample' antialiasting (4)
  * `vsync`         - vertical sync: true, false, swap-interval (true)

## Menus

### `app:menu() -> menu`

Create a menu.

### `app:menubar() -> menu`

Get the app's menu bar (OSX)

### `win:menubar() -> menu|nil` `win:menubar(menu|nil)`

Get/set/remove the window's menu bar (Windows, Linux).

### `win/view:popup(menu, cx, cy)` <br> `menu:popup(win/view, cx, cy)`

Pop up a menu at a point relative to a window or view.

### `menu:add([index, ]text, [action], [options])` <br> `menu:set(index, text, [action], [options])` <br> `menu:add{index =, text =, action =, <option> =}` <br> `menu:set{index =, text =, action =, <option> =}`

Add/set a menu item. The options are:

* `action` - can be a function or another menu to be used as a submenu
* `text` - the text to display:
	* `&` before a letter creates an _access key_
	* `\t` followed by a key combination creates a _shortcut key_
	* the empty string (the default) creates a separator
	* eg. `'&Close\tAlt+F4'` shows as '<u>C</u>lose Alt+F4' and activates on `Alt+C` and on `Alt+F4`
* `submenu` - a submenu (same as when `action` is a submenu)
* `enabled` - enabled state (true)
* `checked` - checked state (false)

### `menu:remove(index)`

Remove menu item at index.

### `menu:get(index) -> item` <br> `menu:get(index, prop) -> val`

Get a menu item, or the value of one of its properties.

### `menu:items([prop]) -> {item1, ...}` <br> `menu:items'#' -> n`

Get the menu items. If a property name is given, pluck the values of that
property from the menu items instead. If '#' is given, get the item count instead.

### `menu:checked(index) -> t|f` <br> `menu:checked(index, t|f)`

Get/set the checked state of a menu item.

## Icons

### Common API

### `icon:free()`

Free the icon.

### `icon:bitmap() -> bmp`

Get the icon's bitmap.

### `icon:invalidate()`

Request icon redrawing.

### `icon:repaint()`

Event: icon needs redrawing.

### `icon:free_bitmap(bmp)`

Event: the icon's bitmap needs to be freed.

### Window icon (Windows)

### `win:icon([which]) -> icon`

Get the window's icon. The `which` arg can be: 'big' (default), 'small'.

### Dock icon (OSX)

### `app:dockicon() -> icon`

Get the app's dock icon.

### Notification icons (Windows, OSX)

### `app:notifyicon(t) -> icon`

Create a notification icon.

### `app:notifyicons() -> {icon1, ...}` <br> `app:notifyicons'#' -> n`

Get all the notification icons. If '#' is given, get the icon count instead.

### `icon:tooltip() -> s` <br> `icon:tooltip(s)`

Get/set the icon's tooltip.

### `icon:menu() -> menu` <br> `icon:menu(menu)`

Get/set a menu for the icon.

### `icon:text() -> s` <br> `icon:text(s)`

Get/set the status bar item's text (OSX only).

### `icon:length() -> n` <br> `icon:length(n)`

Get/set the status bar item's length (OSX only).

## File choose dialogs

### `app:opendialog(t) -> path|{path1,...}|nil`

Open a standard "open file" dialog and wait for it to close. Fields of _`t`_:

  * `title` - dialog's title
  * `filetypes` - supported file extensions eg. `{'txt', 'jpg', ...}`
  * `multiselect` - allow multiple selection (false)
  * `initial_dir` - initial dir

When `multiselect = true` the dialog returns a list of paths,
otherwise it returns a path. If the user closes the dialog without
choosing a file, it returns ni.

### `app:savedialog(t) -> path|nil`

Open a standard "save file" dialog and wait for it to close. Fields of _`t`_:

  * `title` dialog's title
  * `filetypes` - supported file extensions eg. `{'txt', 'jpg', ...}`
  * `filename` - default filename
  * `initial_dir` - initial dir

If the user closes the dialog without choosing a file, it returns ni.

## Clipboard

### `app:getclipboard(format) -> data|nil`

Get the clipboard contents in one of the available formats. The format can be:

  * 'text' - returns a string.
  * 'files' - returns `{path1, ...}`
  * 'bitmap' - returns a [bitmap]

### `app:getclipboard() -> formats`

Get the data formats (`{format = true}`) currently in clipboard.

### `app:setclipboard(f|data[, format])`

Clear or set the clipboard. Passing `false` clears it, otherwise `data` can be:

  * a string (assuming 'text' format).
  * a bitmap (assuming 'bitmap' format).
  * a table `{format = ..., data = ...}`.
  * a list of strings (for format: 'files').

## Drag & Drop

### `win/view:dropfiles(x, y, files)`

Event: files (`{filename1, ...}`) are dropped over the window/view.

### `win/view:dragging('enter', t, x, y) -> s` <br> `win/view:dragging('hover', t, x, y) -> s` <br> `win/view:dragging('drop', t, x, y)` <br> `win/view:dragging('leave')`

Event: something is being dragged over the window/view. The first arg
corresponds to the following mouse events:

  * 'enter' - mouse enter
  * 'hover' - mouse move
  * 'drop' - mouse button up
  * 'leave' - mouse leave

The `t` arg is a table cotaining the drag payload in one or more formats:
`{format = data}`. The `x`, `y` args are the mouse coordinates in window/view
client space.

You can respond to the 'enter' and 'hover' stages by returning:

  * 'copy' - show a cursor indicating that the data is being copied
  * 'link' - show a cursor indicating that the data is being linked
  * 'none' - show the normal arrow cursor
  * 'abort' - show the forbidden icon
  * true - means 'copy'
  * false - means 'abort'
  * nil/nothing - means 'abort'

## Events

Events are a way to associate an action with one or more functions
to be called on that action. To fire an event call
`fire(event_name, args...)`. To add one or more functions to be called when
an event is fired use `on(event_name, handler)`. Those functions will be
called in the order in which they were added. If there's a method on the
target object with the same name as the event, that method will also be
called when the event fires, before any other handlers.

Extra args passed to `fire()` will be passed on to the handlers.
The first handler to return a non-nil value stops the call chain and that
value is returned to the caller who fired the event.

### `function app/win/view:`_`event_name`_`() ... end`

Method that will be fired when `event_name` is fired, before other handlers.

### `app/win/view:on(event, func)`

Call `func` when `event` is fired. Multiple functions can be attached
to the same event: they are called in the order in which they were added.

`event` can be `'event_name'`, `'event_name.namespace'` or
`{event_name, namespace}`, which tags the handler with a namespace (which is
just a convenience to aid in bulk removal of events).

### `app/win/view:off(event)`

Remove all handlers associated with an event name and/or namespace.
`event` can be `'event_name'`, `'.namespace'`, `'event_name.namespace'`,
`{event_name, namespace}`, `{nil, namespace}` or `nil/false` which removes
all events.

### `app/win/view:fire(event, ...) -> ret`

Fire an event. The `event` arg can be the name of a known event or can be
an arbitrary name. Returns the value returned by the first event handler
to return a non-nil value.

### `app/win/view:events(enabled) -> prev_state`

Enable/disable events.

### `app/win/view:event(name, args...)`

This is a meta-event fired on every other event.
The event name and args are passed in as args.

## Version checks

### `app:ver(query) -> t|f`

Check that a certain backend API is at a specified version or beyond.
The query has the form `'<API> <version>'` where API can be
'Windows', 'OSX' or 'X'.

Example: `app:ver'OSX 10.8'` returns `true` on OSX 10.8 and beyond.

For Windows you can use the following table to figure it out:

Release							Version
-------------------------- -----------
Windows 10						10.0 (6.2)
Windows Server 2016 TP		10.0 (6.2)
Windows 8.1						6.3 (6.2)
Windows Server 2012 R2		6.3 (6.2)
Windows 8						6.2
Windows Server 2012			6.2
Windows 7						6.1
Windows Server 2008 R2		6.1
Windows Server 2008			6.0
Windows Vista					6.0
Windows Server 2003 R2		5.2
Windows Server 2003			5.2
Windows XP 64-Bit Edition	5.2
Windows XP						5.1
Windows 2000					5.0

__NOTE:__ Apps not manifested for Windows 8.1 or Windows 10
will report platforms greater than 6.2 as 6.2 (the [luajit] package
comes with proper manifest files).

## Common mistakes

### Assuming that calls are blocking

The number one mistake you can make is to assume that all calls are blocking.
It's very easy to make that mistake because some of them actually are blocking
on some platforms (in order of sanity: Windows, OSX and Linux -- X11 is
particularly bad because _all_ calls are asynchronous there).
In a perfect world they would all be blocking and non-failing
which would make programming with them much more robust and intuitive.
The real world is an unspecified mess. So __never, ever mix queries
with commands__, i.e. never assume that after a state-changing function
returns you can make any assumptions about the state of the objects involved.

### Assuming that events fire in a specific order

Do not assume that events fire in a specific order. Even if they appear to
do so on one platform, that may not hold true on another platform.
For instance, do not assume that app the activation event fires before
the window activation event or that one should cause the other to fire.

### Creating windows in visible state

The `visible` flag when creating windows defaults to `true`, but you should
really create windows with `visible = false`, set up all the event handlers
on them and then call `win:show()`, otherwise you will not catch any events
that trigger before you set up the event handlers (sometimes that includes
the `repaint()` event so you will be showing a non-painted window).

### Hitting undefined behavior

One of the goals of this library is to reduce undefined behavior, but there
will always be corner cases that are not covered. If your app behaves
differently when ported to another platform, please file up a bug report.
Even for contradictory situations (like seetting a minimum size constraint
that is larger than the maxium size constraint) there should be a single
answer for all platforms, even if that answer is arbitrary.

## Getting Involved

This is one of the bigger bricks of luapower but it is one which lends
itself well to community development. The frontend uses composition rather
than inheritance to connect to the backend so the communication between the
two is always explicit. Features are well separated functionally and visually
in the code so they can be developed separately without much risk of
regressions. The code is well commented and there's unit tests and
interactive tests which cover most of the functionality. The code follows
the luapower [coding-style] and [api-design] guidelines.

### Development process

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

