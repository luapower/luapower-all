---
tagline: win32 windows & controls
platforms: mingw32, mingw64
---

## Scope

Windows, common controls and dialogs, message loop and system APIs.

## Features

  * UTF8 Lua strings everywhere (also works with wide char buffers)
  * bitmap widget for custom painting
  * OpenGL and cairo custom-painting widgets (in separate packages)
  * anchor-based layout model for all controls
  * object system with virtual properties (`win.title = 'hello'` sets the title)
  * binding helpers for easy binding of new and future APIs
  * all calls are error-checked
  * automatic memory management (ownership; buffers)
  * flags can be passed as `'FLAG1 FLAG2'`
  * counting from 1 everywhere.

## Status

[Current status](https://github.com/luapower/winapi/issues/26)
and [issues](https://github.com/luapower/winapi/issues).

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

Check out [winapi_demo] to see all the controls in action:

![screnshot](/files/luapower/media/www/winapi_demo.png)

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
				* [Panel][winapi.panelclass] - custom-painted child windows
					* [BitmapPanel][winapi.bitmappanel] - RGBA [bitmap] panels
						* [CairoPanel][winapi.cairopanel] - [cairo] panels
					* [WGLPanel][winapi.wglpanel] - [OpenGL][opengl] panels
				* [Label][winapi.labelclass] - labels
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
			* [Tooltip][winapi.tooltipclass] - tooltips
		* [Menu][winapi.menuclass] - menus and menu bars
		* [NotifyIcon][winapi.notifyiconclass] - system tray icons

### Functions

The "proc" layer is documented in the code, including API quirks
and empirical knowledge, so do check out the source code.

## Modules

{{{module_list}}}


