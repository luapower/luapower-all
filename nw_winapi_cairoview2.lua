--nw winapi backend for cairoview.
local nw = require'nw_winapi'
local glue = require'glue'
local winapi = require'winapi'
local cairo = require'cairo'
require'winapi.cairopanel2'

local window = nw.app.window
local cairoview = glue.inherit({}, window.view)
window.cairoview2 = cairoview

function cairoview:_init(t)

	self.view = winapi.CairoPanel{
		x = t.x,
		y = t.y,
		w = t.w,
		h = t.h,
		visible = true,
		parent = self.window.win,
	}

	local frontend = self.frontend
	function self.view:on_render(cr)
		cr:set_operator(cairo.CAIRO_OPERATOR_SOURCE)
		cr:set_source_rgba(0, 0, 0, 0)
		cr:paint()
		frontend:_backend_render(cr)
	end

end

function cairoview:free()
	self.view:free()
	self.view = nil
end

function cairoview:invalidate()
	self.view:invalidate()
end

function cairoview:rect()
	local r = self.view.rect
	return r.x, r.y, r.w, r.h
end


if not ... then require'nw_test' end
