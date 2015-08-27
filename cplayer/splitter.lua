local player = require'cplayer'

local function splitter(self, t, vertical)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)

	local hot = (not self.active or self.active ~= id) and self:hotbox(x, y, w, h)

	if (not self.active and hot) or self.active == id then
		self.cursor = 'resize_horizontal'
	end

	if not self.active and self.lbutton and hot then
		self.active = id
		self.ui.grab = vertical and self.mousex - x or self.mousey - y
	elseif self.active == id then
		if self.lbutton then
			if vertical then
				x = self.mousex - self.ui.grab
			else
				y = self.mousey - self.ui.grab
			end
		else
			self.active = nil
		end
	end

	self:rect(x, y, w, h)

	return vertical and x or y
end

function player:vsplitter(t)
	splitter(self, t, true)
end

function player:hsplitter(t)
	splitter(self, t, false)
end

if not ... then require'cplayer.widgets_demo' end

