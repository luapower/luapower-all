--go @ luajit -jp=zf tr_test.lua

io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
require'strict'

local tr = require'tr'
local time = require'time'
local bitmap = require'bitmap'
local cairo = require'cairo'
local glue = require'glue'

local bmp = bitmap.new(1000, 1000, 'bgra8', nil, true)
local sr = cairo.image_surface(bmp)
local cr = sr:context()

local tr = tr()
tr:add_font_file('media/fonts/amiri-regular.ttf', 'amiri')
tr:add_font_file('media/fonts/OpenSans-Regular.ttf ', 'open sans')

print'here'
local t0 = time.clock()
local n = 100
local s = assert(glue.readfile('lorem_ipsum.txt'))
local t = tr:flatten{
	font_name = 'open_sans,16',
	--font_name = 'amiri,13',
	line_spacing = 1,
	{
		s
		--('ABCDEFGH abcdefgh 1234 '):rep(200),
	},
}
print'here'
for i=1,n do
	local segs = tr:shape(t)
	local x = 100
	local y = 450
	local w = 550
	local h = 100
	local lines = segs:layout(x, y, w, h, 'right', 'bottom')
	lines:paint(cr)
end

local s = (time.clock() - t0) / n
print(string.format('%0.2f ms    %d fps', s * 1000, 1 / s))

print(string.format('word  cache size:  %d KB', tr.glyph_runs.total_size / 1024))
print(string.format('word  count:       %d   ', tr.glyph_runs.lru.length))
print(string.format('glyph cache size:  %d KB', tr.rs.glyphs.total_size / 1024))
print(string.format('glyph count:       %d   ', tr.rs.glyphs.lru.length))
