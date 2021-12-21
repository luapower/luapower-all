setfenv(1, require'terra.low')
local bitmap = require'terra.bitmap'
require'terra.cairo'

terra test_blend()
	var sr1 = cairo_image_surface_create_from_png'trlib_test.png'
	assert(sr1:status() == 0) --file loaded
	var b1 = sr1:copy()
	var b2 = bitmap.new(1000, 1000, bitmap.FORMAT_ARGB32, -1)
	b1:blend(&b2, 0, 0, bitmap.BLEND_SOURCE)
	var sr = cairo_image_surface_create_for_bitmap(&b2)
	sr:save_png'bitmaplib_test.png'
	sr:free()
	b2:free()
	b1:free()
end
test_blend()
