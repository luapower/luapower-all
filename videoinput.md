---
tagline: video capturing
---

## `local vi = require'videoinput'`

A cross-cross-platform library for capturing video frames from webcams
and other devices in real-time as bgra8 [bitmap]s.

## Status

<warn>Work in progress.</warn>

## API

--------------------------------------- --------------------------------------
`vi.devices() -> {dev1, ...}`           enumerate available devices
`vi.devices'#' -> n`                    device count
`vi.devices'*' -> dev|nil`              default device
`vi.open([dev|id|'*'|t]) -> session`    open a capture session on a device
`session:start()`                       start the session (switch on the camera)
`session:stop()`                        stop the session (switch off the camera)
`session:running([t|f]) /-> t|f`        get/set running status
`session:close()`                       (stop and) close the session
`session:newframe(bmp)`                 event: a new frame was captured
--------------------------------------- --------------------------------------

### `vi.devices() -> {dev1, ...}`

Enumerate available devices. Devices are plain tables with the fields
`id`, `name`, `isdefault`.

### `vi.open([dev|id|'*'|t]) -> session`

Open a capture session on a device. The argument can be a device object,
a device id, nil/nothing/'*' which will open the default device,
or an options table with the fields:

* `device` - the device to open: device object, device id, nil or '*'
