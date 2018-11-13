
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
	parent = win, x = 100, y = 100,
	text = 'Close', cancel = true,
}

ui:run()
~~~

## Class hierarchy

  * `oo.Object` - [oo]'s base class
     * `ui.object` - ui's base class. includes the [events] mixin.
        * `ui` - this module, also serving as the app singleton
        * `ui.selector` - element selectors
        * `ui.element_list` - lists of elements
        * `ui.stylesheet` - stylesheets
        * `ui.transition` - attribute transitions
        * `ui.element` - adds styling and transitions to objects
           * `ui.window` - top-level windows: a thin layer over [nw]'s windows
              * `ui.popup` - frameless pop-up windows
           * `ui.layer` - the basic UI building block
              * `ui.window.view_class` - a window's top layer
              * any widget

## The ui module/singleton

The ui singleton allows for creating OS windows, quitting the app,
creating timers, using the clipboard, adding fonts, etc.

### Forwarded properties, methods and events

The ui singleton is mostly a thin facade over [nw]'s app singleton.
Those `ui` features which map directly to nw app features are listed below
but are not documented here again.

-------------------------------------- ---------------------------------------
__native properties__

`autoquit, maxfps, app_active,`        these map directly to [nw] app features
`app_visible, caret_blink_time,`       except they are exposed as properties
`displays, main_display,`              instead of methods like in [nw].
`active_display, app_id`

__native methods__

`run, poll, stop, quit, runevery,`     these map directly to [nw] app
`runafter, sleep, activate_app,`       methods.
`hide_app, unhide_app, key,`
`getclipboard, setclipboard,`
`opendialog, savedialog,`
`app_already_running,`
`wakeup_other_app_instances,`
`check_single_app_instance`

__native events__

`quitting, activated, deactivated,`    these map directly to [nw] app
`wakeup, hidden, unhidden,`            events.
`displays_changed`
-------------------------------------- ---------------------------------------

### Font management

Fonts must be registered before they can be used. Fonts can be read from
files or from memory buffers. See [tr] for details.

-------------------------------------- ---------------------------------------
`ui:add_font_file(...)`                calls `tr:add_font_file(...)`
`ui:add_mem_font(...)`                 calls `tr:add_mem_font(...)`
-------------------------------------- ---------------------------------------

## Elements

Elements are objects with styling and transitions and a standard constructor.
Windows and layers are both elements so everything in this section applies
to both.

### Constructing elements

Unlike normal objects, elements have a single-form constructor which takes
the `ui` singleton as arg#1 followed by any number of tables whose fields
are first merged into a single table and then copied over to the element in
lexicographic order. This means that:

  * unknown fields are not discarded, which makes for a convenient way to
  create layers or windows with custom fields.
  * properties are set (i.e. setters are called) in a stable
  (albeit arbitrary) order.

### Styling

Cascade styling is a mechanism for applying multiple attribute value sets
to matching sets of elements based on matching tag combinations.

#### Tags

Selecting elements is based on element tags only, which are equivalent to
CSS classes (there is no concept of ids or other things to match on other
than tags).

Elements can be initialized with the attribute `tags = 'tag1 tag2 ...'`
similar to the html class attribute. Tags can also be added/removed later
with `elem:settag(tagname, true|false)` or `elem:settags('+tag1 -tag2 ...')`.
A class can also specify additional default tags with
`myclass.tags = 'tag1 tag2 ...'`.

Tags matching the entire hierarchy of class names up to and including
`'element'` are created automatically for each element, so every layer gets
the `'element'` and `'layer'` tags, etc.

#### Selectors

Selectors are used in two contexts:

  * creating styles with `ui:style()`.
  * finding elements with `ui|win:find()` and `ui|win:each()`.

Selector syntax differs from CSS:

  * simple selectors: `'tag1 tag2'` -- in CSS: `.tag1.tag2`
  * parent-child selectors: `'tag1 > tag2'` -- in CSS: `.tag1 .tag2`

Selector objects can be created with `ui:selector(select_text)`. It's not
normally necessary to create them explicitly (they are created automatically
in places where a selector is expected), but they have additional methods:

  * `sel:filter(func)` -- add a filter function `f(elem) -> true|false`
  to the selector, to further filter the selected results; multiple filters
  can be added and they will be applied in order.
  * `sel:selects(elem) -> true|false` -- test a selector against an element.

