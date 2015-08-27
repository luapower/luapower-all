local player = require'cplayer'
local box = require'box2d'

local function set_hierarchy(items)
	for i,item in ipairs(items) do
		item.index = i
		item.parent = items
	end
end

local function set_sizes(items)
	items._w = 0
	items._h = 0
	for i, item in ipairs(items) do
		if items.vert then
			item._w = math.max(items.min_w or 0, items.w or 0)
			item._h = math.max(item.min_h or 0, item.h or 0, items.min_h or 0, items.item_h or 0)
			items._h = items._h + item._h
			items._w = math.max(items._w, item._w)
		else
			item._h = math.max(items.min_h or 0, items.h or 0)
			item._w = math.max(item.min_w or 0, item.w or 0, items.min_w or 0, items.item_w or 0)
			items._w = items._w + item._w
			items._h = math.max(items._h, item._h)
		end
	end
end

local function set_layout(items)
	items._x = items.x
	items._y = items.y

	local x, y = items._x, items._y
	for i,item in ipairs(items) do
		item._x = x
		item._y = y
		if items.vert then
			y = y + item._h
		else
			x = x + item._w
		end
	end
end

local function set_all(items)
	set_hierarchy(items)
	set_sizes(items)
	set_layout(items)
end

local function remove_item(item)
	assert(item.parent[item.index] == item)
	table.remove(item.parent, item.index)
	set_layout(item.parent)
	item.parent = nil
	item.index = nil
end

local function insert_item(item, items, index)
	table.insert(items, index, item)
	set_layout(items)
end

local function set_drag_layout(items, drag_item, x, y)
	drag_item._x = x
	drag_item._y = y

	if drag_item.parent == items then
		for i = drag_item.index + 1, #items do
			local ditem = items[i]
			if items.vert then
				ditem._y = ditem._y - drag_item._h
			else
				ditem._x = ditem._x - drag_item._w
			end
		end
	end

	--make room for drag_item in layout and return the position where it should be inserted
	local drop_index
	for i,item in ipairs(items) do
		if item ~= drag_item then
			if items.vert then
				if not drop_index and item._y + item._h / 2 > drag_item._y
					and drag_item._x + drag_item._w > items._x and drag_item._x < items._x + items._w
				then
					drop_index = i-1
				end
				if drop_index then
					item._y = item._y + drag_item._h
				end
			else
				if not drop_index and item._x + item._w / 2 > drag_item._x
					and drag_item._y + items._h > items._y and drag_item._y < items._y + items._h
				then
					drop_index = i-1
				end
				if drop_index then
					item._x = item._x + drag_item._w
				end
			end
		end
	end
	return drop_index or #items + (drag_item.parent ~= items and 1 or 0)
end

local function move_item(item, items, i)
	assert(i >= 1 and i <= #items + (item.parent ~= items and 1 or 0))
	table.remove(item.parent, item.index)
	set_layout(item.parent)
	table.insert(items, i, item)
	set_layout(items)
end

local function item_box(item)
	return item._x, item._y, item._w, item._h
end

local function hit_test(mx, my, items)
	for i,item in ipairs(items) do
		if box.hit(mx, my, item_box(item)) then
			return item
		end
	end
end

function player:itemlist(items)
	local id = assert(items.id, 'id missing')
	local x, y, w, h = self:getbox(items)

	set_all(items)

	local mx, my = self:mousepos()
	if self.active == id or (self.active and self.ui.item) then
		if self.lbutton then
			self.ui.drop_index = set_drag_layout(items, self.ui.item, mx - self.ui.dx, my - self.ui.dy)
			self.ui.drop_itemlist = items
		elseif self.active == id then
			if self.ui.drop_index and self.ui.drop_itemlist == items then
				insert_item(self.ui.item, items, self.ui.drop_index)
				self:invalidate()
			end
			self.active = nil
			self.ui.item = nil
		end
	else
		local item = hit_test(mx, my, items)
		if item then
			self.cursor = 'link'
			if not self.active and self.lbutton then
				self.active = id
				self.ui.dx = mx - item._x
				self.ui.dy = my - item._y
				self.ui.item = item
				remove_item(item)
				self:invalidate()
			end
		end
	end

	for i,item in ipairs(items) do
		local x, y, w, h = item_box(item)
		self:rect(x, y, w, h, 'normal_bg', 'normal_fg')
	end

	if self.ui.item then
		local x, y, w, h = item_box(self.ui.item)
		self:rect(x, y, w, h, 'normal_bg', 'normal_fg')
	end
end


if not ... then

local player = require'cplayer'
local glue = require'glue'

local items = {
	id = 'items', x = 10, y = 10, w = 400, h = 40,
	vert = false,
	{w = 50, h = 100},
	{w = 100, h = 50},
	{w = 20, h = 100},
	{w = 70, h = 20},
	{w = 50, h = 100},
}

local items2 = {
	id = 'items2', x = 500, y = 10, w = 400, h = 400,
	vert = true,
	{w = 50, h = 100},
	{w = 100, h = 50},
	{w = 20, h = 100},
	{w = 70, h = 20},
	{w = 50, h = 100},
}

player.continuous_rendering = false

function player:on_render(cr)

	cr:translate(0.5, 0.5)

	self:itemlist(items)
	self:itemlist(items2)

end

player:play()

end

