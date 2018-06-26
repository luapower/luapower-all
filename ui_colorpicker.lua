
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
			local r, g, b = color.convert('rgb', 'hsl', hue, 1, 0.5)
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

hue_bar.mousedown_activate = true

function hue_bar:mousemove(mx, my)
	if not self.active then return end
	self.hue = lerp(my, 0, self.ch-1, 0, 360)
	self:invalidate()
end

function hue_bar:keypress(key)
	if key == 'down' or key == 'up'
		or key == 'pagedown' or key == 'pageup'
		or key == 'home' or key == 'end'
	then
		local delta =
			  (key:find'down' and 1 or -1)
			* (self.ui:key'shift' and .01 or 1)
			* (self.ui:key'ctrl' and .1 or 1)
			* (key:find'page' and 5 or 1)
			* (key == 'home' and 1/0 or 1)
			* (key == 'end' and -1/0 or 1)
			* 360
			* 0.1
		self.hue = self.hue + delta
	end
end

hue_bar.vscrollable = true

function hue_bar:mousewheel(pages)
	self.hue = self.hue +
		-pages / 3
		* (self.ui:key'shift' and .01 or 1)
		* (self.ui:key'ctrl' and .1 or 1)
		* 360
		* 0.1
end

--abstract pick rectangle ----------------------------------------------------

local prect = ui.layer:subclass'pick_rectangle'
ui.pick_rectangle = prect

function prect:get_a() error'stub' end
function prect:set_a(a) error'stub' end
function prect:get_b() error'stub' end
function prect:set_b(b) error'stub' end
function prect:a_range() error'stub' end
function prect:b_range() error'stub' end

function prect:ab(x, y)
	local a1, a2 = self:a_range()
	local b1, b2 = self:b_range()
	local a = clamp(lerp(x, 0, self.cw-1, a1, a2), a1, a2)
	local b = clamp(lerp(y, 0, self.ch-1, b1, b2), b1, b2)
	return a, b
end

function prect:xy(a, b)
	local a1, a2 = self:a_range()
	local b1, b2 = self:b_range()
	local x = lerp(a, a1, a2, 0, self.cw-1)
	local y = lerp(b, b1, b2, 0, self.ch-1)
	return x, y
end

prect.focusable = true

prect.pointer_style = 'circle' --circle, cross

function prect:abrect()
	local a0, b0 = self:ab(0, 0)
	local a1, b1 = self:ab(self.cw, self.ch)
	return a0, b0, a1, b1
end

function prect:a_range()
	local a0, b0, a1, b1 = self:abrect()
	return a0, a1
end

function prect:b_range()
	local a0, b0, a1, b1 = self:abrect()
	return b0, b1
end

prect.pointer_cross_opacity = .5

ui:style('pick_rectangle focused', {
	pointer_cross_opacity = 1,
})

function prect:pointer_cross_rgb(x, y) error'stub' end

function prect:draw_pointer_cross(cr, cx, cy)
	local r, g, b = self:pointer_cross_rgb(cx, cy)
	cr:save()
	cr:rgba(r, g, b, self.pointer_cross_opacity)
	cr:operator'over'
	cr:line_width(1)
	cr:translate(cx, cy)
	cr:new_path()
	for i=1,4 do
		cr:move_to(0, 6)
		cr:rel_line_to(-1, 4)
		cr:rel_line_to(2, 0)
		cr:close_path()
		cr:rotate(math.rad(90))
	end
	cr:fill_preserve()
	cr:stroke()
	cr:restore()
end

prect.circle_pointer_color = '#fff8'
prect.circle_pointer_outline_color = '#3338'
prect.circle_pointer_outline_width = 1
prect.circle_pointer_radius = 9
prect.circle_pointer_inner_radius = 6

ui:style('pick_rectangle focused', {
	circle_pointer_color = '#fff',
	circle_pointer_outline_color = '#333',
})

function prect:draw_pointer_circle(cr, cx, cy)
	cr:save()
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
	cr:restore()
end

function prect:before_draw_content(cr)
	local cx, cy = self:xy(self.a, self.b)
	self['draw_pointer_'..self.pointer_style](self, cr, cx, cy)
end

prect.mousedown_activate = true

function prect:mousemove(mx, my)
	if not self.active then return end
	self.a, self.b = self:ab(mx, my)
end

