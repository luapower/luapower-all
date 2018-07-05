
--ui color picker widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local bitmap = require'bitmap'
local color = require'color'
local cairo = require'cairo'
local line = require'path2d_line'
local lerp = glue.lerp
local clamp = glue.clamp

--hue vertical bar -----------------------------------------------------------

local hue_bar = ui.layer:subclass'hue_bar'
ui.hue_bar = hue_bar

--model

function hue_bar:get_hue()
	return self._hue
end

function hue_bar:set_hue(hue)
	hue = clamp(hue, 0, 360)
	local old_hue = self._hue
	if old_hue ~= hue then
		self._hue = hue
		if self:isinstance() then
			self:fire('hue_changed', hue, old_hue)
			self:invalidate()
		end
	end
end

hue_bar.hue = 0

hue_bar:init_ignore{hue=1}

function hue_bar:after_init(ui, t)
	self._hue = t.hue
end

--view/hue-bar

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

function hue_bar:background_visible()
	return true
end

function hue_bar:paint_background(cr)
	self:draw_bar(cr)
end

--view/pointer

hue_bar.pointer_style = 'sliderule' --sliderule, needle

function hue_bar:before_draw_content(cr)
	local y = glue.round(self.hue / 360 * self.ch) + .5
	self['draw_pointer_'..self.pointer_style](self, cr, y)
end

--view/pointer/needle

hue_bar.needle_pointer_color = '#0008'

ui:style('hue_bar :focused', {
	needle_pointer_color = '#000',
})

function hue_bar:draw_pointer_needle(cr, y)
	local w = self.cw
	cr:save()
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
	cr:restore()
end

--view/pointer/sliderule

local rule = ui.layer:subclass'hue_bar_sliderule'
hue_bar.sliderule_class = rule

rule.activable = false

rule.h = 8
rule.opacity = .7
rule.border_offset = 1
rule.border_width = 2
rule.border_color = '#fff'
rule.corner_radius = 3
rule.outline_width = 1
rule.outline_color = '#333'

ui:style('hue_bar :focused > hue_bar_sliderule', {
	opacity = 1,
})

function rule:before_draw_border(cr)
	cr:line_width(self.outline_width)
	cr:rgba(self.ui:color(self.outline_color))
	self:border_path(cr, -1)
	cr:stroke()
	self:border_path(cr, 1)
	cr:stroke()
end

function hue_bar:draw_pointer_sliderule(cr, y)
	if not self.sliderule or not self.sliderule.islayer then
		self.sliderule = self.sliderule_class(self.ui, {
				parent = self,
			}, self.sliderule)
	end
	local rule = self.sliderule
	rule.y = glue.round(y - rule.h / 2)
	rule.w = self.w
end

--input/mouse

hue_bar.mousedown_activate = true

function hue_bar:mousemove(mx, my)
	if not self.active then return end
	self.hue = lerp(my, 0, self.ch-1, 0, 360)
	self:invalidate()
end

--input/keyboard

hue_bar.focusable = true

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

--input/wheel

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

--model

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

--view/pointer

prect.pointer_style = 'cross' --circle, cross

function prect:before_draw_content(cr)
	local cx, cy = self:xy(self.a, self.b)
	self['draw_pointer_'..self.pointer_style](self, cr, cx, cy)
end

--view/pointer/cross

prect.pointer_cross_opacity = .5

