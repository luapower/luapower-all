---
tagline: tweening & timelines for animation
---

## `local tw = require'tweening'`

A library for the management of gradual value changes for the purposes of
animation.

## Features

  * timing parameters: `duration`, `speed`, `loop`, `backwards`, `yoyo`,
    `ease`, `way`, `offset`.
  * independent timing parameters for each target object and/or attribute.
  * timelines that can be nested, overlapping, and tweened.
  * stagger tweens: alternate end-values over a list of targets.
  * extensible attribute types, value converters and interpolation functions.
  * relative values including directional rotation.
  * pause/resume/restart/reverse individual tweens even when in a timeline.
  * no allocations while tweening.

## Tweens

### `tw:tween(t) -> tween`

Create a new tween. A tween is an object which repeatedly updates a value on
a target object _in time_ based on an interpolation function and timing
parameters.

__NOTE:__ `t` itself is turned into a tween (no new table is created). This
allows any method to be overriden by specifying it directly as a field of `t`.

### Timing model

__field__      __default__   __description__
-------------- ------------- -------------------------------------------------
`start`        current clock start clock (relative when in a timeline)
`duration`     `1`           duration of one iteration (can't be negative)
`ease`         `'quad'`      ease function `f(p) -> d` or name from [easing] module
`way`          `'in'`        easing way: `'in'`, `'out'`, `'inout'` or `'outin'`
`ease_args`    none          optional args to pass to the ease function
`backwards`    `false`       start backwards
`yoyo`         `true`        alternate between forwards and backwards on each iteration
`loop`         `1`           number of iterations (can be fractional; use `1/0` for infinite)
`speed`        `1`           speed factor (must be > 1)
`offset`       `0`           progress at start
`running`      `true`        running or paused
`clock`        `start`       current clock when running, set by `update()`
`resume_clock` `clock`       current clock when paused, set by `update()`

__NOTE__: Timing model fields can be changed anytime (there's no internal
state that must be kept in sync).

__method__                        __description__
--------------------------------- --------------------------------------------
`total_duration() -> dt`          total duration incl. repeats (can be `+/-inf`)
`end_clock() -> t`                end clock (can be `+/-inf`)
`is_infinite() -> bool`           true if `loop` and/or `duration` are `inf`
`is_backwards(i) -> bool`         true if iteration `i` goes backwards
`progress([t]) -> P`              linear progress in `0..1` incl. repeats (can be `inf`)
`clock_at(P) -> t`                clock at total linear progress (which is in `0..1`)
`status([t]) -> status`           status: 'before_start', 'running', 'paused', 'finished'
`loop_progress([t]) -> p`         linear progress in `0..loop`
`loop_clock_at(p) -> t`           clock at loop progress
`distance([t]) -> d`              eased progress in current iteration (in `0..1`)
`update([t])`                     update internal clock and target value

__NOTE__: `progress()`, `clock_at()` and `seek()` map time to `0..1` while
`loop_progress()`, `loop_clock_at()` and `loop_seek()` map time to `0..loop`.
The first set is more convenient but doesn't work when `loop` is `inf`.

#### Changing the state of the tween

__method__           __description__
-------------------- ---------------------------------------------------------
`pause()`            pause (changes `running`, prevents updating `clock`)
`resume()`           resume (changes `running` and `start`)
`seek(P)`            update target value based on progress (changes `start`).
`loop_seek(p)`       update target value based on loop progress (changes `start`).
`stop()`             pause and remove from timeline
`restart()`          restart (changes `start`)
`reverse()`          reverse (changes `start`, `offset`, `backwards`)

__NOTE:__ The methods above change the timing model of the tween, which is
normally supposed to be immutable in order to make the tween stateless. This
is done to allow a tween that is part of a timeline to be paused and resumed
independently of other tweens and of the timeline. Use `clone()` to preseve
the initial definition of the tween.

### Animation model

__field__          __default__         __description__
------------------ ------------------- ---------------------------------------
`target`           (required)          target object
`attr`             (required)          attribute in the target object to tween
`from`             `target[attr]`      start value (defaults to target's value)
`to`               `target[attr]`      end value (defaults to target's value)
`type`             per `attr`          force attribute type
`interpolate`      default for `type`  `f(t, x1, x2[, xout]) -> x`
`get_value() -> v` `target[attr] -> v` value getter
`set_value(v)`     `target[attr] = v`  value setter

See below for how to add attribute type matching rules and interpolators.

__NOTE:__ Animation model fields are read/only. Changing them requires a call
to `reset()`.

### Relative values

`from` and `to` can be given in the format `'<number>'`, `'<number><unit>`,
`'<operator>=<number>'` or `'<operator>=<number><unit>'`, where `operator`
can be `+`, `-` or `*` and `unit` can be:

__unit__     __description__
------------ -----------------------------------------------------------------
`%`          percent, converted to `0..1`
`ms`         milliseconds, converted to seconds
`deg`        degrees, converted to radians
`cw`         rotation: clockwise
`ccw`        rotation: counter-clockwise
`short`      rotation: shortest direction
`deg_cw`     rotation: clockwise in degrees, converted to radians
`deg_ccw`    rotation: counter-clockwise in degrees, converted to radians
`deg_short`  rotation: shortest direction in degrees, converted to radians
------------ -----------------------------------------------------------------

Examples: `'+=10deg'`, `'25%'`.

__NOTE:__ `'25%'` means 25% the initial value, while `'+=25%'` means 125% the
initial value.

__NOTE:__ `cw` and `ccw` assume that increasing angles rotate the target
clockwise (like cairo and other systems where the y-coord grows from top
to bottom).

__NOTE:__ `'+=90deg'` means "rotate the target another 90 degrees clockwise",
while `'90deg_cw'` means "rotate the target to the 90 degrees mark by moving
clockwise". Don't combine relative rotations with `cw` and `ccw`.

### Misc.

__method__                   __description__
---------------------------- --------------------------------------------------
`tween:clone() -> tween`     clone a tween
`tween:totarget() -> obj`    convert to tweenable object

### `tween:clone() -> tween`

Clone a tween in its current state.

### `tween:totarget() -> obj`

Create a proxy object for the tween with the additional tweenable fields
`progress` and `loop_progress`. Other tweenable properties like `speed`
remain accessible.

## Timelines

### `tw:timeline(t) -> tl`

Create a new timeline. A timeline is a list of tweens which are updated in
parallel (or one after another, depending on their `start` time). The list
can also contain other timelines, resulting in a hierarchy of timelines.

__NOTE:__ `t` itself is turned into a timeline (no new table is created).

### Timelines are tweens

A timeline is itself a tween, containing all the fields and methods of the
timing model of a tween (but none of the fields and methods of the animation
model since it's not animating a target object, it's updating other tweens).
This means that a timeline can be used to _tween_ the _progress_ of its
child tweens instead of just updating them on the same clock, since it has a
`distance` resulting from its timing model. It also means that the timeline
can be itself tweened on its _progress_ (which only works if the timeline is
_not_ infinite).

### Tweening other tweens

Setting `tween_progress = true` on a timeline switches the timeline into
tweening its child tweens on their _progress_ (so tweening a temporal value)
instead of just updating them on the same clock. In this mode, the
child's `start` and `duration` are ignored: instead, the timeline's `distance`
is interpolated over the child's progress.

### Timeline-specific fields and methods

__field__        __default__ __description__
---------------- ----------- -------------------------------------------------
`tweens`         `{}`        the list of tweens in the timeline
`ease`           `'linear'`  (a better default for the `tween_progress` mode)
`duration`       `0`         auto-adjusted when adding tweens
`auto_duration`  `true`      auto-increase duration to include all tweens
`auto_remove`    `true`      remove tweens automatically when finished
`tween_progress` `false`     progress-tweening mode

__method__                  __description__
--------------------------- --------------------------------------------------
`add(tween|opt[, start])`   add a tween or create multiple tweens
`each(func, ...)`           iterate tweens recursively
`remove(tween|attr|target)` remove matching tweens recursively
`clear()`                   remove all tweens (non-recursively)
`status()`                  adds `'empty'`

### `tl:add(tween|opt[, start]) -> tl`

Add a new tween to the timeline, set its `start` field and its `timeline`
field, and, if `auto_duration` is `true`, increase timeline's `duration`
to include the entire tween. When part of a timeline, a tween's `start`
is relative to the timeline's start time. If `start` is not given, the
tween is added to the end of the timeline (when the timeline's duration is
infinite then the tween's start is set to `0` instead).

If an options table is given instead, multiple tweens are created and
added to the timeline as follows: `targets` specifies a list of targets,
otherwise `target` specifies a single target, `from` and `to` specifies a
table of from/to attribute -> value pairs. `cycle_from`, `cycle_to`, `cycle`
specifies a table of from/to attribute -> list-of-values pairs such that
values will be distributed to each target in a round-robin fashion. The
values can also be functions.

__NOTE:__ `start` can be a relative value relative to the timeline's current
total duration, eg. `'+=500ms'` means half a second after the last tween,
while `'500ms'` means half a second from the start of the timeline.

### `tl:each(func, ...)`

Run `func(tween)` for each tween of a timeline, recursively. Returning `false`
from `func` breaks the iteration. Returning `'remove'` removes the tween.
Returning another tween replaces the tween.

### `tl:remove(tween|attr|target|id|func)`

Remove a tween or all tweens with a specific attribute, target object or id
recursively.

### `tl:clear()`

Remove all tweens from the timeline (non-recursively).

## The tweening module

### `tw() -> tw`

Create a new `tweening` module. Useful for extending the `tweening` module
with new attribute types, new interpolators or different ways of getting the
wall clock without affecting the original module table.

### Attribute types and interpolators

### `tw.type.<name|pattern|match_func> = attr_type`

Tell tweening about the type of an attribute, eg.
`tw.type['_color$'] = 'list'`

### `tw.interpolate.<attr_type> = function(d, x1, x2[, xout]) -> x`

Add a new interpolation function for an attribute type. Interpolators are
called as `x = f(d, x1, x2, x)` and can update `x` in-place and return it
thus avoiding an allocation on every frame if `x` is a non-scalar type.

### Value parsers

### `tw:parse_value(v, relative_to, tween) -> v`

Parse a value.

### The wall clock

### `tw:clock([t|false]) -> t`

Get/freeze/unfreeze the wall clock. With `t` it freezes the wall clock such
that subsequent `tw:clock()` calls will return `t`. With `false` it unfreezes
it such that subsequent `tw:clock()` calls will return `tw:current_clock()`.

Freezing is useful for creating multiple tweens which start at the exact same
time without having to specify the time.

### `tw:current_clock() -> t`

Current monotonic performance counter, in seconds. Implemented in terms of
[time.clock()][time]. Override this in order to remove the dependency on the
[time] module.

### Easing

### `tw:ease(ease, way, p, i) -> d`

Implemented in terms of [easing.ease()][easing]. Override this in order to
remove the dependency on the [easing] module.