function prect:keypress(key)
	local delta =
		  (self.ui:key'shift' and .01 or 1)
		* (self.ui:key'ctrl' and 0.1 or 1)
		* (key:find'page' and 5 or 1)
		* (key == 'home' and 1/0 or 1)
		* (key == 'end' and -1/0 or 1)
		* 0.1
	if key == 'down' or key == 'up' or key == 'pagedown' or key == 'pageup'
		or key == 'home' or key == 'end'
	then
		local delta = delta * (key:find'down' and -1 or 1)
		self.b = self.b + lerp(delta, 0, 1, self:b_range())
		self:invalidate()
	elseif key == 'left' or key == 'right' then
		local delta = delta * (key:find'left' and -1 or 1)
		self.a = self.a + lerp(delta, 0, 1, self:a_range())
		self:invalidate()
	end
end

prect.vscrollable = true

function prect:mousewheel(pages)
	local delta =
		pages / 3
		* (self.ui:key'shift' and .01 or 1)
		* (self.ui:key'ctrl' and .1 or 1)
		* 0.1
	self.b = self.b + lerp(delta, 0, 1, self:b_range())
end


--saturation/luminance rectangle ---------------------------------------------

local slrect = prect:subclass'sat_lum_rectangle'
ui.sat_lum_rectangle = slrect

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

function slrect:hsl()
	return self.hue, self.sat, self.lum
end

function slrect:rgb()
	return color.convert('rgb', 'hsl', self:hsl())
end

function slrect:rgba(a)
	local r, g, b = color.hsl_to_rgb(self:hsl())
	return r, g, b, a or 1
end

function prect:get_a() return self.sat end
function prect:set_a(a) self.sat = a end
function prect:get_b() return 1-self.lum end
function prect:set_b(b) self.lum = 1-b end
function prect:a_range() return 0, 1 end
function prect:b_range() return 0, 1 end

function slrect:draw_colors(cr)
	if not self._bmp or self._bmp.h ~= self.ch or self._bmp.w ~= self.cw then
		self._bmp = bitmap.new(self.cw, self.ch, 'bgra8')
	end
	if self._bmp_hue ~= self.hue then
		self._bmp_hue = self.hue
		local bmp = self._bmp
		local _, setpixel = bitmap.pixel_interface(bmp)
		local w, h = bmp.w, bmp.h
		for y = 0, h-1 do
			for x = 0, w-1 do
				local sat = lerp(x, 0, w-1, 0, 1)
				local lum = lerp(y, 0, h-1, 1, 0)
				local r, g, b = color.convert('rgb', 'hsl', self.hue, sat, lum)
				setpixel(x, y, r * 255, g * 255, b * 255, 255)
			end
		end
	end
	cr:save()
	local sr = cairo.image_surface(self._bmp)
	cr:operator'over'
	cr:source(sr)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
	sr:free()
	cr:restore()
end

function slrect:pointer_cross_rgb(x, y)
	local hue = self.hue + 180
	local lum = self.lum > 0.5 and 0 or 1
	local sat = 1 - self.sat
	return color.hsl_to_rgb(hue, sat, lum)
end

function slrect:before_draw_content(cr)
	self:draw_colors(cr)
end

--saturation / value rectangle -----------------------------------------------

local svrect = prect:subclass'sat_val_rectangle'
ui.sat_val_rectangle = svrect

svrect.hue = 0
svrect.sat = 0
svrect.val = 0

svrect:track_changes'hue'
svrect:track_changes'sat'
svrect:track_changes'val'

function svrect:override_set_hue(inherited, hue)
	if inherited(self, clamp(hue, 0, 360)) then
		self:invalidate()
	end
end

function svrect:override_set_sat(inherited, sat)
	if inherited(self, clamp(sat, 0, 1)) then
		self:invalidate()
	end
end

function svrect:override_set_val(inherited, val)
	if inherited(self, clamp(val, 0, 1)) then
		self:invalidate()
	end
end

function svrect:hsv()
	return self.hue, self.sat, self.val
end

function svrect:rgb()
	return color.hsv_to_rgb(self:hsv())
end

function svrect:rgba(a)
	local r, g, b = color.hsv_to_rgb(self:hsv())
	return r, g, b, a or 1
end

function svrect:get_a() return self.sat end
function svrect:set_a(a) self.sat = a end
function svrect:get_b() return 1-self.val end
function svrect:set_b(b) self.val = 1-b end
function svrect:a_range() return 0, 1 end
function svrect:b_range() return 0, 1 end

