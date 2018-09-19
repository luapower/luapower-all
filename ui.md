
<warn>Work in Progress</warn>

## `local ui = require'ui'`

Extensible UI toolkit written in Lua with layouts, styles and animations.

## Features

  * OMG widgets!
    * an editable grid that can scroll millions of rows at 60 fps?
	 * a tab list with animated, moveable, draggable, dockable tabs?
	 * a code editor in Lua?
	 * run the demos!
  * consistent Unicode text rendering and editing with [tr].
  * transition-based animations.
  * cascading styles with `> parent` and `:state` selectors.
  * constraint-based, container-based and flow-based layouts.
  * affine transforms.

## Programming Features

  * [object system][oo] with virtual properties and method overriding hooks.
  * layer class containing all the mechanisms necessary for making widgets.
  * comprehensive event-based drag & drop API.

## Example

~~~
local ui = require'ui'

local win = ui:window{
	cw = 500, ch = 300,
	title = 'luapower!',
}

local b = ui:button{
	x = win.cw - ui.button.w - 20,
	y = win.ch - ui.button.h - 20,
	parent = win,
	text = 'Close',
	cancel = true,
}

ui:run()
~~~

## User API

### UI Object

-------------------------------------- ---------------------------------------
__native properties__

`autoquit, maxfps, app_active,` \      these map directly to `nw:app()` \
`app_visible, caret_blink_time,` \     features, see [nw].
`displays, main_display,` \
`active_display, app_id`

__native methods__

`run, poll, stop, quit, runevery,` \   these map directly to `nw:app()` \
`runafter, sleep, activate_app,` \     features, see [nw].
`hide_app, unhide_app, key,` \
`getclipboard, setclipboard,` \
`opendialog, savedialog,` \
`app_already_running,` \
`wakeup_other_app_instances,` \
`check_single_app_instance,` \

__font registration__

`ui:add_font_file(...)`                see [tr:add_font_file(...)][tr]

`ui:add_mem_font(...)`                 see [tr:add_mem_font(...)][tr]
-------------------------------------- ---------------------------------------

### Elements

-------------------------------------- ---------------------------------------
__selectors__

TODO

__stylesheets__

TODO

__attribute types__

TODO

__transition animations__

TODO

__interpolators__

TODO

__element lists__

TODO

__tags & styles__

`elem.stylesheet`

`elem:settag(tag, on)`

`elem:settags('+tag1 -tag2 ...')`

__attribute transitions__

`elem.transition_duration = 0`

`elem.transition_ease = 'expo out'`

`elem.transition_delay = 0`

`elem.transition_repeat = 1`

`elem.transition_speed = 1`

`elem.transition_blend =` \
	`'replace_nodelay'`

`elem:transition(attr, val, dt, ` \
   `ease, duration, ease, delay,` \
   `times, backval, blend)`

`elem:transitioning(attr) -> t|f`
-------------------------------------- ---------------------------------------

### Windows

-------------------------------------- ---------------------------------------
`ui:window{...} -> win`

`win:free()`

__parent/child relationship__

`win.parent`

`win:to_parent(x, y)`

`win:from_parent(x, y)`

__native methods__

`frame_rect, client_rect,` \           these map directly to [nw] features \
`client_to_frame, frame_to_client,` \  so they are documented there.
`closing, close, show, hide,` \
`activate, minimize, maximize,` \
`restore, shownormal, raise, lower,` \
`to_screen, from_screen`

__native properties__

`x, y, w, h, cx, cy, cw, ch,` \        these map directly to [nw] features \
`min_cw, min_ch, max_cw, max_ch,` \    so they are documented there.
`autoquit, visible, fullscreen,` \
`enabled, edgesnapping, topmost,` \
`title, dead, closeable,` \
`activable, minimizable,`
`maximizable, resizeable,` \
`fullscreenable, frame,` \
`transparent, corner_radius,`
`sticky, dead, active, isminimized,` \
`ismaximized, display, cursor`

__element query interface__

`win:find(sel) -> elem_list`

`win:each(sel, f)`

__mouse state__

`win.mouse_x, win.mouse_y`

`win:mouse_pos() -> x, y`

__drawing__

`win:draw(cr)`

`win:invalidate()`

__frameless windows__

`win.move_layer`
-------------------------------------- ---------------------------------------

### Layers

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Widgets

-------------------------------------- ---------------------------------------
__input__
`ui:editbox(...)`                      editbox
`ui:dropdown(...)`                     drop-down
`ui:slider(...)`                       slider
`ui:checkbox(...)`                     check box
`ui:radiobutton(...)`                  radio button
`ui:choicebutton(...)`                 multi-choice button
`ui:colorpicker(...)`                  calendar
`ui:calendar(...)`
__output__
`ui:image(...)`                        image
`ui:progressbar(...)`                  progress bar
__input/output__
`ui:grid(...)`                         editable grid
__action__
`ui:button(...)`                       button
`ui:menu(...)`                         menu
__containers__
`ui:scrollbar(...)`                    scroll bar
`ui:scrollbox(...)`                    scroll box
`ui:popup(...)`                        pop-up window
`ui:tablist(...)`                      tab list
-------------------------------------- ---------------------------------------

__TIP:__ Widgets are implemented in separate modules. Run each module
standalone to see a demo of the widgets implemented in the module.

### Editbox

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Drop-down

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Slider

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Check box

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Radio button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Multi-choice button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Calendar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Image

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Progress bar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Editable grid

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Menu

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Scroll bar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Scroll box

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Pop-up window

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Tab list

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------
