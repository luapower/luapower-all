
## `local ui = require'ui'`

Extensible UI toolkit written in Lua with widgets, layouts, styles and animations.

## Status

See [issues](https://github.com/luapower/ui/issues)
and [milestones](https://github.com/luapower/ui/milestones).

## Highlights

  * editable grid that can scroll millions of rows at 60 fps.
  * tab list with animated, moveable, draggable, dockable tabs.
  * extensible rich text editor with BiDi support.
  * consistent Unicode [text rendering][tr] and editing on all platforms.
  * customization with cascading styles, inheritance and composition.
  * declarative transition animations.
  * flexbox and css-grid-like layouts.

## Example

~~~{.lua}
local ui = require'ui'

local win = ui:window{
	cw = 500, ch = 300,
	title = 'UI Demo',
}

ui:button{
	x = 100,
	y = 100,
	parent = win,
	text = 'Close',
	cancel = true,
}

ui:run()
~~~

## Objects

  * provide [subclassing, overriding and virtual properties][oo]
  * provide [events]

## The `ui` module/singleton

The `ui` singleton is a thin facade over [nw]'s app singleton.
It manages the app's runtime settings, behavior, events and global resources.

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
`check_single_app_instance`

__native events__

`quitting, activated, deactivated,` \  these map directly to nw app \
`wakeup, hidden, unhidden,` \          events, so see [nw].
`displays_changed`

__font registration__

`ui:add_font_file(...)`                see [tr:add_font_file(...)][tr]

`ui:add_mem_font(...)`                 see [tr:add_mem_font(...)][tr]
-------------------------------------- ---------------------------------------

## Elements

Elements provide styling and transitions for windows and layers.
Elements are objects, so all object methods and properties apply.

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

Windows are a thin facade over [nw]'s windows.
Windows are elements, so all element methods and properties apply.

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

__native events__

`activated, deactivated, wakeup,` \    these map directly to nw window \
`shown, hidden,` \                     events, so see [nw].
`minimized, unminimized,` \
`maximized, unmaximized,` \
`entered_fullscreen,` \ \
`exited_fullscreen,` \
`changed,` \
`sizing,` \
`frame_rect_changed, frame_moved,` \
`frame_resized,` \
`client_moved, client_resized,` \
`magnets,` \
`free_cairo, free_bitmap,` \
`scalingfactor_changed`

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

`win.move_layer`                       layer which by dragging it moves the window
-------------------------------------- ---------------------------------------

## Layers

Similar to HTML divs, layers encapsulate all the positioning, drawing and
input infrastructure necessary for implementing widgets, and can also be used
standalone as layout containers, text labels or other presentation elements.
Layers are elements, so all element methods and properties apply.

### Configuration

-------------------------------- ---------------- ------------------------------------------------------------------
__display & behavior__           __default__
`visible`                        true             visible and occupies space in the layout
`enabled`                        true             looks enabled and receives input
`activable`                      true             can be clicked and set as hot
`vscrollable`                    false            enable mouse wheel when hot and not focused
`hscrollable`                    false            enable mouse horiz. wheel when hot and not focused
`scrollable`                     false            can be hit for vscroll or hscroll
`focusable`                      false            can be focused
`draggable`                      true             can be dragged (still needs to respond to start_drag())
`mousedown_activate`             false            activate/deactivate on left mouse down/up
`drag_threshold`                 0                moving distance before start dragging
`max_click_chain`                1                2 for getting doubleclick events, etc.
__affine transforms__
`rotation`                       0                rotation angle (radians)
`rotation_cx, rotation_cy`       0, 0             rotation center coordinates
`scale`                          1                scale factor
`scale_x, scale_y`               false, false     scale factor: axis overrides
`scale_cx, scale_cy`             0, 0             scaling center coordinates
__content box__
`padding`                        0 (none)         default padding for all sides
`padding_left`                   false            padding override: left side
`padding_right`                  false            padding override: right side
`padding_top`                    false            padding override: top side
`padding_bottom`                 false            padding override: bottom side
__hierarchy__
`parent`                         false            painting/clipping parent
`layer_index`                                     index in parent's array part (z-order)
`pos_parent`                     false            positioning parent (false means use `parent`)
__focus__
`tabindex`                       0                tab order, for tab-based navigation
`tabgroup`                       0                tab group, for tab-based navigation
`taborder_algorithm`             'xy'             tab order algorithm: 'xy', 'yx'
__borders__
`border_width`                   0 (none)         border thickness
`border_width_left`              false            border thickness side override
`border_width_right`             false            border thickness side override
`border_width_top`               false            border thickness side override
`border_width_bottom`            false            border thickness side override
`corner_radius`                  0 (square)       border corner radius
`corner_radius_top_left`         false            border corner radius side override
`corner_radius_top_right`        false            border corner radius side override
`corner_radius_bottom_left`      false            border corner radius side override
`corner_radius_bottom_right`     false            border corner radius side override
`border_color`                   '#fff'           border color
`border_color_left`              false            border color side override
`border_color_right`             false            border color side override
`border_color_top`               false            border color side override
`border_color_bottom`            false            border color side override
`border_dash`                    false            border dash: `{width1, width2, ...}`
`border_offset`                  -1 (inside)      border stroke position rel. to box edge (1=outside)
`corner_radius_kappa`            1.2              smoother rounded corners
__backgrounds__
`background_type`                'color'          false, 'color', 'gradient', 'radial_gradient', 'image'
`background_hittable`            true
`background_x, background_y`     0, 0             background offset coords
`background_rotation`            0                background rotation angle (rad)
`background_rotation_cx/_cy`     0, 0             background rotation center coords
`background_scale`               1                background scale factor
`background_scale_cx/_cy`        0, 0             background scale factor: axis override
`background_color`               false (none)     solid color
`background_colors`              false            gradient: `{[offset1], color1, ...}`
`background_x1/_y1/_x2/_y2`      0, 0, 0, 0       linear gradient: end-point coords
`background_cx1/_cy1/_cx2/_cy2`  0, 0, 0, 0       radial gradient: end-point coords
`background_r1/_r2`              0, 0             radial gradient: radii
`background_image`               false (none)     background image file (requires [libjpeg])
`background_operator`            'over'           cairo blending operator
`background_clip_border_offset`  1                like border_offset but for clipping the background
__shadows__
`shadow_x, shadow_y`             0, 0             shadow offset coords
`shadow_color`                   '#000'           shadow color
`shadow_blur`                    0 (none)         shadow blur size
__text__
`text`                           false (none)
`font`                           'Open Sans,14'   font spec: `'name [weight] [slant], size'`
`font_name`                      false            font override: name
`font_weight`                    false            font override: weight (100..900, 'bold', etc.)
`font_slant`                     false            font override: slant ('italic', 'normal')
`font_size`                      false            font override: size
`text_color`                     '#fff'           text color
`line_spacing`                   1                multiply factor over line height for lines
`paragraph_spacing`              2                multiply factor over line height for paragraphs
`text_dir`                       'auto'           BiDi base direction: 'auto', 'rtl', 'ltr'
`nowrap`                         false            disable automatic line wrapping
`text_operator`                  'over'           blending operator (see [cairo])
`text_align`                     'center center'  text x & y alignments: 'l|c|r t|c|b'
`text_align_x`                   false            text x-align override: 'l|c|r'
`text_align_y`                   false            text y-align override: 't|c|b'
__layouting__
`layout`                         false (none)     layout type: false (none), 'textbox', 'flexbox', 'grid'
`min_cw, min_ch`                 0, 0             minimum content-box size for flexible layouts
__null-layouts__
`x, y, w, h`                     0, 0, 0, 0       fixed box coordinates
__flexbox layouts__
`flex_axis`                      'x'              main axis of flow: 'x', 'y'
`flex_wrap`                      false            line-wrap content
`align_main/_cross/_lines`       'stretch'        'stretch', 'start'/'top'/'left', 'end'/'bottom'/'right', 'center'
`align_main`                     'stretch'        main-axis align: additionally: 'space_between', 'space_around', 'space_evenly'
`align_cross`                    'stretch'        cross-axis align: additionally: 'baseline'
`align_lines`                    'stretch'        content-align: additionally: 'space_between', 'space_around', 'space_evenly'
`align_cross_self`               false            item `align_cross` override
`fr`                             1                stretch fraction
__grid layouts__
`grid_flow`                      'x'              flow direction & main axis: 'x', 'y', 'xr', 'yr', 'xb', 'yb', 'xrb', 'yrb'
`grid_wrap`                      1                number of rows/columns on the main axis of flow
`grid_cols`                      {}               column size fractions `{fr1, ...}`
`grid_rows`                      {}               row size fractions `{fr1, ...}`
`col_gap`                        0 (none)         gap size between columns
`row_gap`                        0 (none)         gap size between rows
`align_x`                        'stretch'        'stretch', 'start'/'top'/'left', 'end'/'bottom'/'right', 'center', 'space_between', 'space_around', 'space_evenly'
`align_y`                        'stretch'        'stretch', 'start'/'top'/'left', 'end'/'bottom'/'right', 'center', 'space_between', 'space_around', 'space_evenly'
`align_x_self`                   false            item `align_x` override
`align_y_self`                   false            item `align_y` override
__tooltips__
`tooltip`                        false (none)     native tooltip text
-------------------------------- ---------------- ------------------------------------------------------------------

### Runtime state

-------------------------------- ---------------- ------------------------------------------------------------------
`enabled`                        r/w              enabled and all parents are enabled too
`hot`                            r/o              mouse pointer is over the layer
`active`                         r/w              the mouse is captured
`focused`                        r/o              has keyboard focus
`mouse_x, mouse_y`               r/o              mouse coords from the last mouse event
`window`                         r/o              layer's window
layer's array part               r/o              is where child layers are kept
-------------------------------- ---------------- ------------------------------------------------------------------

### Hierarchy

------------------------------------------------- ------------------------------------------------------------------
`to_back()`                                       set `layer_index` to 1
`to_front()`                                      set `layer_index` to 1/0
`each_child(func)`                                calls `func(layer)` for each child, recursively, depth-first
`children() -> iter() -> layer`
`add_layer(layer, [index])`                       add a child
`remove_layer(layer)`                             remove a child
------------------------------------------------- ------------------------------------------------------------------

### Measuring tools

------------------------------------------------- ------------------------------------------------------------------
__derived geometry__
`border_inner_x/_y/_w/_h`                         border's inner contour box
`border_outer_x/_y/_w/_h`                         border's outer contour box
`baseline`                                        text's baseline
`pw, ph`                                          total horizontal and vertical paddings
`pw1, pw2, ph1, ph2`                              paddings for each side
`cw, ch`                                          content box size
`cx, cy`                                          box's center coords
`x2, y2`                                          box's bottom-right corner coords
__coord converters__
`abs_matrix() -> mt`                              box matrix in window space
`from_box_to_parent(x, y) -> x, y`                convert point from own box space to parent content space.
`from_parent_to_box(x, y) -> x, y`                convert point from parent content space to own box space.
`to_parent(x, y) -> x, y`                         convert point from own content space to parent content space.
`from_parent(x, y) -> x, y`                       convert point from parent content space to own content space.
`to_window(x, y) -> x, y`
`from_window(x, y) -> x, y`
`to_screen(x, y) -> x, y`
`from_screen(x, y) -> x, y`
`to_other(widget, x, y) -> x, y`                  convert point from own content space to other's content space.
`from_other(widget, x, y) -> x, y`                convert point from other's content space to own content space
------------------------------------------------- ------------------------------------------------------------------

### Events

------------------------------------------------- ------------------------------------------------------------------
__mouse__
`activated()`                                     layer activated (mouse captured)
`deactivated()`                                   layer deactivated
`mousemove(x, y, area)`                           mouse moved
`mouseenter(x, y, area)`                          mouse entered
`mouseleave()`                                    mouse left
`[right|middle]mousedown(x, y, area)`             mouse left/right/middle button pressed
`[right|middle]mouseup(x, y, area)`               mouse left/right/middle button depressed
`[right|middle]click(x, y, area)`                 mouse left/right/middle button clicked
`[right|middle]doubleclick()`                     mouse left/right/middle button double-clicked
`[right|middle]tripleclick()`                     mouse left/right/middle button triple-click
`[right|middle]quadrupleclick()`                  mouse left/right/middle button quadruple-click
`mousewheel(delta, x, y, area, pdelta)`           mouse wheel turned
__keyboard__
`gotfocus()`                                      layer focused
`lostfocus()`                                     layer unfocused
`keydown(key)`                                    key pressed
`keyup(key)`                                      key released
`keypress(key)`                                   key pressed (on repeat)
`keychar(s)`                                      utf-8 sequence entered
__drag & drop__
`drag(x, y)`
`enter_drop_target(widget, area)`
`leave_drop_target(widget)`
`end_drag(drag_widget)`
`drop(widget, x, y, area)`
`started_dragging()`
`ended_dragging()`
__hierarchy__
`layer_added(layer, index)`                       a child layer was added
`layer_removed(layer)`                            a child layer was removed
------------------------------------------------- ------------------------------------------------------------------

### Box model

  * layers can be nested, which affects their painting order, clipping and
  positioning relative to each other.
  * layers have a "box" defined by their `x, y, w, h`, and a "content box"
  (aka "client rect") which is the "box" adjusted by paddings.
  * layers are positioned and clipped relative to their parent's content box.
  * unlike html, the content box is _not_ affected by the size of borders.
  * borders can be drawn at an offset relative to the layer's box and the
  border's thickness.
  * a layer's contents and background can be clipped by the padding box
  of its parent, or by the border inner contour of its parent, or it can be
  left unclipped.

### Mouse interaction

  * layers must be set as `activable` in order to receive mouse events.
  * a layer is `hot` when the mouse is over it or when it's `active`.
  * a layer must set `active` on `mousedown` and must reset it on `mouseup`
  in order to have the mouse _captured_ while a mouse button is down;
  this can be done automatically by statically setting `mousedown_activate`.
  * while a layer is `active`, it continues to be `hot` and receive
  `mousemove` events even when the mouse is outside its hit test area or
  outside the window even (that is, the mouse is captured).
  * a layer must be `active` in order to receive drag & drop events.

### Keyboard interaction

  * layers must be set as `focusable` in order to receive keyboard events.
  * keyboard events are only received by the focused layer.
  * return `true` in a `keydown` event to eat up a key stroke so that it
  isn't used by other actions: this is how key conflicts are solved.

### Layouting

Layouting deals with sizing and positioning layers on screen automatically
to accomodate both the content size and the window size. Layers of different
layout types and properties can be mixed freely in a layer hierarchy with
some caveats:

  * non-layouted children of non-layouted layers _are not_ sized by their
  parent and do not size themselves either, thus these layers must be sized
  and positioned manually by setting their `x, y, w, h`.
  * layouted children of non-layouted layers _are not_ sized by their
  parent and must thus set their `min_cw, min_ch`, otherwise they will size
  themselves to the minimum allowed by their children.
  * non-layouted children of layouted layers _are_ sized by their parent
  and must thus set their `min_cw, min_ch`, otherwise they may shrink
  to nothing since they don't resize themselves to contain their content.
  * layouts with wrapping content (nowrap = false, flex_wrap = true) are
  solved on one axis completely before solving on the other axis. This only
  works properly if all the wrappable content has either horizontal flow
  (so the whole layout is width-in-height-out) or vertical flow (so the
  whole layout is height-in-width out). Mixed flows will cause the contents
  which wrap perpendicularly to overflow their container (browsers have this
  limitation too). Setting `min_cw, min_ch` on the cross-flow layers can be
  used to alleviate the problem on a case-by-case basis.

#### No layout

Layers without a layout (layout = false) don't touch their box or their
children's boxes, but instead ask their children to layout themselves.

#### Textbox layouts

Freestanding textbox layers (whose parent is not layouted) size themselves
to contain their `text` property which is line-wrapped on their `min_cw`.

#### Flexbox layouts

Flexbox layers use an algorithm similar to the CSS flexbox algorithm
to size themselves and to size and position their children recursively.

#### Grid layouts

Grid layers use an algorithm similar to the CSS grid algorithm to size
themselves and to size and position their children recursively.

### The top layer

All windows have a top layer in their `view` field. Its size is kept in sync
with the window's client area and it is configured to clear the window's
bitmap on every repaint:

-------------------------------- ---------------- ------------------------------------------------------------------
`background_color`               '#040404'        a default color that works with transparent windows
`background_operator`            'source'         clear background
-------------------------------- ---------------- ------------------------------------------------------------------

User-created layers must ultimately be atteched to the window's view (or to
the window itself which will attach them to the window's view) in order to be
visible and respond to user input. The view is the only layer whose `parent`
is a window, not another layer.

## Widgets

Widgets are layer trees with custom styling and behavior and additional
properties, methods and events. Widgets can be extended by subclassing and
overriding and can be re-styled with `ui:style()`.

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
 * the [event system][events], which adds a pub-sub API.
 * the `ui.object` class, which adds meta-programming facilities (decorators).
 * the `ui.element` class, which adds a base non-visual vocabulary for:
   * applying multiple attribute value sets based on tag combinations (aka CSS)
	* time-based interpolation of attribute values (aka transition animations)
 * the `ui.layer` class, which adds a base visual vocabulary:
	* layer hierarchies with relative affine transforms and clipping
	* drawing borders, backgrounds, shadows, and aligned text
	* hit testing borders, background and content
	* layouting, including css-flexbox and css-grid-like models
 * the `ui.window` and `ui.layer` classes, which work together to provide an input API:
   * routing mouse events to the hot widget; mouse capturing
	* routing keyboard events to the focused widget; tab-based navigation
	* drag & drop API (event-based)

## The `object` base class

  * created with [oo]; inherits oo.Object; published as `ui.object`.
  * inherits the [events] mixin.
  * common ancestor of all classes.

## Method & property decorators

These are meta-programming facilities exposed as class methods for creating
or enhancing the behavior of properties and methods in specific ways.

### `object:memoize(method_name)`

Memoize a method (which must be single-return-value).

### `object:forward_events(obj, events)`

Forward some events (`{event_name1, ...}`) from `obj` to `self`,
i.e. install event handlers in `obj` which forward events to `self`.

### `object:stored_property(prop, [priv])`

Create a r/w property which reads/writes from a "private field" (`priv` which
defaults to `_<prop>`).

### `object:nochange_barrier(prop)`

Change a property so that its setter is only called when the value changes.

### `object:track_changes(prop)`

Change a property so that its setter is only called when the value changes
and also `<prop>_changed` event is fired.

### `object:instance_only(prop)`

Inhibit a property's getter and setter when using the property on the class.
instead, set a private var on the class which serves as default value.
NOTE: use this decorator only _after_ defining the getter and setter.

### `object:enum_property(prop, values)`

Validate a property when being set against a list of allowed values.

## Error reporting

### `object:warn(fmt, ...)`

Issue a warning on `stderr`.

### `object:check(ret, fmt, ...) -> ret|nil`

Issue a warning if `ret` is falsey or return `ret`.

## Submodule autoloading

### `object:autoload(t)`

See [glue].autoload.
