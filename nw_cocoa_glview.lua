--nw cocoa backend for glview.
local nw = require'nw_cocoa'
local ffi = require'ffi'
local glue = require'glue'
local objc = require'objc'
objc.load'OpenGL'

local function unpack_nsrect(r)
	return r.origin.x, r.origin.y, r.size.width, r.size.height
end

local window = nw.app.window
local glview = glue.inherit({}, window.view)
window.glview = glview

local GLView = objc.class('GLView', 'NSOpenGLView')

function GLView.drawRect(cpu)
	local self
	if ffi.arch == 'x64' then
		self = ffi.cast('id', cpu.RDI.p) --RDI = self
	else
		self = ffi.cast('id', cpu.ESP.dp[1].p) --ESP[1] = self
	end
	self.nw_backend:_draw()
end

--convert rect from bottom-up to top-down
function glview:_flip_rect(x, y, w, h)
	local parent_h = select(4, self.window.frontend:client_rect())
	return x, parent_h - h - y, w, h
end

function glview:rect()
	return self:_flip_rect(unpack_nsrect(self.nsview:bounds()))
end


function glview:invalidate()
	self.nsview:setNeedsDisplay(true)
end

function glview:_create_surface()
	if self.pixels then return end
	self.pixels = true
end

function glview:_free_surface()
	if not self.pixels then return end

	self.pixels = nil
end

function glview:_draw()
	self:_create_surface()
	if not self.pixels then return end
	self.frontend:_backend_render()
	self.nsview:openGLContext():flushBuffer()
end


if not ... then require'nw_test' end
