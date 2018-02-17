---
tagline: easing functions
---

## `local easing = require'easing'`

Robert Penner's easing functions.

## Animation API

### `easing.ease(name|func, dir, t1 - t0, T, ...) -> d`

  * `name|func` is (the name of) an ease function (see below)
  * `dir` can be 'in' (default), 'out', 'inout' or 'outin'
  * `t1` is the animation's current time
  * `t0` is the animation's start time
  * `T` is the total animation duration
  * `d` is the value in `0..1` corresponding to the current time

## Easing functions

### `easing.<name> -> f(t, ...) -> v`

These functions map a number in `0..1` into a number in `0..1`.

Currently implemented functions: `linear`, `quad`, `cubic`, `quart`, `quint`,
`expo`, `sine`, `circ`, `back`, `elastic`, `bounce`.

__NOTE:__ Some easing functions take additional parameters (see code).

### `easing.reverse(f) -> g`

Turn an `in` function into an `out` function or viceversa.

### `easing.in_out(f) -> g`

Turn an `in` function into an `in_out` function, or an `out` function into
an `out_in` function.

### `easing.out_in(f) -> g`

Turn an `in` function into an `out_in` function, or an `out` function into
an `in_out` function. Same as `easing.in_out(easing.reverse(f))`.

### `easing.expr.name = 'Lua expression'`

Extend the module with an expression-based formula. This will result in
generating a new easing function called `easing.<name>`.

### `easing.names -> {name1, ...}`

An auto-updated list of easing function names, for listing purposes.

