
local nw = require'nw'
local vi = require'videoinput'
local bitmap = require'bitmap'

local app = nw:app()
local win = app:window{cw = 700, ch = 500, title = 'Press S to toggle session'}

for i,dev in ipairs(vi.devices()) do
	print(dev.isdefault and '*' or '', dev.id, dev.name)
end

local session = vi.open{}

function session:newframe(bmp)
	self._bitmap = bitmap.copy(bmp)
	win:invalidate()
end

function session:lastframe()
	return self._bitmap
end

function win:repaint()
	local src = session:lastframe()
	if not src then return end
	local dst = self:bitmap()
	dst:clear()
	bitmap.paint(dst, src, 10, 10)
end

function win:keydown(key)
	if key == 'S' then
		session:running(not session:running())
	end
end

session:start()

app:run()
