---
tagline: elliptic arcs
---

## `local arc = require'path_arc'`

Math for 2D elliptic arcs defined as:

	center_x, center_y, radius_x, radius_y, start_angle, sweep_angle, [rotation], [x2, y2]

where:

  * (`center_x`, `center_y`) is the ellipse center point.
  * `radius_x` and `radius_y` are the ellipse radii. If negative, the absolute values are used.
  * `start_angle` is the angle where the sweeping starts, in degrees. The modulo 360 value is used.
  * `sweep_angle` is the sweep angle, in degrees. If positive, the arc is sweeped clockwise and if negative, anticlockwise.
    It is capped to the -360..360 degree range when converting to bezier curves and when computing the endpoints,
	 but otherwise the time on the arc is relative to the full sweep, even when the sweep exceeds a full circle.
  * `rotation` is the x-axis rotation of the arc around its center and defaults to 0.
  * `(x2, y2)` is an optional override for the arc's second end point. It is useful when it is required that
    the arc ends at an exact coordinate.

### `arc.observed_sweep(sweep_angle) -> sweep_angle`

The observed sweep is `sweep_angle` capped to the -360..360 degree range.

### `arc.sweep_between(a1, a2[, clockwise]) -> sweep_angle`

Observed sweep between two arbitrary angles, sweeping from `a1` to `a2` in the specified direction (default is clockwise).

### `arc.sweep_time(hit_angle, start_angle, sweep_angle) -> t`

Find an arc's sweep time for a specified angle. If `hit_angle` is over the arc's sweep, the resulted time is in the 0..1 range.

The arc's sweep time is the linear interpolation the arc's sweep interval (in the direction of the sweep) over the 0..1 range. Thus the sweep at t = 0 is 0 and the sweep at t = 1 is `sweep_angle`.

### `arc.is_sweeped(hit_angle, start_angle, sweep_angle) -> true | false`

Check if an angle is inside the sweeped arc, in other words if the sweep time is in the 0..1 range.

### `arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix]) -> x1, y1, x2, y2`

Return the (transformed) endpoints of an elliptic arc.

### `arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix], [segment_max_sweep])`

Construct an elliptic arc from cubic bezier curves.
  * `write` is the consumer function to receive the curves, which is called as:
    `write('curve', x2, y2, x3, y3, x4, y4)`
  The `(x1, y1)` of each curve is the `(x4, y4)` of the last curve. The `(x1, y1)` of the first curve can be computed with a call to `arc.endpoints()`.
  * `matrix` is an optional [affine2d affine transform] that is applied to the resulted segments.
  * `segment_max_sweep` is for limiting the portion of the arc that each bezier segment can cover. The smaller the sweep, the more precise the approximation. If not enforced, this value is computed automatically from the arc's radii and transformation such that an acceptable precision is achieved for screen resolutions.

### `arc.point(t, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix]) -> x, y`

Evaluate an elliptic arc at sweep time t. The time between 0..1 covers the arc over the sweep interval.

### `arc.tangent_vector(t, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix]) -> x0, y0, x1, y1`

Return the tangent vector on an elliptic arc at time `t`. The vector is always oriented towards the sweep of the arc.

### `arc.hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix], [segment_max_sweep]) -> d2, x, y, t`

Compute the shortest distance from point `(x0, y0)` to an elliptic arc, possibly after applying an affine transform. Return the distance squared, the touch point (the point where the perpendicular hits the arc) and the time on the arc where the touch point would split the arc.

### `arc.split(t, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2]) -> `
  ### `cx1, cy1, rx1, ry1, start_angle1, sweep_angle1, rotation1,`
  ### `cx2, cy2, rx2, ry2, start_angle2, sweep_angle2, rotation2, x22, y22`

Split an elliptic arc at time value t where t is capped between 0..1. Optional arguments are returned as nil.

### `arc.length(t, cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix], [segment_max_sweep]) -> len`

Compute the length of an arc at time `t`. For untransformed circular arcs, the length is computed by the well known formula for circle length. Otherwise, the arc is transformed into cubic bezier segments and the sum of the lengths of the segments is computed.

### `arc.bounding_box(cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2], [matrix], [segment_max_sweep]) -> x, y, w, h`

Compute the bounding box of an arc. For untransformed circular arcs, the bounding box is computed very easily based on arc endpoints and sweep check at 0°, 90°, 180° and 270° angles. Otherwise, the arc is transformed into cubic bezier segments and the bounding box of the bounding boxes of the segments is computed.

### `arc.to_svgarc(cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2]) -> x1, y1, radius_x, radius_y, rotation, large_arc_flag, sweep_flag, x2, y2`

Convert an elliptic arc from center parametrization to [path_svgarc][endpoint parametrization].

### `arc.to_arc_3p(cx, cy, rx, ry, start_angle, sweep_angle, [rotation], [x2, y2]) -> x1, y1, xp, yp, x2, y2`

Convert a circular arc from center parametrization to [path_arc_3p][3-point parametrization].

If the arc is not circular, (that is, if `rx ~= ry`) the parametrization is invalid and the function returns nothing.


----
See also: [path_svgarc]
