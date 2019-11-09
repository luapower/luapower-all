
--math for 2D rectangles defined as (x, y, w, h) where w >= 0 and h >= 0.
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'terra.low'.module())

local rect_type = memoize(function(num)

	local struct rect (gettersandsetters) {
		x: num;
		y: num;
		w: num;
		h: num;
	}

	rect.metamethods.__apply = macro(function(self)
		return `unpackstruct(self)
	end)

	terra rect:set(x: num, y: num, w: num, h: num)
		self.x, self.y, self.w, self.h = x, y, w, h
	end

	terra rect:get_x1() return self.x end
	terra rect:get_y1() return self.y end
	terra rect:get_x2() return self.x + self.w end
	terra rect:get_y2() return self.y + self.h end
	terra rect:get_cx() return self.x + self.w / 2 end
	terra rect:get_cy() return self.y + self.h / 2 end

	terra rect:set_x1(v: num) self.x = v end
	terra rect:set_y1(v: num) self.y = v end
	terra rect:set_x2(v: num) self.x = v - self.w end
	terra rect:set_y2(v: num) self.y = v - self.h end
	terra rect:set_cx(v: num) self.x = v - self.w / 2 end
	terra rect:set_cy(v: num) self.y = v - self.h / 2 end

	--fit a rectangle into another, only considering and returning the size.
	terra rect.methods.fit(w: num, h: num, bw: num, bh: num)
		if w / h > bw / bh then
			return bw, bw * h / w
		else
			return bh * w / h, bh
		end
	end

	--intersect two positive 1D segments
	local intersect_segs = macro(function(ax1, ax2, bx1, bx2)
		return `{max(ax1, bx1), min(ax2, bx2)}
	end)

	rect.methods.intersect = overload'intersect'
	rect.methods.intersect:adddefinition(terra(
		x1: num, y1: num, w1: num, h1: num,
		x2: num, y2: num, w2: num, h2: num
	)
		--intersect on each dimension
		var x1, x2 = intersect_segs(x1, x1+w1, x2, x2+w2)
		var y1, y2 = intersect_segs(y1, y1+h1, y2, y2+h2)
		--clamp size
		var w = max(x2-x1, 0)
		var h = max(y2-y1, 0)
		return x1, y1, w, h
	end)
	rect.methods.intersect:adddefinition(terra(self: &rect, r2: rect)
		@self = rect(rect.intersect(self(), r2()))
	end)

	rect.methods.bbox = overload'bbox'
	rect.methods.bbox:adddefinition(terra(
		x1: num, y1: num, w1: num, h1: num,
		x3: num, y3: num, w2: num, h2: num
	)
		if w1 == 0 or h1 == 0 then
			return x3, y3, w2, h2
		elseif w2 == 0 or h2 == 0 then
			return x1, y1, w1, h1
		else
			var x2 = x1 + w1
			var y2 = y1 + h1
			var x4 = x3 + w2
			var y4 = y3 + h2
			var minx = min(min(min(x1, x2), x3), x4)
			var miny = min(min(min(y1, y2), y3), y4)
			var maxx = max(max(max(x1, x2), x3), x4)
			var maxy = max(max(max(y1, y2), y3), y4)
			return minx, miny, maxx-minx, maxy-miny
		end
	end)
	rect.methods.bbox:adddefinition(terra(self: &rect, r2: rect)
		@self = rect(rect.bbox(self(), r2()))
	end)

	--offset a rectangle by d (outward if d is positive)
	rect.methods.offset = overload'offset'
	rect.methods.offset:adddefinition(terra(d: num, x: num, y: num, w: num, h: num)
		return
			x - d,
			y - d,
			w + 2*d,
			h + 2*d
	end)
	rect.methods.offset:adddefinition(terra(self: &rect, d: num)
		@self = rect(rect.offset(d, self()))
	end)

	setinlined(rect.methods)

	return rect
end)

rect = function(num_type)
	return rect_type(num_type or num)
end

return _M
