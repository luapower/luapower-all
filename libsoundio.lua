
--libsoundio binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libsoundio_demo'; return end

local ffi = require'ffi'
require'libsoundio_h'

local C = ffi.load'soundio'
local M = {C = C}

--helpers --------------------------------------------------------------------

local function ptr(p)
	return p ~= nil and p or nil
end

local function checkptr(p)
	return assert(ptr(p), 'non-null pointer expected')
end

local function check(err)
	if err == 0 then return end
	error(ffi.string(C.soundio_strerror(err)), 3)
end

local function vprops(index_table, property_table)
	return function(self, k)
		local get = property_table[k]
		if get then return get(self) end
		local v = index_table[k]
		if not v then error('invalid property '..k, 2) end
		return v
	end
end

--soundio --------------------------------------------------------------------

function M.new(t)
	t = t or {}
	local self = C.soundio_create()
	assert(self ~= nil)
	ffi.gc(self, self.free)
	--local function callback(func) end --TODO: wrap in a Lua state + queue
	--self.on_devices_change = callback(t.on_devices_change)
	--self.on_backend_disconnect = callback(t.on_backend_disconnect)
	--self.on_events_signal = callback(t.on_events_signal)
	--self.emit_rtprio_warning = callback(t.emit_rtprio_warning)
	--self.jack_info_callback = callback(t.on_jack_info)
	--self.jack_error_callback = callback(t.on_jack_error)
	return self
end

local sio = {}
sio.__index = sio

function sio:free()
	ffi.gc(self, nil)
	C.soundio_destroy(self)
end

--backends -------------------------------------------------------------------

M.backends = {
	jack       = C.SoundIoBackendJack,
	pulseaudio = C.SoundIoBackendPulseAudio,
	alsa       = C.SoundIoBackendAlsa,
	coreaudio  = C.SoundIoBackendCoreAudio,
	wasapi     = C.SoundIoBackendWasapi,
	dummy      = C.SoundIoBackendDummy,
}
local backend_names = {}
for k,v in pairs(M.backends) do
	backend_names[tonumber(v)] = k
end
local function tobackend(backend)
	return (assert(M.backends[backend:lower()], 'invalid backend'))
end

function sio:connect(backend)
	check(backend
		and C.soundio_connect_backend(self, tobackend(backend))
		or C.soundio_connect(self))
	self:flush_events()
end

sio.disconnect = C.soundio_disconnect

function sio:backends(which)
	if not which then --enumerate: backend, backend_name
		local i = -1
		return function()
			i = i + 1
			local backend = C.soundio_get_backend(self, i)
			if backend == C.SoundIoBackendNone then return end
			return assert(backend_names[backend])
		end
	elseif which == '#' then --count
		return C.soundio_backend_count(self)
	else --check by name
		return C.soundio_have_backend(self, tobackend(which)) == 1
	end
end

--events ---------------------------------------------------------------------

sio.flush_events = C.soundio_flush_events
sio.wait_events = C.soundio_wait_events
sio.wakeup = C.soundio_wakeup

--device list ----------------------------------------------------------------

sio.force_device_scan = C.soundio_force_device_scan

local function devices_api(getbyindex, count, getdefaultindex)
	local function get(self, i)
		return ffi.gc(checkptr(getbyindex(self, i)), C.soundio_device_unref)
	end
	local function api(self, which, filter)
		if not which then --iterate filtered
			local i = 0
			local n = count(self)
			return function()
				while i < n do
					local dev = get(self, i)
					i = i + 1
					if filter(dev) then
						return dev
					end
				end
			end
		elseif which == '#' then --count
			if filter == nil then
				return count(self)
			end
			--count filtered
			local n = 0
			for dev in api(self, nil, filter) do
				n = n + 1
			end
			return n
		elseif which == '*' then --get default
			if filter == nil then
				local i = getdefaultindex(self)
				return i >= 0 and get(self, i) or nil
			end
			--get default filtered
			local dev = api(self, '*')
			return dev and api(self, dev.id, filter)
		else --find by id
			for dev in api(self, nil, filter) do
				if dev.id == which then
					return dev
				end
			end
		end
	end
	return api
end

local input_devices = devices_api(
	C.soundio_get_input_device,
	C.soundio_input_device_count,
	C.soundio_default_input_device_index)

local output_devices = devices_api(
	C.soundio_get_output_device,
	C.soundio_output_device_count,
	C.soundio_default_output_device_index)

local function fraw(dev) return dev.is_raw end
local function fnotraw(dev) return not dev.is_raw end
local function ftrue(dev) return true end

