---
tagline: easing functions
---

## `local easing = require'easing'`

Robert Penner's easing functions.

## Animation API

### `easing.ease(name|func, way, (t1 - t0) / dt, ...) -> d`

  * `name|func` is (the name of) an ease function (see below)
  * `way` can be 'in' (default), 'out', 'inout' or 'outin'
  * `t1` is the animation's current time
  * `t0` is the animation's start time
  * `dt` is the total animation duration
  * `d` is the value in `0..1` corresponding to the current time
  * `...` are extra args to be passed to the ease function.

## Easing functions

### `easing.<name> -> f(t, ...) -> d`

These functions map a number in `0..1` into a number in `0..1`.

Currently implemented functions: `linear`, `quad`, `cubic`, `quart`, `quint`,
`expo`, `sine`, `circ`, `back`, `elastic`, `bounce`.

__Note:__

 * `elastic` takes additional args `amplitude`, `period`.
 * `slowmo` takes additional args `power`, `ratio`, `yoyo`.

### `easing.reverse(f, t, ...) -> d`

Turn an `in` function into an `out` function or viceversa.

### `easing.inout(f, t, ...) -> d`

Turn an `in` function into an `inout` function, or an `out` function into
an `outin` function.

### `easing.outin(f, t, ...) -> d`

Turn an `in` function into an `outin` function, or an `out` function into
an `inout` function.
Same as `easing.inout(function(t) return easing.reverse(f, t) end, t)`.

### `easing.names -> {name1, ...}`

The list of easing function names in insert order. Extending the module
namespace automatically adds the names to this list.
