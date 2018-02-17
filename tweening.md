---
tagline: tweening for animation
---

## `local tw = require'tweening'`

A library for the management of gradual value changes for the purposes of
animation.

Features:

  * control variables: `duration`, `delay`, `speed`, `loop`, `reverse`,
  `yoyo`, `ease`, `way`, `loop_start`.
  * independent control variables for each target object and/or attribute.
  * nested, overlapping timelines with relative start times.
  * timelines can themselves be tweened as a unit using all control variables.
  * stagger tweens: alternate end-values over a list of targets.
  * extendable attribute types and interpolation functions.
  * built-in interpolators for numbers, integers and lists of numbers.
  * relative values incl. directional rotation.
  * no allocations while tweening.

## Tweens

### `tw:tween(t) -> tween`

Create a new tween. A tween is an object which can be used to interpolate a
single value from a target object _in time_ using an easing function and
other timing parameters.

> __NOTE:__ `t` itself is turned into a tween (no new table is created).

#### Timing model: fields

-------------- ----------- ---------------------------------------------------
__field__      __default__ __description__
`start`        `clock()`   start clock (becomes relative when added to timeline)
`duration`     `1`         duration of one iteration (can't be negative)
`delay`        `0`         delay before the first iteration starts
`speed`        `1`         speed of the entire tween; must be > 0
`loop`         `1`         # of iterations (can be fractional; use `1/0` for infinite)
`reverse`      `false`     start backwards
`yoyo`         `true`      alternate between forwards and backwards on each iteration
`ease`         `'quad'`    ease function `f(t) -> d` or name from [easing]
`way`          `'in'`      easing way: `'in'`, `'out'`, `'inout'` or `'outin'`
`loop_start`   `0`         progress at start (can be fractional)
`paused`       `false`     start paused
`clock() -> t` `tw.clock`  clock source
-------------- ----------- ---------------------------------------------------

#### Timing model: methods

---------------------------------- -------------------------------------------
__method__                         __description__
`tween:start_clock() -> t`         absolute start clock
`tween:total_duration() -> dt`     total duration incl. repeats (can be infinite)
`tween:end_clock() -> t`           end clock (can be infinite)
`tween:is_infinite() -> bool`      true if `loop` or `duration` are infinite
`tween:status([t]) -> status`      status at clock: 'before_start', 'running', 'paused', 'finished'
`tween:total_progress([t]) -> P`   progress in `0..1` at clock incl. repeats (can be infinite)
`tween:clock_at(P) -> t`           clock at total progress
`tween:is_reverse(i) -> bool`      true if iteration `i` goes backwards
`tween:progress([t]) -> p, i`      linear progress in `0..1` in current iteration and iteration index
`tween:distance(p, i) -> d`        eased progress in `0..1` in current iteration and iteration index
`tween:pause()`                    pause (sets `paused` field to `true`)
`tween:resume()`                   resume (sets `paused` field to `false` and advances `start`)
`tween:stop()`                     stop and remove from timeline
`tween:restart()`                  restart (advances `start`)
`tween:reset()`                    reset
`tween:update([t])`                update value at clock
`tween:seek(P)`                    update value at total progress
`tween:totarget() -> obj`          convert to tweenable object
---------------------------------- -------------------------------------------

__NOTE:__ The tween doesn't store the current time or the current value.
Whenever the optional `t` argument indicating a time value is not given,
the current clock is used instead.

#### Animation model: fields

------------------ ------------------- ---------------------------------------
__field__          __default__         __description__
`target`           (required)          target object
`attr`             (required)          attribute in the target object to tween
`start_value`      `target[attr]`      start value
`end_value`        `target[attr]`      end value
`type`             `'number'`          attribute type
`interpolate`      default for `type`  `f(t, x1, x2[, xout]) -> x`
`value_semantics`  default for `type`  (see below)
`get_value() -> v` `target[attr] -> v` value getter
`set_value(v)`     `target[attr] = v`  value setter
------------------ ------------------- ---------------------------------------

## Timelines

### `tw:timeline(t) -> timeline`

Create a new timeline. A timelines is a list of tweens which are tweened in
parallel. The list can also contain other timelines, resulting in a hierarchy
of timelines. A timeline is itself a tween, containing all the fields and
methods of the timing model of a tween (but none of the fields and methods
of the animation model).

implements the timing model can contain all the fields and methods of .

__NOTE:__ `t` itself is turned into a timeline (no new table is created).

### `timeline:add(tween[, start]) -> timeline`

Add a new tween to the timeline and set its `start` field and its `timeline`
field. Once part of a timeline, a tween's `start` becomes relative to the
timeline's start clock.

## The tweening module

### `tw() -> tw`

Create a new `tweening` module. Useful for extending the `tweening` module
with new attribute types and interpolators without affecting the original
module table.

## Attribute types

### `tw.type.<name|pattern|match_func> = attr_type`

Tell tweening about the type of an attribute, eg.
`tw.type['_color$'] = 'list'`

### `tw.interpolate.<attr_type>(d, x1, x2[, xout]) -> x`

Add a new interpolation function for an attribute type.

### `tw.value_semantics.<attr_type> = false`

Declare an interpolation function as having reference semantics. By default
interpolation functions have value semantics, i.e. they are called as
`x = f(d, x1, x2)`. If declared as having reference semantics, they are
instead called as `f(d, x1, x2, x)` and are expected to update `x` in-place
thus avoiding an allocation on every frame if `x` is a heap value.

## The wall clock

### `tw:current_clock() -> t`

Returns the current monotonic performance counter, in seconds.
Implemented as [time].clock(). Overridable.

### `tw:freeze()`

Freeze the clock. Useful for creating multiple tweens starting at the exact
same time.

### `tw:unfreeze()`

Unfreeze the clock.
