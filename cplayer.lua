--cairo player: procedural graphics player with immediate mode gui toolkit
local CairoPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.keyboard'
require'winapi.mouse'
require'winapi.time'
local cairo = require'cairo'
local ffi = require'ffi'
local glue = require'glue'
local layerlist = require'cplayer.layerlist'
local box = require'box2d'
local rmgui = require'cplayer.rmgui'

local player = {
	continuous_rendering = true,
	show_magnifier = true,
	triple_click_max_wait = 500,
}

--winapi keycodes. key codes for 0-9 and A-Z keys are ascii codes.
local keynames = {
	[0x08] = 'backspace',[0x09] = 'tab',      [0x0d] = 'enter',    [0x10] = 'shift',    [0x11] = 'ctrl',
	[0x12] = 'alt',      [0x13] = 'break',    [0x14] = 'capslock', [0x1b] = 'esc',      [0x20] = 'space',
	[0x21] = 'pageup',   [0x22] = 'pagedown', [0x23] = 'end',      [0x24] = 'home',     [0x25] = 'left',
	[0x26] = 'up',       [0x27] = 'right',    [0x28] = 'down',     [0x2c] = 'printscreen',
	[0x2d] = 'insert',   [0x2e] = 'delete',   [0x60] = 'numpad0',  [0x61] = 'numpad1',  [0x62] = 'numpad2',
	[0x63] = 'numpad3',  [0x64] = 'numpad4',  [0x65] = 'numpad5',  [0x66] = 'numpad6',  [0x67] = 'numpad7',
	[0x68] = 'numpad8',  [0x69] = 'numpad9',  [0x6a] = 'multiply', [0x6b] = 'add',      [0x6c] = 'separator',
	[0x6d] = 'subtract', [0x6e] = 'decimal',  [0x6f] = 'divide',   [0x70] = 'f1',       [0x71] = 'f2',
	[0x72] = 'f3',       [0x73] = 'f4',       [0x74] = 'f5',       [0x75] = 'f6',       [0x76] = 'f7',
	[0x77] = 'f8',       [0x78] = 'f9',       [0x79] = 'f10',      [0x7a] = 'f11',      [0x7b] = 'f12',
	[0x90] = 'numlock',  [0x91] = 'scrolllock',
	--varying by keyboard
	[0xba] = ';',        [0xbb] = '+',        [0xbc] = ',',        [0xbd] = '-',        [0xbe] = '.',
	[0xbf] = '/',        [0xc0] = '`',        [0xdb] = '[',        [0xdc] = '\\',       [0xdd] = ']',
	[0xde] = "'",
	--querying

}

local function keyname(vk)
	return
		(((vk >= string.byte'0' and vk <= string.byte'9') or
		(vk >= string.byte'A' and vk <= string.byte'Z'))
			and string.char(vk) or keynames[vk])
end

local keycodes = glue.index(keynames)

local function keycode(name)
	return keycodes[name] or string.byte(name)
end

local cursors = { --names are by function not shape when possible
	--pointers
	normal = winapi.IDC_ARROW,
	text = winapi.IDC_IBEAM,
	link = winapi.IDC_HAND,
	crosshair = winapi.IDC_CROSS,
	invalid = winapi.IDC_NO,
	--move and resize
	resize_nwse = winapi.IDC_SIZENWSE,
	resize_nesw = winapi.IDC_SIZENESW,
	resize_horizontal = winapi.IDC_SIZEWE,
	resize_vertical = winapi.IDC_SIZENS,
	move = winapi.IDC_SIZEALL,
	--app state
	busy = winapi.IDC_WAIT,
	background_busy = winapi.IDC_APPSTARTING,
}

local function set_cursor(name)
	winapi.SetCursor(winapi.LoadCursor(assert(cursors[name or 'normal'])))
end

