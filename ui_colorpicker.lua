
--ui color picker widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local bitmap = require'bitmap'
local color = require'color'
local cairo = require'cairo'
local lerp = glue.lerp
local clamp = glue.clamp

--hue vertical bar -----------------------------------------------------------

local hue_bar = ui.layer:subclass'hue_bar'
ui.hue_bar = hue_bar

hue_bar.focusable = true

hue_bar.corner_radius = 4
hue_bar.pointer_style = 'bar' --bar, needle

hue_bar._hue = 0

function hue_bar:get_hue()    return self._hue end
function hue_bar:set_hue(hue) self._hue = clamp(hue, 0, 360) end

function hue_bar:sync_bar()
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

function hue_bar:draw_bar(cr)
	self:sync_bar()
	local sr = cairo.image_surface(self._bmp)
	cr:operator'over'
	cr:source(sr)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
	sr:free()
end

hue_bar.needle_pointer_color = '#0008'

ui:style('hue_bar focused', {
	needle_pointer_color = '#000',
})

function hue_bar:draw_pointer_needle(cr, y)
	local w = self.cw
	cr:line_width(1)
	cr:operator'over'
	cr:rgba(self.ui:color(self.needle_pointer_color))

	local sw = w / 3
	local sh = 1.5
	cr:new_path()
	cr:move_to(0, y-sh)
	cr:line_to(0, y+sh)
	cr:line_to(sw, y)
	cr:fill()
	cr:move_to(w, y-sh)
	cr:line_to(w, y+sh)
	cr:line_to(w - sw, y)
	cr:fill()
end

local pbar = ui.layer:subclass'hue_bar_pointer_bar'
hue_bar.pointer_bar_class = pbar

pbar.activable = false

pbar.h = 8
pbar.opacity = .7
pbar.border_offset = 1
pbar.border_width = 2
pbar.border_color = '#fff'
pbar.corner_radius = 3
pbar.outline_width = 1
pbar.outline_color = '#333'

ui:style('hue_bar focused > hue_bar_pointer_bar', {
	opacity = 1,
})

function pbar:before_draw_border(cr)
	cr:line_width(self.outline_width)
	cr:rgba(self.ui:color(self.outline_color))
	self:border_path(cr, -1)
	cr:stroke()
	self:border_path(cr, 1)
	cr:stroke()
end

function hue_bar:draw_pointer_bar(cr, y)
	if not self.pointer_bar or not self.pointer_bar.islayer then
		self.pointer_bar = self.pointer_bar_class(self.ui, {
				parent = self,
			}, self.pointer_bar)
	end
	local pb = self.pointer_bar
	pb.y = glue.round(y - pb.h / 2)
	pb.w = self.w
end

function hue_bar:background_visible()
	return true
end

function hue_bar:paint_background(cr)
	self:draw_bar(cr)
end

function hue_bar:before_draw_content(cr)
	local y = glue.round(self.hue / 360 * self.ch) + .5
	self['draw_pointer_'..self.pointer_style](self, cr, y)
end

function hue_bar:mousedown()
	self.active = true
end

function hue_bar:mouseup()
	self.active = false
end

function hue_bar:mousemove(mx, my)
	if not self.active then return end
	self.hue = lerp(my, 0, self.ch-1, 0, 360)
	self:invalidate()
end

function hue_bar:keypress(key)
	if key == 'down' or key == 'up' or key == 'pagedown' or key == 'pageup' then
		local delta =
			(key:find'down' and 1 or -1)
			* (key:find'page' and 10 or 1)
			* (self.ui:key'shift' and .001 or .01)
			* (self.ui:key'ctrl' and 5 or 1)
			* 360
		self.hue = self.hue + delta
		self:invalidate()
	end
end

--saturation/luminance square ------------------------------------------------

local sl_square = ui.layer:subclass'color_sat_lum_square'
ui.color_sat_lum_square = sl_square

sl_square.focusable = true

sl_square.pointer_style = 'circle' --circle, cross

sl_square._hue = 0
sl_square._sat = 0
sl_square._lum = 0

function sl_square:get_hue()    return self._hue end
function sl_square:set_hue(hue) self._hue = clamp(hue, 0, 360) end
function sl_square:get_sat()    return self._sat end
function sl_square:set_sat(sat) self._sat = clamp(sat, 0, 1) end
function sl_square:get_lum()    return self._lum end
function sl_square:set_lum(lum) self._lum = clamp(lum, 0, 1) end

function sl_square:sat_lum_at(x, y)
	return
		clamp(lerp(x, 0, self.cw-1, 0, 1), 0, 1),
		clamp(lerp(y, 0, self.ch-1, 1, 0), 0, 1)
end

function sl_square:sat_lum_coords(sat, lum)
	return
		sat * self.cw,
		(1 - lum) * self.ch
end

function sl_square:hsl()
	return self.hue, self.sat, self.lum
end

function sl_square:rgb()
	return color.hsl_to_rgb(self:hsl())
end

function sl_square:rgba(a)
	local r, g, b = color.hsl_to_rgb(self:hsl())
	return r, g, b, a or 1
end

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
				local lum = lerp(y, 0, h-1, 1, 0)
				local r, g, b = hsl_to_rgb(self.hue, sat, lum)
				setpixel(x, y, r * 255, g * 255, b * 255, 255)
			end
		end
	end
