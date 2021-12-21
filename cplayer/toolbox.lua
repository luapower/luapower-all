local app = require'cplayer'
local box = require'box2d'

local toolbox = {
	--metrics
	edge = 4,
	titlebar_h = 20,
	title_font = 'MS Sans Serif,8',
	hit_edge = 4,
	titlebar_text_halign = 'left',
	--colors
	inactive = {
		bg_color = 'faint_bg',
		titlebar_color = 'normal_bg',
	},
	active = {
		bg_color = 'normal_bg',
		titlebar_color = 'hot_bg',
	},
	bg_color = 'faint_bg',
	titlebar_color = 'normal_bg',
	titlebar_active_color = 'hot_bg',
	--sub-classes
	buttons = {close = {pos = -1}, minimize = {pos = -2}},
}

function toolbox:new(t)
	self = setmetatable(t, {__index = self})
	self.visible = true
	self.minimized = false
	self:set_edges()
	if t.screen then
		t.screen:add(self)
	end
	return self
end

function toolbox:get_title()
	return self.title or self.id
end

function toolbox:is_top()
	return self.screen and self.screen:top_window() == self
end

function toolbox:set_edges()
	local left_button_count = 0
	local right_button_count = 0
	for _,b in pairs(self.buttons) do
		left_button_count = left_button_count + (b.pos > 0 and 1 or 0)
		right_button_count = right_button_count + (b.pos < 0 and 1 or 0)
	end
	self.left_edge = left_button_count * (self.titlebar_h - self.edge) + self.edge
	self.right_edge = right_button_count * (self.titlebar_h - self.edge) + self.edge
end

--setting size and position

function toolbox:_setpos(x, y)
	self.x = x
	self.y = y
end

function toolbox:_setbox(x, y, w, h)
	self.x = x
	self.y = y
	local cx = self.left_edge + self.right_edge
	local cy = self.titlebar_h
	self.w = math.min(math.max(w, self.min_w or 0, cx), self.max_w or 1/0)
	self.h = math.min(math.max(h, self.min_h or 0, cy), self.max_h or 1/0)
end

function toolbox:setpos(x, y)
	if self.screen then
		self.screen:setpos(self, x, y)
	else
		self:_setpos(x, y)
	end
end

function toolbox:setbox(x, y, w, h)
	if self.screen then
		self.screen:setbox(self, x, y, w, h)
	else
		self:_setbox(x, y, w, h)
	end
end

function toolbox:_set_minimized(minimized)
	self.minimized = minimized
end

function toolbox:set_minimized(minimized)
	if self.screen then
		self.screen:set_minimized(self, minimized)
	else
		self:_set_minimized(minimized)
	end
end

--hit testing

function toolbox:_hotbox(x, y, w, h)
	return self.visible and self.app:hotbox(x, y, w, h)
end

function toolbox:hotbox(x, y, w, h)
	if self.screen then
		return self.screen:hotbox(self, x, y, w, h)
	else
		return self:_hotbox(x, y, w, h)
	end
end

--measurements

function toolbox:_getbox()
	return self.x, self.y, self.w, self.h
end

function toolbox:titlebar_box()
	return box.vsplit(1, self.titlebar_h, self:_getbox())
end

function toolbox:contents_box()
	return box.vsplit(2, self.titlebar_h, self:getbox())
end

function toolbox:getbox()
	if self.minimized then
		return self:titlebar_box()
	else
		return self:_getbox()
	end
end

function toolbox:titlebar_grab_box()
	return box.hsplit(2, self.left_edge, box.hsplit(2, -self.right_edge, self:titlebar_box()))
end

function toolbox:titlebar_text_box()
	if self.titlebar_text_halign == 'center' then
		return self:titlebar_box()
	end
	return self:titlebar_grab_box()
end

function toolbox:titlebar_button_box(button)
	local pos = button.pos
	local x, y, w, h = self:titlebar_box()
	return box.offset(-self.edge,
				box.translate((pos + (pos < 0 and 1 or -1)) * (h - self.edge), 0,
					box.hsplit(1, (pos < 0 and -1 or 1) * h, x, y, w, h)))
end

--rendering

function toolbox:draw_titlebar_buttons()
	for _,button in pairs(self.buttons) do
		local x, y, w, h = self:titlebar_button_box(button)
		local hot = not self.active and self:hotbox(x, y, w, h)
		local fx, fy, fw, fh = box.offset(-0.5, x, y, w, h)
		self.app:rect(fx, fy, fw, fh, hot and 'hot_bg' or 'normal_bg', 'normal_fg')
		button:draw(self, hot, x, y, w, h)
	end
end

function toolbox.buttons.close:draw(toolbox, hot, x, y, w, h)
	toolbox.app.cr:move_to(x, y)
	toolbox.app.cr:rel_line_to(w, h)
	toolbox.app.cr:move_to(x + w, y)
	toolbox.app.cr:rel_line_to(-w, h)
	toolbox.app:stroke'normal_fg'
end

