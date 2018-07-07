local glue = require'glue'
local view = require'grid_view'

local grid = {
	--subclasses
	view = view,
}

function grid:new(t)
	self = glue.inherit(t, self)
	self.view = self.view:new(t.view, self)
	return self
end

return grid

