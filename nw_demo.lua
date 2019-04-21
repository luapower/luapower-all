local nw = require'nw'
local box2d = require'box2d'
local cairo = require'cairo'
local glue = require'glue'

if not ... then
	local app = nw:app()
	local dsp = app:main_display()
	local win = app:window{x = dsp.w - 900, y = 200, cw = 800, ch = 400,
		min_cw = 200, min_ch = 28,
		frame = 'none',
		transparent = false,
		corner_radius = 6,
		topmost = false,
		visible = false,
	}

	local function reload()
		package.loaded.nw_demo = nil
		local ok, methods = pcall(require, 'nw_demo')
		if not ok then return end
		--wrap/add methods from the reloaded module
		for k,v in pairs(methods) do
			win[k] = function(self, ...)
				local ok, ret = xpcall(methods[k], debug.traceback, self, ...)
				if not ok then print(ret) end
				return ret
			end
		end
	end
	reload()
	win:show()
	app:runevery(0.2, function()
		reload()
		win:invalidate()
	end)
	function app:event(...)
		print('app', ...)
	end
	function win:event(...)
		print('win', ...)
	end
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

local border_outer_color1 = {89/255, 89/255, 89/255, 1}
local inactive_border_outer_color1 = {96/255, 112/255, 135/255, 1}
local border_outer_color2 = {133/255, 172/255, 229/255, 1}
local inactive_border_outer_color2 = {194/255, 212/255, 237/255, 1}
local icon_color = {189/255, 208/255, 239/255, 1}
local hover_icon_color = {1, 1, 1, 1}
local icon_outline_color = {35/255, 54/255, 86/255, 1}
local border_color = {73/255, 120/255, 206/255, 1}
local inactive_border_color = {153/255, 178/255, 221/255, 1}
local titlebar_color1 = border_color
local titlebar_color2 = {97/255, 146/255, 221/255, 1}
local inactive_titlebar_color1 = inactive_border_color
local inactive_titlebar_color2 = {169/255, 195/255, 231/255, 1}
local hover_color = border_outer_color2
local close_hover_color = {218/255, 77/255, 75/255, 1}

local scale = 1
local border_width = 6
local border_radius = 4
local buttons_w = 100
local buttons_h = 18
local titlebar_h = 24

local buttons_rect
local titlebar_x
local min_rect
local max_rect
local close_rect
local titlebar_rect

local function set_dims(w, h)
	buttons_rect = {w - buttons_w - border_width, 0, buttons_w, buttons_h}
	titlebar_x = w - buttons_w - 60

	min_rect = {buttons_rect[1], buttons_rect[2], 28, buttons_rect[4]}
	max_rect = {buttons_rect[1] + 29, buttons_rect[2], 28, buttons_rect[4]}
	close_rect = {buttons_rect[1] + 56, buttons_rect[2], buttons_w - 28*2, buttons_rect[4]}
	titlebar_rect = {0, 0, w, titlebar_h}
end

