local player = require'cplayer'
local glue = require'glue'

function player:tablist(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local values = t.values
	local item_w = t.item_w or 80
	local item_h = t.item_h or 26
	local selected = t.selected

	if not self.active then
		self.ui.mx0 = nil
	end

	local drag_index, dx, dy, dw, dh
	local x0, y0 = x, y
	for i,item in ipairs(values) do
		local x1, y1, w1, h1 = x0, y0, item_w, item_h
		local id1 = id..'_'..i
		if self.active == id1 then
			drag_index = i
			if not self.ui.mx0 then
				self.ui.mx0 = self.mousex
				self.ui.my0 = self.mousey
			end
			local mx0, my0 = self.cr:device_to_user(self.ui.mx0, self.ui.my0)
			local mx, my = self.cr:device_to_user(self.mousex, self.mousey)
			x1 = x1 + mx - mx0
			dx, dy, dw, dh = x1, y1, w1, h1
		end
		x0 = x0 + w1
	end

	local drop_index
	for i,item in ipairs(values) do

		local id1 = id..'_'..i
		local x1, y1, w1, h1 = x, y, item_w, item_h

		if i == drag_index then
			x1, y1, w1, h1 = dx, dy, dw, dh
		elseif drag_index then
			if not drop_index and x1 + w1 / 2 > dx then
				drop_index = i - (drag_index > i and 0 or 1)
			end
			if drop_index then

				if self.ui.stopwatch then
					if drop_index ~= self.ui.drop_index then
						self.ui.stopwatch = nil
					end
				end

				if self.ui.stopwatch then
					local t = self.ui.stopwatch:progress()
					x1 = x1 + dw * t
				else
					self.ui.stopwatch = self:stopwatch(0.1)
					self.ui.drop_index = drop_index
				end
			end
		end

		if self:button(glue.merge(
								{id = id1, x = x1, y = y1, w = w1, h = h1, immediate = true,
								text = item, cut = 'both', selected = selected == i}, t))
		then
			selected = i
		end

		x = x + w1
	end
	drop_index = drag_index and (drop_index or #values)

	if drop_index and not self.lbutton then
		assert(drop_index >= 1 and drop_index <= #values)
		local drag_value = table.remove(values, drag_index)
		table.insert(values, drop_index, drag_value)
		selected = drop_index
	end

	return selected, values
end


if not ... then

local values = {'apples', 'bannanas', 'apricots'}
local selected = 'bannanas'

function player:on_render(cr)

	selected, values = self:tablist{id = 'test', x = 100, y = 100, w = 200, h = 26,
												values = values, selected = selected}

end

player:play()

end

