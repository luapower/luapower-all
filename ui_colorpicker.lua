
--ui color picker widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local bitmap = require'bitmap'
local color = require'color'
local cairo = require'cairo'
local lerp = glue.lerp
local clamp = glue.clamp
require'ui_slider'

--hue vertical bar -----------------------------------------------------------

local hue_bar = ui.layer:subclass'hue_bar'
ui.hue_bar = hue_bar

hue_bar.focusable = true

hue_bar.pointer_style = 'bar' --bar, needle

hue_bar.hue = 0

hue_bar:track_changes'hue'

function hue_bar:override_set_hue(inherited, hue)
	if inherited(self, clamp(hue, 0, 360)) then
		self:invalidate()
	end
end

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

--saturation/luminance rectangle ---------------------------------------------

local slrect = ui.layer:subclass'sat_lum_rectangle'
ui.sat_lum_rectangle = slrect

slrect.focusable = true

slrect.pointer_style = 'circle' --circle, cross

slrect.hue = 0
slrect.sat = 0
slrect.lum = 0

slrect:track_changes'hue'
slrect:track_changes'sat'
slrect:track_changes'lum'

function slrect:override_set_hue(inherited, hue)
	if inherited(self, clamp(hue, 0, 360)) then
		self:invalidate()
	end
end

function slrect:override_set_sat(inherited, sat)
	if inherited(self, clamp(sat, 0, 1)) then
		self:invalidate()
	end
end

function slrect:override_set_lum(inherited, lum)
	if inherited(self, clamp(lum, 0, 1)) then
		self:invalidate()
	end
end

function slrect:sat_lum_at(x, y)
	return
		clamp(lerp(x, 0, self.cw-1, 0, 1), 0, 1),
		clamp(lerp(y, 0, self.ch-1, 1, 0), 0, 1)
end

function slrect:sat_lum_coords(sat, lum)
	return
		sat * self.cw,
		(1 - lum) * self.ch
end

function slrect:hsl()
	return self.hue, self.sat, self.lum
end

function slrect:rgb()
	return color.hsl_to_rgb(self:hsl())
end

function slrect:rgba(a)
	local r, g, b = color.hsl_to_rgb(self:hsl())
	return r, g, b, a or 1
end

function slrect:sync()
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

function slrect:draw_rectangle(cr)
	local sr = cairo.image_surface(self._bmp)
	cr:operator'over'
	cr:source(sr)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
	sr:free()
end

slrect.pointer_cross_opacity = .5

ui:style('sat_lum_rectangle focused', {
	pointer_cross_opacity = 1,
})

function slrect:draw_pointer_cross(cr, cx, cy)
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

slrect.circle_pointer_color = '#fff8'
slrect.circle_pointer_outline_color = '#3338'
slrect.circle_pointer_outline_width = 1
slrect.circle_pointer_radius = 9
slrect.circle_pointer_inner_radius = 6

ui:style('sat_lum_rectangle focused', {
	circle_pointer_color = '#fff',
	circle_pointer_outline_color = '#333',
})

function slrect:draw_pointer_circle(cr, cx, cy)
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

function slrect:before_draw_content(cr)
	self:sync()
	self:draw_rectangle(cr)
	local cx, cy = self:sat_lum_coords(self.sat, self.lum)
	self['draw_pointer_'..self.pointer_style](self, cr, cx, cy)
end

function slrect:mousedown()
	self.active = true
end

function slrect:mouseup()
	self.active = false
end

function slrect:mousemove(mx, my)
	if not self.active then return end
	self.sat, self.lum = self:sat_lum_at(mx, my)
	self:invalidate()
end

function slrect:keypress(key)
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
picker.sat_lum_rectangle_class = slrect

function picker:create_hue_bar()
	return self.hue_bar_class(self.ui, {
		picker = self,
		parent = self,
		hue_changed = function(_, hue)
			self.hue_slider.position = hue
		end,
	}, self.hue_bar)
end

