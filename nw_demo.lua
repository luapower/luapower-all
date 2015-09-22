local nw = require'nw'
local box2d = require'box2d'
local cairo = require'cairo'
local glue = require'glue'

if not ... then
	local app = nw:app()
	local win = app:window{x = 100, y = 200, cw = 800, ch = 400,
		frame = 'none', transparent = true, topmost = true, visible = false}
	local function reload()
		package.loaded.nw_demo = nil
		local ok, methods = pcall(require, 'nw_demo')
		if not ok then return end
		--wrap/add methods from the reloaded module
		for k,v in pairs(methods) do
			win[k] = function(self, ...)
				local ok, err = xpcall(methods[k], debug.traceback, self)
				if not ok then print(err) end
			end
		end
	end
	win:show()
	app:runevery(0.2, function()
		reload()
		win:invalidate()
	end)
	app:run()
	return
end

--all code below can be live edited and it will be reloaded
--automatically every time the file is saved!

local function round_rect_open(cr, r1, r2, r3, r4, x, y, w, h)
	local d = math.pi / 180
	cr:arc(x + w - r1, y + r1, r1, -90 * d, 0 * d)
	cr:arc(x + w - r2, y + h - r2, r2, 0 * d, 90 * d)
	cr:arc(x + r3, y + h - r3, r3, 90 * d, 180 * d)
	cr:arc(x + r4, y + r4, r4, 180 * d, 270 * d)
end

local function round_rect(cr, ...)
	round_rect_open(cr, ...)
	cr:close_path()
end

local win = {} --hot-loaded pcalled window methods

