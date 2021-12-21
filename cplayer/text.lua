--cplayer text api
local player = require'cplayer'
local ffi = require'ffi'
local lines = require'glue'.lines

local function half(x)
	return math.floor(x / 2 + 0.5)
end

local function text_args(self, s, font, color, line_spacing)
	s = tostring(s)
	font = self:setfont(font)
	self:setcolor(color or 'normal_fg')
	local line_h = font.extents.height * (line_spacing or 1)
	return s, font, line_h
end

local function draw_text(cr, x, y, s, align, line_h) --multi-line text
	if ffi.os == 'OSX' then --TOOD: remove this hack
		y = y + 1
	end
	for s in lines(s) do
		if align == 'right' then
			local extents = cr:text_extents(s)
			cr:move_to(x - extents.width, y)
		elseif align == 'center' then
			local extents = cr:text_extents(s)
			cr:move_to(x - half(extents.width), y)
		else
			cr:move_to(x, y)
		end
		cr:show_text(s)
		y = y + line_h
	end
end

function player:text(x, y, s, font, color, align, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)
	draw_text(self.cr, x, y, s, align, line_h)
end

function player:textbox(x, y, w, h, s, font, color, halign, valign, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)

	self.cr:save()
	self.cr:rectangle(x, y, w, h)
	self.cr:clip()

	if halign == 'right' then
		x = x + w
	elseif halign == 'center' then
		x = x + half(w)
	end

	if valign == 'top' then
		y = y + font.extents.ascent
	else
		local lines_h = 0
		for _ in lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = y + h - font.extents.descent
		elseif valign == 'center' then
			y = y + half(h + font.extents.ascent - font.extents.descent + lines_h)
		end
		y = y - lines_h
	end

	draw_text(self.cr, x, y, s, halign, line_h)

	self.cr:restore()
end


if not ... then

local x1, y1, x2, y2 = 10, 100, 260, 260
local halign = 'center'
local valign = 'center'
local font_size = 12

function player:on_render(cr)

	--text api
	halign = self:mbutton{id = 'halign', x = 10, y = 10, w = 250, h = 26, values = {'left', 'right', 'center'}, selected = halign}
	valign = self:mbutton{id = 'valign', x = 10, y = 40, w = 250, h = 26, values = {'top', 'bottom', 'center'}, selected = valign}
	font_size = self:slider{id = 'font_size', x = 10, y = 70, w = 250, h = 26, i0 = 1, i1 = 100, i = font_size}
	x1, y1 = self:dragpoint{id = 'p1', x = x1, y = y1}
	x2, y2 = self:dragpoint{id = 'p2', x = x2, y = y2}
	--
	self:rect(x1, y1, x2-x1, y2-y1)
	self:textbox(x1, y1, x2-x1, y2-y1, 'tttsssggg\nttt\nggg\nsss', 'Tahoma,'..font_size, nil, halign, valign)

	self:rect(x1 + x2 + 10, y1, x2-x1, y2-y1)
	self:textbox(x1 + x2 + 10, y1, x2-x1, y2-y1, 'ggg\nsss\nttt\ntttsssggg', 'Tahoma,'..font_size, nil, halign, valign)

end

return player:play()

end
