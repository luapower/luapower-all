
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

function M.new(backend)
	local self = C.soundio_create()
	assert(self ~= nil)
	ffi.gc(self, self.free)
	if backend ~= false then
		self:connect(backend)
	end
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

local sample_ranges = {
	[C.SoundIoFormatS8]        = { -2^7,  2^7-1},
	[C.SoundIoFormatU8]        = {    0,  2^8-1},
	[C.SoundIoFormatS16NE]     = {-2^15, 2^15-1},
	[C.SoundIoFormatU16NE]     = {    0, 2^16-1},
	[C.SoundIoFormatS24LE]     = {-2^23, 2^23-1},
	[C.SoundIoFormatU24LE]     = {    0, 2^24-1},
	[C.SoundIoFormatS32LE]     = {-2^31, 2^31-1},
	[C.SoundIoFormatU32LE]     = {    0, 2^32-1},
	[C.SoundIoFormatFloat32LE] = {    0, 1},
	[C.SoundIoFormatFloat64LE] = {    0, 1},
}

function M.sample_range(format)
	return unpack(sample_ranges[tonumber(format)], 1, 2)
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

--device info dump -----------------------------------------------------------

function dev:print(print_)
	local print = print_ or print
	print('Device Info')
	print('  id     : '..self.id)
	print('  name   : '..self.name)
	print('  aim    : '..self.aim)
	print('  layuts : ')
	for i = 0, self.layout_count-1 do
		local layout = self.layouts[i]
		print('   '..i..': ')
		print('     name     : '..layout.name..
			(self.current_layout == layout and ' (current)' or ''))
		print('     channels : ')
		for i = 0, layout.channel_count-1 do
			print('       '..i..' : '..M.channel_name(layout.channels[i]))
		end
	end
	print('  formats : ')
	for i = 0, self.format_count-1 do
		local fmt = self.formats[i]
		print('    '..i..' : '..M.format_string(fmt)..
			(fmt == self.current_format and ' (current)' or ' '))
	end
	print('  sample_rates : ')
	for i = 0, self.sample_rate_count-1 do
		local sr = self.sample_rates[i]
		print('    '..i..' : ' ..sr.min..' - '..sr.max)
	end
	print('  sample_rate_current : '..self.sample_rate_current)
	print('  latency range       : '..self.software_latency_min..' - '..self.software_latency_max)
	print('  current_latency     : '..self.software_latency_current)
	print('  is_raw              : '..tostring(self.is_raw))
	print('  ref_count           : '..self.ref_count)
	print('  probe_error         : '..tostring(self.probe_error))
end

--streams --------------------------------------------------------------------

function dev:stream()
	local dev = self
	local self = checkptr(self.aim == 'o' and
		C.soundio_outstream_create(self) or
		C.soundio_instream_create(self))
	ffi.gc(self, self.free)
	if not dev.probe_error then
		assert(dev:supports_sample_rate(44100))
		assert(dev:supports_format(C.SoundIoFormatFloat32NE))
	end
	self.sample_rate = 44100
	self.format = C.SoundIoFormatFloat32NE
	return self
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

function stroutprop:bytes_per_second()
	return self.bytes_per_frame * self.sample_rate
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

strinprop.bytes_per_second = stroutprop.bytes_per_second

--ringbuffers ----------------------------------------------------------------

local rb = {}
rb.__index = rb

function sio:ringbuffer(capacity)
	local self = checkptr(C.soundio_ring_buffer_create(self, capacity))
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
function rb:write_buf() return self:write_ptr(), self:free_count() end
function rb:read_buf() return self:read_ptr(), self:fill_count() end

--buffered streaming API -----------------------------------------------------

local buf = {}
buf.__index = buf

