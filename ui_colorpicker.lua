
--ui color picker widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local bitmap = require'bitmap'
local color = require'color'
local lerp = glue.lerp
local clamp = glue.clamp

local hue_bar = ui.layer:subclass'hue_bar'
ui.hue_bar = hue_bar

hue_bar.hue = 0

function hue_bar:sync()
	if not self._bmp or self._bmp.h ~= self.ch or self._bmp.w ~= self.cw then
		self._bmp = bitmap.new(self.cw, self.ch, 'bgra8')
		local bmp = self._bmp
		local _, setpixel = bitmap.pixel_interface(bmp)
		for y = 0, bmp.h-1 do
			local hue = lerp(y, 0, bmp.h-1, 0, 360)
			local r, g, b = color.hsl_to_rgb(hue, 1, 0.5)
			for x = 0, bmp.w-1 do
				setpixel(x, y, r * 255, g * 255, b * 255, 255)
			end
		end
	end
end

function hue_bar:before_draw_content(cr)
	self:sync()

	local bmp = self.window.bitmap
	local x, y = self:to_window(0, 0)
	bitmap.paint(bmp, self._bmp, x, y)

	local y = glue.round(self.hue / 360 * self.ch) + .5
	cr:new_path()
	cr:rgba(self.ui:color(self.text_color))
	cr:operator'over'
	cr:line_width(1)
	cr:move_to(-2, y)
	cr:rel_line_to(self.cw + 4, 0)
	cr:stroke()
end

function hue_bar:mousedown()
	self.active = true
end

function hue_bar:mouseup()
	self.active = false
end

function hue_bar:mousemove(mx, my)
	if not self.active then return end
	self.hue = clamp(lerp(my, 0, self.ch-1, 0, 360), 0, 360)
	self:invalidate()
end

local sl_square = ui.layer:subclass'color_sat_lum_square'
ui.color_sat_lum_square = sl_square

sl_square.hue = 0
sl_square.sat = 0
sl_square.lum = 0

function sl_square:sync()
	if not self._bmp or self._bmp.h ~= self.ch or self._bmp.w ~= self.cw then
		self._bmp = bitmap.new(self.cw, self.ch, 'bgra8')
	end
	if self._bmp_hue ~= self.hue then
		self._bmp_hue = self.hue
		local bmp = self._bmp
		local _, setpixel = bitmap.pixel_interface(bmp)
		local w, h = bmp.w, bmp.h
		local hsl_to_rgb = color.hsl_to_rgb_unclamped
		for y = 0, h-1 do
			for x = 0, w-1 do
				local sat = lerp(x, 0, w-1, 0, 1)
				local lum = lerp(y, 0, h-1, 0, 1)
				local r, g, b = hsl_to_rgb(self.hue, sat, lum)
				setpixel(x, y, r * 255, g * 255, b * 255, 255)
			end
		end
	end
end

function sl_square:before_draw_content(cr)
	self:sync()

	local bmp = self.window.bitmap
	local x, y = self:to_window(0, 0)
	bitmap.paint(bmp, self._bmp, x, y)

	local cx = self.sat * self.cw
	local cy = self.lum * self.ch
	cr:rgba(self.ui:color(self.text_color))
	cr:new_path()
	cr:line_width(2)
	cr:operator'xor'
	cr:circle(cx, cy, 8)
	cr:stroke()
end

function sl_square:mousedown()
	self.active = true
end

function sl_square:mouseup()
	self.active = false
end

function sl_square:mousemove(mx, my)
	if not self.active then return end
	self.sat = clamp(lerp(mx, 0, self.cw-1, 0, 1), 0, 1)
	self.lum = clamp(lerp(my, 0, self.ch-1, 0, 1), 0, 1)
	self:invalidate()
end

local picker = ui.layer:subclass'colorpicker'
ui.colorpicker = picker
picker.hue_bar_class = hue_bar
picker.sat_lum_square_class = sl_square

function picker:create_hue_bar()
	local h = 1
	local w = self.cw - h - 10
	return self.hue_bar_class(self.ui, {
		x = w + 10,
		w = h,
		h = self.ch,
		picker = self,
		parent = self,
		padding_left = 15,
	}, self.hue_bar)
end

function picker:create_sat_lum_square()
	local x2 = self.cw - self.hue_bar.w
	local w = math.min(self.ch, x2)
	local dw = math.max(1, x2 - self.ch)
	self.hue_bar.w = self.hue_bar.w + dw
	self.hue_bar.x = self.hue_bar.x - dw
	return self.sat_lum_square_class(self.ui, {
		w = w,
		h = w,
		parent = self,
		picker = self,
	}, self.sat_lum_square)
end

function picker:after_init()
	self.hue_bar = self:create_hue_bar()
	self.sat_lum_square = self:create_sat_lum_square()
end

function picker:before_draw_content()
	self.sat_lum_square.hue = self.hue_bar.hue
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local cp = ui:colorpicker{
		x = 10, y = 10,
		w = 300, h = 260,
		parent = win,
		hue = 270,
	}

end) end