local function fps_function()
	local count_per_sec = 2
	local frame_count, last_frame_count, last_time = 0, 0
	return function()
		last_time = last_time or winapi.GetTickCount()
		frame_count = frame_count + 1
		local time = winapi.GetTickCount()
		if time - last_time > 1000 / count_per_sec then
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

	local window

	if not t.parent then --player has no parent window, so we make a standalone window for it
		window = winapi.Window{
			--if the window is created from the player class then it's the main window
			autoquit = referer == player and true,
			visible = false,
			x = t.x or 100,
			y = t.y or 100,
			w = t.w or 1300,
			h = t.h or 700,
		}
	elseif type(t.parent) == 'table' then --parent is a winapi.Window object
		window = t.parent
	else --parent is a HWND (window handle): wrap it into a winapi.BaseWindow object
		window = winapi.BaseWindow{hwnd = t.parent}
	end

	local panel = CairoPanel{
		parent = window, w = window.client_w, h = window.client_h,
		anchors = {left=true, right=true, top=true, bottom=true},
	}

	self.window = window --needed by filebox
	self.panel = panel --needed by self.close

	--window state
	self.w = panel.client_w
	self.h = panel.client_h
	self.init = true --set to true only on the first frame

	--mouse state
	local pos = winapi.GetCursorPos()
	self.mousex = pos.x
	self.mousey = pos.y
	self.lbutton = bit.band(ffi.C.GetKeyState(winapi.VK_LBUTTON), 0x8000) ~= 0 --left mouse button pressed state
	self.rbutton = bit.band(ffi.C.GetKeyState(winapi.VK_RBUTTON), 0x8000) ~= 0 --right mouse button pressed state
	self.clicked = false       --left mouse button clicked (one-shot)
	self.rightclick = false    --right mouse button clicked (one-shot)
	self.doubleclicked = false --left mouse button double-clicked (one-shot)
	self.tripleclicked = false --left mouse button triple-clicked (one-shot)
	self.waiting_for_tripleclick = false --double-clicked and inside the wait period for triple-click
	self.wheel_delta = 0       --mouse wheel movement as number of scroll pages (one-shot)

	--keyboard state (no key pressed; TODO: get actual values from winapi)
	self.key = nil            --key pressed: key code (one-shot)
	self.char = nil           --key pressed: char code (one-shot)
	self.shift = false        --shift key pressed state (only if key ~= nil)
	self.ctrl = false         --ctrl key pressed state (only if key ~= nil)
	self.alt = false          --alt key pressed state (only if key ~= nil)

	--theme state
	self.theme = referer.theme or self.themes.dark

	--layout state
	self.layout = self.null_layout

	--widget state
	self.active = nil   --has mouse focus
	self.focused = nil  --has keyboard focus
	self.ui = {}        --state to be used by the active control. when changing self.active, its contents are undefined.

	--animation state
	self.stopwatches = {} --{[stopwatch] = stopwatch_object}

	--layers state
	self.layers = layerlist:new()
	self.current_layer = false

	--rmgui state
	self.rmgui = rmgui:new()

	--id cache state
	self.cache = setmetatable({}, {mode = 'kv'})

	--panel receives painting and mouse events

	local fps = fps_function()

	function panel.on_cairo_paint(panel, context)
		self.cr = context

		--set the window title
		local title = self.title or string.format('Cairo %s', cairo.version_string())
		if self.continuous_rendering then
			title = string.format('%s - %d fps', title, fps())
		end
		window.title = title

		--set the window state
		self.w = panel.client_w
		self.h = panel.client_h

		--reset the graphics context
		self.cr:reset_clip()
		self.cr:identity_matrix()

		--paint the background
		self:setcolor'window_bg'
		self.cr:paint()

		--set the wall clock
		self.clock = winapi.GetTickCount()

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
			self:magnifier{id = 'mag', x = self.mousex - 200, y = self.mousey - 100, w = 400, h = 200, zoom_level = 4}
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
		--[[
		self.shift = nil
		self.ctrl = nil
		self.alt = nil
		]]
		self.wheel_delta = 0

		--reset timed vars
		if self.triple_click_start_time then
			if self.clock - self.triple_click_start_time
					>= self.triple_click_max_wait
			then
				self.waiting_for_tripleclick = false
				self.triple_click_start_time = nil
			end
		end
	end

	function panel.on_mouse_move(panel, x, y, buttons)
		self.mousex = x
		self.mousey = y
		self.lbutton = buttons.lbutton
		self.rbutton = buttons.rbutton
		self.rmgui:update('mouse_move', x, y)
		panel:invalidate()
	end
	panel.on_mouse_over = panel.on_mouse_move
	panel.on_mouse_leave = panel.on_mouse_move

	function panel.on_lbutton_down(panel)
		winapi.SetCapture(panel.hwnd)
		if not self.lbutton then
			self.lpressed = true
		end
		self.lbutton = true
		self.clicked = false
		self.rmgui:update('mouse_lbutton_down')
		panel:invalidate()
	end

	function panel.on_lbutton_up()
		winapi.ReleaseCapture()
		self.lpressed = false
		self.lbutton = false
		self.clicked = true
		if self.triple_click_start_time then
			if not self.waiting_for_tripleclick then
				self.waiting_for_tripleclick = true
			elseif self.clock - self.triple_click_start_time
					< self.triple_click_max_wait
			then
				self.tripleclicked = true
				self.waiting_for_tripleclick = false
				self.triple_click_start_time = nil
			end
		end
		self.rmgui:update('mouse_lbutton_up')
		panel:invalidate()
	end

	function panel.on_rbutton_down()
		if not self.rbutton then
			self.rpressed = true
		end
		self.rbutton = true
		self.rightclick = false
		self.rmgui:update('mouse_rbutton_down')
		panel:invalidate()
	end

	function panel.on_rbutton_up()
		self.rpressed = false
		self.rbutton = false
		self.rightclick = true
		self.rmgui:update('mouse_rbutton_up')
		panel:invalidate()
	end

	function panel.on_lbutton_double_click()
		self.doubleclicked = true
		self.triple_click_start_time = self.clock
		panel:invalidate()
		self.rmgui:update('mouse_lbutton_double_click')
	end

	function panel.on_set_cursor(_, _, ht)
		if ht == winapi.HTCLIENT then --we set our own cursor on the client area
			set_cursor(self.cursor)
			return true
		else
			return false
		end
	end

	--window receives keyboard and mouse wheel events

	function window.on_close(window)
		self.rmgui:update('close')
		self:on_close()
	end

	function window.on_mouse_wheel(window, x, y, buttons, wheel_delta)
		self.wheel_delta = self.wheel_delta + (wheel_delta and wheel_delta / 120 or 0)
		self.rmgui:update('mouse_wheel', wheel_delta)
		panel:invalidate()
	end

	window.__wantallkeys = true --suppress TranslateMessage() that eats up our WM_CHARs

	function window:WM_GETDLGCODE()
		return winapi.DLGC_WANTALLKEYS
	end

	local function key_event(window, vk, flags, down)
		self.key = down and keyname(vk) or nil
		self.shift = bit.band(ffi.C.GetKeyState(winapi.VK_SHIFT), 0x8000) ~= 0
		self.ctrl = bit.band(ffi.C.GetKeyState(winapi.VK_CONTROL), 0x8000) ~= 0
		self.alt = bit.band(ffi.C.GetKeyState(winapi.VK_MENU), 0x8000) ~= 0
		self.rmgui:update(down and 'key_down' or 'key_up', self.key)
		panel:invalidate()
	end
	function window.on_key_down(window, vk, flags)
		key_event(window, vk, flags, true)
	end
	function window.on_key_up(window, vk, flags)
		key_event(window, vk, flags, false)
	end
	window.on_syskey_down = window.on_key_down
	window.on_syskey_up = window.on_key_up

	local function key_char_event(window, char, flags, down)
		if down then
			self.char = char
		else
			self.char = nil
		end
		self.rmgui:update(down and 'key_down' or 'key_up', self.char)
		panel:invalidate()
	end
	function window.on_key_down_char(window, char, flags)
		key_char_event(window, char, flags, true)
	end
	window.on_syskey_down_char = window.on_key_down_char
	function window.on_dead_key_up_char(window, char, flags)
		key_char_event(window, char, flags, false)
	end
	window.on_dead_syskey_down_char = window.on_key_down_char

	--set panel to render continuously
	panel:settimer(1,
		function()
			if self.continuous_rendering or next(self.stopwatches) then
				panel:invalidate()
			end
		end)

	window:show()

	return self
end

function player:invalidate()
	self.panel:invalidate()
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
	return bit.band(ffi.C.GetAsyncKeyState(keycode(keyname)), 0x8000) ~= 0
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
	self.main = self:window{on_render = self.on_render}
	return winapi.MessageLoop()
end

if not ... then require'cplayer.widgets_demo' end

return player
