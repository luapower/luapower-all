---
tagline: video capturing
---

## `local vi = require'videoinput'`

A cross-cross-platform library for capturing video frames from webcams
and other devices in real-time as bgra8 [bitmap]s.

<warn>Work in progress.</warn>

## API

--------------------------------------- --------------------------------------
`vi.devices() -> {dev1, ...}`           enumerate available devices
`vi.devices'#' -> n`                    device count
`vi.devices'*' -> dev|nil`              default device
`vi.open([dev|id|'*'|t]) -> session `   open a capture session on a device
`vi:start()`                            start the session (open the webcam)
`vi:stop()`                             stop the session (close the webcam)
`vi:close()`                            stop and) close the session
`vi:newframe(bmp)`                      event: a new frame was captured
--------------------------------------- --------------------------------------

### `vi.devices() -> {dev1, ...}`

Enumerate available devices. Devices are plain tables with the fields
`id`, `name`, `isdefault`.

### `vi.open([dev|id|'*'|t]) -> session`

Open a capture session on a device. The argument can be a device object,
a device id, nil/nothing/'*' which will open the default device,
or an options table with the fields:

* `device` - the device to open: device object, device id, nil or '*'
