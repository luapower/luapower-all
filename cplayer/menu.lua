local player = require'cplayer'

function player:menu(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local items = t.items
	local item_h = t.item_h or 22
	local selected = t.selected

	local clicked
	for i,item in ipairs(items) do
		if self:button{id = id..'_'..item, x = x, y = y, w = w, h = item_h,
								text = item, cut = 'both', selected = selected == item}
		then
			selected = item
			clicked = true
		end
		y = y + item_h
	end
	return selected, clicked
end

if not ... then require'cplayer.widgets_demo' end

