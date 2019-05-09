
--math for 2D rectangles defined as (x, y, w, h).
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'low')

box2d = {}

--fit a rectangle into another
terra box2d.fit(w: num, h: num, bw: num, bh: num)
	if w / h > bw / bh then
		return bw, bw * h / w
	else
		return bh * w / h, bh
	end
end

--intersect two positive 1D segments
local intersect_segs = macro(function(ax1, ax2, bx1, bx2)
	return quote in max(ax1, bx1), min(ax2, bx2) end
end)

--intersect two rectangles
box2d.intersect = macro(function(x1, y1, w1, h1, x2, y2, w2, h2)
	return quote
		--intersect on each dimension
		var x1, x2 = intersect_segs(x1, x1+w1, x2, x2+w2)
		var y1, y2 = intersect_segs(y1, y1+h1, y2, y2+h2)
		--clamp size
		var w = max(x2-x1, 0)
		var h = max(y2-y1, 0)
		in x1, y1, w, h
	end
end)

--accumulating bounding box
local struct bbox {x: num; y: num; w: num; h: num}
terra box2d.bbox()
	return bbox {inf, inf, -inf, -inf}
end
terra bbox:add(x3: num, y3: num, w2: num, h2: num)
	var x1 = self.x
	var y1 = self.y
	var w1 = self.w
	var h1 = self.h
	var x2 = x1 + w1
	var y2 = y1 + h1
	var x4 = x3 + w2
	var y4 = y3 + h2
	var minx = min(min(min(x1, x2), x3), x4)
	var miny = min(min(min(y1, y2), y3), y4)
	var maxx = max(max(max(x1, x2), x3), x4)
	var maxy = max(max(max(y1, y2), y3), y4)
	self.x = minx
	self.y = miny
	self.w = maxx-minx
	self.h = maxy-miny
end
bbox.metamethods.__apply = macro(function(self)
	return `unpackstruct(self)
end)

--offset a rectangle by d (outward if d is positive)
terra box2d.offset(d: num, x: num, y: num, w: num, h: num)
	return x - d, y - d, w + 2*d, h + 2*d
end
