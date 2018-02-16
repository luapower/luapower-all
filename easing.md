---
tagline: easing functions
---

## `local easing = require'easing'`

Robert Penner's [easing functions].

## API

### `easing.<name>(t) -> v`

The functions map a number in `0..1` into a number in `0..1`.

Currently implemented functions: `linear`, `quad`, `cubic`, `quart`, `quint`,
`expo`, `sine`, `circ`, `back`, `elastic`, `bounce`.

### `easing.reverse(f) -> g`

Turn an `in` function into an `out` function or viceversa.

### `easing.in_out(f) -> g`

Turn an `in` function into an `in_out` function, or an `out` function into
an `out_in` function.

### `easing.expr.name = 'Lua expression'`

Extend the module with an expression-based formula. This will result in
generating a new easing function called `easing.<name>`.

### `easing.names -> {name1, ...}`

An auto-updated list of easing function names, for listing purposes.

__NOTE:__ Some easing functions take additional parameters (see code).

[easing functions]: http://www.robertpenner.com/easing/
