--layer list for decoupling paint order from call order in IMGUIs.
--any widget that implements hit() and render() is a layer, and can be added
--to a layer list so it can be painted in z-order, as opposed to the normal
--call-order.

local list = {}

function list:new()
	return setmetatable({}, {__index = self})
end

function list:clear()
	while #self > 0 do
		self[#self] = nil
	end
end

function list:add(layer, z_order)
	z_order = z_order or 0
	local index = #self - z_order + 1
	index = math.min(math.max(index, 1), #self + 1)
	table.insert(self, index, layer)
end

function list:indexof(layer)
	for i,layer1 in ipairs(self) do
		if layer1 == layer then
			return i
		end
	end
end

function list:remove(layer)
	table.remove(self, self:indexof(layer))
end

function list:bring_to_front(layer)
	self:remove(layer)
	self:add(layer)
end

function list:send_to_back(layer)
	self:remove(layer)
	self:add(layer, 1/0)
end

function list:render(cx)
	for i,layer in ipairs(self) do
		layer:render(cx)
	end
end

function list:hit(x, y) --hit any layer
	for i = #self, 1, -1 do
		local layer = self[i]
		if layer:hit(x, y) then
			return layer
		end
	end
end

function list:hit_layer(x, y, target_layer) --hit a particular layer
	if not target_layer then
		return not self:hit(x, y)
	end
	for i = #self, 1, -1 do
		local layer = self[i]
		if layer == target_layer then
			return target_layer:hit(x, y)
		elseif layer:hit(x, y) then
			return false
		end
	end
end


if not ... then require'cplayer.layerlist_demo' end


return list