function toolbox.buttons.minimize:draw(toolbox, hot, x, y, w, h)
	x, y, w, h = box.offset(-2, x, y, w, h)
	local msize = toolbox.minimized and h or math.max(2, math.floor(h * 0.3))

	local x, y, w, h = box.offset(-0.5, box.vsplit(1, -msize, x, y, w, h))
	toolbox.app:rect(x, y, w, h, nil, 'normal_fg')
end

function toolbox:draw_frame()
	local x, y, w, h = box.offset(-0.5, self:getbox())
	self.app:rect(x, y, w, h, self.bg_color, 'normal_fg')
end

function toolbox:draw_titlebar(hot)
	local tx, ty, tw, th = self:titlebar_box()
	self.app:rect(tx, ty, tw, th, hot and 'hot_bg' or self:is_top() and self.titlebar_active_color or self.titlebar_color)

end

function toolbox:draw_titlebar_text(hot)
	local tx, ty, tw, th = self:titlebar_text_box()
	tw = math.max(tw, 0)
	th = math.max(th, 0)
	local title = self:get_title()
	if self.titlebar_text_halign == 'center' then
		--TODO: if text exceeds self:titlebar_grab_box() make it fit
	end
	self.app:textbox(tx, ty, tw, th, title, self.title_font,
							'normal_fg',
							self.titlebar_text_halign, 'center')
end

function toolbox:draw_contents()
	if self.minimized or not self.contents then return end
	local x, y, w, h = self:contents_box()
	self.cr:save()
	self.cr:translate(x, y)
	self:clip_rect(0, 0, w, h)
	self.contents(self)
	self.cr:restore()
end

function toolbox:render()
	if not self.visible then return end
	local id = assert(self.id, 'id missing')

	local window_hot, close_button_hot, minimize_button_hot, titlebar_hot

	window_hot = self:hotbox(self:getbox())
	if window_hot then
		close_button_hot    = self:_hotbox(self:titlebar_button_box(self.buttons.close))
		minimize_button_hot = self:_hotbox(self:titlebar_button_box(self.buttons.minimize))
		titlebar_hot        = self:_hotbox(self:titlebar_grab_box())
	end

	if self.visible and not self.app.active then

		local edges_hot

		if close_button_hot then
			if self.app.lpressed then
				self.app.active = id
				self.app.ui.action = 'close'
			end
		elseif minimize_button_hot then
			if self.app.lpressed then
				self.app.active = id
				self.app.ui.action = 'minimize'
			end
		elseif not self.minimized and self:hotbox(box.offset(self.hit_edge, self:getbox())) then

			local mx, my = self.app:mousepos()
			local x, y, w, h = self:getbox()
			local hit, left, top, right, bottom = box.hit_edges(mx, my, self.hit_edge, x, y, w, h)

			if hit then

				if (top and left) or (bottom and right) then
					self.app.cursor = 'size_diag2'
				elseif (bottom and left) or (top and right) then
					self.app.cursor = 'size_diag1'
				elseif top or bottom then
					self.app.cursor = 'size_v'
				elseif left or right then
					self.app.cursor = 'size_h'
				end

				if self.app.lpressed then
					self.app.active = id
					self.app.ui.action = 'resize'
					self.app.ui.sides = {left = left, top = top, right = right, bottom = bottom}
					if not top and not left then
						self.app.ui.dx = x + w - mx
						self.app.ui.dy = y + h - my
					end
				end

				edges_hot = true
			end
		end

		if not edges_hot and titlebar_hot then --edges are hotter than titlebar

			self.app.cursor = 'move'

			if self.app.doubleclicked then
				self:set_minimized(not self.minimized)
			elseif self.app.lpressed then
				local mx, my = self.app:mousepos()
				self.app.active = id
				self.app.ui.action = 'move'
				local x, y = self:getbox()
				self.app.ui.dx = mx - x
				self.app.ui.dy = my - y
			end
		end

	elseif self.app.active == id then

		if self.app.lbutton then
			if self.app.ui.action == 'move' then
				local mx, my = self.app:mousepos()
				local x = mx - self.app.ui.dx
				local y = my - self.app.ui.dy
				self:setpos(x, y)
			elseif self.app.ui.action == 'resize' then
				local s = self.app.ui.sides
				local x, y, w, h = self:getbox()
				local mx, my = self.app:mousepos()
				if not s.top and not s.left then
					if s.right then
						w = mx + self.app.ui.dx - x
					end
					if s.bottom then
						h = my + self.app.ui.dy - y
					end
					self:setbox(x, y, w, h)
					self:setpos(x, y)
				end
			end
		else
			if self.app.ui.action == 'close' and close_button_hot then
				self.visible = false
				return
			elseif self.app.ui.action == 'minimize' and minimize_button_hot then
				self:set_minimized(not self.minimized)
			end
			self.app.active = nil
		end
	end

	self:draw_frame()
	self:draw_titlebar(not self.active and titlebar_hot)
	self:draw_titlebar_text(not self.active and titlebar_hot)
	self:draw_titlebar_buttons()
	self:draw_contents()
end

function app:toolbox(t)
	return toolbox:new(t)
end


if not ... then require'cplayer.toolbox_demo' end
