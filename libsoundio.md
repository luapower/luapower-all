---
tagline: audio input and output
---

## `local libsoundio = require'libsoundio'`

A binding of [libsoundio](http://libsound.io/), a library for cross-platform
audio input and output.

## API

------------------------------------------- ----------------------------------------
`libsoundio.new() -> sio`                   create a sound I/O state
__backends__
`sio:connect([backend])`                    connect to a backend
`sio:disconnect()`                          disconnect the backend
`sio:backends() -> iter() -> name`          iterate backends
`sio:backends'#' -> n`                      number of available backends
`sio:backends(name) -> t|f`                 check if a backend is available
__devices__
`sio:devices([nil, raw]) -> iter() -> dev`  iterate devices
`sio:devices('#'|'#i'|'#o'[, raw]) -> n`    number of all|input|output devices
`sio:devices('*i'|'*o'[, raw]) -> dev|nil`  the default input or output device
`dev:ref() -> dev`                          increment ref count
`dev:unref() -> dev`                        decrement ref count
`dev:sort_channel_layouts()`                TODO
`dev:supports_format(format) -> t|f`        TODO
`dev:supports_layout(layout) -> t|f`        TODO
`dev:supports_sample_rate(rate) -> t|f`     TODO
`dev:nearest_sample_rate() -> rate`         TODO
`dev.id -> s`                               device unique id
`dev.name -> s`                             device name
`dev.aim -> 'i'|'o'`                        whether it's for input or output
__streams__
`dev:stream'o' -> sout`                     create an output stream
`dev:stream'i' -> sin`                      create an input stream
`sin/sout:free()`                           destroy the stream
`sin/sout:open()`                           open the stream
__ring buffers__
`sio:ringbuffer() -> rb`                    create a thread-safe ring buffer
`rb:capacity() -> bytes`                    get the buffer's capacity
`rb:write_ptr() -> ptr`                     get the write pointer
`rb:advance_write_ptr(bytes)`               advance the write pointer
`rb:read_ptr() -> ptr`                      get the read pointer
`rb:advance_read_ptr(bytes)`                advance the read pointer
`rb:fill_count() -> bytes`                  how many occupied bytes
`rb:free_count() -> bytes`                  how many free bytes
`rb:clear()`                                clear the buffer
`rb:free()`                                 free the buffer
__events__
------------------------------------------- ----------------------------------------
