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

--get the monitor where the mouse is right now. ------------------------------

local mon = MonitorFromPoint(GetCursorPos(), MONITOR_DEFAULTTONEAREST)
local moninfo = GetMonitorInfo(mon)

--create the main window -----------------------------------------------------

local w, h = 600, 500
local win = Window{
	x = (moninfo.work_rect.w - w) / 2, --center the window on the monitor
	y = (moninfo.work_rect.h - h) / 2,
	w = w,
	h = h,
	title = 'Lua Rulez',
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
		maximize_button = false,
		minimize_button = false,
		owner = win, --don't show it in taskbar
		tool_window = true,
		sizeable = false,
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
}
toolbar:load_images(IDB_STD_SMALL_COLOR)

--create a group box ---------------------------------------------------------

local groupbox1 = GroupBox{
	parent = win,
	x = 20,
	y = 150,
	w = 200,
	h = 300,
	text = 'Group 1',
}

local groupbox2 = GroupBox{
	parent = win,
	x = 240,
	y = 150,
	w = 200,
	h = 300,
	text = 'Group 2',
}

--create radio buttons -------------------------------------------------------

local rbt = {}
for i = 1, 5 do
	rbt[i] = RadioButton{
		parent = groupbox1,
		x = 20,
		y = 10 + i * 22,
		text = 'Option &'..i,
	}
end

--create check boxes ---------------------------------------------------------

local cbt = {}
for i = 1, 5 do
	cbt[i] = CheckBox{
		parent = groupbox2,
		x = 20,
		y = 10 + i * 22,
		text = 'Option &'..i,
	}
end

--create a tab control -------------------------------------------------------

local tabs = TabControl{
	parent = win,
	x = 20,
	y = 50,
	w = 200,
	h = 80,
	items = {
		{text = 'Tab1',},
		{text = 'Tab2',},
	},
}

--start the message loop -----------------------------------------------------

os.exit(MessageLoop())
