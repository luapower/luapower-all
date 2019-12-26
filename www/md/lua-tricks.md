---
title:   tricks
tagline: quick Lua cheat sheet
---

This is a collection of Lua idioms and tricks that may not be immediately apparent to the casual code reader.

------------------------------------------- -------------------------------------------
__logic__
`not a == not b`                            both or none
__numbers__
math.min(math.max(x, min), max)             clamp x (upper limit takes precedence)
`x ~= x`                                    number is NaN
`1/0`                                       inf
`-1/0`                                      -inf
`math.huge == math.huge-1`                  check if inf is available without dividing by zero
`x % 1`                                     fractional part (always positive)
`x % 1 == 0`                                number is integer; `math.floor(x) == x`
`x - x % 1`                                 integer part; but better use `math.floor(x)`
`x - x % 0.01`                              x floored to two decimal digits
`x - x % n`                                 closest to `x` smaller than `x` multiple of `n`
`math.modf(x)`                              integer part and fractional part
`math.floor(x+.5)`                          round
`(x >= 0 and 1 or -1)`                      sign
`y0 + (x-x0) * ((y1-y0) / (x1 - x0))`       linear interpolation
`math.fmod(angle, 2*math.pi)`               normalize an angle
__tables__
`next(t) == nil`                            table is empty
__strings__
`s:match'^something'`                       starts with
`s:match'something$'`                       ends with
`s:match'["\'](.-)%1'`                      match pairs of single or double quotes
__i/o__
`f:read(4096, '*l')`                        read lines efficiently
------------------------------------------- -------------------------------------------

