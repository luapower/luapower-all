local glue = require'glue'
local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.wglpanel'
local GLSG = require'sg_gl'
require'sg_gl_shape'
require'sg_gl_obj'
require'sg_gl_debug'

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

local obj_model = {type = 'obj_model', y = 0, scale = .003,
	file = {use_cache = false, path = 'media/obj/lancer/lancer.obj'}}
local axes = {type = 'axes'}
local cube = {type = 'cube'}
local scene = {type = 'group', z = -2, scale = 1, obj_model}

local view1 = {
	type = 'viewport',
	x = 0, y = 0, w = 400, h = 300,
	frustum = {x2 = 0, far = 5},
	scene = scene,
}

local view2 = {
	type = 'viewport',
	x = 420, y = 0, w = 400, h = 300,
	frustum = {x1 = 0, far = 5},
	scene = scene,
}

local view3 = {
	type = 'viewport',
	x = 640, y = 0, w = 700, h = 700,
	frustum = {near = 1, far = 5},
	scene = scene,
}

local view4 = {
	type = 'viewport',
	x = 840, y = 750, w = 400, h = 300,
	scene = {
		type = 'group',
		--{type = 'frustum', view = view1},
		--{type = 'frustum', view = view2},
		{type = 'frustum', view = view3},
		scene,
	}
}

local scenes = {
	type = 'group',
	view1,
	view2,
	view3,
	view4,
}

local rx, ry = 0, 0
local mpressed, mx, my
function panel:on_lbutton_down(x, y, buttons)
	mpressed, mx, my = true, x - rx, y - ry
end

function panel:on_lbutton_up(x, y, buttons)
	mpressed = false
end

function panel:on_mouse_move(x, y, buttons)
	if mpressed then
		rx = self.cursor_pos.x - mx
		ry = self.cursor_pos.y - my
	end
end

local last_time
local function timediff()
	local ffi = require'ffi'
	ffi.cdef'long clock(void);'
	local time = ffi.C.clock() / 1000
	local delta = time - (last_time or 0)
	last_time = time
	return delta
end

function panel:on_render()
	timediff()
	view3.camera = {eye = {0,0,0}, center = {0,0,-1}, up = {0,1,0}, rz = -2,
							ax = ry, ay = rx, az = 0}
	view4.camera = {eye = {2,2,2}, center = {0,0,-1}, up = {0,1,0}, az = 0}
	self.sg:render(scenes)
	--print('render', timediff())
end

--print('start', timediff())
main:init()

os.exit(winapi.MessageLoop())

