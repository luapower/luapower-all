
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

## Before using

You need to get some fonts in order to see text on screen. Refer to
[Font management](#font-management) below for that.

Besides the many hard dependencies this library has, there are also a few
runtime dependencies that are only loaded if/when certain features are used:

  * [libjpeg], if jpeg images are used.
  * [gfonts], if google fonts are used.

## Example

~~~{.lua}
local ui = require'ui'

local win = ui:window{
	cw = 500, ch = 300,   --client area size
	title = 'UI Demo',    --titlebar text
	autoquit = true,      --quit the app on close
}

local btn1 = ui:button{
	parent = win,         --top-level widget
	x = 100, y = 100,     --manually positioned by default
	text = 'Close',       --sized to fit the text by default
	cancel = true,        --close the window on Esc
	tags = 'blue',        --add a tag for styling
}

--style blue buttons for when mouse is over and no buttons are pressed.
ui:style('button blue :hot !:active', {
	background_color = '#66f', --make the background blue
})

function btn1:pressed() --handle button presses
	print'Button pressed!'
end

win:on('closed', function(self) --another way to set up an event handler
	print'Bye!'
end)

ui:run()
~~~

## Class hierarchy

  * [`oo.Object`][oo] - [oo]'s base class
     * `ui.object` - ui's base class. includes the [events] mixin.
        * [`ui`][ui] - this module, also serving as the app singleton
        * [`ui.selector`](#selectors) - element selector
        * `ui.element_list` - list of elements
        * [`ui.stylesheet`](#stylesheets) - stylesheet
        * [`ui.transition`](#transition-animations) - attribute transition
        * [`ui.element`](#elements) - object with styles and transitions
           * [`ui.window`](#windows) - top-level window: a thin layer over [nw]'s windows
              * [`ui.popup`](#pop-up-windows) - frameless pop-up window
           * [`ui.layer`](#layers) - the basic UI building block
              * [`ui.window_view`](#the-top-layer) - a window's top layer
              * [`ui.button`](#buttons) - button
              * [`ui.menu`](#menus) - menu
              * [`ui.editbox`](#editboxes) - editbox
              * [`ui.dropdown`](#drop-downs) - drop-down menu
              * [`ui.slider`](#sliders) - slider
                * [`ui.toggle`](#toggle-buttons) - toggle button
				  * [`ui.checkbox`](#checkboxes) - checkbox
                * [`ui.radiobutton`](#radio-buttons) - radio button
              * [`ui.choicebutton`](#choice-buttons) - choice button
              * [`ui.colorpicker`](#color-pickers) - color picker
              * [`ui.calendar`](#calendars) - calendar
              * [`ui.progressbar`](#progress-bars) - progress bar
              * [`ui.grid`](#editable-grids) - editable grid
              * [`ui.scrollbar`](#scroll-bars) - scrollbar
              * [`ui.scrollbox`](#scroll-boxes) - scrollbox
              * [`ui.tablist`](#tab-lists) - tab list


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

Fonts must be registered before they can be used (fonts can be loaded from
files or from memory buffers). A few default fonts are registered
automatically to make the default styles work.

#### Default fonts

Default fonts are in packages
[fonts-open-sans](/fonts-open-sans) and
[fonts-ionicons](/fonts-ionicons).
If you are on multigit, you can get them with:

	$ mgit clone fonts-open-sans fonts-ionicons

If you have them somewhere else, set `ui.default_fonts_path` after
loading [ui]. Or set `ui.use_default_fonts` to `false` if you don't want
default fonts at all.

#### Custom fonts

Custom fonts can be added with:

  * `ui:add_font_file(...)`, which calls `tr:add_font_file(...)`, or
  * `ui:add_mem_font(...)`, which calls `tr:add_mem_font(...)`.

See [tr] for details on those methods. To change the default font used
for text by all the layers and widgets, set `ui.layer.font` before creating
any layers or widgets, or add a style on the `layer` tag with that.

#### Fonts from google fonts

Fonts from the google fonts repository can be used directly by name without
the need to register them. To enable this, clone the google fonts repository
with:

	$ git clone https://github.com/google/fonts media/fonts/gfonts

and set `ui.use_google_fonts = true` before using [ui]. Set
`ui.google_fonts_path` too if you cloned the repo somewhere else. You also
need the [gfonts] module:

	$ mgit clone gfonts

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
  * match missing tags: `'tag1 !tag2'` -- in CSS: `tag1:not(.tag2)`

Selector objects are created with `ui:selector(select_text)`. It's not
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

Selector-based styles are created with `ui:style(selector, attr_values)`
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
  * `'replace_value'` - replace current transition's end value, or create
  a new transition.
  * `'restart'` - replace current transition with the new one, and also,
  start from the initial value instead of from the current value.
  * `'wait'` - wait for the current transition to terminate before starting
  the new one, but do nothing if the new transition has the same end value
  as the current one.

### UI State

------------- --------------------------------------- ------------------------
r/o property  `hot_widget`                            currently hot widget
r/o property  `active_widget`                         currently active widget
r/o property  `dragged_widget`                        currently dragged widget
------------- --------------------------------------- ------------------------

## Windows

Like all elements, windows are created with `ui:window(attrs1, ...)`.
Attributes can be passed in multiple initialization tables: the values in
latter tables will take precedence over the values in former tables.

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
`hideonclose, fullscreenable, frame,`
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

### Pop-up windows

Pop-up windows are frameless, non-focusable, non-moveable child windows.
They are created with `ui:popup(attrs1, ...)`. Clicking outside the pop-up
area hides the pop-up, subject to the `autohide` property.

### Moving frameless windows

For frameless windows, a layer (usually the layer representing the title bar)
can be assigned to `win.move_layer` which will set it up to move the window
when dragged.

### Window state

------------- --------------------------------------- ------------------------
r/o property  `win.mouse_x, win.mouse_y`              mouse position at the time of last mouse event
method        `win:mouse_pos() -> x, y`               mouse position at the time of last mouse event
r/o property  `focused_widget`                        currently focused widget (`false` if none)
tag           `:active`                               the window is active
tag           `:fullscreen`                           the window is in fullscreen mode
------------- --------------------------------------- ------------------------

## Layers

Similar to HTML divs, layers encapsulate all the positioning, drawing,
clipping, hit-testing and input infrastructure necessary for implementing
widgets, and can also be used standalone as layout containers, text labels
or other presentation elements.

Like all elements, layers are created with `ui:layer(attrs1, ...)`.
Attributes can be passed in multiple initialization tables: the values in
latter tables will take precedence over the values in former tables.

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
`vscrollable`                        `false`            enable mouse wheel when hot
`hscrollable`                        `false`            enable mouse horiz. wheel when hot
`focusable`                          `false`            can be focused
`draggable`                          `true`             can be dragged (still needs to respond to `start_drag()`)
`background_hittable`                `true`             background area receives mouse input even when there's no background
`mousedown_activate`                 `false`            activate/deactivate on left mouse down/up
`drag_threshold`                     `0`                moving distance before start dragging
`[button]click_chain`                `1`                2 for getting doubleclick events, etc.
`tabgroup`                           `0`                tab group, for tab-based navigation
`tabindex`                           `0`                tab order in tab group, for tab-based navigation
`taborder_algorithm`                 `'xy'`             tab order algorithm: `'xy'`, `'yx'`
__content box__
`padding`                            `0`                padding for all sides
`padding_<side>`                     `false`            `left`/`right`/`top`/`bottom` padding override
__layouting__
`layout`                             `false`            layout model: `false` (none), `'textbox'`, `'flexbox'`, `'grid'`
`min_cw, min_ch`                     `0`                minimum content-box size for flexible layouts
`snap_x`, `snap_y`                   `true`             snap `x, w, min_cw` and `y, h, min_ch` to pixels
__layout=false__
`x, y, w, h`                         `0`                fixed position & size
__flexbox & grid layouts__
`align_items_x`, `align_items_y`     `'stretch'`        `'stretch'`, `'start'`/`'top'`/`'left'`, `'end'`/`'bottom'`/`'right'`, `'center'`, `'space_between'`, `'space_around'`, `'space_evenly'`
`item_align_x`, `item_align_y`       `'stretch'`        `'stretch'`, `'start'`/`'top'`/`'left'`, `'end'`/`'bottom'`/`'right'`, `'center'`, `'baseline'`
`align_x`, `align_y`                 `false`            item override for `item_align_x` and `item_align_y`
__flexbox layout__
`flex_flow`                          `'x'`              main axis of flow: `'x'`, `'y'`
`flex_wrap`                          `false`            line-wrap child layers
`fr`                                 `1`                item stretch fraction for `'stretch'` alignments.
__grid layout__
`grid_flow`                          `'x'`              main axis & direction for automatic positioning: `'x'`, `'y'`, `'xr'`, `'yr'`, `'xb'`, `'yb'`, `'xrb'`, `'yrb'`
`grid_wrap`                          `1`                number of rows/columns on the main axis of flow
`grid_cols`                          `{}`               column stretch fractions `{fr1, ...}`
`grid_rows`                          `{}`               row stretch fractions `{fr1, ...}`
`grid_gap`                           `0`                gap size between grid rows & columns
`grid_col_gap`                       `false`            override gap size for grid columns
`grid_row_gap`                       `false`            override gap size for grid rows
`grid_pos`                           `nil`              element position in grid: `'[row][/span] [col][/span]'`
__transparency & clipping__
`opacity`                            `1`                overall opacity in `0..1`
`clip_content`                       `false`            content clipping: `false` (don't clip), `'padding'`/`true` (clip to content box), `'background'` (clip to background clip box)
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
`background_x/y`                     `0`                background offset coords
`background_rotation`                `0`                background rotation angle (radians)
`background_rotation_cx/cy`          `0`                background rotation center coords
`background_scale`                   `1`                background scale factor
`background_scale_cx/cy`             `0`                background scale center coords
`background_operator`                `'over'`           cairo blending operator
`background_clip_border_offset`      `1`                like `border_offset` but for clipping the background
`background_color`                   `false`            background color
`background_colors`                  `false`            gradient: `{[offset1], color1, ...}`
`background_x1/y1/x2/y2`             `0`                linear gradient: end-point coords
`background_cx1/cy1/cx2/cy2`         `0`                radial gradient: end-point coords
`background_r1/r2`                   `0`                radial gradient: radii
`background_image`                   `false`            background image file (requires [libjpeg])
`background_image_format`            `'%s'`             string.format() template for `background_image`
__shadow__
`shadow_x, shadow_y`                 `0`                shadow offset coords
`shadow_color`                       `'#000'`           shadow color
`shadow_blur`                        `0`                shadow blur size (0=disable)
__text__
`text`                               `false`            text, wrapped around `cw`
`font`                               `'Open Sans,14'`   font spec: `'name [weight] [slant][, size]'`
`font_name`                          `false`            font name override
`font_weight`                        `false`            font weight override: `100..900`, `'bold'`, etc.
`font_slant`                         `false`            font slant override: `'italic'`, `'normal'`
`font_size`                          `false`            font size override
`text_color`                         `'#fff'`           text color
`line_spacing`                       `1`                multiply factor over line height for lines
`paragraph_spacing`                  `2`                multiply factor over line height for paragraphs
`text_dir`                           `'auto'`           BiDi base direction: `'auto'`, `'rtl'`, `'ltr'`
`nowrap`                             `false`            disable automatic line wrapping
`text_operator`                      `'over'`           blending operator (see [cairo])
`text_align_x`                       `'center'`         text x-align: `'left'`, `'center'`, `'right'`, `'auto'`
`text_align_y`                       `'center'`         text y-align: `'top'`, `'center'`, `'bottom'`
__cursor__
`cursor`                             `'arrow'`          default mouse cursor (see [nw] for values)
`cursor_<area>`                      `nil`              mouse cursor for an area
__tooltip__
`tooltip`                            `false`            native tooltip text (false=none)
__rotation & scaling__
`rotation`                           `0`                rotation angle (radians)
`rotation_cx, rotation_cy`           `0`                rotation center coordinates
`scale`                              `1`                scale factor
`scale_cx, scale_cy`                 `0`                scale center coords
------------------------------------ ------------------ ----------------------

### Box model

#### Layer hierarchy

  * layers can be nested, which affects their painting order, clipping and
  positioning relative to each other.
  * layers can be atteched to a parent layer by specifying a `parent`.
  * `parent` can be set to a window object, in which case the window will
  change it to point to its `view` layer.
  * layers can be moved to another parent after creation by changing their
  `parent` property.
  * child layers can be specified in the array parts of the init tables,
  either as plain tables with a `class` attribute or pre-created.

#### Size & positioning

  * layers have a "box" defined by `x, y, w, h` and a "content box"
  (or "client rectangle") which is the same box adjusted by paddings.
  * layers are positioned relative to their parent's _content box_.
  * `x, y, w, h` are input fields (user must set their values) only when
  layouting is disabled on a layer and its parent. When a layout model is
  used, those fields are controlled by the layout.
  * setting `cw, ch, cx, cy, x2, y2` only sets `x, y, w, h` indirectly.

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
method        `bbox_in(parent,x1,y1,...) -> x,y,w,h`  bounding box of a list of points in another layer's content box
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
  * `click_chain` controls how many repeated clicks are to be taken
  as one single click chain (a double-click, triple-click or quadruple-click).
  if set to 1 for instance, double-clicks are never received.

#### Keyboard interaction

  * layers must be set `focusable` in order to receive keyboard events.
  * keyboard events are received by the focused layer first and bubble up
  to all its parents up to its window.
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
tag           `:enabled`                                   `enabled` property is set
              __hot state__
r/o property  `hot`                                        mouse pointer is over the layer (or the layer is active)
tag           `:hot`                                       layer is hot
tag           `:hot_<area>`                                layer is hot on a specific area
              __active state__
r/w property  `active`                                     mouse is captured
tag           `:active`                                    layer is active
event         `activated()`                                layer was activated
event         `deactivated()`                              layer was deactivated
              __mouse events & state__
event         `mousemove(x, y, area)`                      mouse moved over a layer area
event         `mouseenter(x, y, area)`                     mouse entered the layer area
event         `mouseleave()`                               mouse left the layer area
event         `[button]mousedown(x, y, area)`              mouse button pressed
event         `[button]mouseup(x, y, area)`                mouse button depressed
event         `[button]click(x, y, area)`                  mouse button click
event         `[button]doubleclick(x, y, area)`            mouse button double-click
event         `[button]tripleclick(x, y, area)`            mouse button triple-click
event         `[button]quadrupleclick(x, y, area)`         mouse button quadruple-click
event         `mousewheel(delta, x, y, area, pdelta)`      mouse wheel moved `delta` notches
event         `<event>_<area>(...)`                        mouse event over area (all except mouseenter and mouseleave)
r/o property  `mouse_x, mouse_y`                           mouse coords from the last mouse event
              __focused state__
r/o property  `focused`                                    layer has keyboard focus
tag           `:focused`                                   layer is focused
tag           `:child_focused`                             layer is a parent of a layer that has focus
method        `focus()`                                    focus the layer
method        `unfocus()`                                  unfocus the layer
event         `gotfocus()`                                 layer was focused
event         `lostfocus()`                                layer was unfocused
tag           `:window_active`                             layer has focus and window is active
event         `window_activated()`                         window was activated while layer has focus
event         `window_deactivated()`                       window was deactivated while layer has focus
              __keyboard events__
event         `keydown(key)`                               a key was pressed
event         `keyup(key)`                                 a key was released
event         `keypress(key)`                              a key was pressed (on repeat)
event         `keychar(s)`                                 an utf-8 sequence was entered
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
r/o property  `dragging`                                   layer is being dragged
r/o property  `floating`                                   layer is being dragged or its box is animating
tag           `:dragging`                                  layer is being dragged
tag           `:dropping`                                  dragged layer is over a drop target
tag           `:drop_target`                               layer is a potential drop target
tag           `:drag_source`                               dragging was initiated from this layer
------------- -------------------------------------------- -------------------

### Layouting

Layouting deals with sizing and positioning layers automatically to
accommodate both the content size and the window size. Layouting is enabled
via the `layout` attribute. Layers with different layout types and properties
can be mixed freely in a layer hierarchy with some caveats, as explained below.

#### No layout

Layers without a layout (`layout = false`) don't position or size
themselves or their children, but instead ask their children to lay
themselves out according to their own `layout` setting.

No-layout children of no-layout parents _are not_ sized by their parent
and do not size themselves either, thus these layers must be sized and
positioned manually by setting their `x, y, w, h`.

Layouted children of no-layout layers _are not_ sized by their parent
and must thus set their `min_cw, min_ch`, otherwise they will size
themselves to the minimum allowed by their children.

No-layout children of layouted parents _are_ sized by their parent
and must thus set their `min_cw, min_ch`, otherwise they may shrink
to nothing since they don't size themselves to contain their content.

#### Textbox layouts

Freestanding textbox layers (whose parent is not layouted) size themselves
to contain their `text` property which is line-wrapped on their `min_cw`.

#### Flexbox layouts

Flexbox layers use an algorithm similar to the CSS flexbox algorithm
to size themselves and to size and position their children recursively.

#### Grid layouts

Grid layers use an algorithm similar to the CSS grid algorithm to size
themselves and to size and position their children recursively.

#### Wrapping layouts

Layouts with wrapping content (`nowrap = false`, `flex_wrap = true`) are
solved on one axis completely before solving on the other axis. This only
works properly if all the wrappable content has either horizontal flow
(so the whole layout is _width-in-height-out_) or vertical flow (so the
whole layout is _height-in-width-out_). Mixed flows will cause the contents
which wrap perpendicularly to the main flow to overflow their container
(browsers have this limitation too). Setting `min_cw, min_ch` on the
cross-flow layers can be used to alleviate the problem on a case-by-case
basis.

### The top layer

Windows have a top layer in their `view` field. Its size is kept in sync
with the window's client area and it's configured to clear the window's
bitmap on every repaint with these settings:

  * `background_color = '#040404f0'`
  * `background_operator = 'source'`

User-created layers must ultimately be attached to the window's view (or to
the window itself which will attach them to the window's view) in order to be
visible and respond to user input. The window view is the only layer whose
`parent` is a window object, not another layer.

## Widgets

Widgets are layers (usually containing other layers) with custom styling
and behavior and additional properties, methods and events. Widgets can be
extended by subclassing and method overriding and can be over-styled with
`ui:style()` or by assigning them a different stylesheet.

The methods below are actually widget classes used as methods (see the [oo]
section on virtual classes), so `ui.button` is the button class, etc.

----------------------------------------------- ------------------------------
__input widgets__
[`ui:button(...)`](#buttons)                    create a button
[`ui:menu(...)`](#menus)                        create a menu
[`ui:editbox(...)`](#editboxes)                 create an editbox
[`ui:dropdown(...)`](#drop-downs)               create a drop-down
[`ui:slider(...)`](#sliders)                    create a slider
[`ui:toggle(...)`](#toggle-buttons)             create a toggle button
[`ui:checkbox(...)`](#checkboxes)               create a check box
[`ui:radiobutton(...)`](#radio-buttons)         create a radio button
[`ui:choicebutton(...)`](#choice-buttons)       create a choice button
[`ui:colorpicker(...)`](#color-pickers)         create a color picker
[`ui:calendar(...)`](#calendars)                create a calendar
__output  widgets__
[`ui:progressbar(...)`](#progress-bars)         create a progress bar
__input/output  widgets__
[`ui:grid(...)`](#editable-grids)               create a grid
__containers__
[`ui:scrollbar(...)`](#scroll-bars)             create a scroll bar
[`ui:scrollbox(...)`](#scroll-boxes)            create a scroll box
[`ui:popup(...)`](#pop-up-windows)              create a pop-up window
[`ui:tablist(...)`](#tab-lists)                 create a tab list
----------------------------------------------- ------------------------------

__TIP:__ Widgets are implemented in separate modules. Run each module as a
standalone script to see a demo of the widgets implemented in the module.

## Buttons

Buttons are created with `ui:button(attrs1, ...)`.

------------ ---------------------- ------------ -----------------------------
r/w property `default`              `false`      pressing Enter anywhere presses the button
r/w property `cancel`               `false`      pressing Esc anywhere presses the button
r/w property `profile`              `false`      style profile: `false`, `'text'`
r/w property `key`                  `false`      key shortcut (see `app:key()` in [nw])
tag          `:over`                             the button is pressed and the mouse is over the button
event        `pressed()`                         the button was pressed
------------ ---------------------- ------------ -----------------------------

## Menus

Menus are created with `ui:menu(attrs1, ...)`.

------------ ---------------------- ------------ -----------------------------
TODO
------------ ---------------------- ------------ -----------------------------

## Editboxes

Editboxes are created with `ui:editbox(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
__behavior__
r/w property `password`                          `false`      mask characters
r/w property `maxlen`                            `4096`       max text length in codepoints
r/w property `multiline`                                      multi-line scrollable editbox
__styling__
tag          `multiline`                                      editbox is multi-line
tag          `:insert_mode`                                   editor is in insert mode
r/w property `caret_color`	                      `'#fff'`     caret fill color
r/w property `caret_opacity`                     `1           caret opacity
r/w property `selection_color`                   `'#66f8'`    selection fill color
__hit testing__
hittest area `text`                                           area over unselected text
hittest area `selection`                                      area over a selection rectangle
__moving__
event        `caret_moved()`                                  caret moved
__editing__
r/o property `text_len`                                       text length in codepoints
r/w property `insert_mode`                       `false`      insert mode (Insert key toggles)
r/o property `edited`                            `false`      text was edited
method       `undo()`                                         undo the last operation
method       `redo()`                                         redo the last operation
event        `text_changed()`                                 text changed
__drawing__
method       `caret_rect() -> x, y, w, h`                     caret rectangle
method       `draw_password_char(cr, i, w, h)`                draw a password hiding symbol
__cue__
r/w property `cue`                                            cue text
r/w property `show_cue_when_focused`             `false`
------------ ----------------------------------- ------------ ----------------

## Drop-downs

Drop-down menus are created with `ui:dropdown(attrs1, ...)`.

------------ ---------------------- ------------ -----------------------------
TODO
------------ ---------------------- ------------ -----------------------------

## Sliders

Sliders are created with `ui:slider(attrs1, ...)`.

------------ ---------------------- ------------ -----------------------------
r/w property `min_position`         `0`          min. position
r/w property `max_position`         `false`      max. position (overrides `size`)
r/w property `position`             `0`          current position
r/w property `progress`             `false`      current progress (overrides `position`)
r/w property `step_start`           `0`          position of first step
r/w property `step`                 `false`      no stepping
r/w property `step_labels`          `false`      step labels: `{label = value, ...}`
r/w property `snap_to_labels`       `true`       ...if there are any
r/w property `step_line_h`          `5`
r/w property `step_line_color`      `'#fff'`     `false` to disable
r/w property `key_nav_speed`        `0.1`        constant 10% speed on left/right keys
r/w property `smooth_dragging`      `true`       pin stays under the mouse while dragging
r/w property `phantom_dragging`     `true`       drag a secondary translucent pin
event        `position_changed(p)`               slider position changed
component    `track`
component    `fill`
component    `pin`
component    `marker`
component    `tip`
component    `step_label`
------------ ---------------------- ------------ -----------------------------

## Toggle buttons

Toggle buttons are created with `ui:toggle(attrs1, ...)`.

Toggle buttons are custom sliders so all slider options apply.

------------ ----------------------------------- ------------ ----------------
r/w property `option`                            `false`      button is "on" or "off"
tag          `:on`                                            button is "on"
event        `option_changed(v)`                              button was toggled
event        `option_enabled()`                               button was set to "on"
event        `option_disabled()`                              button was set to "off"
------------ ----------------------------------- ------------ ----------------

## Checkboxes

Checkboxes are created with `ui:checkbox(attrs1, ...)`.

Checkboxes are implemented as a flexbox with two items: a button and a textbox.

------------ ----------------------------------- ------------ ----------------
r/w property `align`                             `'left'`     check button alignment vis label
r/w property `checked`                           `false`      checkbox is checked
tag          `:checked`                                       checkbox is checked
event        `was_checked()`                                  checkbox was checked
event        `was_unchecked()`                                checkbox was unchecked
event        `checked_changed(v)`                             checked state changed
component    `button`                                         check button
component    `label`                                          checkbox label
------------ ----------------------------------- ------------ ----------------

## Radio buttons

Radio buttons are created with `ui:radiobutton(attrs1, ...)`.

Radio buttons custom checkboxes so all checkbox options apply.

------------ ----------------------------------- ------------ ----------------
r/w property `radio_group`                       `'default'`  radio button's option group
r/w property `align`                             `'left'`     checkbox alignment vis its label
------------ ----------------------------------- ------------ ----------------

## Radio button lists

Radio button lists are created with `ui:radiobuttonlist(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
TODO
------------ ----------------------------------- ------------ ----------------

## Choice buttons

Choice buttons are created with `ui:choicebutton(attrs1, ...)`.

Choice buttons are functionally like radio button lists. Visually they are
implemented as a flexbox with multiple buttons, one of which is selected.

------------ ----------------------------------- ------------ ----------------
TODO
`event`      `value_selected()`                               a button was selected
------------ ----------------------------------- ------------ ----------------

## Color pickers

Color pickers are created with `ui:colorpicker(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
TODO
------------ ----------------------------------- ------------ ----------------

## Calendars

Calendars are created with `ui:calendar(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
TODO
------------ ----------------------------------- ------------ ----------------

## Progress bars

Progress bars are created with `ui:progressbar(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
r/w property `progress`                          `0`          progress in `0..1`
stub         `format_text(p) -> s`                            format progress text
------------ ----------------------------------- ------------ ----------------

## Editable grids

Grids are created with `ui:grid(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
TODO
------------ ----------------------------------- ------------ ----------------

## Scroll bars

Scroll bars are created with `ui:scrollbar(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
r/w property `content_length`                    `0`
r/w property `view_length`                       `0`
r/w property `offset`                            `0`          in `0..content_length` range
r/w property `vertical`                          `true`       rotated 90deg
r/w property `step`                              `false`      snap
r/w property `autohide`                          `false`      hide when mouse is not near the scrollbar
r/w property `autohide_empty`                    `true`       hide when content is smaller than the view
r/w property `autohide_distance`                 `20`         distance around the scrollbar for `autohide`
r/w property `click_scroll_length`               `300`        how much to scroll when clicking on the track
r/w property `margin`                            `nil`        margin when inside a scrollbox
tag          `:near`                                          autohidden scrollbar is visible
tag          `vertical`                                       scrollbar is vertical
tag          `horizontal`                                     scrollbar is horizontal
method       `empty()`                                        the content is smaller than the view
method       `scroll_to(offset, [duration])`                  scroll to offset
method       `scroll_to_view(x, w, [duration])`               scroll to position in view
method       `scroll(delta, [duration])`                      scroll a number of pixels
method       `scroll_pages(pages, [duration])`                scroll a number of pages
------------ ----------------------------------- ------------ ----------------

## Scroll boxes

Scroll boxes are created with `ui:scrollbox(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
r/w property `wheel_scroll_length`               `50`         how much is a mouse wheel notch
r/w property `auto_h`                            `false`      auto-height: TODO
r/w property `auto_w`                            `false`      auto-width: TODO
r/w property `scroll_margin`                     `0`          `scroll_to_view()` margin
r/w property `scroll_margin_<side>`              `false`      `scroll_margin` side overrides
component    `vscrollbar`                                     the vertical scrollbar
component    `hscrollbar`                                     the horizontal scrollbar
component    `view`                                           content's parent layer
method       `scroll_to_view(x, y, w, h)`                     scroll to view rect in content's content space.
method       `view_rect() -> x,y,w,h`                         view rect in content's content space.
------------ ----------------------------------- ------------ ----------------

## Tab lists

### Tabs

Tabs are created with `ui:tab(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
r/w property `tablist`                                        tab list owner
r/w property `index`                                          order in tab list
r/w property `selected`
method       `select()`
method       `unselect()`
tag          `:selected`
event        `tab_selected()`
event        `tab_unselected()`
method       `close()`
event        `closing() -> [false]`
event        `closed()`
r/w property `draggable_outside`                 `true`       can be dragged out of the tablist
------------ ----------------------------------- ------------ ----------------

### Tab lists

Tab lists are created with `ui:tablist(attrs1, ...)`.

------------ ----------------------------------- ------------ ----------------
i/r property `tabs`
i property   `selected_tab_index`
r/w property `selected_tab`
r/w property `main_tablist`                                   responds to Tab & Ctrl+Tab globally
r/w property `tablist_group`
r/w property `tab_spacing`                       `-10`
r/w property `tab_slant_left`                    `70`         tab slant in degrees
r/w property `tab_slant_right`                   `70`         tab slant in degrees
r/w property `tabs_padding_left`                 `10`
r/w property `tabs_padding_right`                `10`
event        `tab_selected()`
event        `tab_unselected()`
------------ ----------------------------------- ------------ ----------------

## Creating new widgets

The API for creating and extending widgets is necessarily larger and more
complex than the API for instantiating and using existing widgets, since
widgets are supposed to encapsulate complex user interaction patterns
as well as provide customizable presentation and behavior.

The main topics that need to be understood in order to create new widgets
or extend existing ones are:

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
	 * freeing order
  * the `ui.window` and `ui.layer` classes, which together provide an input model:
    * routing mouse events to the hot widget; mouse capturing
    * routing keyboard events to the focused widget; tab-based navigation
    * the drag & drop API
  * drawing with [cairo], if you need procedural 2D drawing.
  * rendering text with [tr], if layers are not enough.

### The `ui.object` base class

  * inherits [`oo.Object`][oo].
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

Issue a warning on `stderr`. Use this to report API misuses that are not
fatal (ideally there should be no fatal errors at all).

### `object:check(ret, fmt, ...) -> ret|nil`

Issue a warning if `ret` is falsey otherwise return `ret`.

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

### Synchronization

Synchronization is about updating a layer's state when its writable
properties are changed. Some parts of the state are updated directly as a
result of updating the property (eg. changing a layer's `parent` property
moves the layer in the layer hierarchy immediately), while others are updated
on the next frame, in a specific order, in multiple passes through the layer
hierarchy: on a first pass, styles are applied (if any tags were added or
removed; this can result in new transitions being created), then transitions
are updated (if there are any in progress) and finished transitions are
discarded. This is done via `sync()` which also calls `sync()` recursively
on the layer's children (hence the top-down call order).

Layouts are updated on a second pass by calling `sync_layout()` on the
window's view layer.

#### Layout synchronization

Every layer has a layout, which is responsible for sizing itself, as well
as sizing and positioning its children. Layouts come in two flavors:
wrapping and non-wrapping.

Non-wrapping layouts (`false` and `'textbox'` types) are computed in a single
top-down pass via `sync_layout()`.

Wrapping layouts (types `'flexbox'` and `'grid'`) are computed in 4 passes
as follows, assuming `layout_axis_order = 'xy'`: a bottom-up pass to compute
the minimum width, a top-down pass to lay out all layers on the x-axis and
line-wrap the horizontally-flowing text, another bottom-up pass to compute
the minimum height now that the text has been wrapped, and a final top-down
pass to lay out all layers on the y-axis. These steps are encapsulated in
`sync_layout_separate_axes()` which call in order: `sync_min_w()`,
`sync_layout_x()`, `sync_min_h()`, `sync_layout_y()`.

Because layers with wrapping layouts can have children with non-wrapping
layouts and viceversa, wrapping layouts must implement `sync_layout()` too
and likewise, non-wrapping layouts must implement `sync_layout_x()`
and `sync_layout_y()`.

### Freeing order

When a layer is freed, it is first unfocused, then its children are removed
recursively depth-first, from the topmost to the bottommost, then the layer
is removed from its parent.

## Extending the core engine

Many aspects of the core engine can also be extended with:

  * adding new attribute types and type matches
  * adding new transition interpolators
  * adding new transition blend modes
  * adding new ways to look-up fonts
  * adding new image file decoders
  * adding new layout systems.

## Changing the underlying libraries

  * changing the 2D graphics library requires mostly just re-implementing
  the various `draw_*()` methods of the layer class, since most widgets
  don't use the graphics library directly, but use layers instead.
  Any library that can draw on a BGRA bitmap can work.
  * changing the text rendering engine requires re-implementing
  `sync_text_*()` and `draw_text()`, except for the editbox widget which
  uses [tr]'s selection and cursor objects extensively to select and edit
  the text, so those would have to be provided too.
  * changing the native windows library is a bit harder because [nw]'s
  API is already very high-level and covers a lot of functionality
  seldom found in other libraries of this type. Adding missing functionality
  to [nw] instead would probably be easier.

## Porting to a new platform

OS integration is done exclusively through the [nw], [fs] and [time] modules,
everything else being portable Lua code or portable C code. Even text shaping,
a task usually delegated to the OS, is done with 100% portable code.
The [nw] library itself has a frontend/backend split since it already
supports multiple platforms, so porting [ui] to a new platform may be
only a matter of adding a new backend to [nw] (not to imply that this
is easy, but at least it's contained).

