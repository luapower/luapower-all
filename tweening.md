---
tagline: tweening for animation
---

## `local tw = require'tweening'`

A library for the management of gradual value changes for the purposes of
animation.

## Features

  * timing parameters: `duration`, `delay`, `speed`, `loop`, `reverse`,
  `yoyo`, `ease`, `way`, `loop_start`.
  * independent timing parameters for each target object and/or attribute.
  * nested, overlapping timelines with relative start times.
  * timelines can be tweened as a unit using all timing parameters (see below).
  * stagger tweens: alternate end-values over a list of targets.
  * extendable attribute types and interpolation functions.
  * relative values incl. directional rotation.
  * no allocations while tweening.

## Tweens

### `tw:tween(t) -> tween`

Create a new tween. A tween is an object which repeatedly updates a value on
a target object _in time_ based on an interpolation function and timing
parameters.

> __NOTE:__ `t` itself is turned into a tween (no new table is created).

#### Timing model

__field__      __default__  __description__
-------------- ------------ --------------------------------------------------
`start`        `clock()`    start clock (becomes relative when added to timeline)
`duration`     `1`          duration of one iteration (can't be negative)
`delay`        `0`          delay before the first iteration starts
`speed`        `1`          speed of the entire tween; must be > 0
`loop`         `1`          # of iterations (can be fractional; use `1/0` for infinite)
`reverse`      `false`      start backwards
`yoyo`         `true`       alternate between forwards and backwards on each iteration
`ease`         `'quad'`     ease function `f(t) -> d` or name from [easing]
`way`          `'in'`       easing way: `'in'`, `'out'`, `'inout'` or `'outin'`
`loop_start`   `0`          1.25 means start at 25% on the _second_ iteration
`paused`       `false`      start paused
`clock() -> t` `tw:clock()` clock source

__method__                  __description__
--------------------------- --------------------------------------------------
`start_clock() -> t`        absolute start clock
`total_duration() -> dt`    total tween duration incl. repeats (can be infinite)
`end_clock() -> t`          absolute end clock (can be infinite)
`is_infinite() -> bool`     true if `loop` and/or `duration` are infinite
`status([t]) -> status`     status at clock: 'before_start', 'running', 'paused', 'finished'
`total_progress([t]) -> P`  linear progress in `0..1` at clock incl. repeats (can be infinite)
`clock_at(P) -> t`          absolute clock at total linear progress
`is_reverse(i) -> bool`     true if iteration `i` goes backwards
`progress([t]) -> p, i`     linear progress in `0..1` in current iteration and iteration index
`distance(p, i) -> d`       eased progress in `0..1` in current iteration and iteration index
`pause()`                   pause (sets `paused` field to `true`)
`resume()`                  resume (sets `paused` field to `false` and advances `start`)
`stop()`                    stop and remove from timeline
`restart()`                 restart (advances `start`)
`reset()`                   reset
`update([t])`               update value at clock
`seek(P)`                   update value at total progress
`totarget() -> obj`         convert to tweenable object

__NOTE:__ The tween doesn't store the current time or the current value.
Whenever the optional `t` argument indicating a time value is not given,
the current clock is used instead.

#### Animation model

__field__          __default__         __description__
------------------ ------------------- ---------------------------------------
`target`           (required)          target object
`attr`             (required)          attribute in the target object to tween
`start_value`      `target[attr]`      start value (defaults to target's value)
`end_value`        `target[attr]`      end value (defaults to target's value)
`type`             `'number'`          attribute type
`interpolate`      default for `type`  `f(t, x1, x2[, xout]) -> x`
`value_semantics`  default for `type`  (see below)
`get_value() -> v` `target[attr] -> v` value getter
`set_value(v)`     `target[attr] = v`  value setter

## Timelines

### `tw:timeline(t) -> tl`

Create a new timeline. A timeline is a list of tweens which are tweened in
parallel (or one after another, depending on their `start` time). The list
can also contain other timelines, resulting in a hierarchy of timelines.

__NOTE:__ `t` itself is turned into a timeline (no new table is created).

### Timelines are tweens

A timeline is itself a tween, containing all the fields and methods of the
timing model of a tween but none of the fields and methods of the animation
model because it's not animating a target object but it's tweening other
tweens. "Tweening other tweens" means that the value that is being tweened
is the _progress_ of the timeline itself (so a temporal value). So for
instance, by specifying `reverse = true` on the timeline, the whole animation
will be played back in reverse, which is very different than setting
`reverse = true` individually on the child tweens. Likewise, setting a
non-linear `ease` function will make the playback of the whole animation
non-linear, etc. There's a catch with infinite tweens: if the timeline
contains infinite (`loop = 1/0`) tweens, its duration is automatically
adjusted to infinite (unless otherwise specified), in which case only the
`speed` and `delay` parameters will be used.

### Timeline-specific fields and methods

__field__       __default__ __description__
--------------- ----------- --------------------------------------------------
`ease`          `'linear'`
`duration`      `0`
`auto_duration` `true`      auto-increase duration to include all tweens
`auto_remove`   `true`      remove tweens automatically when finished

__method__                         __description__
--------------------------- --------------------------------------------------
`add:
`status()`                  `'empty'`

### `tl:add(tween[, start]) -> timeline`

Add a new tween to the timeline, set its `start` field and its `timeline`
field, and, if `auto_duration` is `true`, increase timeline's `duration`
to include the entire tween. When part of a timeline, a tween's `start`
becomes relative to the timeline's start time. If `start` is not given, the
tween is added to the end of the timeline (when the timeline's duration is
infinite then the tween's start is set to `0` instead).

### `tl:remove(tween|attr|target) -> true|false`

Remove a tween or all tweens with a specific attribute or target object
recursively. Returns true if any were removed.

### `tl:clear() ->  true|false`

Remove all tweens from the timeline. Returns true if any were removed.

## The tweening module

### `tw() -> tw`

Create a new `tweening` module. Useful for extending the `tweening` module
with new attribute types and interpolators without affecting the original
module table.

### Attribute types

### `tw.type.<name|pattern|match_func> = attr_type`

Tell tweening about the type of an attribute, eg.
`tw.type['_color$'] = 'list'`

### `tw.interpolate.<attr_type> = function(d, x1, x2[, xout]) -> x`

Add a new interpolation function for an attribute type.

### `tw.value_semantics.<attr_type> = false`

Declare an interpolation function as having reference semantics. By default
interpolation functions have value semantics, i.e. they are called as
`x = f(d, x1, x2)`. If declared as having reference semantics, they are
instead called as `f(d, x1, x2, x)` and are expected to update `x` in-place
thus avoiding an allocation on every frame if `x` is a non-scalar type.

### The wall clock

### `tw:current_clock() -> t`

Current monotonic performance counter, in seconds.

### `tw:freeze()`

Freeze the wall clock. Useful for creating multiple tweens which start at the
exact same time.

### `tw:unfreeze()`

Unfreeze the wall clock.