function picker:create_sat_lum_rectangle()
	return self.sat_lum_rectangle_class(self.ui, {
		parent = self,
		picker = self,
		sat_changed = function(_, sat)
			self.sat_slider.position = sat
		end,
		lum_changed = function(_, lum)
			self.lum_slider.position = lum
		end,
	}, self.sat_lum_rectangle)
end

function picker:create_rgb_editbox()
	return self.ui:editbox{
		multiline = false,
		picker = self,
		parent = self,
	}
end

function picker:after_init()
	self.hue_bar = self:create_hue_bar()
	self.sat_lum_rectangle = self:create_sat_lum_rectangle()
	self.rgb_editbox = self:create_rgb_editbox()
	self.hex_editbox = self:create_rgb_editbox()
	self.rgb_label = self.ui:layer{text = 'RGB:', parent = self, text_align = 'left'}
	self.hex_label = self.ui:layer{text = 'HEX:', parent = self, text_align = 'left'}
	self.hue_label = self.ui:layer{text = 'Hue:', parent = self, text_align = 'left'}
	self.sat_label = self.ui:layer{text = 'Sat:', parent = self, text_align = 'left'}
	self.lum_label = self.ui:layer{text = 'Lum:', parent = self, text_align = 'left'}
	self.hue_slider = self.ui:slider{
		parent = self,
		size = 360,
		step = 1,
		position = self.hue_bar.hue,
		position_changed = function(slider, pos)
			self.hue_bar.hue = pos
		end,
	}
	self.sat_slider = self.ui:slider{
		parent = self,
		size = 1,
		step = 0.001,
		position = self.sat_lum_rectangle.sat,
		position_changed = function(slider, pos)
			self.sat_lum_rectangle.sat = pos
		end,
	}
	self.lum_slider = self.ui:slider{
		parent = self,
		size = 1,
		step = 0.001,
		position = self.sat_lum_rectangle.lum,
		position_changed = function(slider, pos)
			self.sat_lum_rectangle.lum = pos
		end,
	}
end

function picker:sync()

	local hb = self.hue_bar
	local sr = self.sat_lum_rectangle
	local re = self.rgb_editbox
	local xe = self.hex_editbox
	local rl = self.rgb_label
	local xl = self.hex_label
	local hl = self.hue_label
	local hs = self.hue_slider
	local sl = self.sat_label
	local ss = self.sat_slider
	local ll = self.lum_label
	local ls = self.lum_slider

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
	sr.w = w
	sr.h = w

	sr.hue = self.hue_bar.hue

	local sx, sy = 14, 4
	local x1 = self.cw + sx + sx
	local w1 = 30
	local h = 30
	local x2 = x1 + sx + w1
	local w2 = 100
	local y = 0

	rl.x = x1
	rl.y = y
	rl.w = w1
	rl.h = h
	re.x = x2
	re.y = y
	re.w = w2

	local r, g, b = sr:rgb()
	re.text = string.format(
		'%d, %d, %d',
		r * 255, g * 255, b * 255)

	y = y + h + sy

	xl.x = x1
	xl.y = y
	xl.w = w1
	xl.h = h
	xe.x = x2
	xe.y = y
	xe.w = w2

	xe.text = color.rgb_to_string(r, g, b, 'hex')

	y = y + h + sy + 20

	hl.x = x1
	hl.y = y
	hl.w = w1
	hl.h = h
	hs.x = x2
	hs.y = y
	hs.w = w2
	hs.h = h

	y = y + h + sy

	sl.x = x1
	sl.y = y
	sl.w = w1
	sl.h = h
	ss.x = x2
	ss.y = y
	ss.w = w2
	ss.h = h

	y = y + h + sy

	ll.x = x1
	ll.y = y
	ll.w = w1
	ll.h = h
	ls.x = x2
	ls.y = y
	ls.w = w2
	ls.h = h
end

function picker:before_draw_content()
	self:sync()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.layer.background_color = '#222'

	local cp = ui:colorpicker{
		x = 20, y = 20,
		w = 220, h = 200,
		parent = win,
		hue_bar = {hue = 60},
		sat_lum_rectangle = {sat = .7, lum = .3},
	}

end) end

