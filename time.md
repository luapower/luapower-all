---
tagline: time and sleeping
platforms: mingw, linux, osx
---

## `local time = require'time'`

## API

------------------------- ----------------------------------------------------
`time.time() -> n`        wall clock time with ~100us precision
`time.clock() -> n`       monotonic time in seconds with ~1us precision
`time.sleep(s)`           sleep with sub-second precision (~10-100ms)
`time.install()`          increase accuracy of `os.date()` and `os.time()`
------------------------- ----------------------------------------------------

### `time.time() -> n`

Reads the wall-clock time as a UNIX timestamp.
It is the same as the time returned by `os.time()` on all platforms,
except it has sub-second precision. It is affected by drifting,
leap seconds and time adjustments by the user. It is not affected
by timezones. It can be used to synchronize time between different
boxes on a network regardless of platform.

### `time.clock() -> n`

Reads a monotonic performance counter, and is thus more accurate than
`time.time()`, it should never go back or drift, but it doesn't have
a fixed time base between program executions. It can be used
for measuring short time intervals for thread synchronization, etc.

