---
tagline: 2D cubic bezier curves
---

## `local bezier3 = require'path_bezier3'`

Math for 2D cubic bezier curves defined as
  `x1, y1, x2, y2, x3, y3, x4, y4`
where `(x1, y1)` and `(x4, y4)` are the end points and `(x2, y2)` and `(x3, y3)` are the control points or handles.

### `bezier3.bounding_box(x1, y1, x2, y2, x3, y3, x4, y4) -> left, top, width, height`

Compute the bounding box using derivative root finding (closed form solution, no dynamic allocations).

### `bezier3.point(t, x1, y1, x2, y2, x3, y3, x4, y4) -> x, y`

Evaluate a cubic bezier at parameter t using De Casteljau linear interpolation.

### `bezier3.length(t, x1, y1, x2, y2, x3, y3, x4, y4) -> length`

Return the length of the curve at parameter t. The approximation is done by way of Gauss quadrature and is thus very fast and accurate and does no dynamic allocations. The algorithm is explained in detail [here](http://processingjs.nihongoresources.com/bezierinfo/#intoffsets_c).

### `bezier3.split(t, x1, y1, x2, y2, x3, y3, x4, y4) -> ax1, ay1, ax2, ay2, ax3, ay3, ay4, bx1, by1, bx2, by2, bx3, by3, by4`

Split a cubic bezier at parameter t into two cubic curves using De Casteljau linear interpolation.

### `bezier3.hit(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4) -> d2, x, y, t`

Find the nearest point on a cubic bezier curve by way recursive subdivision of a 5th degree bezier curve.

Return the shortest distance squared from point `(x0, y0)` to the curve, plus the touch point, and the parametric value t on the curve where the touch point would split the curve.

The algorithm originates from Graphics Gems
([NearestPoint.c](http://webdocs.cs.ualberta.ca/~graphics/books/GraphicsGems/gems/NearestPoint.c)).
The Lua implementation is fast making no dynamic allocations.

### `bezier3.interpolate(write, x1, y1, x2, y2, x3, y3, x4, y4, [m_approximation_scale, [m_angle_tolerance, [m_cusp_limit]]])`

Approximate a cubic bezier curve with line segments which are outputted by calling the provided `write` function
as `write('line', x2, y2)`. Only the second point of each segment is thus outputted.

  * `m_approximation_scale` must be adjusted to the overall scale of the world-to-screen transformation.
  * `m_angle_tolerance` should only be enabled when the width of the scaled stroke is greater than 1.
  * `m_cusp_limit` should not exceed 10-15 degrees.

The algorithm is from the AGG library and it's described in detail
[here](http://www.antigrain.com/research/adaptive_bezier/index.html).

The Lua implementation makes no dynamic allocations and the recursion is depth limited.

Unlike linear interpolation, adaptive interpolation provides a constant approximation error at any given scale,
resulting in the smallest number of segments. Collinearity detection with this algorithm is not cheap but results
in versatile curves. Since the approximation error is adapted to both angle and scale, offsets look good,
non-linear transformations can be applied on the resulted segments, and a simple scanline rasterizer can be used
for fast rendering of the segments.

----
See also: [path_bezier2]
