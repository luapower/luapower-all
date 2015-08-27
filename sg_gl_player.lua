local glue = require'glue'
local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.wglpanel'

local GLSG = require'sg_gl'
require'sg_gl_mesh'
require'sg_gl_obj'

local function init()
	local main = winapi.Window{
		autoquit = true,
		visible = false,
	}

	local panel = winapi.WGLPanel{
		anchors = {left = true, top = true, right = true, bottom = true},
		visible = false,
	}

	function main:init()
		panel.w = self.client_w
		panel.h = self.client_h
		panel.parent = self
		panel:init(self)
		panel.visible = true
		self.visible = true
		panel:settimer(1/60, panel.invalidate)
	end

	function panel:init()
		self.sg = GLSG:new()
	end

	function panel:on_destroy()
		self.sg:free()
	end

	function panel:on_render()
		viewport.w = self.client_w
		viewport.h = self.client_h
		--viewport.camera = {eye = {0,0,0}, center = {0,0,-1}, up = {0,1,0}, rz = -2,
		--							ax = r + self.cursor_pos.y, ay = r, az = 0 + self.cursor_pos.x}
		self.sg:render(viewport)
	end

end

local viewport = {
	type = 'viewport',
	x = 0, y = 0, w = 1000, h = 1000,
	scene = {
		type = 'group', z = -2,
	}
}

local player = {}

function player:play()
	init()
	os.exit(winapi.MessageLoop())
end

return player

