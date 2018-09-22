---
tagline: color parsing, formatting and computation
---

## `local color = require'color'`

Color parsing, formatting, conversion and computation in HSL, HSV
and RGB color spaces.

Quick facts:

  * color spaces: `'hsl'`, `'hsv'`, `'rgb'`.
  * `r, g, b, s, L, v` are in `0..1` range, `h` is in `0..360` range.
  * color formats: `'#'`, `'#rrggbbaa'`, `'#rrggbb'`, `'#rgba'`, `'#rgb'`,
  `'#g'`, `#gg`
  `'rgba'`, `'rgb'`, `'rgba%'`, `'rgb%'`, `'hsla'`, `'hsl'`, `'hsla%'`, `'hsl%'`.

## API

---------------------------------------------------- ------------------------------------------------
`color.parse(str[, space]) -> [space, ]x, y, z[, a]` parse color string
`color.convert(dspace, sspace, x, y, z[, a]) -> ...` convert color from sspace to dspace
`color.format([fmt], space, x, y, z[, a]) -> s`      format color (see above)
`color.clamp(space, x, y, z[, a]) -> x, y, z[, a]`   clamp values to color space
---------------------------------------------------- ------------------------------------------------

__NOTE__: x, y, z means r, g, b in the `'rgb'` color space,
h, s, L in the `'hsl'` color space and h, s, v in the `'hsv'` color space.

__NOTE__: When alpha is missing, the color has no alpha when formatting or clamping.

## Color objects

---------------------------------------------------- ------------------------------------------------
__constructors__
`color(str) -> col`                                  create a HSL color object from a string
`color([space, ]x, y, z[, a]) -> col`                create a HSL color object from discrete values
`color([space, ]{x, y, z[, a]}) -> col`              create a HSL color object from a table
`color.hsl(h, s, L[, a]) -> col`                     calls `color('hsl', h, s, L, a)`
`color.hsv(h, s, v[, a]) -> col`                     calls `color('hsv', h, s, v, a)`
`color.rgb(r, g, b[, a]) -> col`                     calls `color('rgb', r, g, b, a)`
__fields__
`col.h, col.s, col.L, col.a`                         color fields (for reading and writing)
`col() -> h, s, L[, a]`                              color fields unpacked
__conversion__
`col:hsl() -> h, s, L`                               color fields unpacked without alpha
`col:hsla() -> h, s, L, a`                           color fields unpacked with alpha
`col:hsv() -> h, s, v`                               convert to HSV
`col:rgb() -> r, g, b`                               convert to RGB
`col:hsva() -> h, s, v, a`                           convert to HSVA
`col:rgba() -> r, g, b, a`                           convert to RGBA
__formatting__
`col:format([fmt]) -> str`                           convert to string
`tostring(col) -> str`                               calls `col:format'#'`
__computation in HSL space__
`col:hue_offset(hue_delta) -> color`                 create a color with a different hue (in degrees)
`col:complementary() -> color`                       create a complementary color
`col:neighbors(angle) -> color1, color2`             create two neighboring colors (by hue), offset by "angle"
`col:triadic() -> color1, color2`                    create two new colors to make a triadic color scheme
`col:split_complementary(angle) -> color1, color2`   create two new colors, offset by angle from a color's complementary
`col:desaturate_to(saturation) -> color`             create a new color with saturation set to a new value
`col:desaturate_by(r) -> color`                      create a new color with saturation set to a old saturation times r
`col:lighten_to(lightness) -> color`                 create a new color with lightness set to a new value
`col:lighten_by(r) -> color`                         create a new color with lightness set to its lightness times r
`col:bw([whiteL]) -> color`                          create a new color with lightness either 0 or 1 based on whiteL threshold
`col:variations(f, n) -> {color1, ...}`              create n variations of a color using supplied function and return them as a table
`col:tints(n) -> {color1, ...}`                      create n tints of a color and return them as a table
`col:shades(n) -> {color1, ...}`                     create n shades of a color and return them as a table
`col:tint(r) -> color`                               create a color tint
`col:shade(r) -> color`                              create a color shade
---------------------------------------------------- ------------------------------------------------


[colors lib]: http://sputnik.freewisdom.org/lib/colors/
