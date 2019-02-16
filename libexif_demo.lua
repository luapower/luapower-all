local exif = require"libexif"
local glue = require"glue"
local exif_data = exif.read(glue.readfile('media/jpeg/autumn-wallpaper.jpg'))

if exif_data then
	local tags = exif_data:get_tags()

	if tags.Software then
		print("This image was made in \"" .. tags.Software .. "\".")
	else
		print("The image doesn't have information about software in which it was created!")
	end

	exif_data:free()
else
	print("Looks like image doesn't have EXIF informaton or file is not valid.")
end