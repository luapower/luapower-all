local time = require'time'
local fs = require'fs'
local jpeg = require'libjpeg'
local bitmap = require'bitmap'
local boxblur = require'boxblur'
local nw = require'nw'

local passes = 3
local max_radius = 50
local repeats = max_radius

local f = assert(fs.open'media/jpeg/birds.jpg')
local j = assert(jpeg.open(f:buffered_read()))
local img = assert(j:load{accept = {g8 = true}})
j:free()
f:close()
local blur = boxblur.new(img, max_radius, passes, 'g8')

for passes = 1, passes do
	local t0 = time.clock()
	for i=1,repeats do
		blur:blur(repeats-i+1, passes)
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
	local radius = math.floor((self:mouse'x' or 0) / 20) - 10
	blur:blur(radius)
	local winbmp = self:bitmap()
	bitmap.paint(winbmp, blur.src.parent, 0, 0)
	bitmap.paint(winbmp, blur.dst, blur.dst.x, blur.dst.y)
end

function win:mousemove()
	self:invalidate()
end

win:show()
nw:app():run()
