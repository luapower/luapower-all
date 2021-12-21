---
tagline: 2D quadratic bezier curves
---

## `local bezier2 = require'path2d_bezier2'`

Math for 2D quadratic bezier curves defined as

	x1, y1, x2, y2, x3, y3

where `(x1, y1)` and `(x3, y3)` are the end points and `(x2, y2)` is the control point.

### `bezier2.bounding_box(x1, y1, x2, y2, x3, y3) -> left, top, width, height`

Compute the bounding box using derivative root finding (fast, no dynamic allocations).

### `bezier2.to_bezier3(x1, y1, x2, y2, x3, y3) -> x1, y1, x2, y2, x3, y3, x4, y4`

Return the [cubic bezier curve][path2d_bezier3] that best approximates the quadratic curve, using degree elevation.

### `bezier2._3point_control_point(x1, y1, x0, y0, x3, y3) -> x2, y2`

Return a fair candidate based on chord lengths for the control point of a quad bezier given
its end points (x1, y1) and (x3, y3) and a point (x0, y0) that lies on the curve.

### `bezier2.point(t, x1, y1, x2, y2, x3, y3) -> x, y`

Evaluate a quadratic bezier at parameter t using De Casteljau linear interpolation.

### `bezier2.length(t, x1, y1, x2, y2, x3, y3) -> length`

Return the length of the curve at parameter t. The approximation is done by way of Gauss quadrature and is thus
very fast and accurate and does no dynamic allocations.
The algorithm is explained in detail [here](http://processingjs.nihongoresources.com/bezierinfo/#intoffsets_c).

### `bezier2.split(t, x1, y1, x2, y2, x3, y3) -> ax1, ay1, ax2, ay2, ax3, ay3, bx1, by1, bx2, by2, bx3, by3`

Split a quadratic bezier at parameter t into two quadratic curves using De Casteljau linear interpolation.

### `bezier2.hit(x0, y0, x1, y1, x2, y2, x3, y3) -> d2, x, y, t`

Find the nearest point on a quadratic bezier curve by way of [solving a 3rd degree equation][eq].

Return the shortest distance squared from point `(x0, y0)` to a quadratic bezier curve, plus the touch point,
and the parametric value t on the curve where the touch point splits the curve.

The algorithm is from [http://blog.gludion.com/2009/08/distance-to-quadratic-bezier-curve.html].

The Lua implementation is closed form and makes no dynamic allocations.

### `bezier2.interpolate(write, x1, y1, x2, y2, x3, y3[, m_approximation_scale[, [m_angle_tolerance]])`

Approximate a quadratic bezier curve with line segments using recursive subdivision.
The segments are outputted by calling the provided `write` function as `write('line', x2, y2)`.
Only the second point of each segment is thus outputted.

  * `m_approximation_scale` must be adjusted to the overall scale of the world-to-screen transformation.
  * `m_angle_tolerance` should only be enabled when the width of the scaled stroke is greater than 1.

The algorithm is from the AGG library and it's described in detail
	[here](http://www.antigrain.com/research/adaptive_bezier/index.html).

The Lua implementation makes no dynamic allocations and the recursion is depth limited.

----
See also: [path2d_bezier3]
