--go@ bin/mingw32/luajit -e io.stdout:setvbuf'no';io.stderr:setvbuf'no';require'strict';pp=require'pp' *

setfenv(1, require'winapi')
require'winapi.windowclass'
require'winapi.menuclass'
require'winapi.buttonclass'
require'winapi.toolbarclass'
require'winapi.groupboxclass'
require'winapi.checkboxclass'
require'winapi.radiobuttonclass'
require'winapi.editclass'
require'winapi.tabcontrolclass'
require'winapi.monitor'
require'winapi.cursor'
require'winapi.bitmappanel'
require'winapi.listboxclass'
local have_wgl   = pcall(require, 'winapi.wglpanel')
local have_cairo = pcall(require, 'winapi.cairopanel')

--get the monitor where the mouse is right now. ------------------------------

local mon = MonitorFromPoint(GetCursorPos(), MONITOR_DEFAULTTONEAREST)
local moninfo = GetMonitorInfo(mon)

--create the main window -----------------------------------------------------

local w, h = 600, 700
local win = Window{
	x = (moninfo.work_rect.w - w) / 2, --center the window on the monitor
	y = (moninfo.work_rect.h - h) / 2,
	w = w,
	h = h,
	title = (' '):rep(50)..' ┬┴┬┴┤ Lua Rulez ├┬┴┬┴',
	autoquit = true, --quit the app when the window is closed
}

--create and show an about box -----------------------------------------------

local function about_box()

	local w, h = 300, 200
	local aboutwin = Window{
		x = win.x + (win.w - w) / 2, --center the window on its parent
		y = win.y + (win.h - h) / 2,
		w = 300,
		h = 200,
		title = 'About winapi',
		maximizable = false,
		minimizable = false,
		resizeable = false,
		owner = win, --don't show it in taskbar
		tool_window = true,
	}

	local w, h = 100, 24
	local okbtn = Button{
		x = (aboutwin.client_w - w) / 2,
		y = aboutwin.client_h * 5/6 - h,
		parent = aboutwin,
		default = true, --respond to pressing Enter
	}

	--make it modal
	function okbtn:on_click()
		aboutwin:close()
	end
	function aboutwin:on_close()
		win:enable()
	end
	aboutwin.__wantallkeys = true --give us the ESC key!
	function okbtn:on_key_down(vk)
		if vk == VK_ESCAPE then
			aboutwin:close()
		end
	end
	win:disable()

	okbtn:focus()
end

--create menus for the main menu bar -----------------------------------------

local filemenu = Menu{
	items = {
		{text = '&Close', on_click = function() win:close() end},
	},
}

local aboutmenu = Menu{
	items = {
		{text = '&About', on_click = about_box},
	},
}

--create the main menu bar ---------------------------------------------------

local menubar = MenuBar()
menubar.items:add{text = '&File', submenu = filemenu}
menubar.items:add{text = '&About', submenu = aboutmenu}
win.menu = menubar

--create a toolbar -----------------------------------------------------------

require'winapi.showcase'

local toolbar = Toolbar{
	parent = win,
	image_list = ImageList{w = 16, h = 16, masked = true, colors = '32bit'},
	items = {
		--NOTE: using `iBitmap` instead of `i` because `i` counts from 1
		{iBitmap = STD_FILENEW,  text = 'New'},
		{iBitmap = STD_FILEOPEN, text = 'Open'},
		{iBitmap = STD_FILESAVE, text = 'Save'},
	},
	anchors = {top = true, left = true, right = true},
}
toolbar:load_images(IDB_STD_SMALL_COLOR)

--create a group box ---------------------------------------------------------

local groupbox1 = GroupBox{
	parent = win,
	x = 20,
	y = 160,
	w = 100,
	h = 170,
	text = 'Group 1',
}

local groupbox2 = GroupBox{
	parent = win,
	x = 140,
	y = 160,
	w = 100,
	h = 170,
	text = 'Group 2',
}

--create radio buttons -------------------------------------------------------

for i = 1, 5 do
	RadioButton{
		parent = groupbox1,
		x = 20,
		y = 10 + i * 22,
		w = 60,
		text = 'Option &'..i,
		checked = i == 2,
	}
end

--create check boxes ---------------------------------------------------------

for i = 1, 5 do
	CheckBox{
		parent = groupbox2,
		x = 20,
		y = 10 + i * 22,
		w = 60,
		text = 'Option &'..i,
		checked = i == 3,
	}
end

--create a tab control -------------------------------------------------------

local tabs = TabControl{
	parent = win,
	x = 380,
	y = 50,
	w = 200,
	h = 100,
	items = {
		{text = 'Tab1',},
		{text = 'Tab2',},
	},
}

