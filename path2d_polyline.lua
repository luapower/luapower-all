
local line = require'path2d_line'

local function map_proc(filter, read, write)
	local function pass(...)
		if not ... then return end
		write(filter(...))
		return true
	end
	while pass(read()) do end
end

local function map(filter, read)
	return coroutine.wrap(function() map_proc(filter, read, coroutine.yield) end)
end

local function random_points_proc(n, writepoint)
	for i=1,n do
		writepoint(math.random(), math.random())
	end
end

local function random_points(n)
	return coroutine.wrap(function() random_points_proc(n, coroutine.yield) end)
end

local function scale_proc(s, x, y)
	return s * x, s * y
end

local function scale(s)
	return function(x, y) return scale_proc(s, x, y) end
end

local function segments_proc(readpoint, writesegment)
	local x1, y1 = readpoint()
	for x2, y2 in readpoint do
		writesegment(x1, y1, x2, y2)
		x1, y1 = x2, y2
	end
end

local function segments(readpoint)
	return coroutine.wrap(function() segments_proc(readpoint, coroutine.yield) end)
end

local function segment_pair_proc(readsegment, writepair)
	local ax1, ay1, ax2, ay2 = readsegment()
	for bx1, by1, bx2, by2 in readsegment do
		writepair(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
		ax1, ay1, ax2, ay2 = bx1, by1, bx2, by2
	end
end

local function segment_pairs(readsegment)
	return coroutine.wrap(function() segment_pair_proc(readsegment, coroutine.yield) end)
end

local function polygon_offset_proc(d, readpair, writepoint)
	local first = true
	local lastox, lastoy, lastx, lasty
	for ax1, ay1, ax2, ay2, bx1, by1, bx2, by2 in readpair do
		local oax1, oay1, oax2, oay2 = line.offset(d, ax1, ay1, ax2, ay2)
		local obx1, oby1, obx2, oby2 = line.offset(d, bx1, by1, bx2, by2)
		local t1, t2 = line.line_line_intersection(oax1, oay1, oax2, oay2, obx1, oby1, obx2, oby2)
		if first then
			writepoint(oax1, oay1, ax1, ay1)
			first = false
		end
		local ox, oy = line.point(t1, oax1, oay1, oax2, oay2)
		writepoint(ox, oy, bx1, by1)
		lastox, lastoy, lastx, lasty = obx2, oby2, bx2, by2
	end
	if lastox then
		writepoint(lastox, lastoy, lastx, lasty)
	end
end

local function polygon_offset(d, readpair)
	return coroutine.wrap(function() polygon_offset_proc(d, readpair, coroutine.yield) end)
end

if ... then return end

local player = require'cplayer'

local points = {}

math.randomseed(1)
for x, y in map(scale(500), random_points(4)) do
	table.insert(points, {x, y})
end

local function points_iter(t)
	return coroutine.wrap(function()
		for i,p in ipairs(t) do
			coroutine.yield(unpack(p))
		end
	end)
end

local curve = {{100,100}, {100,300}, {900,200}, {500,100}}

local d = 60

function player:on_render(cr)

	d = self:slider{id = 'd', x = 10, y = 10, w = 200, h = 26, i0 = 5, i1 = 200, i = d}

	--[[
	for i,p in ipairs(points) do
		p[1], p[2] = self:dragpoint{id = 'p'..i, x = p[1], y = p[2]}
	end
	]]

	for i,p in ipairs(curve) do
		p[1], p[2] = self:dragpoint{id = 'cp'..i, x = p[1], y = p[2]}
	end
	local bezier3 = require'path2d_bezier3'
	local points = {}
	table.insert(points, {curve[1][1], curve[1][2]})
	local function write(cmd, x, y)
		table.insert(points, {x, y})
	end
	bezier3.interpolate(write,
		curve[1][1], curve[1][2],
		curve[2][1], curve[2][2],
		curve[3][1], curve[3][2],
		curve[4][1], curve[4][2], 1, 10, 10)

	for x1, y1, x2, y2 in segments(points_iter(points)) do
		self:line(x1, y1, x2, y2, '#ffffff40', 1)
		--self:line(line.offset(d, x1, y1, x2, y2))
	end
	for ox, oy, x, y in polygon_offset(d, segment_pairs(segments(points_iter(points)))) do
		self:line(ox, oy, x, y)
	end
	for ox, oy, x, y in polygon_offset(-d, segment_pairs(segments(points_iter(points)))) do
		self:line(ox, oy, x, y)
	end

	for x1, y1, x2, y2 in segments(polygon_offset(d, segment_pairs(segments(points_iter(points))))) do
		self:dot(x1, y1, 2)
		self:dot(x2, y2, 2)
		self:line(x1, y1, x2, y2, '#ffffff40', 2)
	end
	for x1, y1, x2, y2 in segments(polygon_offset(-d, segment_pairs(segments(points_iter(points))))) do
		self:dot(x1, y1, 2)
		self:dot(x2, y2, 2)
		self:line(x1, y1, x2, y2, '#ffffff40', 2)
	end

end

player:play()
