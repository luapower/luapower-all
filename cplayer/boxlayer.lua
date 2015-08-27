--box layer stub to use as base class for rectangular layer objects.
local glue = require'glue'
local box = require'box2d'

local boxlayer = {}

function boxlayer:getbox()
	return self.x, self.y, self.w, self.h
end

function boxlayer:hit(x, y)
	return box.hit(x, y, self:getbox())
end

function boxlayer:render(cx)
	local x, y, w, h = self:getbox()
	cx:rect(x, y, w, h, self.color or 'normal_bg', nil)
end


if not ... then require'cplayer.layerlist_demo' end


return boxlayer
