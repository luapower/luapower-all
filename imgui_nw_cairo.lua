
--imgui nw+cairo driver.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'imgui_demo'; return end

local imgui = require'imgui'
local nw = require'nw'
local cairo = require'cairo'
local freetype = require'freetype'
local time = require'time'
local gfonts = require'gfonts'

local imgui_nw_cairo = {}

local app = nw:app()
local ft = freetype:new()

function imgui_nw_cairo:bind(win, imgui_class)

	local imgui = (imgui_class or imgui):new()

	function imgui:window()
		return win
	end

	function win:imgui()
		return imgui
	end

	function imgui:unbind()
		win:off'.imgui'
		win.imgui = nil
	end

	function imgui:_backend_clock()
		return time.clock()
	end

	function imgui:_backend_mouse_state()
		return
			win:mouse'x',
			win:mouse'y',
			win:mouse'left',
			win:mouse'right'
	end

	function imgui:_backend_key_state(keyname)
		return app:key(keyname)
	end

	function imgui:_backend_client_size()
		return win:client_size()
	end

	function imgui:_backend_set_title(title)
		win:title(title)
	end

	function imgui:_backend_set_cursor(cursor)
		win:cursor(cursor or 'arrow')
	end

	function imgui:_backend_render_frame()
		win:fire('imgui_render', imgui)
	end

	win:on('repaint.imgui', function(self)
		local bmp = self:bitmap()
		local cr = bmp:cairo()
		imgui:_backend_repaint(cr)
	end)

	--stub file-finding implementation based on gfonts module
	function win:imgui_find_font_file(name, weight, slant)
		return gfonts.font_file(name, weight, slant)
		--local file = string.format('media/fonts/%s.ttf', name)
	end

	local font_cache = {} --{name -> face}
	local cur_id, cur_face

	function imgui:_backend_load_font(name, weight, slant)
		if not name then
			self.cr:font_face(cairo.NULL)
			cur_id, cur_face = nil
			return
		end
		local id =
			name:lower() .. '|' ..
			tostring(weight):lower() .. '|'
			.. slant:lower()
		if cur_id == id then
			return
		end
		local face = font_cache[id]
		if face == nil then
			local file = win:imgui_find_font_file(name, weight, slant)
			if file then
				local ft_face = ft:face(file)
				face = cairo.ft_font_face(ft_face) -- TODO: weight, slant
				font_cache[id] = face
			else
				font_cache[id] = false
			end
		end
		if face then
			self.cr:font_face(face)
			cur_id, cur_face = id, face
		end
	end

	function imgui:_backend_invalidate()
		win:invalidate()
	end

	function imgui:_backend_layer_surface()
		return cairo.recording_surface'color_alpha'
	end

	local function bind_event(name)
		win:on(name .. '.imgui', function(self, ...)
			imgui:_backend_event(name, ...)
		end)
	end
	bind_event'mousemove'
	bind_event'mouseenter'
	bind_event'mouseleave'
	bind_event'mousedown'
	bind_event'mouseup'
	bind_event'mousewheel'
	bind_event'keydown'
	bind_event'keyup'
	bind_event'keypress'
	bind_event'keychar'

	win:on('click.imgui', function(self, button, count, x, y)
		if count == 2 then
			imgui:_backend_event('doubleclick', button, x, y)
			if not imgui.tripleclicks then
				return true
			end
		elseif count == 3 then
			imgui:_backend_event('tripleclick', button, x, y)
			return true
		end
	end)

	app:runevery(0, function()
		if imgui.continuous_rendering or next(imgui.stopwatches) then
			win:invalidate()
		end
	end)

	return imgui
end

function imgui_nw_cairo:unbind(win)
	win:imgui():unbind()
end

return imgui_nw_cairo