function sio:devices(which, raw)
	local filter =
		raw == true and fraw
		or raw == false and fnotraw
		or raw == nil and ftrue
		or raw --custom filter
	if not which then --iterate all
		local next_dev = input_devices(self, nil, filter)
		local on_input = true
		return function()
			local dev = next_dev()
			if not dev and on_input then
				next_dev = output_devices(self, nil, filter)
				on_input = false
				dev = next_dev()
			end
			return dev
		end
	elseif which == '#' then --count all
		return
			input_devices(self, '#', filter) +
			output_devices(self, '#', filter)
	elseif which == '#i' then
		return input_devices(self, '#', filter)
	elseif which == '#o' then
		return output_devices(self, '#', filter)
	elseif which == '*i' then
		return input_devices(self, '*', filter)
	elseif which == '*o' then
		return output_devices(self, '*', filter)
	else --find by id
		return
			input_devices(self, which, filter) or
			output_devices(self, which, filter)
	end
end

--devices --------------------------------------------------------------------

local dev = {}

function dev:ref() C.soundio_device_ref(self); return self; end
function dev:unref() C.soundio_device_unref(self); return self; end

dev.supports_format = C.soundio_device_supports_format
dev.supports_layout = C.soundio_device_supports_layout
dev.supports_sample_rate = C.soundio_device_supports_sample_rate
dev.nearest_sample_rate = C.soundio_device_nearest_sample_rate

local devprop = {}
function devprop:id() return ffi.string(self.id_ptr) end
function devprop:name() return ffi.string(self.name_ptr) end
function devprop:aim() return
	self.aim_enum == C.SoundIoDeviceAimInput and 'i' or 'o'
end
function devprop:probe_error()
	return self.probe_error_code ~= 0 and self.probe_error_code or nil
end

dev.__eq = C.soundio_device_equal
dev.__index = vprops(dev, devprop)

--formats --------------------------------------------------------------------

function M.format_string(format)
	return ffi.string(C.soundio_format_string(format))
end

M.bytes_per_sample = C.soundio_get_bytes_per_sample

function M.bytes_per_frame(format, channel_count)
	return M.bytes_per_sample(format) * channel_count
end

function M.bytes_per_second(format, channel_count, sample_rate)
	return M.bytes_per_frame(format, channel_count) * sample_rate
end

--channels -------------------------------------------------------------------

