require'terra'
local low = require'boxblurlib'
low.Blur:build()
print'built'

local time = require'time'
local fs = require'fs'
local jpeg = require'libjpeg'
local bitmap = require'bitmap'

local bb = require'boxblurlib_h'
local nw = require'nw'

local passes = 2
local max_radius = 50
local repeats = max_radius

local f = assert(fs.open'media/jpeg/birds.jpg')
local j = assert(jpeg.open(f:buffered_read()))
local img = assert(j:load{accept = {g8 = true}})
j:free()
f:close()
local function paint(_, b)
	local bmp = {data = b.pixels, stride = b.stride, w = b.w, h = b.h, size = b.stride * b.h, format = 'g8'}
	bitmap.paint(bmp, img, 0, 0)
end
local blur = bb.blur(bb.BITMAP_G8, paint, nil)

for passes = 1, passes do
	local t0 = time.clock()
	for i=1,repeats do
		blur:blur(img.w, img.h, repeats-i+1, passes)
	end
	local t1 = time.clock()
	local s = (t1 - t0) / repeats
	local b = img.w * img.h
	local B = 1920 * 1080
	local sB = B * s / b
	local fps = 1 / sB
	print(string.format('%d fps @ full-hd %d passes (%.2fms/frame)',
		fps, passes, sB * 1e3))
end

local win = nw:app():window{w = 1800, h = 1000, visible = false}

function win:repaint()
	local radius = math.max(0, math.floor((self:mouse'x' or 0) / 20) - 10)
	local b = blur:blur(img.w, img.h, radius, passes)
	local winbmp = self:bitmap()
	local bmp = {data = b.pixels, stride = b.stride, w = b.w, h = b.h, size = b.stride * b.h, format = 'g8'}
	bitmap.paint(winbmp, bmp, 100, 100)
end

function win:mousemove()
	self:invalidate()
end

win:show()
nw:app():run()

blur:free()
