
--cairo player: cross-platform procedural graphics
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'cplayer.widgets_demo'; return end

local nw = require'nw'
local cairo = require'cairo'
local glue = require'glue'
local box = require'box2d'
local layerlist = require'cplayer.layerlist'
local rmgui = require'cplayer.rmgui'
local time = require'time'

local player = {
	continuous_rendering = true,
	show_magnifier = true,
	tripleclicks = false,
}

local function fps_function()
	local count_per_sec = 2
	local frame_count, last_frame_count, last_time = 0, 0
	return function()
		last_time = last_time or time.clock()
		frame_count = frame_count + 1
		local time = time.clock()
		if time - last_time > 1 / count_per_sec then
			last_frame_count, frame_count = frame_count, 0
			last_time = time
		end
		return last_frame_count * count_per_sec
	end
end

function player:on_close() end --stub

function player:window(t)

	local referer = self
	local self = glue.inherit({}, player)

	local window = nw:app():window{
		autoquit = referer == player and true,
		visible = false,
		x = t.x or 100,
		y = t.y or 100,
		w = t.w or 1300,
		h = t.h or 700,
	}

	self.window = window --needed by filebox

	--window state
	self.w, self.h = window:client_size()
	self.init = true --set to true only on the first frame

	--mouse state
	self.mousex = window:mouse'x' or 0
	self.mousey = window:mouse'y' or 0
	self.lbutton = window:mouse'left'
	self.rbutton = window:mouse'right'
	self.clicked = false       --left mouse button clicked (one-shot)
	self.rightclick = false    --right mouse button clicked (one-shot)
	self.doubleclicked = false --left mouse button double-clicked (one-shot)
	self.tripleclicked = false --left mouse button triple-clicked (one-shot)
	self.wheel_delta = 0       --mouse wheel number of scroll pages (one-shot)

	--keyboard state
	self.key = nil
	self.char = nil
	self.shift = false
	self.ctrl = false
	self.alt = false

	--theme state
	self.theme = referer.theme or self.themes.dark

	--layout state
	self.layout = self.null_layout

	--widget state
	self.active = nil   --has mouse focus
	self.focused = nil  --has keyboard focus
	self.ui = {}        --state to be used by the 	 control.

	--animation state
	self.stopwatches = {} --{[stopwatch] = stopwatch_object}

	--layers state
	self.layers = layerlist:new()
	self.current_layer = false

	--rmgui state
	self.rmgui = rmgui:new()

	--id cache state
	self.cache = setmetatable({}, {mode = 'kv'})

	local fps = fps_function()

	function window.repaint(window)

		local bmp = window:bitmap()
		local cr = bmp:cairo()

		self.cr = cr

		--set the window title
		local title = self.title
			or string.format('Cairo %s', cairo.version_string())
		if self.continuous_rendering then
			title = string.format('%s - %d fps', title, fps())
		end
		window:title(title)

		--set the window state
		self.w, self.h = window:client_size()

		--reset the graphics context
		self.cr:reset_clip()
		self.cr:identity_matrix()

		--paint the background
		self:setcolor'window_bg'
		self.cr:paint()

		--set the clock
		self.clock = time.clock()

		--clear the cursor state
		self.cursor = nil

		--remove completed stopwatches
		for t in pairs(self.stopwatches) do
			if t:finished() then
				self.stopwatches[t] = nil
			end
		end

		--render the frame
		self:on_render(self.cr)

		window:cursor(self.cursor or 'arrow')

		--render any user-added layers and clear the list
		self.cr:identity_matrix()
		self.cr:reset_clip()
		for i,layer in ipairs(self.layers) do
			self.current_layer = layer
			layer:render(self)
		end
		self.layers:clear()
		self.current_layer = false

		--render the rmgui
		self.rmgui:render(self)

		--magnifier glass: so useful it's enabled by default
		if self.show_magnifier and self:keypressed'ctrl' then
			self.cr:identity_matrix()
			self:magnifier{
				id = 'mag',
				x = self.mousex - 200,
				y = self.mousey - 100,
				w = 400,
				h = 200,
				zoom_level = 4,
			}
		end

		--reset the one-shot init trigger
		self.init = false

		--reset the one-shot state vars
		self.lpressed = false
		self.rpressed = false
		self.clicked = false
		self.rightclick = false
		self.doubleclicked = false
		self.tripleclicked = false
		self.key = nil
		self.char = nil
		self.wheel_delta = 0
	end

	function window.mousemove(window, x, y)
		self.mousex = x
		self.mousey = y
		self.lbutton = window:mouse'left'
		self.rbutton = window:mouse'right'
		self.rmgui:update('mouse_move', x, y)
		window:invalidate()
	end
	window.mouseenter = window.mousemove

	function window.mouseleave(window)
		window:invalidate()
	end

	function window.mousedown(window, button, x, y)
		if button == 'left' then
			if not self.lbutton then
				self.lpressed = true
			end
			self.lbutton = true
			self.clicked = false
			self.rmgui:update('mouse_lbutton_down')
			window:invalidate()
		elseif button == 'right' then
			if not self.rbutton then
				self.rpressed = true
			end
			self.rbutton = true
			self.rightclick = false
			self.rmgui:update('mouse_rbutton_down')
			window:invalidate()
		end
	end

	function window.mouseup(window, button, x, y)
		if button == 'left' then
			self.lpressed = false
			self.lbutton = false
			self.clicked = true
			self.rmgui:update('mouse_lbutton_up')
			window:invalidate()
		elseif button == 'right' then
			self.rpressed = false
			self.rbutton = false
			self.rightclick = true
			self.rmgui:update('mouse_rbutton_up')
			window:invalidate()
		end
	end

	function window.click(window, button, count, x, y)
		if count == 2 then
			self.doubleclicked = true
			window:invalidate()
			self.rmgui:update('mouse_lbutton_double_click')
			if not self.tripleclicks then
				return true
			end
		elseif count == 3 then
			self.tripleclicked = true
			window:invalidate()
			self.rmgui:update('mouse_lbutton_tripple_click')
			return true
		end
	end

	--window receives keyboard and mouse wheel events

	function window.closed(window)
		self.rmgui:update('close')
		self:on_close()
	end

	function window.mousewheel(window, delta, x, y)
		self.wheel_delta = self.wheel_delta + (delta / 120 or 0)
		self.rmgui:update('mouse_wheel', delta)
		window:invalidate()
	end

	local function key_event(window, key, down)
		self.key = down and key or nil
		self.shift = nw:app():key'shift'
		self.ctrl = nw:app():key'ctrl'
		self.alt = nw:app():key'alt'
		self.rmgui:update(down and 'key_down' or 'key_up', key)
		window:invalidate()
	end
	function window.keydown(window, key)
		key_event(window, key, true)
	end
	function window.keyup(window, key)
		key_event(window, key, false)
	end
	function window.keypress(window, key)
		key_event(window, key, true)
	end

	local function key_char_event(window, char, down)
		self.char = down and char or nil
		self.rmgui:update(down and 'key_down' or 'key_up', char)
		window:invalidate()
	end
	function window.keychar(window, char)
		key_char_event(window, char, true)
	end

	nw:app():runevery(0, function()
		if self.continuous_rendering or next(self.stopwatches) then
			window:invalidate()
		end
	end)

	window:show()

	return self