local sample_types = {
	[C.SoundIoFormatS8]        = 'int8_t',
	[C.SoundIoFormatU8]        = 'uint8_t',
	[C.SoundIoFormatS16NE]     = 'int16_t',
	[C.SoundIoFormatU16NE]     = 'uint16_t',
	[C.SoundIoFormatS32LE]     = 'int32_t',
	[C.SoundIoFormatU32LE]     = 'uint32_t',
	[C.SoundIoFormatFloat32LE] = 'float',
	[C.SoundIoFormatFloat64LE] = 'double',
}

function strout:buffer(buffer_size_seconds)

	local function setup_state(ringbuffer_ptr, bpf)

		local ffi = require'ffi'
		local sio = require'libsoundio'

		local ringbuffer = ffi.cast('struct SoundIoRingBuffer*', ringbuffer_ptr)

		local function write_callback(outstream, frame_count_min, frame_count_max)
			local avail_bytes = ringbuffer:fill_count()
			local max_bytes = math.min(avail_bytes, frame_count_max * bpf)
			local max_frames = math.floor(max_bytes / bpf)
			local buf = ringbuffer:read_ptr()
			local frames_left = max_frames
			while frames_left > 0 do
				local areas, write_frames = outstream:begin_write(frames_left)
				if write_frames <= 0 then break end
				local read_bytes = write_frames * bpf
				ffi.copy(areas[0].ptr, buf, read_bytes)
				ringbuffer:advance_read_ptr(read_bytes)
				if outstream:end_write() then break end --underflow
				frames_left = frames_left - write_frames
			end
		end

		local write_cb = ffi.cast('SoundIoWriteCallback', write_callback)
		return tonumber(ffi.cast('intptr_t', write_cb))
	end

	local sample_type = sample_types[tonumber(self.format)]
	local ptr_type = sample_type
		and ffi.typeof('$(*)[$]', ffi.typeof(sample_type), self.layout.channel_count)
		or ffi.typeof'void*'
	local bps = self.bytes_per_second
	local buffer_size = math.ceil((buffer_size_seconds or 1) * bps)

	local ringbuffer = self.device.soundio:ringbuffer(buffer_size)

	local state = require('luastate').open()
	state:openlibs()
	state:push(setup_state)

	local ringbuffer_addr = tonumber(ffi.cast('intptr_t', ringbuffer))
	local write_cb_addr = state:call(ringbuffer_addr, self.bytes_per_frame)
	self.write_callback = ffi.cast('SoundIoWriteCallback', write_cb_addr)

	local buffer = setmetatable({
		ringbuffer = ringbuffer,
		state = state,
		ptr_type = ptr_type,
		stream = self,
	}, buf)
	return buffer
end

function buf:free()
	self.stream.write_callback = nil
	self.ringbuffer:free()
	self.state:close()
end

function buf:write_ptr()
	return ffi.cast(self.ptr_type, self.ringbuffer:write_ptr())
end

function buf:advance_write_ptr(n)
	self.ringbuffer:advance_write_ptr(n * self.stream.bytes_per_frame)
end

function buf:read_ptr()
	return ffi.cast(self.ptr_type, self.ringbuffer:read_ptr())
end

function buf:advance_read_ptr(n)
	self.ringbuffer:advance_read_ptr(n * self.stream.bytes_per_frame)
end

function buf:fill_count()
	return math.floor(self.ringbuffer:fill_count() / self.stream.bytes_per_frame)
end

function buf:free_count()
	return math.floor(self.ringbuffer:free_count() / self.stream.bytes_per_frame)
end

function buf:capacity()
	return math.floor(self.ringbuffer:capacity() / self.stream.bytes_per_frame)
end

buf.write_buf = rb.write_buf
buf.read_buf = rb.read_buf

--metatype assignments -------------------------------------------------------

ffi.metatype('struct SoundIo', sio)
ffi.metatype('struct SoundIoDevice', dev)
ffi.metatype('struct SoundIoRingBuffer', rb)
ffi.metatype('struct SoundIoOutStream', strout)
ffi.metatype('struct SoundIoInStream', strin)
ffi.metatype('struct SoundIoChannelLayout', layout)

return M
