local soundio = require'libsoundio'
local ffi = require'ffi'
local lua = require'luastate'
local time = require'time'

local sio = soundio.new()
sio:connect()

--reflection -----------------------------------------------------------------

local idev = sio:devices'*i'
local odev = sio:devices'*o'
local idev_raw = sio:devices('*i', true)
local odev_raw = sio:devices('*o', true)
print(idev.id == (idev_raw and idev_raw.id), idev == idev_raw)

print'Devices'
for dev in sio:devices() do
	print('  '..
		(dev == idev and '*i' or
		dev == odev and '*o' or ' '..dev.aim)..
		(dev.is_raw and '/raw' or '    '),
		dev.id, dev.name)
end

odev:print()

--buffered streaming ---------------------------------------------------------

local dev = odev
assert(not dev.probe_error, 'device probing error')

local str = dev:stream()
str:open()
assert(not str.layout_error, 'unable to set channel layout')

local buf = str:buffer(0.1) --make a 0.1s buffer
str:clear_buffer()

str:start()

local pitch = 440
local volume = 0.1
local sin_factor = 2 * math.pi / str.sample_rate * pitch
local frame0 = 0
local function sample(frame, channel)
	local octave = channel + 1
	return volume * math.sin((frame0 + frame) * sin_factor * octave)
end

local duration, interval = 1, 0.05
print(string.format('Playing L=%dHz R=%dHz for %ds...', pitch, pitch * 2, duration))

for i = 1, duration / interval do
	local p, n = buf:write_buf()
	if n > 0 then
		print(string.format('latency: %-.2fs, empty: %3d%%',
			str:latency(), n / buf:capacity() * 100))
		for channel = 0, str.layout.channel_count-1 do
			for i = 0, n-1 do
				p[i][channel] = sample(i, channel)
			end
		end
		buf:advance_write_ptr(n)
		frame0 = frame0 + n
	end
	time.sleep(interval)
end

buf:free()
str:free()
sio:free()
print'Done'
