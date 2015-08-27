
--nw xcb backend for glview.
--Written By Cosmin Apreutesei. Public Domain.

if not ... then require'nw_test' end

local nw = require'nw_xcb'
local glue = require'glue'

local window = nw.app.window
local glview = glue.inherit({}, window.view)
window.glview = glview

function glview:_init(t)
end

function glview:free()
end

function glview:invalidate()
end

function glview:rect()
	return 0, 0, 0, 0
end
