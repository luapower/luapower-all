---
tagline: 2D geometry in Lua
---

## in development

Most sub-modules are ready, but they need more integration work.
They can be used independently and they have their own demos and docs.

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

  * [lines][path_line], with horizontal and vertical variations
  * [quadratic bezier curves][path_bezier2] and [cubic bezier curves][path_bezier3], with
    smooth and symmetrical variations
  * absolute and relative-to-current-point variations for all commands
  * [elliptic arcs][path_arc], [3-point circular arcs][path_arc_3p] and
    [svg-style elliptic arcs][path_svgarc] and [3-point circles][path_circle_3p]
  * composite [shapes][path_shapes]:
    * rectangles, including round-corner and elliptic-corner variations
    * circles and ellipses, and 3-point circles
    * 1-anchor-point and 2-anchor-point stars, and regular polygons
    * superformula
  * [text][path_text], using [freetype], [harfbuzz],
    [libunibreak][libunibreak] for fonts and shaping (NYI)
  * [catmull-rom][path_catmull] splines (NYI)
  * [cubic splines][path_spline3] (NYI)
  * [spiro curves][path_spiro] (NYI, also GPL)

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
  * direct manipulation [path editor][path_edit] with chained updates and constraints,
    making it easy to customize and extend to support new command types (TODO).

### Help needed

I am far from being an expert at floating point math. I'm sure there are many opportunities for preserving
precision and avoiding degenerate cases that I've haven't thought about. A code review by someone experienced
in this area would help greatly.

When an elliptic (or circular) arc is approximated with bezier curves, the arc t value (sweep time) is almost
the same as the curve t value (parametric time). Almost, but not quite. The error is contained by increasing
the number of segments that make up the arc. But instead of increasing the number of segments for larger arcs,
I would prefer to have a formula to synchronize the t values for a chosen number of segments, assuming such
formula is easy enough to compute.
