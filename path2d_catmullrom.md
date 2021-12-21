---
tagline: catmull-rom splines
---

## `local catmull = require'path2d_catmullrom'`

Math for 2D Catmull-Rom splines defined as:

	k, x1, y1, x2, y2, x3, y3, x4, y4


### `catmull.to_bezier3(k, x1, y1, x2, y2, x3, y3, x4, y4) -> x1, y1, x2, y2, x3, y3, x4, y4`

Convert a catmull-rom segment to a cubic bezier curve.

### `catmull.point(t, k, x1, y1, x2, y2, x3, y3, x4, y4) -> x, y`

Get the point at time `t` on a catmull-rom segment.

