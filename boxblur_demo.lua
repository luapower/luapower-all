local time = require'time'
local jpeg = require'nanojpeg'
local bitmap = require'bitmap'
local boxblur = require'boxblur'
local nw = require'nw'

local passes = 1
local max_radius = 50
local repeats = max_radius

local img = jpeg.load'media/jpeg/birds.jpg'
local blur = boxblur.new(img, max_radius, passes, 'g8')
blur:update()

local t0 = time.clock()
for i=1,repeats do
	blur:blur(repeats-i+1)
end
local t1 = time.clock()
local s = (t1 - t0) / repeats
local b = img.w * img.h
local B = 1920 * 1080
local sB = B * s / b
local fps = 1 / sB
print(string.format('%d fps @ full-hd %d passes (%.2fms/frame)',
	fps, passes, sB * 1e3))

local win = nw:app():window{w = 1800, h = 1000, visible = false}

function win:repaint()
	local radius = math.floor((self:mouse'x' or 1) / 20) - 10
	radius = math.min(math.max(radius, 0), max_radius)
	local blurred = blur:blur(radius)
	local winbmp = self:bitmap()
	bitmap.paint(winbmp, blur.src.parent, 0, 0)
	bitmap.paint(winbmp, blurred, blur.dst.x, blur.dst.y)
end

function win:mousemove()
	self:invalidate()
end

win:show()
nw:app():run()
