---
tagline: easing functions
---

## `local easing = require'easing'`

Robert Penner's [easing functions].

## API

### `easing.<formula>(t, b, c, d) -> value in b..c`

The formulas map input `d` to output `r`, where `d` is in `0 .. t` and `r`
is in `b + 0 .. c`.

Formulas:
`linear            `,
`in_sine           `,
`in_out_quint      `,
`in_out_back       `,
`in_out_cubic      `,
`in_quint          `,
`out_quart         `,
`in_quad           `,
`out_in_quint      `,
`in_out_bounce     `,
`out_in_quad       `,
`out_quint         `,
`in_expo           `,
`in_elastic        `,
`in_out_circ       `,
`out_cubic         `,
`in_out_expo       `,
`in_circ           `,
`in_quart          `,
`in_out_quad       `,
`out_back          `,
`in_bounce         `,
`out_sine          `,
`out_in_cubic      `,
`out_in_expo       `,
`out_in_bounce     `,
`out_bounce        `,
`in_out_elastic    `,
`out_expo          `,
`in_back           `,
`out_elastic       `,
`out_in_elastic    `,
`out_quad          `,
`out_in_circ       `,
`in_cubic          `,
`out_in_sine       `,
`in_out_quart      `,
`out_in_quart      `,
`out_circ          `,
`in_out_sine       `,
`out_in_back       `.

## Usage for animation

### `easing.<formula>(t1 - t0, d0, d1, T) -> d`

  * t1 is the animation's current time
  * t0 is the animation's start time
  * d0 is the start value
  * d1 is the end value
  * T is the total animation duration
  * d is the current value in d0..d1 corresponding to the current time

Some formulas take additional parameters (see code).

[easing functions]: http://www.robertpenner.com/easing/
