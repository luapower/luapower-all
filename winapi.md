---
tagline: win32 windows & controls
platforms: mingw32, mingw64
---

## Scope

Windows, common controls and dialogs, message loop, system APIs,
OpenGL and cairo.

## Features

  * UTF8 Lua strings everywhere (also works with wide char buffers)
  * all calls are error-checked
  * memory management (managing ownership; allocation of in/out buffers)
  * flags can be passed as `'FLAG1 FLAG2'`
  * counting from 1 everywhere
  * object system with virtual properties (`win.title = 'hello'` sets the title)
  * anchor-based layout model for all controls
  * binding helpers for easy binding of new and future APIs
  * cairo and OpenGL widgets.

## Hello World

~~~{.lua}
local winapi = require'winapi'
require'winapi.windowclass'

local win = winapi.Window{
	w = 500,                --all these are "initial fields"
	h = 300,
	title = 'Lua rulez',
	autoquit = true,        --this is to quit app when the window is closed
	visible = false,        --this field is from BaseWindow
}

function win:on_close()    --this is an event handler
	print'Bye'
end

print(win.title)           --this is how to read the value of a property
win.title = 'Lua rulez!'   --this is how to set the value of a property
win:show()                 --this is a method call

os.exit(winapi.MessageLoop()) --start the message loop
~~~

## Demos

Check out [winapi_demo] to see all the controls in action.

Also, many modules can be run as standalone scripts, which will
showcase their functionality, so there's lots of little demos there too.

[winapi_demo]: https://github.com/luapower/winapi/blob/master/winapi_demo.lua

## Documentation

### Architecture

  * [winapi_design] - hi-level overview of the library
  * [winapi_binding] - how the binding works, aka developer documentation
  * [winapi_history] - the reasoning behind various design decisions

### Classes

* [Object][winapi.object] - objects
	* [VObject][winapi.vobject] - objects with virtual properties
		* [BaseWindow][winapi.basewindowclass] - base class for top-level windows and controls
			* [Window][winapi.windowclass] - final class for top level windows
			* [Control][winapi.controlclass] - base class for controls
				* [BaseButton][winapi.basebuttonclass] - base class for buttons
					* [Button][winapi.buttonclass] - push-buttons
					* [CheckBox][winapi.checkboxclass] - checkboxes
					* [RadioButton][winapi.radiobuttonclass] - radio buttons
					* [GroupBox][winapi.groupboxclass] - group boxes
				* [Edit][winapi.editclass] - edit boxes
				* [ComboBox][winapi.comboboxclass] - combo boxes and drop-down lists
				* [ListBox][winapi.listboxclass] - list boxes
				* [ListView][winapi.listviewclass] - list views
				* [TabControl][winapi.tabcontrolclass] - tab bars
				* [Toolbar][winapi.toolbarclass] - toolbars
				* [Panel][winapi.menuclass] - custom frameless windows
				* [WGLPanel][winapi.wglpanel] - [OpenGL][opengl] panel
				* [CairoPanel][winapi.cairopanel] - [cairo] panel
		* [Menu][winapi.menuclass] - menus and menu bars
		* [NotifyIcon][winapi.notifyiconclass] - system tray icons

### Functions

The "proc" layer is documented in the code, including API quirks
and empirical knowledge, so do check out the source code.

## Modules

{{module_list}}
