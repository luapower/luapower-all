---
tagline: color computation
---

## `local color = require'color'`

Color computation in HSL space. Shamelessly ripped off and modified from [Sputnik's colors lib][colors lib], by Yuri Takhteyev.

  * `r, g, b, s, L` are in 0..1 range.
  * `h` is in 0..360 range.


## Direct conversions

---------------------------------------------------- ------------------------------------------------
`color.hsl_to_rgb(h, s, L) -> r, g, b`               HSL -> RGB; h is modulo 360; s, L are clamped to range
`color.rgb_to_hsl(r, g, b) -> h, s, L`               RGB -> HSL; r, g, b are clamped to range
`color.rgb_to_string(r, g, b) -> s`                  generate '#rrggbb' hex color
`color.string_to_rgb(s) -> r, g, b | nil`            parse a '#rrggbb' hex color
`color.rgba_to_string(r, g, b, a) -> s`              generate a '#rrggbbaa' hex color
`color.string_to_rgba(s) -> r, g, b, a | nil`        parse a '#rrggbbaa' hex color (the 'aa' part is optional)
---------------------------------------------------- ------------------------------------------------


## Color objects

---------------------------------------------------- ------------------------------------------------
`color('#rrggbb') -> col`                            create a new HSL color object from a RGB string
`color(h, s, L) -> col`                              create a new HSL color object from HSL values
`col.h, col.s, col.L`                                color fields (for reading and writing)
`col:hsl() -> h, s, L` <br> `col() -> h, s, L`       color fields unpacked
`col:rgb() -> r, g, b`                               convert to RGB
`col:tostring() -> '#rrggbb'`                        convert to RGB string
`col:hue_offset(hue_delta) -> color`                 create a new color with a different hue
`col:complementary() -> color`                       create a complementary color
`col:neighbors(angle) -> color1, color2`             create two neighboring colors (by hue), offset by "angle"
`col:triadic() -> color1, color2`                    create two new colors to make a triadic color scheme
`col:split_complementary(angle) -> color1, color2`   create two new colors, offset by angle from a color's complementary
`col:desaturate_to(saturation) -> color`             create a new color with saturation set to a new value
`col:desaturate_by(r) -> color`                      create a new color with saturation set to a old saturation times r
`col:lighten_to(lightness) -> color`                 create a new color with lightness set to a new value
`col:lighten_by(r) -> color`                         create a new color with lightness set to its lightness times r
`col:variations(f, n) -> {color1, ...}`              create n variations of a color using supplied function and return them as a table
`col:tints(n) -> {color1, ...}`                      create n tints of a color and return them as a table
`col:shades(n) -> {color1, ...}`                     create n shades of a color and return them as a table
`col:tint(r) -> color`                               create a color tint
`col:shade(r) -> color`                              create a color shade
---------------------------------------------------- ------------------------------------------------


[colors lib]:    http://sputnik.freewisdom.org/lib/colors/
