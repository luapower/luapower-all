---
tagline: audio input and output
---

## `local soundio = require'libsoundio'`

A binding of [libsoundio](http://libsound.io/), a library for cross-platform
audio input and output.

## API

------------------------------------------- ----------------------------------------
`soundio.new() -> sio`                      create a libsoundio state
`sio:free()`                                free the libsoundio state
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
`dev.ref_count -> n`                        current reference count
`dev:ref|unref() -> dev`                    increment/decrement device ref count
`dev:sort_channel_layouts()`                TODO
`dev.id -> s`                               device unique id
`dev.name -> s`                             device name
`dev.aim -> 'i'|'o'`                        whether it's for input or output
`dev.soundio -> sio`                        back reference to libsoundio state
`dev.is_raw -> t|f`                         check if it's a raw device
`dev.probe_error -> error_code|nil`         device probe error code (SoundError enum)
__sample rates__
`dev.sample_rates -> sample_rate_range[]`   rample rate ranges (0-based cdata array)
`dev.sample_rate_count -> n`                number of sample rate ranges
`dev.sample_rate_current -> i`              index of current sample rate range
`dev:supports_sample_rate(rate) -> t|f`     TODO
`dev:nearest_sample_rate() -> rate`         TODO
__sample formats__
`dev.formats -> format[]`                   sample formats (0-based cdata array)
`dev.format_count -> n`                     number of formats
`dev.current_format -> format`              current format
`dev:supports_format(format) -> t|f`        check if device supports a format
`soundio.format_string -> s`                string representation of a format
`soundio.bytes_per_sample(format) -> n`     format bytes per sample
`soundio.bytes_per_frame(format, cn) -> n`  bytes per frame for a format and channel count
`soundio.bytes_per_second(format,cn,sr)->n` bytes per second for a format, channel count and sample rate
__channels__
`soundio.channel_id(name) -> channel`       "front-left" -> C.SoundIoChannelIdFrontLeft
`soundio.channel_name(channel) -> name`     C.SoundIoChannelIdFrontLeft -> "Front Left"
__channel layouts__
`dev.layouts -> layout[]`                   channel layouts (0-based cdata array)
`dev.layout_count -> n`                     number of channel layouts
`dev.current_layout -> layout`              current layout
`layout:find_channel(channel) -> i|nil`     index of channel in layout
`layout:detect_builtin() -> t|f`            sets layout.name if it matches a builtin one
`dev:sort_layouts()`                        sort layouts by channel count, descending
`dev:supports_layout(layout) -> t|f`        TODO
`soundio.layouts() -> iter() -> layout`     iterate built-in channel layouts
`soundio.layouts'#' -> n`                   number of built-in channel layouts
`soundio.layouts('*', nc) -> layout`        default layout per number of channels
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
__latencies__
`dev.software_latency_min -> s`             min. latency
`dev.software_latency_max -> s`             max. latency
`dev.software_latency_current -> s`         current latency (0 if unknown)
__events__
------------------------------------------- ----------------------------------------
