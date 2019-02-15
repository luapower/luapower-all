--libexif binding
if not ... then require'libexif_demo' return end

local ffi = require'ffi'
local C = ffi.load'exif'
require'libexif_h'

local exif = {
	C = C
}

local meta_exif_data = {}
meta_exif_data.__index = meta_exif_data
meta_exif_data.__tostring = function() return "ExifData" end

function meta_exif_data:get_tags()
	local tags = {}
	local buf = ffi.new("char[1024]")

	local for_content = ffi.cast("ExifDataForeachContentFunc", function(exif_content)
		C.exif_content_fix(exif_content)
		local ifd = C.exif_content_get_ifd(exif_content)

		local for_entry = ffi.cast("ExifContentForeachEntryFunc", function(exif_entry)
			C.exif_entry_fix(exif_entry)
			local tag_name = ffi.string(C.exif_tag_get_name_in_ifd(exif_entry.tag, ifd))
			local tag_value = ffi.string(C.exif_entry_get_value(exif_entry, buf, 1024))

			if tag_value == "Internal error (unknown value 0)" then
				tag_value = nil
			end -- Exception
			tags[tag_name] = tag_value
		end)

		C.exif_content_foreach_entry(exif_content, for_entry, nil)
		for_entry:free()
	end)

	C.exif_data_foreach_content(self.raw, for_content, nil)
	for_content:free()

	return tags
end

function meta_exif_data:free()
	return C.exif_data_free(self.raw)
end

function exif.read(data)
	if type(data) ~= "string" then return false end
	local edata = ffi.new("ExifData*")
	local loader = ffi.new("ExifLoader*")
	loader = C.exif_loader_new()
	local buf = ffi.cast("unsigned char*", data)
	C.exif_loader_write(loader, buf, #data)
	edata = C.exif_loader_get_data(loader)
	C.exif_loader_unref(loader)

	if edata == nil then
		C.exif_data_free(edata)

		return false
	end

	return setmetatable({
		raw = edata
	}, meta_exif_data)
end

return exif