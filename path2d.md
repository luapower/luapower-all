---
tagline: 2D geometry in Lua
---

## `local path = require'path'`

Fast, full-featured 2D geometry library written in Lua. \
Includes construction, drawing, measuring, hit testing and editing of 2D paths.

### Overview

  * written in Lua
  * modular, bottom-up style programming (procedural, no state, no objects)
  * dynamic allocations avoided throughout
  * all features available under [affine transformation][affine2d], with fast code paths for special cases
  * full support for SVG path command set and semantics and more.

### Geometric types

  * [lines][path2d_line], with horizontal and vertical variations
  * [quadratic bezier curves][path2d_bezier2] and [cubic bezier curves][path2d_bezier3], with
    smooth and symmetrical variations
  * absolute and relative-to-current-point variations for all commands
  * [elliptic arcs][path2d_arc], [3-point circular arcs][path2d_arc_3p] and
    [svg-style elliptic arcs][path2d_svgarc] and [3-point circles][path2d_circle_3p]
  * composite [shapes][path2d_shapes]:
    * rectangles, including round-corner and elliptic-corner variations
    * circles and ellipses, and 3-point circles
    * 1-anchor-point and 2-anchor-point stars, and regular polygons
    * superformula
  * [catmull-rom][path2d_catmullrom] splines
  * [cubic splines][path2d_spline3] (NYI)
  * [spiro curves][path2d_spiro] (NYI, GPL licensed)
  * [text][path2d_text], using [freetype] and native text engines (NYI)

### Measuring

  * bounding box
  * length at time t
  * point at time t
  * arc length parametrization (NYI)

### Hit testing

  * shortest distance from point
  * inside/outside testing for closed subpaths (NYI)

### Drawing

  * simplification (decomposing into primitive operations)
  * adaptive interpolation of quad and cubic bezier curves
  * polygon offseting with different line join and line cap styles (NYI)
  * dash generation (NYI)
  * text-to-path (NYI)
  * conversion to cairo paths for drawing with [cairo] or with [sg_cairo]
  * conversion to OpenVG paths for drawing with the [openvg] API (NYI)

### Editing

  * adding, removing and updating commands
  * splitting of lines, curves and arcs at time t
  * joining of lines, curves and arcs (NYI)
  * conversion between lines, curves, arcs and composite shapes (NYI).
  * direct manipulation [path editor][path2d_editor] with chained updates and constraints,
    making it easy to customize and extend to support new command types (WIP).

### Help needed

Please see the list of open [issues](https://github.com/luapower/path2d/issues).