function win:repaint()
	local bmp = self:bitmap()
	local cr = bmp:cairo()
	local mx, my = self:mouse'pos'

	local w = (bmp.w - scale) / scale
	local h = (bmp.h - scale) / scale
	set_dims(w, h)

	if not self:active() then
		border_color = inactive_border_color
		titlebar_color1 = inactive_titlebar_color1
		titlebar_color2 = inactive_titlebar_color2
		border_outer_color1 = inactive_border_outer_color1
		border_outer_color2 = inactive_border_outer_color2
	end

	cr:reset_clip()
	cr:identity_matrix()
	cr:operator'source'
	cr:rgba(0, 0, 0, 0)
	cr:paint()
	cr:scale(scale, scale)
	cr:translate(0.5, 0.5)

	if not self:ismaximized() then

		--outer border 1
		local r = border_radius
		round_rect(cr, r, r, r, r, box2d.offset(0, 0, 0, w, h))
		cr:rgba(unpack(border_outer_color1))
		cr:line_width(1)
		cr:stroke()

		--outer border 2
		local r = border_radius-1
		round_rect(cr, r, r, r, r, box2d.offset(-1, 0, 0, w, h))
		cr:rgba(unpack(border_outer_color2))
		cr:line_width(1)
		cr:stroke()

		--clipping region
		local r = border_radius-1.5
		round_rect(cr, r, r, r, r, box2d.offset(-1.5, 0, 0, w, h))
		cr:clip()

	end

	--background
	cr:rgba(1, 1, 1, 1)
	cr:paint()

	--titlebar
	if true then
		cr:move_to(0, 0)
		cr:rel_line_to(0, titlebar_h)
		cr:rel_line_to(titlebar_x, -.5)
		cr:rel_line_to(10, 0)
		cr:rel_line_to(w - titlebar_x, 0)
		cr:rel_line_to(0, -titlebar_h - 0)
		cr:close_path()
		local pat = cairo.linear_gradient(0, 0, 0, titlebar_h)
		pat:add_color_stop(1, unpack(titlebar_color1))
		pat:add_color_stop(0, unpack(titlebar_color2))
		cr:source(pat)
		cr:fill()
		pat:unref()
	else
		--buttons background
		local r = border_radius
		round_rect(cr, 0, r, r, 0, unpack(buttons_rect))
		local pat = cairo.linear_gradient(0, 0, 0, titlebar_h)
		pat:add_color_stop(1, unpack(titlebar_color1))
		pat:add_color_stop(0, unpack(titlebar_color2))
		cr:source(pat)
		cr:fill()
		pat:unref()
	end

	--buttons hover backgrounds
	mx = mx and mx / scale
	my = my and my / scale

	if mx then
		if self.min_hover then
			local r = border_radius
			round_rect(cr, 0, 0, r, 0, unpack(min_rect))
			cr:rgba(unpack(hover_color))
			cr:fill()
		end

		if self.max_hover then
			local r = border_radius
			round_rect(cr, 0, 0, 0, 0, unpack(max_rect))
			cr:rgba(unpack(hover_color))
			cr:fill()
		end

		if self.close_hover then
			local r = border_radius
			round_rect(cr, 0, r, 0, 0, unpack(close_rect))
			cr:rgba(unpack(close_hover_color))
			cr:fill()
		end

	end

	--buttons outline
	cr:line_width(1)
	local r = border_radius
	round_rect(cr, 0, r, r, 0, unpack(buttons_rect))
	cr:rgba(unpack(border_outer_color2))
	cr:stroke()
	local r = border_radius-.5
	round_rect(cr, 0, r, r, 0, box2d.translate(-1, -1, unpack(buttons_rect)))
	cr:rgba(unpack(border_outer_color1))
	cr:stroke()

	local function vline(xofs)
		cr:move_to(buttons_rect[1] + xofs, buttons_rect[2])
		cr:rel_line_to(0, buttons_rect[4] - 1.5)
		cr:rgba(unpack(border_outer_color1))
		cr:stroke()
		cr:move_to(buttons_rect[1] + xofs + 1, buttons_rect[2])
		cr:rel_line_to(0, buttons_rect[4] - 1.5)
		cr:rgba(unpack(border_outer_color2))
		cr:stroke()
	end
	vline(28)
	vline(56)

	local function min_icon(x, y, w, h, r)
		x, y, w, h = buttons_rect[1] + x, buttons_rect[2] + y, w, h
		round_rect(cr, r, r, r, r, box2d.offset(1, x, y, w, h))
		cr:rgba(unpack(self.min_hover and hover_icon_color or icon_color))
		cr:fill_preserve()
		cr:rgba(unpack(icon_outline_color))
		cr:stroke()
	end
	min_icon(8, buttons_h - 8, 11, 2, 1.5)

	local function max_icon(x, y, w, h, r)
		x, y, w, h = buttons_rect[1] + x, buttons_rect[2] + y, w, h
		cr:fill_rule'even_odd'
		round_rect(cr, r, r, r, r, box2d.offset(1, x, y, w, h))
		cr:new_sub_path()
		round_rect(cr, r, r, r, r, box2d.offset(-2, x, y, w, h))
		cr:close_path()
		cr:rgba(unpack(self.max_hover and hover_icon_color or icon_color))
		cr:fill_preserve()
		cr:rgba(unpack(icon_outline_color))
		cr:stroke()
	end

	local function restore_icon()
		max_icon(28+12, buttons_h - 14, 9, 6, 0.5)
		max_icon(28+9, buttons_h - 11, 9, 6, 0.5)
	end

	if self:ismaximized() then
		restore_icon()
	else
		max_icon(28+9, buttons_h - 12, 11, 7, 0.5)
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
		cr:rgba(unpack(self.close_hover and hover_icon_color or icon_color))
		cr:fill_preserve()
		cr:rgba(unpack(icon_outline_color))
		cr:stroke()
	end
	close_icon(56+15, buttons_h - 13)

end

function win:mousemove(mx, my)
	self:invalidate()
end

function win:mouseleave()
	self:invalidate()
end

function win:mousedown(x, y)

end

function win:activated()
	self:invalidate()
end

function win:deactivated()
	self:invalidate()
end

function win:hittest(mx, my, where)

	local w, h = self:client_size()
	set_dims(w, h)

	self.min_hover = box2d.hit(mx, my, unpack(min_rect))
	self.max_hover = box2d.hit(mx, my, unpack(max_rect))
	self.close_hover = box2d.hit(mx, my, unpack(close_rect))
	self.titlebar_hover =
		not where --the titlebar is below the invisible resize grip
		and box2d.hit(mx, my, unpack(titlebar_rect))

	if self.min_hover or self.max_hover or self.close_hover then
		return false --titlebar buttons are above the invisible resize grip
	elseif self.titlebar_hover then
		if self:ismaximized() or self:fullscreen() then return end
		return 'move'
	end
end

function win:click(button, count)
	if count == 2 and self.titlebar_hover then
		if self:ismaximized() then
			self:restore()
		else
			self:maximize()
		end
		return true
	end
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
