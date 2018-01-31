local nw = require'nw'
local imgui = require'imgui_nw_cairo'
local fs = require'fs'
local glue = require'glue'

local app = nw:app()

--create a window and bind imgui to it ---------------------------------------

local x, y, w, h = app:active_display():desktop_rect()
local win = app:window{x = x, y = y, w = w / 2, h = h, title = 'Demo',
	visible = false, autoquit = true}

imgui:bind(win)

function imgui_demo_app(imgui)
	local app = require'imgui_demo_app'
	app(imgui)
end

function win:imgui_render()
	local ok, err = xpcall(imgui_demo_app, debug.traceback, self:imgui())
	if not ok then
		--show the stack trace on the screen rather than on the console
		local bmp = self:bitmap()
		local cr = bmp:cairo()
		cr:save()
		cr:identity_matrix()
		cr:move_to(10, 20)
		cr:font_face('Fixedsys')
		cr:font_size(12)
		cr:rgb(1, 1, 1)
		for s in glue.lines(err) do
			s = s:gsub('\t', '    ')
			local x, y = cr:current_point()
			cr:show_text(s)
			cr:move_to(x, y + 16)
		end
		cr:restore()
		print(err)
	end
end

--autoreload modules for fast development ------------------------------------

local function module_filepath(mod)
	return package.searchpath(mod, package.path)
	    or package.searchpath(mod, package.cpath)
end

local function reload_module(mod)
	local mod0 = package.loaded[mod]
	package.loaded[mod] = nil
	local ok, err = xpcall(require, debug.traceback, mod)
	if not ok then
		package.loaded[mod] = mod0
		show_error(err)
	end
	return ok, err
end

local function reload_module_func(mod, reload)
	local path = assert(module_filepath(mod))
	local last_mtime = fs.attr(path, 'mtime')
	return function()
		local mtime = fs.attr(path, 'mtime')
		if mtime <= last_mtime then return end
		last_mtime = mtime
		local ok = reload_module(mod)
		if ok and reload then
			reload()
		end
		return ok
	end
end

local reload_app = reload_module_func'imgui_demo_app'

app:runevery(0.1, function()
	if reload_app() then
		win:invalidate()
	end
end)

--show the window & start the app --------------------------------------------

win:show()
app:run()