Selector objects pass-through the selector constructor, which is short for
saying that the selector constructor can take a selector object as arg#1 in
which case the selector object is simply returned and no selector is created.

#### Styles

Selector-based styles can be created with `ui:style(selector, attr_values)`
which adds them to the default stylesheet `ui.element.stylesheet`. Inline
styles can be added with the `style` attribute when creating the element.

Styles are updated automatically on the next repaint. They can also be
updated manually with `elem:sync_styles()`.

#### Stylesheets

  * use `ss = ui:stylesheet()` to create a new stylesheet.
  * use `ss:style(selector, attr_values)` to add styles to it.
  * replace `ui.element.stylesheet` to change the styling of the entire app.
  * replace `ui.button.stylesheet` to change the styling of all buttons.
  * pass `stylesheet` when creating an element to set its stylesheet.
  * use `ss1:add_stylesheet(ss2)` to copy styles from another stylesheet.

#### State tags

Tags that start with `:` are _state tags_ and are used exclusively for
tagging element states like `:hot` and `:selected`.

Styles containing state tags are applied only after all styles containing
only normal tags are applied. It's as if styles containing state tags
were added to a second stylesheet that was included after the default one.
This allows overriding base styles without resetting any matching state
styles, so for instance, declaring a new style for `'mybutton'` will not
affect the syle set previously for `'mybutton :hot'`.

#### Finding elements using selectors

  * `ui|win|elem_list:find(sel) -> elem_list` - find elements and return them in a list.
  * `ui|win|elem_list:each(sel, func)` - run `func(elem)` for each element found.

### Transition animations

Transitions are about gradually changing the value of an element attribute
from its current value to a new value using linear interpolation.

Every attribute can be animated providing it has a data type that can be
interpolated. Currently, numbers, colors and color gradients can be
interpolated, but more data types and interpolator functions can be added
if needed (see the code for that).

Transitions can be created by calling:

~~~{.lua}
	elem:transition(
		attr, val, [duration], [ease], [delay],
		[times], [backval], [blend], [speed], [from]
	)
~~~

or they can be defined declaratively as styles:

------------------------ ------------------ ----------------------------------
`transition_<attr>`                         set to `true` to enable transitions for an attribute
`transition_duration`    `0` (disabled)     animation duration (seconds)
`transition_ease`        `'expo out'`       easing function and way (see [easing])
`transition_delay`       `0`                delay before starting (seconds)
`transition_repeat`      `1`                repeat times
`transition_speed`       `1`                speed factor
`transition_blend`       `'replace'`        blend function: `'replace'`, `'restart'`, `'wait'`
`transition_from`        _current value_    start value
------------------------ ------------------ ----------------------------------

Transition parameters can also be specified for each attribute with
`transition_<param>_<attr>`, eg. `transition_duration_opacity = 2`.

Transitions are updated automatically on every repaint and are freed
automatically when they finish. They can also be updated manually with
`elem:sync_transitions()`.

#### Transition blending

Transition blending controls what happens when a transition is created
over an attribute that is already in transition. Possible behaviors depend
on the `transition_blend` attribute, which can be:

  * `'replace'` - replace current transition with the new one, but do nothing
  if the new transition has the same end value as the current one.
  * `'restart'` - replace current transition with the new one, and also,
  start from the initial value instead of from the current value.
  * `'wait'` - wait for the current transition to terminate before starting
  the new one, but do nothing if the new transition has the same end value
  as the current one.

## Windows

Like all elements, windows are created with `ui:window(attrs1, ...)`.
Attributes can be passed in multiple tables: the values in latter tables
will take precedence over the values in former tables.

Windows are elements, so all element methods and properties apply.

### Forwarded properties, methods and events

Windows are a thin facade over [nw] windows. Those features which map
directly to nw window features are listed below but are not documented here
again.

-------------------------------------- ---------------------------------------
__native properties__

`x, y, w, h, cx, cy, cw, ch,`          these map directly to [nw] window
`min_cw, min_ch, max_cw, max_ch,`      features except they are exposed as
`autoquit, visible, fullscreen,`       properties instead of methods like
`enabled, edgesnapping, topmost,`      in [nw].
`title, dead, closeable,`
`activable, minimizable,`
`maximizable, resizeable,`
`fullscreenable, frame,`
`transparent, corner_radius,`
`sticky, dead, active, isminimized,`
`ismaximized, display, cursor`

__native methods__

