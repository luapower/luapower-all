---
tagline: basic math for the cartesian plane
---

##	local point = require'path2d_point'

Basic math functions for the cartesian plane. Angles are expressed in degrees, not radians.

### `point.hypot(a, b) -> c`
Hypotenuse function: computes `sqrt(a^2 + b^2)` without underflow / overflow problems.

### `point.distance(x1, y1, x2, y2) -> d`
Dstance between two points.

### `point.distance2(x1, y1, x2, y2) -> d2`
Distance between two points squared.

### `point.point_around(cx, cy, r, angle) -> x, y`
Point at a specified angle on a circle.

### `point.rotate_point(x, y, cx, cy, angle) -> x, y`
Eotate point (x,y) around origin (cx,cy) by angle.

### `point.point_angle(x, y, cx, cy) -> angle`
Angle between two points in -360..360 degree range.

### `point.reflect_point(x, y, cx, cy) -> x, y`
Reflect point through origin (i.e. rotate point 180deg around another point).

### `point.reflect_point_distance(x, y, cx, cy, length) -> x, y`
Reflect point through origin at a specified distance.
