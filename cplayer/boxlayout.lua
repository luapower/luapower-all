local player = require'cplayer'

--box layouts

local box = {}
local box_meta = {__index = box}

function box:new(x, y, w, h)
	return setmetatable({x = x, y = y, w = w, h = h}, box_meta)
end

function box:unpack()
	return self.x, self.y, self.w, self.h
end

function box:sub(x, y, w, h)
	if w < 0 then x, w = x + w, -w end
	if h < 0 then y, h = y + h, -h end
	return self:new(self.x + x or 0, self.y + y or 0, w or self.w, h or self.h)
end

function box:copy()
	return self:new(self:unpack())
end

function box:vsplit(h1, h2)
	if not h1 and not h2 then
		h1 = self.h / 2
	end
	h1 = h1 or self.h - h2
	h2 = h2 or self.h - h1
	return
		self:sub(nil, nil, nil, h1),
		self:sub(nil, h1, nil, h2)
end

function box:hsplit(w1, w2)
	if not w1 and not w2 then
		w1 = self.w / 2
	end
	w1 = w1 or self.w - w2
	w2 = w2 or self.w - w1
	return
		self:sub(nil, nil, w1, nil),
		self:sub(nil, w1, w2, nil)
end

function box:offset(x1, y1, x2, y2)
	return self:new(self.x1 + x1 or 0, self.y1 + y1 or 0, self.w + x2 or 0, self.h + y2 or 0)
end

function box:pad(o)
	return self:offset(-o, -o, o, o)
end

local function align(align, x1, w1, x, w)
	return
		align == 'center' and (2 * x + w - w1) / 2 or
		align == 'left'   and x or
		align == 'right'  and x + w - w1 or
		error'invalid align'
end

local function align_box(halign, valign, x1, y1, w1, h1, x, y, w, h)
	return
		align(halign, x1, w1, x, w),
		align(valign, y1, h1, y, h)
end

function box:align(w, h, halign, valign)
	halign = halign or 'center'
	valign = valign or 'middle'
	return
		halign == 'center' and (self.w - w) / 2 or
			halign == 'left' and 0 or
			halign == 'right' and self.w - w,
		valign == 'middle' and (self.h - h) / 2 or
			valign == 'top' and 0 or
			valign == 'bottom' and self.h - h,
		w, h
end

function player:subbox(t)
	--
end

function player:anchor(x, y, w, h)
	self.x = self.x + (self.advance == 'right' and w or self.advance == 'left' and -w or 0)
	self.y = self.y + (self.advance == 'down' and h or self.advance == 'down' and -h or 0)
	return x, y, w, h
end

--containers

function player:move(x, y)
	self.cpx = x or self.cpx
	self.cpy = y or self.cpy
end