`close`, `free`,                       these map directly to [nw] window
`frame_rect, client_rect,`             methods.
`client_to_frame, frame_to_client,`
`closing, close, show, hide,`
`activate, minimize, maximize,`
`restore, shownormal, raise, lower,`
`to_screen, from_screen`

__native events__

`activated, deactivated, wakeup,`      these map directly to [nw] window
`shown, hidden,`                       events.
`minimized, unminimized,`
`maximized, unmaximized,`
`entered_fullscreen,`
`exited_fullscreen,`
`changed, sizing,`
`frame_rect_changed, frame_moved,`
`frame_resized,`
`client_moved, client_resized,`
`magnets,`
`free_cairo, free_bitmap,`
`scalingfactor_changed`
-------------------------------------- ---------------------------------------

### Child windows

A child window by [nw]'s definition is a top-level window that does not
appear in the taskbar and by default will follow its parent window when that
is moved. That behavior is extended here so that a child window is positioned
_relative to a layer_ in another window so that it follows that layer even
when the parent window itself doesn't move but only the layer moves inside it.

-------------------------------------- ---------------------------------------
`win.parent`                           a layer in another window
`win:to_parent(x, y) -> x, y`          window's client space -> its parent space
`win:from_parent(x, y) -> x, y`        window's parent space -> its client space
-------------------------------------- ---------------------------------------

### Moving frameless windows

For frameless windows, a layer (usually the layer representing the title bar)
can be assigned to `win.move_layer` which will set it up to move the window
when dragged.

## Window state tags

-------------------------------------- ---------------------------------------
`:active`                              the window is active
`:fullscreen`                          the window is in fullscreen mode
-------------------------------------- ---------------------------------------

### Window mouse state

-------------------------------------- ---------------------------------------
`win.mouse_x, win.mouse_y` \           mouse position at the time of last mouse event.
`win:mouse_pos() -> x, y`
-------------------------------------- ---------------------------------------

## Layers

Similar to HTML divs, layers encapsulate all the positioning, drawing,
clipping, hit-testing and input infrastructure necessary for implementing
widgets, and can also be used standalone as layout containers, text labels
or other presentation elements.

Like all elements, layers are created with `ui:layer(attrs1, ...)`.
Attributes can be passed in multiple tables: the values in latter tables
will take precedence over the values in former tables.

Layers are elements, so all element methods and properties apply.

### Configuration

The following attributes can be used to initialize a layer and can also be
changed freely at runtime to change its behavior or appearance.