ui:style('pick_rectangle :focused', {
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

--view/pointer/circle

prect.circle_pointer_color = '#fff8'
prect.circle_pointer_outline_color = '#3338'
prect.circle_pointer_outline_width = 1
prect.circle_pointer_radius = 9
prect.circle_pointer_inner_radius = 6

ui:style('pick_rectangle :focused', {
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

--input/mouse

prect.mousedown_activate = true

function prect:mousemove(mx, my)
	if not self.active then return end
	self.a, self.b = self:ab(mx, my)
end

--input/keyboard

prect.focusable = true

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
		local delta = delta * (key:find'down' and 1 or -1)
		self.b = self.b + lerp(delta, 0, 1, self:b_range())
		self:invalidate()
	elseif key == 'left' or key == 'right' then
		local delta = delta * (key:find'left' and -1 or 1)
		self.a = self.a + lerp(delta, 0, 1, self:a_range())
		self:invalidate()
	end
end

--input/wheel

prect.vscrollable = true

function prect:mousewheel(pages)
	local delta =
		-pages / 3
		* (self.ui:key'shift' and .01 or 1)
		* (self.ui:key'ctrl' and .1 or 1)
		* 0.1
	self.b = self.b + lerp(delta, 0, 1, self:b_range())
end

--saturation/luminance rectangle ---------------------------------------------

local slrect = prect:subclass'sat_lum_rectangle'
ui.sat_lum_rectangle = slrect

--model

slrect.hue = 0
slrect.sat = 0
slrect.lum = 0

slrect:stored_property'hue'
slrect:stored_property'sat'
slrect:stored_property'lum'

slrect:track_changes'hue'
slrect:track_changes'sat'
slrect:track_changes'lum'

function slrect:override_set_hue(inherited, hue)
	if inherited(self, hue % 360) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function slrect:override_set_sat(inherited, sat)
	if inherited(self, clamp(sat, 0, 1)) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function slrect:override_set_lum(inherited, lum)
	if inherited(self, clamp(lum, 0, 1)) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function slrect:hsl()
	return self.hue, self.sat, self.lum
end

function slrect:rgb()
	return color.convert('rgb', 'hsl', self:hsl())
end

function slrect:get_a() return self.sat end
function slrect:set_a(a) self.sat = a end
function slrect:get_b() return 1-self.lum end
function slrect:set_b(b) self.lum = 1-b end
function slrect:a_range() return 0, 1 end
function slrect:b_range() return 0, 1 end

slrect:init_ignore{hue=1, sat=1, lum=1}

function slrect:after_init(ui, t)
	self._hue = t.hue
	self._sat = t.sat
	self._lum = t.lum
end

--view

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
	return color.convert('rgb', 'hsl', hue, sat, lum)
end

function slrect:before_draw_content(cr)
	self:draw_colors(cr)
end

--saturation / value rectangle -----------------------------------------------

local svrect = prect:subclass'sat_val_rectangle'
ui.sat_val_rectangle = svrect

--model

svrect.hue = 0
svrect.sat = 0
svrect.val = 0

svrect:stored_property'hue'
svrect:stored_property'sat'
svrect:stored_property'val'

svrect:track_changes'hue'
svrect:track_changes'sat'
svrect:track_changes'val'

function svrect:override_set_hue(inherited, hue)
	if inherited(self, hue % 360) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function svrect:override_set_sat(inherited, sat)
	if inherited(self, clamp(sat, 0, 1)) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function svrect:override_set_val(inherited, val)
	if inherited(self, clamp(val, 0, 1)) then
		self:fire'color_changed'
		self:invalidate()
	end
end

function svrect:hsv()
	return self.hue, self.sat, self.val
end

function svrect:rgb()
	return color.convert('rgb', 'hsv', self:hsv())
end

function svrect:get_a() return self.sat end
function svrect:set_a(a) self.sat = a end
function svrect:get_b() return 1-self.val end
function svrect:set_b(b) self.val = 1-b end
function svrect:a_range() return 0, 1 end
function svrect:b_range() return 0, 1 end

svrect:init_ignore{hue=1, sat=1, val=1}

function svrect:after_init(ui, t)
	self._hue = t.hue
	self._sat = t.sat
	self._val = t.val
end

--view

function svrect:draw_colors(cr)
	cr:save()
	local g1 = cairo.linear_gradient(0, 0, 0, self.ch)
	g1:add_color_stop(0, 1, 1, 1, 1)
	g1:add_color_stop(1, 0, 0, 0, 1)
	local g2 = cairo.linear_gradient(0, 0, self.cw, 0)
	local r, g, b = color.convert('rgb', 'hsl', self.hue, 1, .5)
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

function svrect:pointer_cross_rgb(x, y)
	local hue = self.hue + 180
	local val = self.val > 0.5 and 0 or 1
	local sat = 1 - self.sat
	return color.convert('rgb', 'hsv', hue, sat, val)
end

function svrect:before_draw_content(cr)
	self:draw_colors(cr)
end

--saturation / luminance triangle --------------------------------------------

local sltr = slrect:subclass'sat_lum_triangle'
ui.sat_lum_triangle = sltr

function sltr:override_set_angle(inherited, angle)
	if inherited(self, angle % 360) then
		self:invalidate()
	end
end

function sltr:get_triangle_radius()
	return math.min(self.cw, self.ch) / 2
end

function sltr:triangle_points()
	local r = self.triangle_radius
	local a = math.rad(self.hue)
	local third = 2/3 * math.pi
	local x1 =  math.cos(a + 0 * third) * r
	local y1 = -math.sin(a + 0 * third) * r
	local x2 =  math.cos(a + 1 * third) * r
	local y2 = -math.sin(a + 1 * third) * r
	local x3 =  math.cos(a + 2 * third) * r
	local y3 = -math.sin(a + 2 * third) * r
	return x1, y1, x2, y2, x3, y3
end

function sltr:xy(a, b)
	local s, l = a, 1-b
	local hx, hy, sx, sy, vx, vy = self:triangle_points()
	local mx = (sx + vx) / 2
	local my = (sy + vy) / 2
	local a  = (1 - 2 * math.abs(l - .5)) * s
	local x = self.cx + sx + (vx - sx) * l + (hx - mx) * a
	local y = self.cy + sy + (vy - sy) * l + (hy - my) * a
	return x, y
end

function sltr:ab(x, y)
	local r = self.triangle_radius
	x = x - r
	y = y - r
	local hx, hy, sx, sy, vx, vy = self:triangle_points()
	local bx = (sx + vx) / 2
	local by = (sy + vy) / 2
	local _, _, _, l = line.hit(x, y, sx, sy, vx, vy)
	local _, _, _, t = line.hit(x, y, bx, by, hx, hy)
	local s = clamp(t / (2 * (l <= 0.5 and l or (1 - l))), 0, 1)
	return s, 1-l
end

function sltr:draw_colors(cr)
	local r = self.triangle_radius
	local hx, hy, sx, sy, vx, vy = self:triangle_points()

	cr:save()

	cr:translate(r, r)

	cr:new_path()
	cr:move_to(hx, hy)
	cr:line_to(sx, sy)
	cr:line_to(vx, vy)
	cr:close_path()
	cr:clip()

	--start from a black triangle
	cr:rgba(0, 0, 0, 1)
	cr:rectangle(-r, -r, 2*r, 2*r)
	cr:operator'over'
	cr:fill()

	--hsl(hue, 1, 1) to transparent gradient
	local g1 = cairo.linear_gradient(hx, hy, (sx + vx) / 2, (sy + vy) / 2)
	local R, G, B = color.convert('rgb', 'hsl', self.hue, 1, .5)
	g1:add_color_stop(0, R, G, B, 1)
	g1:add_color_stop(1, R, G, B, 0)
	cr:operator'over'
	cr:source(g1)
	cr:rectangle(-r, -r, 2*r, 2*r)
	cr:fill()

	--white to transparent gradient
	local g2 = cairo.linear_gradient(vx, vy, (hx + sx) / 2, (hy + sy) / 2)
	g2:add_color_stop(0, 1, 1, 1, 1)
	g2:add_color_stop(1, 1, 1, 1, 0)
	cr:operator'lighten'
	cr:source(g2)
	cr:rectangle(-r, -r, 2*r, 2*r)
	cr:fill()

	cr:rgb(0, 0, 0) --release source
	g1:free()
	g2:free()

	cr:restore()
end

--color picker ---------------------------------------------------------------

local picker = ui.layer:subclass'colorpicker'
ui.colorpicker = picker

--model

picker._mode = 'HSL'

function picker:get_mode()
	return self._mode
end

function picker:set_mode(mode)
	self._mode = mode
	if self:isinstance() then
		local hsl = mode == 'HSL'
		self.rectangle = hsl and self.sat_lum_rectangle or self.sat_val_rectangle

		self.sat_lum_rectangle.visible = hsl
		self.lum_label.visible = hsl
		self.lum_slider.visible = hsl

		self.sat_val_rectangle.visible = not hsl
		self.val_label.visible = not hsl
		self.val_slider.visible = not hsl

		if hsl then
			local h, s, l = color.convert('hsl', 'hsv', self.sat_val_rectangle:hsv())
			self.sat_lum_rectangle.sat = s
			self.sat_lum_rectangle.lum = l
		else
			local h, s, v = color.convert('hsv', 'hsl', self.sat_lum_rectangle:hsl())
			self.sat_val_rectangle.sat = s
			self.sat_val_rectangle.val = v
		end

		self.mode_button.selected = mode
	end
end

--view

picker.hue_bar_class = hue_bar
picker.sat_lum_rectangle_class = slrect
picker.sat_val_rectangle_class = svrect
picker.mode_button_class = ui.choicebutton

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
		visible = false,
		sat_changed = function(_, sat)
			self.sat_slider.position = sat
		end,
		lum_changed = function(_, lum)
			self.lum_slider.position = lum
		end,
		color_changed = function()
			self:sync_editboxes()
		end,
	}, self.sat_lum_rectangle)
end

function picker:create_sat_val_rectangle()
	return self.sat_val_rectangle_class(self.ui, {
		parent = self,
		picker = self,
		visible = false,
		sat_changed = function(_, sat)
			self.sat_slider.position = sat
		end,
		val_changed = function(_, val)
			self.val_slider.position = val
		end,
		color_changed = function()
			self:sync_editboxes()
		end,
	}, self.sat_val_rectangle)
end

function picker:create_mode_button()
	return self.mode_button_class(self.ui, {
		parent = self,
		picker = self,
		values = {'HSL', 'HSV'},
		value_selected = function(_, mode)
			self.mode = mode
		end,
		button = {h = 17, text_size = 11},
		button_corner_radius = 5,
		w = 70,
	}, self.mode_button)
end

function picker:create_rgb_editbox()
	return self.ui:editbox{
		multiline = false,
		picker = self,
		parent = self,
	}
end

function picker:sync_editboxes()
	if not self.window.cr then return end
	local sr = self.rectangle
	local re = self.rgb_editbox
	local xe = self.hex_editbox
	local r, g, b = sr:rgb()
	re.text = string.format(
		'%d, %d, %d',
		r * 255, g * 255, b * 255)
	xe.text = color.format('#', 'rgb', r, g, b)
end

function picker:sync()

	local hb = self.hue_bar
	local sr = self.rectangle
	local mb = self.mode_button
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
	local vl = self.val_label
	local vs = self.val_slider

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

	mb.x = 400

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

	y = y + h + sy

	xl.x = x1
	xl.y = y
	xl.w = w1
	xl.h = h
	xe.x = x2
	xe.y = y
	xe.w = w2

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

	vl.x = x1
	vl.y = y
	vl.w = w1
	vl.h = h
	vs.x = x2
	vs.y = y
	vs.w = w2
	vs.h = h
end

function picker:before_draw_content()
	self:sync()
end

--init

picker:init_ignore{mode=1}

function picker:after_init(ui, t)

	self.hue_bar = self:create_hue_bar()

	self.sat_lum_rectangle = self:create_sat_lum_rectangle()
	self.sat_val_rectangle = self:create_sat_val_rectangle()

	self.mode_button = self:create_mode_button()

	self.rgb_editbox = self:create_rgb_editbox()
	self.hex_editbox = self:create_rgb_editbox()

	self.rgb_label = self.ui:layer{text = 'RGB:', parent = self, text_align = 'left'}
	self.hex_label = self.ui:layer{text = 'HEX:', parent = self, text_align = 'left'}
	self.hue_label = self.ui:layer{text = 'Hue:', parent = self, text_align = 'left'}
	self.sat_label = self.ui:layer{text = 'Sat:', parent = self, text_align = 'left'}
	self.lum_label = self.ui:layer{text = 'Lum:', parent = self, text_align = 'left'}
	self.val_label = self.ui:layer{text = 'Val:', parent = self, text_align = 'left'}

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
			self.rectangle.sat = pos
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
	self.val_slider = self.ui:slider{
		parent = self,
		size = 1,
		step = 0.001,
		position = self.sat_val_rectangle.val,
		position_changed = function(slider, pos)
			self.sat_val_rectangle.val = pos
		end,
	}

	self.mode = t.mode
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.view.background_color = '#222'

	local cp = ui:colorpicker{
		x = 20, y = 20,
		w = 220, h = 200,
		parent = win,
		hue_bar = {hue = 60, tooltip = 'Hue bar'},
		sat_lum_rectangle = {sat = .7, lum = .3}, --, tooltip = 'Saturation x Luminance square'},
		sat_val_rectangle = {sat = .7, val = .3}, --, tooltip = 'Saturation x Value square'},
		--mode = 'HSV',
		--sat_lum_rectangle_class = sltr,
	}

end) end

