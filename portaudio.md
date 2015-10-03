---
tagline: portable audio I/O
---

A binding of [PortAudio](http://portaudio.com/), the audio I/O library
which powers Audacity. The included binaries only support the 'directsound'
host APIs.

<warn>Work in progress.</warn>

## API

------------------------------------------ ------------------------------------------
__host APIs__
`pa.hostapis() -> iter() -> i, info`       iterate host APIs
`pa.hostapis'#' -> n`                      host API count
`pa.hostapis'*' -> i`                      index of default host API
`pa.hostapi([i|api]) -> info|nil`          host API info
__devices__
`pa.devices'#' -> n`                       device count
`pa.devices'*i' -> i`                      index of default input device
`pa.devices'*o' -> i`                      index of default output device
`pa.devices() -> iter() -> i, info`        iterate devices
`pa.device('*i'|'*o'|i) -> info|nil`       device info
__streams__
`pa.open(['*i'|'*o'|t]) -> stream`         open a stream
`stream:close()`                           close
`stream:start()`                           start
`stream:stop()`                            stop
`stream:abort()`                           abort
`stream:running() -> t|f`                  check if started
`stream:active() -> t|f`                   check if active
`stream:info() -> info`                    stream info
`stream:time() -> time`                    time
`stream:cpuload() -> ?`                    CPU load
`stream:read(buf, n)`                      read `n` frames from stream into `buf`
`stream:write(buf, n)`                     write `n` frames from `buf` to stream
`stream:read'#' -> n`                      how many samples can be read without blocking
`stream:write'#' -> n`                     how many samples can be written without blocking
__other__
`pa.samplesize(format) -> n`               sample size for a format
`pa.sleep(s)`                              sleep
------------------------------------------ ------------------------------------------

## Host APIs

### `pa.hostapi([i|api]) -> info`

Get info about a host API. Possible APIs are: 'pa', 'directsound', 'mme',
'asio', 'soundmanager', 'coreaudio', 'oss', 'alsa',  'al', 'beos', 'wdmks',
'jack', 'wasapi', 'audiosciencehpi'.

## Streams

### `pa.open(['*i'|'*o'|i|t]) -> stream`

Open a stream. The arg can be `'*i'` (default input device), `'*o'` (default
output device), a valid device index (in which case it will be used for
input and/or output depending on its number of input and output channels),
or a table with the fields:

* `input`, `output` - input and/or output devices; can be either:
	* `'*i'` - default input device
	* `'*o'` - default output device
	* a table with the fields:
		* `device` - the device index (`'*i'` or `'*o'`)
		* `channels` - number of channels (2)
		* `format` - sample format: 'float32', 'int32', 'int24', 'int16',
		'int8', 'uint8', 'custom' ('int16')
		* `latency` - suggested latency (0)
* `samplerate` - sample rate (44100)
* `callback` - (optional) callback function `f([input, ][output, ]n, timeinfo, status) -> ret`:
	* `input`, `output` - the buffer: `void*`
	* `n` - the number of frames to be read/written
	* `timeinfo` - a C struct with the fields:
		* `input_buffer_adc_time` - TODO
		* `current_time` - TODO
		* `output_buffer_dac_time` - TODO
	* `status` - TODO
	* `ret` - nil|nothing|'continue', false|'abort', true|'complete'
* `finished` - (optiona) callback `f()` called when the stream has finished
* `frames` - how many frames to pass to the callback buffer (0 i.e. variable)
* `noclip` - TODO (false)
* `nodither` - TODO (false)
* `neverdropinput` - TODO (false)
* `primeoutput` - TODO (false)

