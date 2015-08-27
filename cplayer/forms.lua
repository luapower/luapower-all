local player = require'cplayer'

function player:form(form)
	for i, widget in ipairs(form) do
		self[widget.type](self, widget)
	end
end


if not ... then

local form = {
	{type = 'button', id = 'OK', x = 10, y = 10, w = 60, h = 20},
	{type = 'toolbox', id = 'toolbox', x = 10, y = 40, w = 200, h = 200,
		contents = function(self)
			self:button{id = 'Cancel', x = 10.5, y = 10.5, w = 60, h = 20}
		end,
	},
}

function player:on_render(cr)
	self:form(form)
end

player:play()

end