function win:repaint()
	local bmp = self:bitmap()
	local cr = bmp:cairo()
	local mx, my = self:mouse'pos'

	local scale = 1
	mx = mx and mx / scale
	my = my and my / scale
	local w = (bmp.w - scale) / scale
	local h = (bmp.h - scale) / scale
	local border_width = 6
	local border_radius = 4
	local border_color = {73/255, 120/255, 206/255, 1}
	local border_outer_color1 = {89/255, 89/255, 89/255, 1}
	local border_outer_color2 = {133/255, 172/255, 229/255, 1}
	local icon_color = {189/255, 208/255, 239/255, 1}
	local hover_icon_color = {1, 1, 1, 1}
	local icon_outline_color = {35/255, 54/255, 86/255, 1}
	local titlebar_rect = {0, 0.5, w, 26}
	local titlebar_color1 = border_color
	local titlebar_color2 = {97/255, 146/255, 221/255, 1}
	local buttons_w = 100
	local buttons_h = 18
	local buttons_rect = {w - buttons_w - border_width, 0, buttons_w, buttons_h}
	local hover_color = border_outer_color2
	local close_hover_color = {218/255, 77/255, 75/255, 1}

	cr:reset_clip()
	cr:identity_matrix()
	cr:set_operator(cairo.CAIRO_OPERATOR_SOURCE)
	cr:set_source_rgba(0, 0, 0, 0)
	cr:paint()
	cr:scale(scale, scale)
	cr:translate(0.5, 0.5)

	--outer border 1
	local r = border_radius
	round_rect(cr, r, r, r, r, box2d.offset(0, 0, 0, w, h))
	cr:set_source_rgba(unpack(border_outer_color1))
	cr:set_line_width(1)
	cr:stroke()

	--outer border 2
	local r = border_radius-1
	round_rect(cr, r, r, r, r, box2d.offset(-1, 0, 0, w, h))
	cr:set_source_rgba(unpack(border_outer_color2))
	cr:set_line_width(1)
	cr:stroke()

	--clipping region
	local r = border_radius-1.5
	round_rect(cr, r, r, r, r, box2d.offset(-1.5, 0, 0, w, h))
	cr:clip()

	--background
	cr:set_source_rgba(1, 1, 1, 1)
	cr:paint()

	--titlebar
	cr:rectangle(unpack(titlebar_rect))
	local pat = cairo.cairo_pattern_create_linear(0, 0, 0, titlebar_rect[4])
	pat:add_color_stop_rgba(1, unpack(titlebar_color1))
	pat:add_color_stop_rgba(0, unpack(titlebar_color2))
	cr:set_source(pat)
	cr:fill()
	pat:destroy()

	--buttons hover backgrounds
	if mx then
		local b1rect = {buttons_rect[1], buttons_rect[2], 28, buttons_rect[4]}
		self.min_hover = box2d.hit(mx, my, unpack(b1rect))
		if self.min_hover then
			local r = border_radius
			round_rect(cr, 0, 0, r, 0, unpack(b1rect))
			cr:set_source_rgba(unpack(hover_color))
			cr:fill()
		end

		local b2rect = {buttons_rect[1] + 29, buttons_rect[2], 28, buttons_rect[4]}
		self.max_hover = box2d.hit(mx, my, unpack(b2rect))
		if self.max_hover then
			local r = border_radius
			round_rect(cr, 0, 0, 0, 0, unpack(b2rect))
			cr:set_source_rgba(unpack(hover_color))
			cr:fill()
		end

		local b3rect = {buttons_rect[1] + 56, buttons_rect[2], buttons_w - 28*2, buttons_rect[4]}
		self.close_hover = box2d.hit(mx, my, unpack(b3rect))
		if self.close_hover then
			local r = border_radius
			round_rect(cr, 0, r, 0, 0, unpack(b3rect))
			cr:set_source_rgba(unpack(close_hover_color))
			cr:fill()
		end
	end

	--buttons outline
	cr:set_line_width(1)
	local r = border_radius
	round_rect(cr, 0, r, r, 0, unpack(buttons_rect))
	cr:set_source_rgba(unpack(border_outer_color2))
	cr:stroke()
	local r = border_radius-.5
	round_rect(cr, 0, r, r, 0, box2d.translate(-1, -1, unpack(buttons_rect)))
	cr:set_source_rgba(unpack(border_outer_color1))
	cr:stroke()

	local function vline(xofs)
		cr:move_to(buttons_rect[1] + xofs, buttons_rect[2])
		cr:rel_line_to(0, buttons_rect[4] - 1.5)
		cr:set_source_rgba(unpack(border_outer_color1))
		cr:stroke()
		cr:move_to(buttons_rect[1] + xofs + 1, buttons_rect[2])
		cr:rel_line_to(0, buttons_rect[4] - 1.5)
		cr:set_source_rgba(unpack(border_outer_color2))
		cr:stroke()
	end
	vline(28)
	vline(56)

	local function min_icon(x, y, w, h, r)
		x, y, w, h = buttons_rect[1] + x + .5, buttons_rect[2] + y + .5, w, h
		round_rect(cr, r, r, r, r, box2d.offset(1, x, y, w, h))
		cr:set_source_rgba(unpack(icon_outline_color))
		cr:fill()
		cr:rectangle(x, y, w, h)
		cr:set_source_rgba(unpack(self.min_hover and hover_icon_color or icon_color))
		cr:fill()
	end
	min_icon(8, buttons_h - 9, 11, 3, 2)

	local function max_icon(x, y, w, h, r)
		x, y, w, h = buttons_rect[1] + x + .5, buttons_rect[2] + y + .5, w, h
		cr:set_fill_rule(cairo.CAIRO_FILL_RULE_EVEN_ODD)
		round_rect_open(cr, r, r, r, r, box2d.offset(1, x, y, w, h))
		cr:new_sub_path()
		round_rect(cr, r, r, r, r, box2d.offset(-4, x, y, w, h))
		cr:set_source_rgba(unpack(icon_outline_color))
		cr:fill()
		cr:rectangle(x, y, w, h)
		cr:set_source_rgba(unpack(self.max_hover and hover_icon_color or icon_color))
		cr:fill()
	end

	local function restore_icon(x, y, w, h, r)
		--
	end

	if self:ismaximized() then
		restore_icon(28+8, buttons_h - 3, 11, 7, 2)
	else
		max_icon(28+8, buttons_h - 13, 11, 7, 2)
	end

	local function close_icon(x, y)
		cr:move_to(buttons_rect[1] + x, buttons_rect[2] + y)
		local w = 4
		local h = 2
		local k = (h * 2 + w) / 2
		cr:rel_line_to(w, 0)
		cr:rel_line_to(h, h)
		cr:rel_line_to(h, -h)
		cr:rel_line_to(w, 0)
		cr:rel_line_to(-k, k)
		cr:rel_line_to(k, k)
		cr:rel_line_to(-w, 0)
		cr:rel_line_to(-h, -h)
		cr:rel_line_to(-h, h)
		cr:rel_line_to(-w, 0)
		cr:rel_line_to(k, -k)
		cr:close_path()
		cr:set_source_rgba(unpack(self.close_hover and hover_icon_color or icon_color))
		cr:fill_preserve()
		cr:set_source_rgba(unpack(icon_outline_color))
		cr:stroke()
	end
	close_icon(56+15, buttons_h - 13)

end

function win:mousemove(x, y)
	self:invalidate()
end

function win:mousedown(x, y)

end

function win:mouseup(x, y)
	if self.min_hover then
		self:minimize()
	elseif self.max_hover then
		if self:ismaximized() then
			self:restore()
		else
			self:maximize()
		end
	elseif self.close_hover then
		self:close()
	end
end

return win
