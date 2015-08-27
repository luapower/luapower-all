--nw winapi backend for cairoview.
local nw = require'nw_winapi'
local glue = require'glue'
local winapi = require'winapi'
local cairo = require'cairo'
require'winapi.cairopanel2'

local window = nw.app.window
local cairoview = glue.inherit({}, window.view)
window.cairoview2 = cairoview

local default_anchors = {left = true, top = true, right = true, bottom = true}

function cairoview:_init(t)

	self._panel = winapi.CairoPanel{
		x = t.x,
		y = t.y,
		w = t.w,
		h = t.h,
		visible = true,
		parent = self.window.win,
		anchors = glue.update(default_anchors, t.anchors),
	}

	local cr

	function self._panel:__create_surface(surface)
		cr = surface:create_context()
	end

	function self._panel:__destroy_surface(surface)
		cr:free()
		cr = nil
	end

	function self._panel.on_render(panel, surface)
		cr:set_operator(cairo.CAIRO_OPERATOR_SOURCE)
		cr:set_source_rgba(0, 0, 0, 0)
		cr:paint()
		self.frontend:_backend_render(cr)
	end

end

function cairoview:free()
	self._panel:free()
	self._panel = nil
end

function cairoview:invalidate()
	self._panel:invalidate()
end

function cairoview:rect()
	local r = self._panel.rect
	return r.x, r.y, r.w, r.h
end


if not ... then require'nw_test' end
