---
tagline: portable audio I/O
---

A binding of [PortAudio](http://portaudio.com/), the audio I/O library
which powers Audacity.

## API

------------------------------------------ ------------------------------------------
__host APIs__
`pa.hostapis() -> iter() -> i, info`       iterate host APIs
`pa.hostapis'#' -> n`                      host API count
`pa.hostapis'*' -> i`                      index of default host API
`pa.hostapi([i|type]) -> info`             host API info
__devices__
`pa.devices'#' -> n`                       device count
`pa.devices'*i' -> i`                      index of default input device
`pa.devices'*o' -> i`                      index of default output device
`pa.devices() -> iter() -> i, info`        iterate devices
`pa.device('*i', '*o', i) -> info`         device info
__streams__
`pa.open(t) -> stream`                     open a stream
`stream:close()`                           close
`stream:start()`                           start
`stream:stop()`                            stop
`stream:abort()`                           abort
`stream:stopped() -> t|f`                  check if stopped
`stream:active() -> t|f`                   check if active
`stream:info() -> info`                    stream info
`stream:time() -> time`                    time
`stream:cpuload() -> ?`                    CPU load
`stream:read(buf, frames)`                 read
`stream:write(buf, frames)`                write
__other__
`pa.samplesize(format) -> n`               sample size for a format
`pa.sleep(s)`                              sleep
------------------------------------------ ------------------------------------------

## Streams

### `pa.open(t) -> stream`

Open a stream. `t` is a table with the fields:

* `samplerate` - sample rate: 48000, ...

