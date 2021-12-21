--draw a checkerboard to see transparent stuff over
local player = require'cplayer'

function player:checkerboard(sz)
	local cr = self.cr
	local w = self.w
	local h = self.h
	sz = sz or 30
	for y=0,h/sz do
		for x=0,w/sz do
			cr:rectangle(x * sz, y * sz, sz, sz)
			cr:rgba(.5, .5, .5, 0.2 * ((x + y % 2) % 2))
			cr:fill()
		end
	end
end

