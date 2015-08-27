---
tagline: easing functions
---

## `local easing = require'easing'`

Robert Penner's [easing functions].

## API

### `easing.<formula>(t, b, c, d) -> value in b..c`

The formulas map input `d` to output `r`, where `d` is in `0 .. t` and `r` is in `b + 0 .. c`.

## Usage for animation

	easing.<formula>(t1 - t0, d0, d1, T) -> d


  * t1 is the animation's current time
  * t0 is the animation's start time
  * d0 is the start value
  * d1 is the end value
  * T is the total animation duration
  * d is the current value in d0..d1 corresponding to the current time

Some formulas take additional parameters (see code).

[easing functions]: http://www.robertpenner.com/easing/
