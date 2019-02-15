local exif = require"libexif"
local glue = require"glue"
local exif_data = exif.read(glue.readfile('media/jpeg/autumn-wallpaper.jpg'))

local compare_table = {
	ColorSpace = "sRGB",
	DateTime = "2007:12:18 07:24:35",
	ExifVersion = "Exif Version 2.1",
	FlashPixVersion = "FlashPix Version 1.0",
	Orientation = "Top-left",
	PixelXDimension = "1920",
	PixelYDimension = "1080",
	ResolutionUnit = "Inch",
	Software = "Adobe Photoshop Elements 4.0.1 Macintosh",
	XResolution = "72",
	YResolution = "72"
}

local compare_check = {}

for k, v in pairs(compare_table) do
	compare_check[k] = false
end

if exif_data ~= nil then
	local tags = exif_data:get_tags()
	local ok = true

	for k, v in pairs(tags) do
		if compare_table[k] == v then
			compare_check[k] = true
		elseif compare_table[k] == nil then
			print("[libexif] Image gets new unlisted tag!", k, v)
			ok = false
		else
			compare_check[k] = true
			print("[libexif] Image gets new value for tag!", k, v)
			ok = false
		end
	end

	local all = true

	for k, v in pairs(compare_check) do
		if v == false then
			print("[libexif] Image lost EXIF tag!", k)
			all = false
		end
	end

	if all then
		print("[libexif] All tags were found.")
	end

	if ok then
		print("[libexif] OK")
	else
		print("[libexif] ERROR")
	end
else
	print("[libexif] EXIF parsing failed!")
end