local player = require'cplayer'
local glue = require'glue'

function player:on_render(cr)
	self.tab = self:tablist{id = 'tabs', x = 10, y = 10, w = 500, h = 24, item_w = 80,
									items = {'tab1', 'tab2', 'tab3'}, selected = self.tab}
end

player:play()
