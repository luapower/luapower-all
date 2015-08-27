--stateless itemlist (no animation)
local player = require'cplayer'
local box = require'box2d'

function player:itemlist(id, x, y, vert, item_w, item_h, allow_drag, allow_drop)
	local list = self.cache[id] or {id = id}
	list.x = x
	list.y = y
	list.vert = vert
	list.item_x = x
	list.item_y = y
	list.item_w = item_w
	list.item_h = item_h
	list.allow_drag = allow_drag
	list.allow_drop = allow_drop
	list.i = 1
	self.cache[id] = list
	self.ui.drop_index = nil
	return list
end

function player:item(list, item_wh)

	local i = list.i
	local x, y = list.item_x, list.item_y
	local w = (not list.vert and item_wh) or list.item_w
	local h = (list.vert and item_wh) or list.item_h

	local mx, my = self:mousepos()

	local skip_inc, check_drop

	if list.allow_drag and not self.active and self.lpressed and box.hit(mx, my, x, y, w, h) then

		self.active = list.id
		self.ui.command = 'drag_item'
		self.ui.dx = mx - x
		self.ui.dy = my - y
		self.ui.drag_index = i
		self.ui.drag_index_x = x
		self.ui.drag_index_y = y
		self.ui.drag_index_w = w
		self.ui.drag_index_h = h

		skip_inc = true

	elseif self.active == list.id then

		if self.lbutton then

			self.ui.drag_index_x = mx - self.ui.dx
			self.ui.drag_index_y = my - self.ui.dy

			if i == self.ui.drag_index then

				x = self.ui.drag_index_x
				y = self.ui.drag_index_y

				skip_inc = true
			else
				check_drop = true
			end

		else

			if self.ui.drop_index then
				--
			end
			self.active = nil
			self.ui.command = nil

		end

	elseif self.active and self.ui.command == 'drag_item' then

		check_drop = true

	end

	if list.allow_drop and check_drop and not self.ui.drop_index then

		if list.vert then

			if y + h / 2 > self.ui.drag_index_y
				and self.ui.drag_index_x + w > list.x
				and self.ui.drag_index_x < list.x + list.item_w
			then
				self.ui.drop_index = i - 1
				if self.ui.drag_index >= i then
					self.ui.drop_index = self.ui.drop_index + 1
				end

				y = y + self.ui.drag_index_h
			end

		else

			if x + w / 2 > self.ui.drag_index_x
				and self.ui.drag_index_y + h > list.y
				and self.ui.drag_index_y < list.y + list.item_h
			then
				self.ui.drop_index = i - 1
				if self.ui.drag_index >= i then
					self.ui.drop_index = self.ui.drop_index + 1
				end

				x = x + self.ui.drag_index_w
				end

		end

	end

	if not skip_inc then
		if list.vert then
			list.item_y = y + h
		else
			list.item_x = x + w
		end
	end

	list.i = list.i + 1

	return x, y, w, h
end

if not ... then

player.continuous_rendering = false

function player:test_list(id, ...)
	local list = self:itemlist(id, ...)
	for i = 1, 10 do
		local x, y, w, h = box.offset(0.5, self:item(list, i * 15))
		local color = {i % 4 / 6 + 0.05, 0, 0, 1}

		if self.active == id and i == self.ui.drag_index then
			self.layers:add{render = function(self, app)
				app:rect(x, y, w, h, color, 'normal_fg')
			end}
		else
			self:rect(x, y, w, h, color, 'normal_fg')
		end
	end
end

function player:on_render(cr)

	self:test_list('list1', 10, 10, true, 200, 26, true, false)
	self:test_list('list2', 250, 100, false, 200, 26, false, true)
	self:test_list('list3', 250, 200, false, 200, 26, true, true)

end

player:play()

end
