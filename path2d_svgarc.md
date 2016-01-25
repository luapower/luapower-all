---
tagline: svg-style elliptic arcs
---

## `local svgarc = require'path2d_svgarc'`

Math for 2D [SVG-style] endpoint parametrization elliptic arcs defined as:

	x1, y1, radius_x, radius_y, rotation, large_arc_flag, sweep_flag, x2, y2

where:

  * `(x1, y1)` and `(x2, y2)` are the arc's endpoints
  * `radius_x` and `radius_y` are the two radii of the ellipse. If negative, the absolute values are used.
  * rotation is the x-axis rotation of the ellipse and defaults to 0.
  * `large_arc_flag` is 1 if the arc should be > 180 degrees and 0 if not.
  * `sweep_flag` is 1 for a clockwise sweep and 0 for an anticlockwise sweep.

The two flags are needed because with just the endpoints and the ellipse radii, there can be 2 possible ellipses
and thus 4 possible arcs that can be represented. The flags help narrow it down to one arc.

	svgarc.to_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, ...) ->
		cx, cy, rx, ry, start_angle, sweep_angle, rotation, ...

Convert an elliptic arc from endpoint parametrization to [center parametrization][path2d_arc].

If the endpoints conicide or rx or ry is 0, the parametrization is invalid and nothing is returned.

	svgarc.split(t, x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2) ->
		x11, y11, rx1, ry1, rotation1, large_arc_flag1, sweep_flag1, x22, y22
		x21, y21, rx2, ry2, rotation2, large_arc_flag2, sweep_flag2, x22, y22

Split a svg elliptic arc at time `t` into two svg arcs.

----
See also: [path2d_arc]


[SVG-style]: http://www.w3.org/TR/SVG/paths.html#PathDataEllipticalArcCommands
