---
tagline: tweening for animation
---

## `local tweening = require'tweening'`

Tweening is the management of gradual, smooth value changes for the purposes
of animation.

Features:

  * tweening control variables: duration, ease, delay, speed, direction,
  yoyo, loop, loop start.
  * all control variables can be given independently for each target object
  and/or attribute.
  * nested, overlapping timelines with relative start times.
  * timelines can be tweened as a whole using all tweening control variables.
  * relative values
  * stagger animations: target lists with cyclic variation of the end-values.
  * extendable interpolation functions.
  * pause/resume/restart.

### `tweening() -> tweening`

Subclass `tweening`. Useful for extending the `tweening` module with
new interpolators without affecting the global module instance.

### `tweening.interpolate(d, x1, x2[, xout]) -> x`

### `tweening:tween(o) -> tween`

### `tweening:timeline(o) -> timeline`


### The timing model

  * `duration`
  * `ease`
  * `delay`
  * `speed`
  * `direction`
  * `yoyo`
  * `loop`
  * `loop_start`

### The animation model

  * `start_value`
  * `end_value`
  * `target`
  * `attr`
  * `attr_type`
  * `interpolate`
  *
