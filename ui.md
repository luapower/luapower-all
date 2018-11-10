
## `local ui = require'ui'`

Extensible UI toolkit written in Lua featuring layouts, styles and animations.

## Status

See [issues](https://github.com/luapower/ui/issues)
and [milestones](https://github.com/luapower/ui/milestones).

## Features

  * feature-packed editable grid that can scroll millions of rows at 60 fps.
  * tab list with animated, moveable, draggable, dockable tabs.
  * highly hackable code editor written in Lua.
  * consistent Unicode [text rendering][tr] and editing on all platforms.
  * cascading styles.
  * declarative transition animations.
  * flexbox and css-grid-like layouts.
  * affine transforms.

## Example

~~~{.lua}
local ui = require'ui'

local win = ui:window{
	cw = 500, ch = 300,
	title = 'UI Demo',
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

### The `ui` object

-------------------------------------- ---------------------------------------
__native properties__

`autoquit, maxfps, app_active,` \      these map directly to nw app \
`app_visible, caret_blink_time,` \     features, so see [nw].
`displays, main_display,` \
`active_display, app_id`

__native methods__

`run, poll, stop, quit, runevery,` \   these map directly to nw app \
`runafter, sleep, activate_app,` \     features, so see [nw].
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

## Elements

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

## Windows

-------------------------------------- ---------------------------------------
`ui:window{...} -> win`

`win:free()`

__parent/child relationship__

`win.parent`

`win:to_parent(x, y)`

`win:from_parent(x, y)`

__native methods__

`frame_rect, client_rect,` \           these map directly to nw window \
`client_to_frame, frame_to_client,` \  methods, so see [nw].
`closing, close, show, hide,` \
`activate, minimize, maximize,` \
`restore, shownormal, raise, lower,` \
`to_screen, from_screen`

__native properties__

`x, y, w, h, cx, cy, cw, ch,` \        these map directly to nw window \
`min_cw, min_ch, max_cw, max_ch,` \    methods, so see [nw].
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

## Layers

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Box model

  * layers can be nested, which affects their painting order, clipping and
  positioning relative to each other.
  * layers have a "box" defined by their `x, y, w, h`, and a "content box"
  which is the same box adjusted by paddings.
  * layers are positioned and clipped relative to their parent's content box.
  * unlike html, the content box is _not_ affected by borders.
  * borders can be drawn at an offset relative to the layer's box and the
  border's thickness.
  * a layer's contents and background can be clipped by the padding box
  of its parent, or by the border inner contour of its parent, or it can be
  left unclipped.

### Mouse interaction

  * layers must be `activable` in order to receive mouse events.
  * a layer is `hot` when the mouse is over it or when it's `active`.
  * a layer must set `active` on `mousedown` and must reset it on `mouseup`
  in order to have the mouse _captured_ while a mouse button is down;
  this can be done automatically by statically setting `mousedown_activate`.
  * while a layer is `active`, it continues to be `hot` and receive
  `mousemove` events even when the mouse is outside its hit test area or
  outside the window even (that is, the mouse is captured).
  * a layer must be `active` in order to receive drag & drop events.

### Keyboard interaction

  * layers must be `focusable` in order to receive keyboard events.
  * keyboard events are only received by the focused layer.
  * return `true` in a `keydown` to eat up a key stroke so that it
  isn't used by other actions: this is how key conflicts are solved.

## Widgets

-------------------------------------- ---------------------------------------
__input__
`ui:editbox(...)`                      create an editbox
`ui:dropdown(...)`                     create a drop-down
`ui:slider(...)`                       create a slider
`ui:checkbox(...)`                     create a check box
`ui:radiobutton(...)`                  create a radio button
`ui:choicebutton(...)`                 create a multi-choice button
`ui:colorpicker(...)`                  create a calendar
`ui:calendar(...)`
__output__
`ui:image(...)`                        create an image
`ui:progressbar(...)`                  create a progress bar
__input/output__
`ui:grid(...)`                         create a grid
__action__
`ui:button(...)`                       create a button
`ui:menu(...)`                         create a menu
__containers__
`ui:scrollbar(...)`                    create a scroll bar
`ui:scrollbox(...)`                    create a scroll box
`ui:popup(...)`                        create a pop-up window
`ui:tablist(...)`                      create a tab list
-------------------------------------- ---------------------------------------

__TIP:__ Widgets are implemented in separate modules. Run each module
standalone to see a demo of the widgets implemented in the module.

## Editboxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Drop-downs

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Sliders

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Check boxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Radio buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Multi-choice buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Calendars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Images

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Progress bars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Editable grids

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Menus

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Scroll bars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Scroll boxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Pop-up windows

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Tab lists

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

# Creating new widgets

The API for creating and extending widgets is larger and more complex
than the API for instantiating and using existing widgets. This is normal,
since widgets are supposed to encapsulate complex user interaction patterns
as well as provide customizable presentation and behavior.

The main topics that need to be understood in order to create new widgets are:

 * the [object system][oo], which provides extensibility mechanisms:
	* subclassing and instantiation
	* virtual properties
	* method overriding
 * the [event system][events], which implements a generic pub-sub API
 * the `ui.object` class, which provides meta-programming facilities for:
   * memoizing methods
	* creating "stored" properties
	* creating "live" (aka "instance-only") properties
	* creating self-validating enum properties
 * the `ui.element` class, which provides a base non-visual vocabulary for:
   * applying multiple attribute value sets based on tag combinations (aka CSS)
	* time-based interpolation of attribute values (aka transition animations)
 * the `ui.layer` class, which provides a base visual vocabulary:
	* layer hierarchies with relative affine transforms and clipping
	* drawing borders, backgrounds, shadows, and aligned text
	* hit testing borders, background and content
	* layouting, including css-flexbox and css-grid-like models
 * the `ui.window` and `ui.layer` classes, which work together to provide an input API:
   * routing mouse events to the hot widget; mouse capturing
	* routing keyboard events to the focused widget; tab-based navigation
	* drag & drop API (event-based)

## The object class

  * base class, created with [oo]; inherits oo.Object.
  * inherits the [events] mixin.

## Method & property decorators

Various utilities (exposed as class methods) for changing the behavior of
specific properties and methods.

### object:memoize(method_name)

Memoize a method (which must be single-return-value).

### `object:forward_events(obj, events)`

Forward some events (`events = {event_name1, ...}`) from `obj` to `self`,
i.e. install event handlers in `obj` which forward events to `self`.

### `object:stored_property(prop, [priv])`

Create a r/w property named `prop` which reads/writes from a "private field".

### `object:nochange_barrier(prop)`

Call `prop`'s setter only when setting a diff. value than current.

### `object:track_changes(prop)`

Fire a `<prop>_changed` event when the property value changes.

### `object:instance_only(prop)`

Inhibit a property's getter and setter when using the property on the class.
instead, set a private var on the class which serves as default value.
NOTE: use this only _after_ defining the getter and setter.

### `object:enum_property(prop, values)`

Validate a property when being set against a list of allowed values.

