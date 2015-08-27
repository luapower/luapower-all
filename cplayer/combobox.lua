local player = require'cplayer'

function player:combobox(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local items, selected = t.items, t.selected
	local text = selected or 'pick...'

	local menu_h = 100

	local down = self.lbutton
	local hot = self:hotbox(x, y, w, h)

	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if hot and self.clicked then
			if not self.cmenu then
				local menu_id = id .. '_menu'
				self.cmenu = {id = menu_id, x = x, y = y + h, w = w, h = menu_h, items = items}
				self.active = nil
			else
				self.cmenu = nil
			end
		elseif not hot then
			self.active = nil
			self.cmenu = nil
		end
	end

	--drawing
	self:rect(x, y, w, h, 'faint_bg')
	self:textbox(x, y, w, h, text, t.font, 'normal_fg', 'left', 'center')

	return self.cmenu
end

if not ... then require'cplayer.widgets_demo' end

