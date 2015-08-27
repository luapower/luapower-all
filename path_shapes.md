---
tagline: 2D closed shapes
---

##	local shapes = require'path_shapes'

Drawing and other math for 2D closed shapes.
All construction routines take a `write` consumer function which will be called as: `write(command, args...)`.

## Ellipses

### `shapes.ellipse_to_bezier3(write, cx, cy, rx, ry)`
### `shapes.ellipse_bbox(cx, cy, rx, ry) -> left, top, width, height`

## Circles

### `shapes.circle_to_bezier3(write, cx, cy, r)`
### `shapes.circle_to_bezier2(write, cx, cy, r[, segments])`
### `shapes.circle_bbox(cx, cy, r) -> left, top, width, height`
### `shapes.circle_length(cx, cy, r) -> length`
### `shapes.circle_3p_to_bezier3(write, x1, y1, x2, y2, x3, y3)`

## Rectangles

### `shapes.rect_to_lines(write, x, y, w, h)`
### `shapes.rect_to_straight_lines(write, x, y, w, h)`
### `shapes.rect_bbox(x, y, w, h) -> left, top, width, height`
### `shapes.rect_length(x, y, w, h) -> length`

## Rectangles with rounded corners

### `shapes.round_rect_to_bezier3(write, x, y, w, h, r)`
### `shapes.round_rect_to_arcs(write, x, y, w, h, r)`
### `shapes.round_rect_bbox(write, x, y, w, h, r)`
### `shapes.round_rect_length(x, y, w, h, r) -> length`

## Rectangles with elliptic arc corners

### `shapes.elliptic_rect_to_bezier3(write, x, y, w, h, rx, ry)`
### `shapes.elliptic_rect_to_elliptic_arcs(write, x, y, w, h, rx, ry)`
### `shapes.elliptic_rect_bbox(x, y, w, h, rx, ry) -> left, top, width, height`

## Stars and Regular Polygons

### `shapes.rpoly_to_lines(write, cx, cy, x1, y1, n)`
Construct a regular polygon with line segments. A regular polygon has a center, an anchor point and a number of segments.

### `shapes.star_to_star_2p(cx, cy, x1, y1, r2, n) -> cx, cy, x1, y1, x2, y2, n`
Convert a simple star to a 2-anchor-point star. A simple star has a center, an anchor point, a secondary radius and a number of leafs. A 2-anchor-point star has a center, two anchor points and a number of leafs.

### `shapes.star_to_lines(write, cx, cy, x1, y1, r2, n)`
Construct a star with line segments.

### `shapes.star_2p_to_lines(write, cx, cy, x1, y1, x2, y2, n)`
Construct a 2-anchor-point star using line segments.

## Formulas and the Superformula

### `shapes.formula_to_lines(write, formula, steps, ...)`
Linearly interpolate a shape defined by a custom formula, and unite the points with line segments.

### `shapes.superformula(t, cx, cy, size, a, b, m, n1, n2, n3)`
Return the point at time t (t covers the entire shape in the 0..1 range) on a [superformula](http://en.wikipedia.org/wiki/Superformula).

### `shapes.superformula_to_lines(write, cx, cy, size, steps, a, b, m, n1, n2, n3)`

Construct a superformula by linear interpolation using `steps` number of line segments.