--create a bitmap panel ------------------------------------------------------

local bmppanel = BitmapPanel{w = 100, h = 100, x = 20, y = 50, parent = win}

function bmppanel:on_bitmap_paint(bmp)
	local p = self.cursor_pos
	local pixels = ffi.cast('uint8_t*', bmp.data)
	for y = 0, bmp.h - 1 do
		for x = 0, bmp.w - 1 do
			pixels[y * bmp.stride + x * 4 + 0] = x + p.x - 100
			pixels[y * bmp.stride + x * 4 + 1] = y + p.y - 100
			pixels[y * bmp.stride + x * 4 + 2] = x + p.x - 100
		end
	end
end

function bmppanel:on_mouse_move(x, y)
	self:invalidate()
end
win:settimer(1/30, function()
	--bmppanel:invalidate()
end)

--create a cairo panel -------------------------------------------------------

if have_cairo then

local cairo = require'cairo'
local cairopanel = CairoPanel{w = 100, h = 100, x = 140, y = 50, parent = win}

local r = 0
function cairopanel:on_cairo_paint(cr)
	cr:set_source_rgba(0,0,0,1)
	cr:paint()

	cr:identity_matrix()
	cr:translate(self.w/2, self.h/2)
	r = r + .02
	cr:rotate(r)
	cr:translate(-self.w/2, -self.h/2)
	cr:scale(0.4, 0.4)

	cr:set_source_rgba(0,0.7,0,1)

	cr:set_line_width (40.96)
	cr:move_to(76.8, 84.48)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:set_line_join(cairo.CAIRO_LINE_JOIN_MITER)
	cr:stroke()

	cr:move_to(76.8, 161.28)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:set_line_join(cairo.CAIRO_LINE_JOIN_BEVEL)
	cr:stroke()

	cr:move_to(76.8, 238.08)
	cr:rel_line_to(51.2, -51.2)
	cr:rel_line_to(51.2, 51.2)
	cr:set_line_join(cairo.CAIRO_LINE_JOIN_ROUND)
	cr:stroke()
end

win:settimer(1/30, function()
	cairopanel:invalidate()
end)

end

--create a wglpanel ----------------------------------------------------------

if have_wgl then

local wglpanel = WGLPanel{w = 100, h = 100, x = 260, y = 50, parent = win}

local function cube(w, r)
	gl.glPushMatrix()
	gl.glTranslated(0,0,-3)
	gl.glScaled(w, w, 1)
	gl.glRotated(r,1,r,1)
	gl.glTranslated(0,0,2)
	local function face(c)
		gl.glBegin(gl.GL_QUADS)
		gl.glColor4d(c,0,0,.5)
		gl.glVertex3d(-1, -1, -1)
		gl.glColor4d(0,c,0,.5)
		gl.glVertex3d(1, -1, -1)
		gl.glColor4d(0,0,c,.5)
		gl.glVertex3d(1, 1, -1)
		gl.glColor4d(c,0,c,.5)
		gl.glVertex3d(-1, 1, -1)
		gl.glEnd()
	end
	gl.glTranslated(0,0,-2)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glTranslated(0,0,-2)
	gl.glRotated(-90,0,1,0)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glRotated(-90,1,0,0)
	gl.glTranslated(0,2,0)
	face(1)
	gl.glTranslated(0,0,2)
	face(1)
	gl.glPopMatrix()
end

function wglpanel:on_set_viewport()
	local w, h = self.w, self.h
	gl.glViewport(0, 0, w, h)
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
	gl.glScaled(1, w/h, 1)
end

local r = 0
function wglpanel:on_render()
	gl.glClearColor(0, 0, 0, 1)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_SRC_ALPHA)
	gl.glDisable(gl.GL_DEPTH_TEST)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glDisable(gl.GL_LIGHTING)
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	gl.glTranslated(0,0,-1)
	r = r + 2
	cube(2, r)
end

win:settimer(1/30, function()
	wglpanel:invalidate()
end)

end

--create some buttons --------------------------------------------------------

local closebtn = Button{
	x = win.client_w - 130,
	y = win.client_h - 40,
	w = 100,
	text = '&Close',
	parent = win,
	anchors = {right = true, bottom = true},
}

function closebtn:on_click()
	win:close()
end

win.min_cw = win.client_w
win.min_ch = win.client_h

--create a list box ----------------------------------------------------------

local lb = ListBox{parent = win, x = 260, y = 167, h = 160, hextent = 100}
for i = 1,100 do
	lb.items:add(' xxx test xxx xxx  '..i)
end

--start the message loop -----------------------------------------------------

os.exit(MessageLoop())
