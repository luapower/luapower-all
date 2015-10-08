
local vf = require'libvorbis_file'
local ffi = require'ffi'

local vf = vf.open{path = 'media/ogg/A-major.ogg'}

vf:print()

local buf = ffi.new'int16_t[4096]'
while true do
	local n = vf:read(buf, ffi.sizeof(buf))
	print(n)
	if n == 0 then break end
end