function M.channel_id(name)
	local chan = C.soundio_parse_channel_id(name, #name)
	if chan == SoundIoChannelIdInvalid then return end
	return chan
end

function M.channel_name(channel)
	return ffi.string(C.soundio_get_channel_name(channel))
end

--channel layouts ------------------------------------------------------------

local layout = {}
local layoutprop = {}
layout.__eq = C.soundio_channel_layout_equal
layout.__index = vprops(layout, layoutprop)

layoutprop.name = devprop.name

function M.builtin_layouts(which, channel_count)
	if not which then --iterate
		local i = -1
		local n = C.soundio_channel_layout_builtin_count()
		return function()
			i = i + 1
			if i >= n then return end
			return C.soundio_channel_layout_get_builtin(i)
		end
	elseif which == '#' then --count
		return C.soundio_channel_layout_builtin_count()
	elseif which == '*' then --default layout per channel count
		return C.soundio_channel_layout_get_default(channel_count)
	end
end

function layout:find_channel(channel)
	if type(channel) == 'string' then
		channel = assert(M.channel_id(channel), 'invalid channel name')
	end
	local i = C.soundio_channel_layout_find_channel(self, channel)
	return i ~= -1 and i or nil
end

function layout:detect_builtin()
	return C.soundio_channel_layout_detect_builtin(self)
end

function dev:sort_layouts()
	C.soundio_sort_channel_layouts(self.layouts, self.layout_count)
end

--streams --------------------------------------------------------------------

function dev:stream()
	local self = checkptr(dev.aim == 'o' and
		C.soundio_outstream_create(self) or
		C.soundio_instream_create(self))
	return ffi.gc(self, self.free)
end

--streams/output -------------------------------------------------------------

local strout = {}
local stroutprop = {}
strout.__index = vprops(strout, stroutprop)

stroutprop.name = devprop.name

function stroutprop:layout_error()
	return self.layout_error_code ~= 0 and self.layout_error_code or nil
end

function strout:free()
	ffi.gc(self, nil)
	C.soundio_outstream_destroy(self)
end

function strout:open() check(C.soundio_outstream_open(self)) end
function strout:start() check(C.soundio_outstream_start(self)) end

local areas = ffi.new'struct SoundIoChannelArea*[1]'
local fcnt  = ffi.new'int[1]'

function strout:begin_write(n)
	fcnt[0] = n
	check(C.soundio_outstream_begin_write(self, areas, fcnt))
	return areas[0], fcnt[0]
end

function strout:end_write()
	local ret = C.soundio_outstream_end_write(self)
	if ret == C.SoundIoErrorUnderflow then
		return true
	end
	check(ret)
end

function strout:clear_buffer()
	check(C.soundio_outstream_clear_buffer(self))
end

function strout:pause(pause)
	check(C.soundio_outstream_pause(self, pause))
end

local dbuf = ffi.new'double[1]'

function strout:latency()
	check(C.soundio_outstream_get_latency(self, dbuf))
	return dbuf[0]
end

--streams/input --------------------------------------------------------------

local strin = {}
local strinprop = {}
strin.__index = vprops(strin, strinprop)

strinprop.name         = stroutprop.name
strinprop.layout_error = stroutprop.layout_error

function strin:free()
	ffi.gc(self, nil)
	C.soundio_instream_destroy(self)
end

function strin:open() check(C.soundio_instream_open(self)) end
function strin:start() check(C.soundio_instream_start(self)) end

function strin:begin_read(n)
	fcnt[0] = n
	check(C.soundio_instream_begin_read(self, areas, fcnt))
	return areas[0], fcnt[0]
end

function strin:end_read()
	check(C.soundio_instream_end_read(self))
end

function strin:pause(pause)
	check(C.soundio_instream_pause(self, pause))
end

function strin:latency()
	check(C.soundio_instream_get_latency(self, dbuf))
	return dbuf[0]
end

--ringbuffers ----------------------------------------------------------------

local rb = {}
rb.__index = rb

function M.ringbuffer(sio, capacity)
	local self = checkptr(C.soundio_ring_buffer_create(sio, capacity))
	return ffi.gc(self, self.free)
end

function rb:free()
	ffi.gc(self, nil)
	C.soundio_ring_buffer_destroy(self)
end

rb.capacity = C.soundio_ring_buffer_capacity
rb.write_ptr = C.soundio_ring_buffer_write_ptr
rb.advance_write_ptr = C.soundio_ring_buffer_advance_write_ptr
rb.read_ptr = C.soundio_ring_buffer_read_ptr
rb.advance_read_ptr = C.soundio_ring_buffer_advance_read_ptr
rb.fill_count = C.soundio_ring_buffer_fill_count
rb.free_count = C.soundio_ring_buffer_free_count
rb.clear = C.soundio_ring_buffer_clear

--ringbuffer-based streaming API ---------------------------------------------

local async = {}

function async:write(channel, frames)

end

function strout:setasync(t)

	local function setup_state(ringbuffer_ptr)

		local ffi = require'ffi'
		local sio = require'libsoundio'
		local C = sio.C

		local function protect(func)
			local function pass(ok, ...)
				if not ok then
					io.stderr:write(string.format("error: %s\n", (...)))
					os.exit(1)
				end
				return ...
			end
			return function(...)
				return pass(xpcall(func, debug.traceback, ...))
			end
		end

		local ringbuffer = ffi.cast('struct SoundIoRingBuffer*', ringbuffer_ptr)

		local function write_callback(outstream, frame_count_min, frame_count_max)

			local fill_bytes = ringbuffer:fill_count()
			local read_buf = ringbuffer:read_ptr()
			local fill_bytes = math.min(fill_bytes, frame_count_max * 4)
			local frames_left = math.floor(fill_bytes / 4)

			if frames_left <= 0 then return end

			local areas, frame_count = nil, frames_left
			while true do
				areas, frame_count = outstream:begin_write(frame_count)

				if frame_count == 0 then
					break
				end

				print(fill_bytes)
				ffi.copy(areas[0].ptr, read_buf, fill_bytes)
				ringbuffer:advance_read_ptr(fill_bytes)

				if outstream:end_write() then return end

				frames_left = frames_left - frame_count
				if frames_left <= 0 then
					break
				end
			end

		end

		local write_cb = ffi.cast('SoundIoWriteCallback', protect(write_callback))
		return tonumber(ffi.cast('intptr_t', write_cb))
	end

	local buffer_size = t.buffer_size or 2^16
	local ringbuffer = M.ringbuffer(soundio, buffer_size)

	local state = require('luastate').open()
	state:openlibs()
	state:push(setup_state)

	local write_callback = state:call(tonumber(ffi.cast('intptr_t', ringbuffer)))
	self.write_callback = ffi.cast('SoundIoWriteCallback', write_callback)

	async.ringbuffer = ringbuffer
	async.state = state

	return async
end

--metatype assignments -------------------------------------------------------

ffi.metatype('struct SoundIo', sio)
ffi.metatype('struct SoundIoDevice', dev)
ffi.metatype('struct SoundIoRingBuffer', rb)
ffi.metatype('struct SoundIoOutStream', strout)
ffi.metatype('struct SoundIoInStream', strin)
ffi.metatype('struct SoundIoChannelLayout', layout)

return M
