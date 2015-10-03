local pa = require'portaudio'
local ffi = require'ffi'
local lua = require'luastate'

print('version:      ', pa.version())
print('version text: ', pa.versionstring())

print('host API count:   ', pa.hostapis'#')
print('default host API: ', pa.hostapis'*')

for i,info in pa.hostapis() do
	print('Host API ', i)
	print('', 'type          ', info.type)
	print('', 'name          ', info.name)
	print('', 'device count  ', info.devices)
	print('', 'input device  ', info.default_input_device)
	print('', 'output device ', info.default_output_device)
end

for i,dev in pa.devices() do
	print('Device ', i)
	print('', 'name                ', dev.name)
	print('', 'host API            ', dev.host_api)
	print('', 'max input channels  ', dev.max_input_channels)
	print('', 'max output channels ', dev.max_output_channels)
	print('', 'default sample rate ', dev.default_sample_rate)
end

local state = lua.open()
state:openlibs()
state:push(function()
	local ffi = require'ffi'
	local pa = require'portaudio'

	local PERIOD = math.floor(44100 / 440)
	local VOLUME = math.floor(0.5^4 * 2^15-1)
	local function sine_wave(sample_index, channel)
		return math.sin(sample_index * 2 * math.pi / PERIOD) * VOLUME
	end
	local n = 44100 * 2 * 2
	local buf = ffi.new('int16_t[?]', n)
	for i=0,n-1,2 do
		buf[i]   = sine_wave(i, 0)
		buf[i+1] = sine_wave(i, 1)
	end

	local si = 0
	local function pa_callback(_, buf, n, time, status, _)
		local buf = ffi.cast('int16_t*', buf)
		print('pa_callback', buf, n, status)
		if buf == nil then return 0 end
		for i=0,n-1 do
			buf[i*2]   = sine_wave(si, 0)
			buf[i*2+1] = sine_wave(si, 1)
			si = si + 1
		end
		return pa.C.paContinue
	end

	local cb = ffi.cast('PaStreamCallback*', pa_callback)
	return tonumber(ffi.cast('intptr_t', cb))
end)
local pa_callback = ffi.cast('PaStreamCallback*', state:call())

local stream = pa.open{
	output = {},
	callback = pa_callback,
	frames = 44100,
	finished = function() print'finished' end,
}
stream:start()
--stream:write(buf, n)
print(stream:running())
print(stream:active())
print'sleeping'
pa.sleep(5)
print'stopping'
stream:stop()
print'closing'
stream:close()

--[[
	print('device', dev.device)
	print('', 'channels ', dev.channelCount)
	print('', 'format   ', dev.sampleFormat)
	print('', 'latency  ', dev.suggestedLatency)
]]

pa.terminate()
