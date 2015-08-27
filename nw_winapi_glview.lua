--nw winapi backend for glview.
local nw = require'nw_winapi'
local glue = require'glue'
local winapi = require'winapi'
require'winapi.wglpanel'

local window = nw.app.window
local glview = glue.inherit({}, window.view)
window.glview = glview

function glview:_init(t)

	self.view = winapi.WGLPanel{
		x = t.x,
		y = t.y,
		w = t.w,
		h = t.h,
		visible = false,
		parent = self.window.win,
	}

	local frontend = self.frontend
	function self.view:on_render()
		frontend:_backend_render()
	end

	local gl = require'winapi.gl11'

	function self.view:set_viewport()
		--set default viewport
		local w, h = self.client_w, self.client_h
		gl.glViewport(0, 0, w, h)
		gl.glMatrixMode(gl.GL_PROJECTION)
		gl.glLoadIdentity()
		gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
		gl.glScaled(1, w/h, 1)
	end

	self.view:show()
end

function glview:free()
	self.view:free()
	self.view = nil
end

function glview:invalidate()
	self.view:invalidate()
end

function glview:rect()
	local r = self.view.rect
	return r.x, r.y, r.w, r.h
end

if not ... then require'nw_test' end
