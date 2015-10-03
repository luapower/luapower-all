
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

local function vprops(get, getprop)
	return function(self, k)
		local getprop = getprop[k]
		if getprop then return getprop(self) end
		return get[k]
	end
end

--soundio --------------------------------------------------------------------

local function soundio_free(self)
	ffi.gc(self, nil)
	C.soundio_destroy(self)
end

function M.new(t)
	t = t or {}
	local self = C.soundio_create()
	assert(self ~= nil)
	ffi.gc(self, soundio_free)
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
	return assert(M.backends[backend:lower()], 'invalid backend')
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

local function devices_api(get, count, getdefault)
	local function api(self, which, filter)
		if not which then --iterate filtered
			local i = 0
			local n = count(self)
			return function()
				while i < n do
					local dev = checkptr(get(self, i))
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
				local i = getdefault(self)
				return i >= 0 and checkptr(get(self, i)) or nil
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

dev.sort_channel_layouts = C.soundio_device_sort_channel_layouts
dev.supports_format = C.soundio_device_supports_format
dev.supports_layout = C.soundio_device_supports_layout
dev.supports_sample_rate = C.soundio_device_supports_sample_rate
dev.nearest_sample_rate = C.soundio_device_nearest_sample_rate

local devget = {}
function devget:id() return ffi.string(self.id_ptr) end
function devget:name() return ffi.string(self.name_ptr) end
function devget:aim() return
	self.aim_enum == C.SoundIoDeviceAimInput and 'i' or 'o'
end

dev.__eq = C.soundio_device_equal
dev.__index = vprops(dev, devget)

--streams --------------------------------------------------------------------

function dev:stream(which)
	local out = which ~= 'i'
	local self = checkptr(out and
		C.soundio_outstream_create(self) or
		C.soundio_instream_create(self))
	ffi.gc(self, self.free)
	return self
end

--streams/output -------------------------------------------------------------

local strout = {}
strout.__index = strout

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
strin.__index = strin

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

function rb:free()
	ffi.gc(self, nil)
	C.soundio_ring_buffer_destroy(self)
end

function M.ringbuffer(sio, capacity)
	return ffi.gc(checkptr(C.soundio_ring_buffer_create(sio, capacity)), rb.free)
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

function strout:setup(t)

	local function setup(ringbuffer_ptr, underflow_callback)

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

			local float_sample_rate = outstream.sample_rate
			local seconds_per_frame = 1 / float_sample_rate
			local err

			local fill_bytes, read_buf, frames_left

			fill_bytes = ringbuffer:fill_count()
			read_buf = ringbuffer:read_ptr()
			fill_bytes = math.min(fill_bytes, frame_count_max * 4)
			frames_left = math.floor(fill_bytes / 4)

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
				areas[0].ptr = areas[0].ptr + fill_bytes
				areas[1].ptr = areas[1].ptr + fill_bytes

				if outstream:end_write() then return end

				frames_left = frames_left - frame_count
				if frames_left <= 0 then
					break
				end
			end

		end
		local write_cb =
			ffi.cast('SoundIoWriteCallback', protect(write_callback))

		local underflow_cb = underflow_callback
			and ffi.cast('SoundIoUnderflowCallback', protect(underflow_callback))

		return
			tonumber(ffi.cast('intptr_t', write_cb)),
			tonumber(ffi.cast('intptr_t', underflow_cb))

	end

	local lua = require'luastate'

	local state = lua.open()
	state:openlibs()
	state:push(setup)

	local ringbuffer = M.ringbuffer(soundio, buffer_size)
	local write_callback, underflow_callback =
		state:call(
			tonumber(ffi.cast('intptr_t', ringbuffer)),
			t.underflow_callback
		)
	write_callback = ffi.cast('SoundIoWriteCallback', write_callback)
	underflow_callback = ffi.cast('SoundIoUnderflowCallback', underflow_callback)

	self.write_callback = write_callback
	self.underflow_callback = underflow_callback

	ffi.gc(self, function()
		ringbuffer = nil --anchor it
	end)
end

--metatype assignments -------------------------------------------------------

ffi.metatype('struct SoundIo', sio)
ffi.metatype('struct SoundIoDevice', dev)
ffi.metatype('struct SoundIoRingBuffer', rb)
ffi.metatype('struct SoundIoOutStream', strout)
ffi.metatype('struct SoundIoInStream', strin)

return M
