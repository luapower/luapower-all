--nw winapi backend for glview.
local nw = require'nw_winapi'
local glue = require'glue'
local winapi = require'winapi'
require'winapi.wglpanel'
local gl = require'winapi.gl11'

local window = nw.app.window
local glview = glue.inherit({}, window.view)
window.glview = glview

function glview:_init(t)

	self.panel = winapi.WGLPanel{
		x = t.x,
		y = t.y,
		w = t.w,
		h = t.h,
		visible = false,
		parent = self.window.win,
		anc = t.anchors,
	}

	local frontend = self.frontend
	function self.panel:on_render()
		frontend:_backend_render()
	end

	function self.panel:on_set_viewport()
		--set default viewport
		local w, h = self.client_w, self.client_h
		gl.glViewport(0, 0, w, h)
		gl.glMatrixMode(gl.GL_PROJECTION)
		gl.glLoadIdentity()
		gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
		gl.glScaled(1, w/h, 1)
	end

	self.panel:show()
end

