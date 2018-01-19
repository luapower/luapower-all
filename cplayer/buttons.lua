local player = require'cplayer'

local kappa = 4 / 3 * (math.sqrt(2) - 1)

local function button_path(cr, x1, y1, w, h, cut)
	local rx, ry = 5, 5
	rx = math.min(math.abs(rx), math.abs(w/2))
	ry = math.min(math.abs(ry), math.abs(h/2))
	if rx == 0 and ry == 0 then
		rect_to_lines(write, x1, y1, w, h)
		return
	end
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	if cut == 'right' or cut == 'both' then
		cr:move_to(x2, y1)
		cr:line_to(x2, y2)
		cr:line_to(cut == 'right' and x1+rx or x1, y2)
	else
		cr:move_to(cx, y1)
		cr:curve_to(cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
		cr:line_to(x2, y2-ry)
		cx, cy = x2-rx, y2-ry
		cr:curve_to(cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
		cr:line_to(cut and x1 or x1+rx, y2)
	end
	if cut == 'left' or cut == 'both' then
		cr:line_to(x1, y1)
	else
		cx, cy = x1+rx, y2-ry
		cr:curve_to(cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
		cr:line_to(x1, y1+ry)
		cx, cy = x1+rx, y1+ry
		cr:curve_to(cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
		cr:line_to(cx, y1)
	end
	cr:close_path()
end

function player:button(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local text = t.text or id
	local cut = t.cut
	local selected = t.selected
	local enabled = t.enabled == nil and true or t.enabled
	local font = t.font

	local down = self.lbutton
	local pressed = self.lpressed
	local hot = enabled and self:hotbox(x, y, w, h)

	if hot and (not self.active or self.active == id)  then
		self.cursor = 'hand'
	end

	local clicked = false
	if not self.active and hot and pressed then
		self.active = id
	elseif self.active == id then
		if hot then
			clicked = not down
			selected = clicked
		end
		if not down then
			self.active = nil
		end
	end

	local color_state = (selected or self.active == id and hot and down) and 'selected'
								or ((not self.active or self.active == id) and hot and 'hot')
								or enabled and (t.default and 'default' or 'normal')
								or 'disabled'
	local bg_color = color_state..'_bg'
	local fg_color = color_state..'_fg'

	--drawing
	local old_theme = self:save_theme(t.theme)
	button_path(self.cr, x + 0.5, y + 0.5, w - 1, h - 1, cut)
	self:fillstroke(bg_color, 'normal_border', 1)
	self:textbox(x, y, w, h, text, font, fg_color, 'center', 'center')
	self.theme = old_theme

	return (t.immediate and self.active == id and hot and down) or clicked
end

function player:togglebutton(t)
	if self:button(t) then
		return not t.selected
	else
		return t.selected
	end
end

function player:mbutton(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local values, texts, selected, enabled = t.values, t.texts, t.selected, t.enabled
	local multisel = type(selected) == 'table' and (t.multiselect == true or t.multiselect == nil)

	local bw = math.floor(w / #values)
	local left_w = w
	for i,v in ipairs(values) do
		local bw = i < #values and bw or left_w
		local cut = #values > 1 and (i==#values and 'left' or i==1 and 'right' or 'both')
		local t = {id = id..'_'..i, x = x, y = y, w = bw, h = h, text = texts and (texts[v] or texts[i]) or tostring(v),
						cut = cut, enabled = enabled and enabled[v], default = t.default == v}
		if multisel then
			t.selected = selected[v]
			selected[v] = self:togglebutton(t)
		else
			t.selected = selected == v
			if self:button(t) then
				selected = v
			end
		end
		x = x + bw - 1
		left_w = left_w - (bw - 1)
	end
	return selected
end

if not ... then require'cplayer.widgets_demo' end

