---
tagline: 3-point parametrization of circles
---

## `local circle_3p = require'path_circle_3p'`

### `circle_3p.to_circle(x1, y1, x2, y2, x3, y3) -> cx, cy, r`
Find the unique circle that passes through 3 points.
If the points are collinear or any two points are coincidental, nothing is returned.


----
See also: [path_arc_3p]