------------------------------------ ------------------ ----------------------
__layer hierarchy__
`parent`                             `false`            parent: for positioning, painting and clipping
`layer_index`                        `1/0`              preferred z-order: `1=backmost`, `1/0=frontmost`
`pos_parent`                         `false`            positioning parent (`false` means use `parent`)
__behavior__
`visible`                            `true`             visible and occupies space in the layout
`enabled`                            `true`             looks enabled and can receive input
`activable`                          `true`             can be clicked and hovered (set as hot)
`vscrollable`                        `false`            enable mouse wheel when hot and not focused
`hscrollable`                        `false`            enable mouse horiz. wheel when hot and not focused
`scrollable`                         `false`            can be hit for vscroll or hscroll
`focusable`                          `false`            can be focused
`draggable`                          `true`             can be dragged (still needs to respond to `start_drag()`)
`background_hittable`                `true`             background area receives mouse input even when there's no background
`mousedown_activate`                 `false`            activate/deactivate on left mouse down/up
`drag_threshold`                     `0`                moving distance before start dragging
`max_click_chain`                    `1`                2 for getting doubleclick events, etc.
`tabgroup`                           `0`                tab group, for tab-based navigation
`tabindex`                           `0`                tab order in tab group, for tab-based navigation
`taborder_algorithm`                 `'xy'`             tab order algorithm: `'xy'`, `'yx'`
__content box__
`padding`                            `0`                padding for all sides
`padding_<side>`                     `false`            `left`/`right`/`top`/`bottom` padding override
__layouting__
`layout`                             `false`            layout model: `false` (none), `'textbox'`, `'flexbox'`, `'grid'`
`min_cw, min_ch`                     `0`                minimum content-box size for flexible layouts
__layout=false__
`x, y, w, h`                         `0`                fixed position & size
__flexbox layout__
`flex_axis`                          `'x'`              main axis of flow: `'x'`, `'y'`
`flex_wrap`                          `false`            line-wrap content
`align_main/cross/lines`             `'stretch'`        `'stretch'`, `'start'`/`'t[op]'`/`'l[eft]'`, `'end'`/`'b[ottom]'`/`'r[ight]'`, `'c[enter]'`
`align_main`                         `'stretch'`        main-axis align: `'space_between'`, `'space_around'`, `'space_evenly'`
`align_cross`                        `'stretch'`        cross-axis align: `'baseline'`
`align_lines`                        `'stretch'`        content-align: `'space_between'`, `'space_around'`, `'space_evenly'`
`align_cross_self`                   `false`            item `align_cross` override
`fr`                                 `1`                item stretch fraction for `align_main='stretch'`
__grid layout__
`grid_flow`                          `'x'`              main axis & direction for automatic positioning: `'x'`, `'y'`, `'xr'`, `'yr'`, `'xb'`, `'yb'`, `'xrb'`, `'yrb'`
`grid_wrap`                          `1`                number of rows/columns on the main axis of flow
`grid_cols`                          `{}`               column size fractions `{fr1, ...}` for `align_x='stretch'`
`grid_rows`                          `{}`               row size fractions `{fr1, ...}` for `align_y='stretch'`
`col_gap`                            `0`                gap size between columns
`row_gap`                            `0`                gap size between rows
`grid_pos`                           `nil`              element position in grid: `'[row][/span] [col][/span]'`
`align_x`                            `'stretch'`        `'stretch'`, `'start'`/`'l[eft]'`, `'end'`/`'r[ight]'`, `'c[enter]'`, `'space_between'`, `'space_around'`, `'space_evenly'`
`align_y`                            `'stretch'`        `'stretch'`, `'start'`/`'t[op]'`, `'end'`/`'b[ottom]'`, `'c[enter]'`, `'space_between'`, `'space_around'`, `'space_evenly'`
`align_x_self`, `align_y_self`       `false`            item `align_x` and `align_y` overrides
__transparency & clipping__
`opacity`                            `1`                overall opacity (0..1)
`clip_content`                       `false`            content clip area: `'padding'`/`true`, `'background'`, `false` (don't clip)
__borders__
`border_width`                       `0`                border thickness for all sides
`border_width_<side>`                `false`            `left`/`right`/`top`/`bottom` border thickness override
`corner_radius`                      `0`                border corner radius for all corners
`corner_radius_<corner>`             `false`            `top_left`/`top_right`/`bottom_left`/`bottom_right` corner radius override
`border_color`                       `'#fff'`           border color
`border_color_<side>`                `false`            `left`/`right`/`top`/`bottom` border color override
`border_dash`                        `false`            border dash pattern: `{length1, ...}`
`border_offset`                      `-1`               border stroke position rel. to box edge (-1=inside..1=outside)
`corner_radius_kappa`                `1.2`              smoother rounded corners (1=circle arc)
__background__
`background_type`                    `'color'`          `false`, `'color'`, `'gradient'`, `'radial_gradient'`, `'image'`
`background_x, background_y`         `0`                background offset coords
`background_rotation`                `0`                background rotation angle (radians)
`background_rotation_cx/cy`          `0`                background rotation center coords
`background_scale`                   `1`                background scale factor
`background_scale_cx/cy`             `0`                background scale factor: axis override
`background_color`                   `false`            solid color
`background_colors`                  `false`            gradient: `{[offset1], color1, ...}`
`background_x1/y1/x2/y2`             `0`                linear gradient: end-point coords
`background_cx1/cy1/cx2/cy2`         `0`                radial gradient: end-point coords
`background_r1/r2`                   `0`                radial gradient: radii
`background_image`                   `false`            background image file (requires [libjpeg])
`background_operator`                `'over'`           cairo blending operator
`background_clip_border_offset`      `1`                like `border_offset` but for clipping the background
__shadow__
`shadow_x, shadow_y`                 `0`                shadow offset coords
`shadow_color`                       `'#000'`           shadow color
`shadow_blur`                        `0`                shadow blur size (0=disable)
__text__
`text`                               `false`            text, wrapped around `cw`
`font`                               `'Open Sans,14'`   font spec: `'name [weight] [slant], size'`
`font_name`                          `false`            font override: name
`font_weight`                        `false`            font override: weight (`100..900`, `'bold'`, etc.)
`font_slant`                         `false`            font override: slant (`'italic'`, `'normal'`)
`font_size`                          `false`            font override: size
`text_color`                         `'#fff'`           text color
`line_spacing`                       `1`                multiply factor over line height for lines
`paragraph_spacing`                  `2`                multiply factor over line height for paragraphs
`text_dir`                           `'auto'`           BiDi base direction: `'auto'`, `'rtl'`, `'ltr'`
`nowrap`                             `false`            disable automatic line wrapping
`text_operator`                      `'over'`           blending operator (see [cairo])
`text_align`                         `'c c'`            text x & y alignments: `'l[eft]|c[enter]|r[ight] t[op]|c[enter]|b[ottom]'`
`text_align_x`                       `false`            text x-align override: `'l[eft]'`, `'c[enter]'`, `'r[ight]'`
`text_align_y`                       `false`            text y-align override: `'t[op]'`, `'c[enter]'`, `'b[ottom]'`
__tooltip__
`tooltip`                            `false`            native tooltip text (false=none)
__rotation & scaling__
`rotation`                           `0`                rotation angle (radians)
`rotation_cx, rotation_cy`           `0`                rotation center coordinates
`scale`                              `1`                scale factor
`scale_x, scale_y`                   `false`            scale factor: axis overrides
`scale_cx, scale_cy`                 `0`                scaling center coordinates
------------------------------------ ------------------ ----------------------

### Box model

#### Layer hierarchy

  * layers can be nested, which affects their painting order, clipping and
  positioning relative to each other.
  * layers can be moved to another parent by changing their `parent` property.
  * `parent` can be set to a window object, in which case the window will
  change it to point to its `view` layer.

#### Size & positioning

  * layers have a "box" defined by `x, y, w, h` and a "content box"
  (or "client rectangle") which is the same box adjusted by paddings.
  * layers are positioned relative to their parent's _content box_.
  * `x, y, w, h` are input fields (user must set their values) only when
  layouting is disabled on a layer and its parent. When a layout model is
  used, those fields are controlled by the layout.
  * `x, y, w, h` can be set indirectly by setting `cw, ch, cx, cy, x2, y2`.

#### Z-order

  * a layer keeps its children in its array part which also dictates their
  painting order: first child is painted first.
  * setting the `parent` property adds the layer to the end of its new
  parent's child list.
  * layers can change their paint order with `to_front()`, `to_back()`
  or by setting their `layer_index` property directly.
  * you can sort a layer's children by sorting the layer itself with
  `table.sort()`.
  * `layer_index` represents a preferred index when constructing a layer,
  but at runtime it always reflects the actual index in the parent array.

#### Borders

  * unlike HTML, the content box is _not_ affected by borders!
  * the offset at which the border is drawn relative to the layer's box
  can be controlled with the `border_offset` property where `-1` draws an
  inner border, `1` draws an outer border, and `0` draws a stroke with its
  median line coinciding with the box (so half-in half-out).

#### Clipping

  * a layer's contents can be clipped by its padding box, by the inner
  contour of its border, or it can be left unclipped, courtesy of the
  `clip_content` property.
  * a layer's background is always clipped.

### Box model API

------------- --------------------------------------- ------------------------
              __layer hierarchy & z-order__
r/w property  `parent`                                layer's parent
r/o property  `window`                                layer's window
r/w property  `layer_index`                           index in parent array (z-order)
method        `to_back()`                             set `layer_index` to `1`
method        `to_front()`                            set `layer_index` to `1/0`
method        `each_child(func)`                      call `func(layer)` for each child recursively depth-first
method        `children() -> iter() -> layer`         iterate children recursively depth-first
event         `layer_added(layer, index)`             a child layer was added
event         `layer_removed(layer)`                  a child layer was removed
              __size & positioning__
plain field   `x, y, w, h`                            computed box size and position
r/w property  `cw, ch`                                content box size
r/w property  `cx, cy`                                box's center coords
r/w property  `x2, y2`                                box's bottom-right corner coords
r/o property  `pw, ph`                                total horizontal and vertical paddings
r/o property  `pw1, pw2, ph1, ph2`                    paddings for each side
r/o property  `inner_x/y/w/h`                         border's inner contour box
r/o property  `outer_x/y/w/h`                         border's outer contour box
r/o property  `baseline`                              text's baseline
method        `size() -> w, h`                        box size
method        `client_size() -> cw, ch`               content box size
method        `padding_size() -> cw, ch`              content box size
method        `client_rect() -> 0, 0, cw, ch`         content box rect in content box space
              __space conversion__
method        `from_box_to_parent  (x, y) -> x, y`    own box space -> parent content space
method        `from_parent_to_box  (x, y) -> x, y`    parent content space -> own box space
method        `to_parent           (x, y) -> x, y`    own content space -> parent content space
method        `from_parent         (x, y) -> x, y`    parent content space -> own content space
method        `to_window           (x, y) -> x, y`    own content space -> window's content space
method        `from_window         (x, y) -> x, y`    window's content space -> own content space
method        `to_screen           (x, y) -> x, y`    own content space -> screen space
method        `from_screen         (x, y) -> x, y`    screen space -> own content space
method        `to_other    (widget, x, y) -> x, y`    own content space -> other's content space
method        `from_other  (widget, x, y) -> x, y`    other's content space -> own content space
------------- --------------------------------------- ------------------------

### Input model

#### Mouse interaction

  * layers must be set `activable` in order to receive mouse events.
  * an activable layer becomes `hot` when the mouse is over it.
  * a layer can capture mouse movements while a mouse button is down by
  setting its `active` property on `mousedown` and clearing it on `mouseup`.
  this will be done automatically if `mousedown_activate` is set.
  * while a layer is `active`, it continues to be `hot` and receive
  `mousemove` events even when the mouse is outside its hit-test area or
  outside the window even (that is, the mouse is captured).

#### Keyboard interaction

  * layers must be set `focusable` in order to receive keyboard events.
  * keyboard events are only received by the focused layer and bubble up
  to its parents.
  * return `true` in a `keydown` event to eat up a key stroke so that it
  isn't used by other actions: this is how key conflicts are solved.

#### Drag & drop

  * a layer must be in `active` state for dragging to work.
  * when the user starts dragging a layer, the `start_drag()` method is
  called on the layer (which by default doesn't do anything). Draggable
  layers must implement this method to return the layer that is to be dragged
  (could be `self` or other layer) and an optional "grab position" inside
  that layer. If a layer is returned, a dragging operation starts and the
  `started_dragging()` event is fired on the dragged layer.
  * when the dragging operation starts, all visible and enabled layers from
  all windows are asked to `accept_drag_widget()`. Those that can be a drop
  target for the dragged layer must return `true` (the default implementation
  does not return anything) after which the dragged layer is asked to
  `accept_drop_widget()` too (the default implementation returns `true`).
  The potential drop targets then get the `:drop_target` tag.
  * when the layer is dragged over an accepting layer, `accept_drag_widget()`
  and `accept_drop_widgets()` are called again on the respective layers,
  this time with a mouse position and target area. If these calls both
  return `true`, the dragged layer receives the `enter_drop_target()` event.
  * when the mouse is depressed over a drop target, the drop target receives
  the `drop()` event, the dragged layer receives the `ended_dragging()` event,
  and the initiating layer receives the `end_drag()` event.

### Input model API

------------- -------------------------------------------- -------------------
              __enabled state__
r/w property  `enabled`                                    enabled and all parents are enabled too
tag           `:disabled`                                  layer is disabled (`enabled` property is false)
              __hot state__
r/o property  `hot`                                        mouse pointer is over the layer (or the layer is active)
tag           `:hot`                                       layer is hot
tag           `:hot_<area>`                                layer is hot and on a specific area
              __active state__
r/w property  `active`                                     mouse is captured
tag           `:active`                                    layer is active
event         `activated()`                                layer activated (mouse captured)
event         `deactivated()`                              layer deactivated
              __mouse events & state__
event         `mousemove(x, y, area)`                      mouse moved over a layer's area
event         `mouseenter(x, y, area)`                     mouse entered a layer's area
event         `mouseleave()`                               mouse left the layer's area
event         `[right|middle]mousedown(x, y, area)`        mouse left/right/middle button pressed
event         `[right|middle]mouseup(x, y, area)`          mouse left/right/middle button depressed
event         `[right|middle]click(x, y, area)`            mouse left/right/middle button click
event         `[right|middle]doubleclick()`                mouse left/right/middle button double-click
event         `[right|middle]tripleclick()`                mouse left/right/middle button triple-click
event         `[right|middle]quadrupleclick()`             mouse left/right/middle button quadruple-click
event         `mousewheel(delta, x, y, area, pdelta)`      mouse wheel moved `delta` notches
r/o property  `mouse_x, mouse_y`                           mouse coords from the last mouse event
              __focused state__
r/o property  `focused`                                    has keyboard focus
tag           `:focused`                                   layer has focus
tag           `:child_focused`                             layer is a parent of a layer that has focus
method        `focus()`                                    focus layer
method        `unfocus()`                                  unfocus layer
event         `gotfocus()`                                 layer focused
event         `lostfocus()`                                layer unfocused
              __keyboard events__
event         `keydown(key)`                               key pressed
event         `keyup(key)`                                 key released
event         `keypress(key)`                              key pressed (on repeat)
event         `keychar(s)`                                 utf-8 sequence entered
              __drag & drop__
stub method   `start_drag(button, mx, my, area)`           called on dragging layer to start dragging
stub method   `accept_drag_widget(widget, mx, my, area)`   called on drop target to accept the payload
stub method   `accept_drop_widget(widget, area)`           called on dragged layer accept the target
event         `started_dragging()`                         fired on dragged layer after dragging started
event         `drag(x, y)`                                 fired on dragged layer while dragging
event         `enter_drop_target(widget, area)`            fired on dragged layer when entering a target
event         `leave_drop_target(widget)`                  fired on dragged layer when leaving a target
event         `drop(widget, x, y, area)`                   fired on drop target to perform the drop
event         `ended_dragging()`                           fired on dragged layer after dragging ended
event         `end_drag(drag_widget)`                      called on initiating layer after dragging ended
tag           `:dragging`                                  layer is being dragged
tag           `:dropping`                                  dragged layer is over a drop target
tag           `:drop_target`                               layer is a potential drop target
tag           `:drag_source`                               dragging was initiated from this layer
------------- -------------------------------------------- -------------------

### Layouting

Layouting deals with sizing and positioning layers automatically to
accommodate both the content size and the window size. Layers with different
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
`background_operator`            'source'         makes it clear the background
-------------------------------- ---------------- ------------------------------------------------------------------

User-created layers must ultimately be atteched to the window's view (or to
the window itself which will attach them to the window's view) in order to be
visible and respond to user input. The view is the only layer whose `parent`
is a window, not another layer.

## Widgets

Widgets are layers (usually containing other layers) with custom styling
and behavior and additional properties, methods and events. Widgets can be
extended by subclassing and overriding and can be re-styled with `ui:style()`
or by assigning them a different stylesheet.

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

## Creating new widgets

The API for creating and extending widgets is larger and more complex
than the API for instantiating and using existing widgets. This is normal,
since widgets are supposed to encapsulate complex user interaction patterns
as well as provide customizable presentation and behavior.

The main topics that need to be understood in order to create new widgets are:

 * the [object system][oo] and its extensibility mechanisms:
	* subclassing and instantiation
	* virtual properties
	* method overriding
 * the [event system][events].
 * the `ui.object` class and its meta-programming utilities (decorators).
 * the `ui.element` class and the way its constructor works.
 * the `ui.layer` class and its visual model:
	* layer hierarchies with relative affine transforms and clipping
	* borders, backgrounds, shadows, aligned text
	* hit testing
	* layouting, for making the widgets elastic
 * the `ui.window` and `ui.layer` classes, which together provide an input API:
   * routing mouse events to the hot widget; mouse capturing
	* routing keyboard events to the focused widget; tab-based navigation
	* the drag & drop API (event-based)

### The `ui.object` base class

  * inherits [oo].Object.
  * inherits the [events] mixin.
  * common ancestor of all classes.
  * tweaked so that class hierarchy depth does not affect performance.

#### Method & property decorators

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

### Error reporting

### `object:warn(fmt, ...)`

Issue a warning on `stderr`.

### `object:check(ret, fmt, ...) -> ret|nil`

Issue a warning if `ret` is falsey or return `ret`.

### Submodule autoloading

### `object:autoload(t)`

See [glue].autoload.

### The element constructor

  * the order in which attribute values are copied over when creating a new
  element can be altered with the class method
  `:init_priority{field->priority}` to accommodate any dependencies between
  properties.
  * some properties can be excluded from being automatically set this way
  with the class method `:init_ignore{field->true}`, in which case they
  must be set manually in the constructor.
  * `init_priority()` and `init_ignore()` can be called multiple times on
  the same class, adding new fields every time.
  * the constructor `:init(ui, t)` receives `ui` followed by the merged arg
  table which is also set up to inherit the class, thus providing transparent
  access to defaults.

