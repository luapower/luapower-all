---
tagline: cairo scene graph rendering
---

## `local SG = require'sg_cairo'`

Rendering of cairo 2D scene graph objects.

### `SG:new(surface[,cache]) -> sg`

Create a new scene graph renderer that can draw scene graph objects on a cairo surface. A cache object can be passed
so you can share cached resources like fonts and images with other renderers, otherwise a private cache object will be created.

### `sg:render(object)`

Render a scene graph object on the cairo surface of the renderer.

### `sg:preload(object)`

Preload a scene graph object. Loads images and fonts into the cache.

### `sg:measure(object) -> x1,y1,x2,y2`

Compute the bounding box of the object in device coordinates.
_Note that the box is wrong for strokes with width greater than 1 - this may be a cairo bug._

### `sg:hit_test(x, y, object) -> {object1,...}`

Hit-test a point on a scene graph. Returns all hit objects, from the outermost to innermost.

## Cairo scene graph objects

A scene graph object is a plain Lua table describing what is to be rendered. It can be a color, gradient, image,
shape, group, svg or some other extended type. A group describes a list of objects of any type to be painted in order.
A shape describes a path to be filled and/or stroked with an object of any type, including a group or another shape.
Attributes describing space transforms, transparency, painting operator and visibility apply to all object types.

_N is number, S is string, true | false is boolean, CDATA is ffi cdata.
The value in parens is the default value for the property.
Missing values are replaced with defaults, not inherited, so that an object's style is context-independent,
and only the transformation matrix and clipping area are contextual._

~~~{.lua}
<object> = {
	<color> | <gradient> | <image> | <shape> | <group> | <svg> | <extension>,

	absolute = true | false (false),
	matrix = {a, b, c, d, e, f} (nil),
	x = N (0), --translation x
	y = N (0), --translation y
	angle = N (0), --rotation angle in degrees
	cx = N (0), --x of center of rotation and scale
	cy = N (0), --y of center of rotation and scale
	sx = N (1), --x scale
	sy = N (1), --y scale
	scale = N (1),
	skew_x = N (0),
	skew_y = N (0),
	transforms = {
		{'matrix', a, b, c, d, e, f} |
		{'translate', x, y (0)} |
		{'rotate', angle, cx (0), cy (0)} |
		{'scale', scale | sx, sy} |
		{'skew', x, y},
		...
	} (nil)

	alpha = N (1), --clamped to 0..1

	operator =
		'clear' | 'source' | 'over' | 'in' | 'out' | 'atop' | 'dest' | 'dest_over' | 'dest_in' | 'dest_out' |
		'dest_atop' | 'xor' | 'add' | 'saturate' | 'multiply' | 'screen' | 'overlay' | 'darken' |
		'lighten' | 'color_dodge' | 'color_burn' | 'hard_light' | 'soft_light' | 'difference' |
		'exclusion' | 'hsl_hue' | 'hsl_saturation' | 'hsl_color' | 'hsl_luminosity' (over),

	hidden = true | false (false),

	invalid = true | false (false) (*),
	nocache = true | false (false) (*),
}

(*) cache control options apply to path, font.file, image.file, svg.file, and gradient nodes.

<color> =
	type = 'color', r, g, b, a (1) --values are clamped to 0..1

<gradient> =
	type = 'gradient',
	<linear-gradient> | <radial-gradient>

	<linear-gradient> =
	x1 = N, y1 = N, x2 = N, y2 = N,

	<radial-gradient> =
	x1 = N, y1 = N, x2 = N, y2 = N, r1 = N, r2 = N,

	relative = true | false (false),
	filter = 'fast' | 'good' | 'best' | 'nearest' | 'bilinear' | 'gaussian' (fast),
	extend = 'none' | 'repeat' | 'reflect' | 'pad' (pad)

<image> =
	type = 'image',
	file = {type = S (inferred from file extension), path = S | string = S | cdata = CDATA, size = N},
	filter = 'fast' | 'good' | 'best' | 'nearest' | 'bilinear' | 'gaussian' (best),
	extend = 'none' | 'repeat' | 'reflect' | 'pad' (none),

<shape> =
	type = 'shape',
	path = <path_object> (see the path module),

	fill = <object> (nil),
	fill_rule = 'nonzero' | 'evenodd' (nonzero),

	stroke = <object> (nil),
	line_dashes = {offset = N (0), N1,...} (nil, no dashes)
	line_width = N (1),
	line_cap = 'butt' | 'round' | 'square' (square),
	line_join = 'miter' | 'round' | 'bevel' (miter),
	miter_limit = N (4),

	stroke_first = true | false (false),


<font> = {
	<font-spec> | <font-file>

	<font-spec> =
		family = S (Arial),
		slant = 'normal' | 'italic' | 'oblique' (normal),
		weight = 'normal' | 'bold' (normal),

	<font-file> =
		file = {
			path = S,
			load_options = { --default is false for all options
				default = true | false, no_scale = true | false, no_hinting = true | false,
				render = true | false, no_bitmap = true | false, vertical_layout = true | false,
				force_autohint = true | false, crop_bitmap = true | false, pedantic = true | false,
				ignore_global_advance_width = true | false, no_recurse = true | false,
				ignore_transform = true | false, monochrome = true | false, linear_design = true | false,
				no_autohint = true, false
			} (nil, all false)
		},

	options = {
		antialias = 'default' | 'none' | 'gray' | 'subpixel' | 'fast' | 'good' | 'best' (default),
		subpixel_order = 'default' | 'rgb' | 'bgr' | 'vrgb' | 'vbgr' (default),
		hint_style = 'default' | 'none' | 'slight' | 'medium' | 'full' (default),
		hint_metrics = 'default' | 'off' | 'on' (default),
	},
	size = N (12),
}

<svg> =
	type = 'svg',
	file = {path = S | string = S | cdata = CDATA, size = N | read = function() -> <S, size | nil>},

<group> =
	type = 'group', <object>, ...

<extension> =
	type = <name>, ... (the object is drawn by invoking the render function sg.draw[name])

~~~

See [path2] for how to specify path_objects.

