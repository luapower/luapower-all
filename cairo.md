---
tagline: cairo graphics engine
---

## `local cairo = require'cairo'`

A lightweight ffi binding of the [cairo graphics] library with the following features:

  * cairo types have associated methods, so you can use `context:paint()` instead of `cairo.cairo_paint(context)`
  * pointers to objects for which cairo holds no references are bound to Lua's garbage collector to prevent leaks
  * ref-counted objects have a free() method that checks ref. count and a destroy() method that doesn't.
  * functions that work with `char*` are made to accept/return Lua strings.
  * output buffers are optional - if not passed on as arguments, temporary buffers are allocated instead; the values in the buffers are then returned as multiple return values, such as in `context:clip_extents([dx1][,dy1][,dx2[,dy2]) -> x1, y1, x2, y2`, where dx1 etc. are `double[1]` buffers.
  * the included binary is built with support for in-memory surfaces, recording surfaces, ps surfaces, pdf surfaces, svg surfaces, win32 surfaces, win32 fonts and freetype fonts.

See the [cairo manual] for the function list, remembering that method call style is available for them.

Additional wrappers are provided for completeness:

-------------------------------------------- ------------------------------------------------
`cr:quad_curve_to(x1, y1, x2, y2)`           add a quad bezier to the current path
`cr:rel_quad_curve_to(x1, y1, x2, y2)`       add a relative quad bezier to the current path
`cr:circle(cx, cy, r)`                       add a circle to the current path
`cr:ellipse(cx, cy, rx, ry)`                 add an ellipse to the current path
`cr:skew(ax, ay)`                            skew current matrix
`cr:rotate_around(cx, cy, angle)`            rotate current matrix around point
`cr:safe_transform(mt)`                      transform current matrix if possible
`mt:transform(with_mt) -> mt`                transform matrix with other matrix
`mt:invertible() -> true|false`              is matrix invertible?
`mt:safe_transform(with_mt)`                 transform matrix if possible
`mt:skew(ax, ay)`                            skew matrix
`mt:rotate_around(cx, cy, angle)`            rotate matrix around point
`surface:apply_alpha(alpha)`                 make surface transparent
-------------------------------------------- ------------------------------------------------

[cairo graphics]:   http://cairographics.org/
[cairo manual]:     http://cairographics.org/manual/

