local catmull = require'path_catmullrom'
local bezier3 = require'path_bezier3'
local player = require'cplayer'

local function eq(a, b) return math.abs(a - b) < 1e-12 end

--generate random catmull-friendly points
math.randomseed(os.time())
local t = {}
local x, y = 50,200
for i=1,24 do
	table.insert(t, {x, y})
	x = x + math.random(10, 100)
	y = y + math.random(-100, 100)
end
table.insert(t, {200, 100})

--close the curve
t[#t-1] = t[2]
t[#t] = t[3]
t[1] = t[#t-2]

local k = 1

function player:on_render(cr)
	k = self:slider{id = 'k', x = 10, y = 10, w = 100, h = 26, i0 = -2, i1 = 2, step = 0.01, i = k}

	for i=1,#t do
		t[i][1], t[i][2] = self:dragpoint{id = 'p'..i, x = t[i][1], y = t[i][2]}
	end

	for i=1,#t-3 do
		local x1, y1, x2, y2, x3, y3, x4, y4 =
			t[i][1], t[i][2], t[i+1][1], t[i+1][2], t[i+2][1], t[i+2][2], t[i+3][1], t[i+3][2]

		--conversion to bezier and back: test precision
		local ak, ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4 =
			bezier3.to_catmullrom(catmull.to_bezier3(1, x1, y1, x2, y2, x3, y3, x4, y4))
		assert(eq(ax1, x1))
		assert(eq(ay1, y1))
		assert(eq(ax2, x2))
		assert(eq(ay2, y2))
		assert(eq(ax3, x3))
		assert(eq(ay3, y3))
		assert(eq(ax4, x4))
		assert(eq(ay4, y4))

		--linear interpolation
		for t=0,1,0.1 do
			local x, y = catmull.point(t, k, x1, y1, x2, y2, x3, y3, x4, y4)
			self:dot(x, y, 2)
		end

		--bezier conversion
		x1, y1, x2, y2, x3, y3, x4, y4 = catmull.to_bezier3(k, x1, y1, x2, y2, x3, y3, x4, y4)
		self:dot(x1, y1, 2)
		self:dot(x2, y2, 2)
		self:dot(x3, y3, 2)
		self:dot(x4, y4, 2)
		self:curve(x1, y1, x2, y2, x3, y3, x4, y4)
	end
end

player:play()
