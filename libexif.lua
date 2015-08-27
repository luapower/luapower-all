--libexif binding
local ffi = require'ffi'
local C = ffi.load'exif'
require'libexif_h'

if not ... then
	local ed = C.exif_data_new_from_file('media/jpeg/autumn-wallpaper.jpg')
	if ed ~= nil then
		C.exif_data_dump(ed)
		C.exif_data_unref(ed)
	end
end

return C
