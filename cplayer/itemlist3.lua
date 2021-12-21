local player = require'cplayer'
local box = require'box2d'

local itemlist = {}

function itemlist:new(t)
	return setmetatable(t or {}, {__index = itemlist})
end

function itemlist:add(item, index)
	index = index or #self + 1
	item.parent = itemlist
	item.index = index
	table.insert(self, index, item)
end

function itemlist:layout()
	local dx, dy, dw, dh = app.ui.dx, app.ui.dy, app.ui.dw, app.ui.dh
	local drop_index
	local x, y = self.x, self.y
	local i = 1

	return function()
		local item = self[i]
		if not item then return end

		local w = item.w or self.item_w
		local h = item.h or self.item_h

		if item == drag_item then
			i = i + 1
			return dx, dy, dw, dh
		end

		if not drop_index then
			--check if the drag item is between two items
			if y + h / 2 > dy and dx + dw > x and dx < x + w then
				drop_index = i

				--drag index is above this item so the drop index must be decremented to exclude it
				if app.ui.di and app.ui.di < i then
					drop_index = drop_index - 1
				end

				--make room for the drag item
				if self.vert then
					y = y + dh
				else
					x = x + dw
				end
			end
		end

		local x1, y1 = x, y

		--advance the current point and index
		if self.vert then
			y = y + h
		else
			x = x + w
		end
		i = i + 1

		return x1, y1, w, h
	end
end

function itemlist:render(app)

end

function itemlist:update(app)

	local item_index = list.item_index
	local x, y = list.item_x, list.item_y
	local w = (not list.vert and item_wh) or list.item_w
	local h = (list.vert and item_wh) or list.item_h

	local mx, my = app:mousepos()

	if not app.active and app.lpressed and box.hit(mx, my, x, y, w, h) then
		app.active = list.id
		app.ui.dx = mx - x
		app.ui.dy = my - y
		app.ui.drag_item = item_index
		app.ui.drag_item_x = x
		app.ui.drag_item_y = y
		app.ui.drag_item_w = w
		app.ui.drag_item_h = h
	end


	if self.active == list.id or (self.active and self.ui.drag_item) then
		if self.lbutton then

			self.ui.drag_item_x = mx - self.ui.dx
			self.ui.drag_item_y = my - self.ui.dy

			if item_index == self.ui.drag_item then

				x = self.ui.drag_item_x
				y = self.ui.drag_item_y

			else
				if list.vert then

					if not self.ui.drop_index then
						if y + h / 2 > self.ui.drag_item_y
							and self.ui.drag_item_x + w > list.x
							and self.ui.drag_item_x < list.x + list.item_w
						then
							self.ui.drop_index = item_index - 1
							if self.ui.drag_item >= item_index then
								self.ui.drop_index = self.ui.drop_index + 1
							end

							y = y + self.ui.drag_item_h
						end
					end

				end

			end

		elseif self.active == list.id then
			if self.ui.drop_index then
				--
			end
			self.active = nil
			self.ui.drag_item = nil
		end
	end

	if item_index ~= self.ui.drag_item then
		if list.vert then
			list.item_y = y + h
		else
			list.item_x = x + w
		end
	end

	list.item_index = list.item_index + 1

	return x, y, w, h, self.ui.drop_index
end


if not ... then

local list1 = itemlist:new{item_h = 26, item_w = 100}

list1:add_item{}
list1:add_item{}
list1:add_item{}

function player:on_render(cr)
	--list1:
end

player:play()

end