end

function player:invalidate()
	self.window:invalidate()
end

--layout api

function player:getbox(t)
	return self.layout:getbox(t)
end

--null layout

--a null layout is a stateless layout that requires all box coordinates
--to be specified.
player.null_layout = {}

function player.null_layout:getbox(t)
	return
		assert(t.x, 'x missing'),
		assert(t.y, 'y missing'),
		assert(t.w, 'w missing'),
		assert(t.h, 'h missing')
end

--mouse helpers

function player:mousepos()
	return self.cr:device_to_user(self.mousex, self.mousey)
end

function player:hotbox(x, y, w, h)
	local mx, my = self:mousepos()
	return
		box.hit(mx, my, x, y, w, h)
		and self.cr:in_clip(mx, my)
		and self.layers:hit_layer(mx, my, self.current_layer)
end

--keyboard helpers

function player:keypressed(keyname)
	return nw:app():key(keyname)
end

--animation helpers

local stopwatch = {}

function player:stopwatch(duration, formula)
	local t = glue.inherit({player = self, start = self.clock,
		duration = duration, formula = formula}, stopwatch)
	self.stopwatches[t] = true
	return t
end

function stopwatch:finished()
	return self.player.clock - self.start > self.duration
end

function stopwatch:progress()
	if self.formula then
		local easing = require'easing'
		return math.min(easing[formula]((self.player.clock - self.start), 0, 1, self.duration), 1)
	else
		return math.min((self.player.clock - self.start) / self.duration, 1)
	end
end

--submodule autoloader

glue.autoload(player, {
	--themes
	themes       = 'cplayer.theme',
	parse_color  = 'cplayer.theme',
	setcolor     = 'cplayer.theme',
	parse_font   = 'cplayer.theme',
	setfont      = 'cplayer.theme',
	save_theme   = 'cplayer.theme',
	fill         = 'cplayer.theme',
	stroke       = 'cplayer.theme',
	fillstroke	 = 'cplayer.theme',
   --basic shapes & text
	dot          = 'cplayer.theme',
	rect         = 'cplayer.theme',
	circle       = 'cplayer.theme',
	line         = 'cplayer.theme',
	curve        = 'cplayer.theme',
   text         = 'cplayer.text',
	textbox      = 'cplayer.text',
	--basic widgets
	vscrollbar   = 'cplayer.scrollbars',
	hscrollbar   = 'cplayer.scrollbars',
	scrollbox    = 'cplayer.scrollbars',
	vsplitter    = 'cplayer.splitter',
	hsplitter    = 'cplayer.splitter',
	button       = 'cplayer.buttons',
	mbutton      = 'cplayer.buttons',
	togglebutton = 'cplayer.buttons',
	slider       = 'cplayer.slider',
	menu         = 'cplayer.menu',
	editbox      = 'cplayer.editbox',
	combobox     = 'cplayer.combobox',
	filebox      = 'cplayer.filebox',
	image        = 'cplayer.image',
	label        = 'cplayer.label',
	dragpoint    = 'cplayer.dragpoint',
	dragpoints   = 'cplayer.dragpoint',
	tablist      = 'cplayer.tablist',
	magnifier    = 'cplayer.magnifier',
	analog_clock = 'cplayer.analog_clock',
	hue_wheel    = 'cplayer.hue_wheel',
	sat_lum_square = 'cplayer.sat_lum_square',
	toolbox      = 'cplayer.toolbox',
	screen       = 'cplayer.screen',
	checkerboard = 'cplayer.checkerboard',
	--complex widgets
	code_editor  = 'cplayer.code_editor',
	grid         = 'cplayer.grid',
	treeview     = 'cplayer.treeview',
})

--main loop

function player:play(...)
	if ... then --player loaded as module, return it instead of running it
		return player
	end
	self.main = self:window{
		on_render = self.on_render,
		x = self.x,
		y = self.y,
		w = self.w,
		h = self.h,
	}
	return nw:app():run()
end

return player