end

function sl_square:draw_square(cr)
	local sr = cairo.image_surface(self._bmp)
	cr:operator'over'
	cr:source(sr)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
	sr:free()
end

sl_square.pointer_cross_opacity = .5

ui:style('color_sat_lum_square focused', {
	pointer_cross_opacity = 1,
})

function sl_square:draw_pointer_cross(cr, cx, cy)
	local hue = self.hue + 180
	local lum = self.lum > 0.5 and 0 or 1
	local sat = 1 - self.sat
	local r, g, b = color.hsl_to_rgb(hue, sat, lum)
	cr:rgba(r, g, b, self.pointer_cross_opacity)
	cr:operator'over'
	cr:line_width(1)

	cr:save()
	cr:translate(cx, cy)
	cr:new_path()
	for i=1,4 do
		cr:move_to(0, 6)
		cr:rel_line_to(-1, 4)
		cr:rel_line_to(2, 0)
		cr:close_path()
		cr:rotate(math.rad(90))
	end
	cr:restore()
	cr:fill_preserve()
	cr:stroke()
end

sl_square.circle_pointer_color = '#fff8'
sl_square.circle_pointer_outline_color = '#3338'
sl_square.circle_pointer_outline_width = 1
sl_square.circle_pointer_radius = 9
sl_square.circle_pointer_inner_radius = 6

ui:style('color_sat_lum_square focused', {
	circle_pointer_color = '#fff',
	circle_pointer_outline_color = '#333',
})

function sl_square:draw_pointer_circle(cr, cx, cy)
	cr:rgba(self.ui:color(self.circle_pointer_color))
	cr:operator'over'
	cr:line_width(self.circle_pointer_outline_width)
	cr:fill_rule'even_odd'
	cr:new_path()
	cr:circle(cx, cy, self.circle_pointer_radius)
	cr:circle(cx, cy, self.circle_pointer_inner_radius)
	cr:fill_preserve()
	cr:rgba(self.ui:color(self.circle_pointer_outline_color))
	cr:stroke()
end

function sl_square:before_draw_content(cr)
	self:sync()
	self:draw_square(cr)
	local cx, cy = self:sat_lum_coords(self.sat, self.lum)
	self['draw_pointer_'..self.pointer_style](self, cr, cx, cy)
end

function sl_square:mousedown()
	self.active = true
end

function sl_square:mouseup()
	self.active = false
end

function sl_square:mousemove(mx, my)
	if not self.active then return end
	self.sat, self.lum = self:sat_lum_at(mx, my)
	self:invalidate()
end

function sl_square:keypress(key)
	if key == 'down' or key == 'up' or key == 'pagedown' or key == 'pageup' then
		local delta =
			(key:find'down' and -1 or 1)
			* (key:find'page' and 10 or 1)
			* (self.ui:key'shift' and .001 or .01)
			* (self.ui:key'ctrl' and 5 or 1)
		self.lum = self.lum + delta
		self:invalidate()
	elseif key == 'left' or key == 'right' then
		local delta =
			(key:find'left' and -1 or 1)
			* (self.ui:key'shift' and .001 or .01)
			* (self.ui:key'ctrl' and 5 or 1)
		self.sat = self.sat + delta
		self:invalidate()
	end
end

--color picker ---------------------------------------------------------------

local picker = ui.layer:subclass'colorpicker'
ui.colorpicker = picker
picker.hue_bar_class = hue_bar
picker.sat_lum_square_class = sl_square

function picker:create_hue_bar()
	return self.hue_bar_class(self.ui, {
		picker = self,
		parent = self,
	}, self.hue_bar)
end

function picker:create_sat_lum_square()
	return self.sat_lum_square_class(self.ui, {
		parent = self,
		picker = self,
	}, self.sat_lum_square)
end

function picker:create_rgb_editbox()
	self.rgb_edit = self.ui:editbox{
		multiline = false,
		picker = self,
		parent = self,
	}
end

function picker:after_init()
	self.hue_bar = self:create_hue_bar()
	self.sat_lum_square = self:create_sat_lum_square()
	self.rgb_editbox = self:create_rgb_editbox()
end

function picker:sync()

	local hb = self.hue_bar
	local sl = self.sat_lum_square
	local re = self.rgb_edit

	local h = 1
	local w = self.cw - h - 10
	hb.x = w + 10 + 8
	hb.w = h
	hb.h = self.ch

	local x2 = self.cw - self.hue_bar.w
	local w = math.min(self.ch, x2)
	local dw = math.max(1, x2 - self.ch)
	hb.w = hb.w + dw
	hb.x = hb.x - dw
	sl.w = w
	sl.h = w

	sl.hue = self.hue_bar.hue

	re.x = self.cw + 10 + 8
	re.y = 0
	re.w = 200
	re.h = self.ch

	local r, g, b = sl:rgb()
	re.text = string.format(
		'RGB: %d, %d, %d',
		r * 255, g * 255, b * 255)
end

function picker:before_draw_content()
	self:sync()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local cp = ui:colorpicker{
		x = 20, y = 20,
		w = 220, h = 200,
		parent = win,
		hue = 270,
	}

end) end

