
setfenv(1, require'terra/low'.module())
require'terra/memcheck'
require'terra/tr_paint_cairo'
setfenv(1, require'terra/tr_api')
local strlen = includecstring'unsigned long long strlen (const char *str);'.strlen
local sprintf = includecstring'int sprintf(char* str, const char* format, ...);'.sprintf

local font_paths_list = {
	'../media/fonts/OpenSans-Regular.ttf',
	'../media/fonts/Amiri-Regular.ttf',
	'../media/fonts/Amiri-Bold.ttf',
	'../media/fonts/FSEX300.ttf',
}
local font_paths = constant(`array([font_paths_list]))

terra load_font(font_id: int, file_data: &&opaque, file_size: &size_t)
	var font_path = font_paths[font_id]
	@file_data, @file_size = readfile(font_path)
end

terra unload_font(font_id: int, file_data: &&opaque, file_size: &size_t)
	dealloc(@file_data)
end

local numbers = {}
for i=1, 100000 do
	add(numbers, tostring(i..' '))
end
local numbers = concat(numbers)

local texts_list = {
	--assert(glue.readfile'tr_test/sample_arabic.txt'),
	'Hello World\nNew Line',
	--numbers,
	assert(readfile'tr_test/lorem_ipsum.txt'),
	assert(readfile'tr_test/sample_wikipedia1.txt'),
	assert(readfile'tr_test/sample_names.txt'),
}
local texts = constant(`array([texts_list]))

local font_paths_count = #font_paths_list
local texts_count = #texts_list
local paint_times = 1

terra test()
	var sr = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1920, 1080)
	var cr = sr:context()
	var r = tr_renderer_new(load_font, unload_font)

	r.glyph_cache_max_size = 1024*1024
	r.glyph_run_cache_max_size = 1024*1024

	var layouts: arr(&Layout)
	layouts:init()

	for font_i = 0, font_paths_count do --go through all fonts

		var font_id = r:font()

		for text_i = 0, texts_count do --go through all sample texts

			var layout = r:layout()
			layouts:add(layout)

			var text = texts[text_i]
			layout:set_text_utf8(text, -1)

			layout:set_font_id   (0, -1, font_id)
			layout:set_font_size (0, -1, 16)
			layout:set_color     (0, -1, 0xffffffff)

			cr:rgb(0, 0, 0)
			cr:paint()

			var t0: double
			var wanted_fps = 60
			var glyphs_per_frame = -1

			var offset_count = [int](1/r.subpixel_x_resolution)

			--probe'start'

			for offset_i = 0, offset_count do --go through all subpixel offsets

				var w = sr:width()
				var h = sr:height()
				var offset_x = offset_i * (1.0 / offset_count)

				layout.align_w = w
				layout.align_h = h
				layout.align_x = ALIGN_LEFT
				layout.align_y = ALIGN_TOP
				layout.clip_x  = 0
				layout.clip_y  = 0
				layout.clip_w  = w
				layout.clip_h  = h
				layout.x = offset_x
				layout.y = 0

				layout:layout()

				--probe'layout'

				r.paint_glyph_num = 0
				t0 = clock()
				for frame_i = 0, paint_times do
					--cr:rgb(0, 0, 0)
					--cr:paint()
					layout:paint(cr)
					if glyphs_per_frame == -1 then
						glyphs_per_frame = r.paint_glyph_num
					end
				end

			end

			var dt = clock() - t0
			pfn('%.2fs\tpaint %d times %7d glyphs %7.2f%% of a frame @60fps',
				dt, paint_times, r.paint_glyph_num,
				100 * glyphs_per_frame * wanted_fps * dt / r.paint_glyph_num)

			var s: char[200]
			sprintf(s, 'out%d.png', layouts.len)
			--sr:save_png(s)

		end

		--layouts.len = 0

	end

	print('layouts: ', layouts.len)
	for i,layout in layouts do
		(@layout):release()
	end
	layouts:free()

	pfn('Glyph cache size     : %7.2fmB', r.glyphs.size / 1024.0 / 1024.0)
	pfn('Glyph cache count    : %7d', r.glyphs.count)
	pfn('GlyphRun cache size  : %7.2fmB', r.glyph_runs.size / 1024.0 / 1024.0)
	pfn('GlyphRun cache count : %7d', r.glyph_runs.count)

	r:release()
	cr:free()
	sr:free()

	memreport()
end
test()
