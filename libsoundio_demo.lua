local soundio = require'libsoundio'
local ffi = require'ffi'
local lua = require'luastate'
local time = require'time'

local sio = soundio.new()

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
assert(not dev.probe_error)

local str = dev:stream()
str:open()
assert(not str.layout_error)
local buf = str:buffer(0.1)
str:clear_buffer()
str:start()

local pitch = 440
local mins, maxs = soundio.sample_range(str.format)
local volume = 0.1 * maxs
local sin_factor = 2 * math.pi / str.sample_rate * pitch
local frame0 = 0
local function sample(frame, channel)
	local octave = channel + 1
	return volume * math.sin((frame0 + frame) * sin_factor * octave)
end

local duration, interval, protection = 1, 0.01, 0.05
print(string.format('Playing L=%dHz R=%dHz for %ds...', pitch, pitch * 2, duration))

local min_frame_count = str.sample_rate * (interval + protection)

for i = 1, duration / interval do
	local p, fn = buf:write_buf()
	local n = math.floor(math.min(fn, min_frame_count))
	if n > 0 then
		print(string.format('latency: %-.2fs, empty: %3d%%, filling: %3d%%',
			str:latency(), fn / buf:capacity() * 100, n / buf:capacity() * 100))
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
