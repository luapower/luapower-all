---
tagline: audio input and output
---

## `local soundio = require'libsoundio'`

A binding of [libsoundio](http://libsound.io/), a library for cross-platform
audio input and output.

## API

------------------------------------------------- ----------------------------------------
`soundio.new() -> sio`                            create a libsoundio state
__backends__
`sio:connect([backend])`                          connect to a/the default backend
`sio:disconnect()`                                disconnect the backend
`sio:backends() -> iter() -> name`                iterate backends
`sio:backends'#' -> n`                            number of available backends
`sio:backends(name) -> t|f`                       check if a backend is available
__devices__
`sio:devices([nil,raw])->iter()->dev`             iterate devices
`sio:devices('#'|'#i'|'#o'[, raw])->n`            number of all|input|output devices
`sio:devices('*i'|'*o'[,raw])->dev|nil`           the default input or output device
`dev.id -> s`                                     device unique id
`dev.name -> s`                                   device name
`dev.aim -> 'i'|'o'`                              device aim: input or output
`dev.soundio -> sio`                              weak back-reference to the libsoundio state
`dev.is_raw -> t|f`                               raw device
`dev.probe_error -> error_code|nil`               device probe error code (C.SoundError enum)
__sample rates__
`dev.sample_rates -> ranges[]`                    0-based array of C.SoundIoSampleRateRange
`dev.sample_rate_count -> n`                      number of sample rate ranges
`dev.sample_rate_current -> i`                    index of current sample rate range
`dev:supports_sample_rate(rate) -> t|f`           check if a sample rate is supported
`dev:nearest_sample_rate(rate) -> rate`           nearest supported sample rate
__sample formats__
`dev.formats -> format[]`                         0-based array of C.SoundIoFormat
`dev.format_count -> n`                           number of formats
`dev.current_format -> format`                    current format (as C.SoundIoFormat)
`dev:supports_format(format) -> t|f`              check if device supports a format
`soundio.format_string(format) -> s`              string representation of a format
`soundio.bytes_per_sample(format) -> n`           format bytes per sample
`soundio.bytes_per_frame(format, cc) -> n`        bytes per frame for a format and channel count
`soundio.bytes_per_second(format, cc, sr) -> n`   bytes per second for a format, channel count and sample rate
__channels__
`soundio.channel_id(name) -> channel`             "front-left" -> C.SoundIoChannelIdFrontLeft
`soundio.channel_name(channel) -> name`           C.SoundIoChannelIdFrontLeft -> "Front Left"
__channel layouts__
`dev.layouts -> layout[]`                         0-based array of C.SoundIoChannelLayout
`dev.layout_count -> n`                           number of channel layouts
`dev.current_layout -> layout`                    current layout (as C.SoundIoChannelLayout)
`layout:find_channel(channel) -> i|nil`           index of channel (by name or id) in layout
`layout:detect_builtin() -> t|f`                  set layout.name if it matches a builtin one
`dev:sort_layouts()`                              sort layouts by channel count, descending
`dev:supports_layout(layout) -> t|f`              check if a channel layout is supported
`soundio.builtin_layouts() -> iter() -> layout`   iterate built-in channel layouts
`soundio.builtin_layouts'#' -> n`                 number of built-in channel layouts
`soundio.builtin_layouts('*', cc) -> layout`      default layout for a certain channel count
__streams__
`dev:stream() -> sin|sout`                        create an input|output stream
`sin|sout:open()`                                 open the stream
`sin|sout:start()`                                start the stream
`sin|sout:pause(t|f|)`                            pause/unpause the stream
`sin|sout.device -> dev`                          weak back-reference to the device
`sin|sout.format -> format`                       sample format
`sin|sout.sample_rate -> rate`                    sample rate
`sin|sout.layout -> layout`                       channel layout
`sin|sout.software_latency -> seconds`            software latency
`sin|sout.name`                                   stream/client/session name
`sin|sout.non_terminal_hint -> t|f`               JACK hint for nonterminal output streams
`sin|sout.bytes_per_frame -> n`                   bytes per frame
`sin|sout.bytes_per_sample -> n`                  bytes per sample
`sin|sout.layout_error -> errcode|nil`            error setting the channel layout
`sin.read_callback <- f(sin, minfc, maxfc)`       read callback (1)
`sin.overflow_callback <- f(sin)`                 buffer full callback (1)
`sout.write_callback <- f(sout, minfc, maxfc)`    write callback (1)
`sout.underflow_callback <- f(sout)`              buffer empty callback (1)
`sin|sout.error_callback <- f(sin, err)`          error callback (1)
`sin|sout:latency() -> seconds`                   get the actual latency
`sout:begin_write(n) -> areas, n`                 start writing `n` frames to the stream
`sout:end_write() -> true|nil`                    say that frames were written (returns true for underflow)
`sout:clear_buffer()`                             clear the buffer
`sin:begin_read(n) -> areas, n`                   start reading `n` frames from the stream
`sin:end_read()`                                  say that the frames were read
__ring buffers__
`sio:ringbuffer() -> rb`                          create a thread-safe ring buffer
`rb:capacity() -> bytes`                          the buffer's capacity
`rb:write_ptr() -> ptr`                           the write pointer
`rb:advance_write_ptr(bytes)`                     advance the write pointer
`rb:read_ptr() -> ptr`                            the read pointer
`rb:advance_read_ptr(bytes)`                      advance the read pointer
`rb:fill_count() -> bytes`                        how many occupied bytes
`rb:free_count() -> bytes`                        how many free bytes
`rb:clear()`                                      clear the buffer
`sin|sio:ringbuffer() -> rb`                      set up a ring buffer for async streaming
__latencies__
`dev.software_latency_min -> s`                   min. software latency
`dev.software_latency_max -> s`                   max. software latency
`dev.software_latency_current -> s`               current software latency (0 if unknown)
__events__
`sio:flush_events()`                              update info on all devices
`sio:wait_events()`                               flush events and wait for more events
`sio:wakeup()`                                    stop waiting for events
__memory management__
`sio|sin|sout|rb:free()`                          free the object and detach it from gc
`dev.ref_count -> n`                              current reference count
`dev:ref|unref() -> dev`                          increment/decrement device ref count
__C__
`soundio.C -> clib`                               the C namespace
------------------------------------------------- ----------------------------------------

__(1)__ Stream callbacks are called from other threads, thus cannot be
assigned to functions from the caller interpreter state. Instead, separate
[luastate]s must be created for each thread and the callbacks must be
assigned to functions from those states.

## Example

~~~{.lua}
local soundio = require'libsoundio'
local time = require'time'

local sio = soundio.new()
assert(sio:backends'#' > 0, 'no backends')
sio:connect()

local dev = assert(sio:devices'*o', 'no output devices')

local str = dev:stream()
str:open()
local rb = str:ringbuffer()
str:start()

while true do
	local areas, n = rb:begin_write(44100)
	for i = 0, n-1 do
		--TODO
	end
	rb:end_write()
end

~~~

## Backends

------------ ----------------------- ---------------
__name__     __platforms__           __default on__
jack         Linux, OSX, Windows
pulseaudio   Linux, OSX, Windows
alsa         Linux                   Linux
coreaudio    OSX                     OSX
wasapi       Windows                 Windows
dummy        Linux, OSX, Windows
------------ ----------------------- ---------------

