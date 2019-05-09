setfenv(1, require'low')
require'bitmaplib'
require'cairolib'

terra test_blend()
	var sr1 = cairo_image_surface_create_from_png'trlib_test.png'
	var b1 = sr1:copy() --TODO: this comes as RGB24
	var b2 = bitmap.new(1000, 1000, BITMAP_ARGB32, -1)
	b1:blend(&b2, 0, 0, BITMAP_COPY)
	var sr = cairo_image_surface_create_for_bitmap(&b2)
	sr:save_png'bitmaplib_test.png'
	sr:free()
	b2:free()
	b1:free()
end
test_blend()