function svrect:draw_colors(cr)
	cr:save()

	local g1 = cairo.linear_gradient(0, 0, 0, self.h)
	g1:add_color_stop(0, 1, 1, 1, 1)
	g1:add_color_stop(1, 0, 0, 0, 1)

	local g2 = cairo.linear_gradient(0, 0, self.cw, 0)
	local r, g, b = color.hsl_to_rgb(self.hue, 1, .5)
	g2:add_color_stop(0, r, g, b, 0)
	g2:add_color_stop(1, r, g, b, 1)

	cr:operator'over'
	cr:new_path()
	cr:rectangle(0, 0, self.cw, self.ch)
	cr:source(g1)
	cr:fill_preserve()
	cr:operator'multiply'
	cr:source(g2)
	cr:fill()

	cr:rgb(0, 0, 0) --clear source
	g1:free()
	g2:free()

	cr:restore()
end

function slrect:pointer_cross_rgb(x, y)
	local hue = self.hue + 180
	local val = self.val > 0.5 and 0 or 1
	local sat = 1 - self.sat
	return color.hsv_to_rgb(hue, sat, val)
end

function slrect:before_draw_content(cr)
	self:draw_colors(cr)
end

--saturation / luminance triangle --------------------------------------------

local sltr = slrect:subclass'sat_lum_triangle'
ui.sat_lum_triangle = sltr

sltr.angle = 0

sltr:track_changes'angle'

function sltr:override_set_angle(inherited, angle)
	if inherited(self, clamp(angle, 0, 2*math.pi)) then
		self:invalidate()
	end
end

function sltr:sat_lum_at(x, y)
	return --TODO
end

function sltr:sat_lum_coords(sat, lum)
	return --TODO
end

function sltr:draw_colors(cr)
	if not self._bmp or self._bmp.h ~= self.ch or self._bmp.w ~= self.cw then
		self._bmp = bitmap.new(self.cw, self.ch, 'bgra8')
	end
	if self._bmp_hue ~= self.hue or self._bmp_angle ~= self.angle then
		self._bmp_hue = self.hue
		self._bmp_angle = self.angle
		local bmp = self._bmp
		local _, setpixel = bitmap.pixel_interface(bmp)
		local w, h = bmp.w, bmp.h
		local hsl_to_rgb = color.hsl_to_rgb_unclamped

		--[[
		local hx = self.hx
		local hy = self.hy
		local sx = self.sx
		local sy = self.sy
		local vx = self.vx
		local vy = self.vy
		local size = self.innerSize

		--ctx.translate(this.wheelRadius, this.wheelRadius);

		// make a triangle
		ctx.beginPath();
		ctx.moveTo(hx, hy);
		ctx.lineTo(sx, sy);
		ctx.lineTo(vx, vy);
		ctx.closePath();
		ctx.clip();

		ctx.fillStyle = '#000';
		ctx.fillRect(-this.wheelRadius, -this.wheelRadius, size, size);

		// create gradient from hsl(hue, 1, 1) to transparent
		var grad0 = ctx.createLinearGradient(hx, hy, (sx + vx) / 2, (sy + vy) / 2);
		var hsla = 'hsla(' + M.round(this.hue * (180/PI)) + ', 100%, 50%, ';
		grad0.addColorStop(0, hsla + '1)');
		grad0.addColorStop(1, hsla + '0)');
		ctx.fillStyle = grad0;
		ctx.fillRect(-this.wheelRadius, -this.wheelRadius, size, size);
		// => gradient: one side of the triangle is black, the opponent angle is $color

		// create color gradient from white to transparent
		var grad1 = ctx.createLinearGradient(vx, vy, (hx + sx) / 2, (hy + sy) / 2);
		grad1.addColorStop(0, '#fff');
		grad1.addColorStop(1, 'rgba(255, 255, 255, 0)');
		ctx.globalCompositeOperation = 'lighter';
		ctx.fillStyle = grad1;
		ctx.fillRect(-this.wheelRadius, -this.wheelRadius, size, size);
		// => white angle

		]]

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
		step = 1/4,
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

	xe.text = color.format('#', 'rgb', r, g, b)

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
		hue_bar = {hue = 60, tooltip = 'Hue bar'},
		sat_lum_rectangle = {sat = .7, lum = .3, tooltip = 'Saturation x Luminance square'},
	}

end) end

