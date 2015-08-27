--nw winapi backend for cairoview.
local nw = require'nw_winapi'
local ffi = require'ffi'
local glue = require'glue'
local winapi = require'winapi'
local cairo = require'cairo'

local window = nw.app.window
local cairoview = glue.inherit({}, window.view)
window.cairoview = cairoview

function cairoview:_create_surface(x, y, w, h)
	--create a pixman surface on the window's backbuffer.
	local bb = self.window:backbuffer()

	local data = ffi.cast('uint8_t*', bb.data) + (y * bb.w + x) * 4
	local stride = bb.w * 4

	assert(not self.pixman_cr)

	self.pixman_surface = cairo.cairo_image_surface_create_for_data(data,
									cairo.CAIRO_FORMAT_ARGB32, w, h, stride)

	self.pixman_cr = self.pixman_surface:create_context()

	self.clear_cr = self.pixman_surface:create_context()
	self.clear_cr:set_operator(cairo.CAIRO_OPERATOR_SOURCE)
	self.clear_cr:set_source_rgba(0, 0, 0, 0)
end

function cairoview:release_backbuffer()
	self.clear_cr = self.clear_cr:free()
	self.pixman_cr = self.pixman_cr:free()
	self.pixman_surface = self.pixman_surface:free()
end

function cairoview:_init(t)
	self.x = t.x
	self.y = t.y
	self.w = t.w
	self.h = t.h
	self:_create_surface(t.x, t.y, t.w, t.h)
end

function cairoview:free()
	self:release_backbuffer()
end

function cairoview:invalidate()
	--ask the window backend to invalidate this view and any overlapping views.
	self.window:invalidate_view(self.frontend)
	self.window:redraw()
end

function cairoview:redraw()
	if not self.pixman_cr then
		self:_create_surface()
	end
	self.frontend:_backend_render(self.pixman_cr)
end

function cairoview:clear()
	self.clear_cr:paint()
end

function cairoview:rect()
	return self.x, self.y, self.w, self.h
end

function cairoview:resize(x, y, w, h)
	self:release_backbuffer()
	self:_create_surface(x, y, w, h)
end

function cairoview:set_zorder(zorder)
	--
end


if not ... then require'nw_test' end
