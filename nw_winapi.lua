
--native windows - winapi backend.
--Written by Cosmin Apreutesei. Public domain.

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local box2d = require'box2d'
local cbframe = require'cbframe' --for drag&drop on x64
local bitmap = require'bitmap' --for clipboard
local winapi = require'winapi'
local time = require'time'
require'winapi.spi'
require'winapi.sysinfo'
require'winapi.systemmetrics'
require'winapi.windowclass'
require'winapi.gdi'
require'winapi.bitmap'
require'winapi.dibitmap'
require'winapi.icon'
require'winapi.dpiaware'
require'winapi.devcaps'
require'winapi.monitor'
require'winapi.ddev'
require'winapi.cursor'
require'winapi.keyboard'
require'winapi.rawinput'
require'winapi.mouse'
require'winapi.notifyiconclass'
require'winapi.filedialogs'
require'winapi.clipboard'
require'winapi.shellapi'
require'winapi.dragdrop'
require'winapi.panelclass'
require'winapi.module'
require'winapi.sync'
require'winapi.tooltipclass'

local nw = {name = 'winapi'}

--helpers --------------------------------------------------------------------

local function unpack_rect(rect)
	return rect.x, rect.y, rect.w, rect.h
end

local function pack_rect(rect, x, y, w, h)
	rect = rect or winapi.RECT()
	rect.x1, rect.y1, rect.x2, rect.y2 = x, y, x + w, y + h
	return rect
end

--app object -----------------------------------------------------------------

local app = {}
nw.app = app

function app:init(frontend)

	self.frontend = frontend

	--enable WM_INPUT for keyboard events
	local rid = winapi.types.RAWINPUTDEVICE()
	rid.dwFlags = 0
	rid.usUsagePage = 1 --generic desktop controls
	rid.usUsage     = 6 --keyboard
	winapi.RegisterRawInputDevices(rid, 1, ffi.sizeof(rid))

	--enable waking up this app instance by other instances of this app
	self:_init_wakeup()

	return self
end

--version checks -------------------------------------------------------------

function app:ver(what)
	if what == 'windows' then
		local vinfo = winapi.RtlGetVersion()
		return string.format('%d.%d.%d.%d',
			vinfo.dwMajorVersion, vinfo.dwMinorVersion,
			vinfo.wServicePackMajor, vinfo.wServicePackMinor)
	end
end

--message loop ---------------------------------------------------------------

--manual repainting of all windows based on the `_invalid_clock` flag.
--returns the number of seconds to wait until calling this again.
function app:_repaint_all(d)

	local t0 = self._first_frame_time
	local t1 = self._last_frame_time
	local t2 = time.clock()
	local n = d > 0 and t0 and (t2 - t0) / d or 0 --quantity of frame markers
	local i0 = self._last_frame or 1
	local i1 = math.floor(n) + 1
	local dt = (math.ceil(n) - n) * d --how much time till next frame mark
	local eps = 1/1000 --how much time is close enough to the next frame mark

	if t1 and t2 - t1 < d - eps and dt > eps then
		return dt
	end

	local lost_count = i1 - i0 - 1
	if lost_count > 0 then
		--TODO: we're still losing one frame every now and then
		--print('lost frames:', lost_count)
	end

	self._first_frame_time = t0 or t2
	self._last_frame_time = t2
	self._last_frame = i1

	local t = self.frontend._windows
	for i = 1, #t do
		local win = t[i]
		if not win:dead() then
			win.backend:repaint(t2)
		end
	end

	local repaint_time = time.clock() - t2
	local wait_time = math.max(0, d - dt - repaint_time)

	return wait_time
end

function app:poll(timeout)
	self:_repaint_all(0)
	return winapi.ProcessNextMessage(timeout)
end

function app:run()
	while true do
		local d = 1 / self.frontend:maxfps()
		local wait_time = self:_repaint_all(d)
		repeat
			local more, exit_code = winapi.ProcessNextMessage(wait_time)
			if not more and exit_code then
				return exit_code
			end
			wait_time = 0
		until not more
	end
end

function app:stop()
	winapi.PostQuitMessage()
end

--timers ---------------------------------------------------------------------

local appwin

function app:runevery(seconds, func)
	appwin = appwin or winapi.Window{visible = false}
	appwin:settimer(seconds, func)
end

--windows --------------------------------------------------------------------

local window = {}
app.window = window

local Window = winapi.subclass({}, winapi.Window)

local winmap = {} --winapi_window->frontend_window

local last_active_window

function window:new(app, frontend, t)
	self = glue.update({app = app, frontend = frontend}, self)

	local framed = t.frame == 'normal' or t.frame == 'toolbox'
	self._layered = t.transparent

	--NOTE: resizeable flag (WS_SIZEBOX) needs the frame flag (WS_DLGFRAME),
	--which means we can't have frameless windows that are also resizeable.
	self.win = Window{
		--state
		x = t.x,
		y = t.y,
		w = t.w,
		h = t.h,
		min_cw = t.min_cw,
		min_ch = t.min_ch,
		max_cw = t.max_cw,
		max_ch = t.max_ch,
		visible = false,
		minimized = t.minimized,
		maximized = t.maximized,
		enabled = t.enabled,
		--frame
		title = t.title,
		border = framed,
		frame = framed,
		window_edge = framed, --must be off for frameless windows!
		layered = self._layered,
		tool_window = t.frame == 'toolbox',
		owner = t.parent and t.parent.backend.win,
		--behavior
		topmost = t.topmost,
		minimizable = t.minimizable,
		maximizable = t.maximizable,
		closeable = t.closeable,
		resizeable = framed and t.resizeable, --must be off for frameless windows!
		activable = t.activable,
		receive_double_clicks = false, --we do our own double-clicking
		own_dc = t.opengl and true or nil,
	}

	self:invalidate()

	self:_set_region()

	--init keyboard state
	self.win.__wantallkeys = true --don't let IsDialogMessage() filter out our precious WM_CHARs
	self:_reset_keystate()

	--start tracking mouse leave
	winapi.TrackMouseEvent{hwnd = self.win.hwnd, flags = winapi.TME_LEAVE}

	--set window state
	self._fullscreen = false

	--set back-references
	self.win.frontend = frontend
	self.win.backend = self
	self.win.app = app

	self:_init_icon_api()
	self:_init_drop_target()

	--announce acceptance to drop files into the window.
	winapi.DragAcceptFiles(self.win.hwnd, true)

	self:_init_opengl(t.opengl)

	--register window
	winmap[self.win] = self.frontend

	--if this is the first window, register it as the last active window
	--just in case the user calls app:activate() before this window activates.
	if not last_active_window then
		last_active_window = self
	end

	self.win[app._wakeup_wm_name] = function(win)
		if last_active_window == self then --receive this on one window only
			app.frontend:_backend_wakeup()
		end
	end

	return self
end

function window:_set_region()
	local cr = self.frontend:corner_radius()
	if cr == 0 then return end
	local r = self.win.rect
	--yes, it's w+1, h+1 with regions and yes, we need the redraw flag.
	self._hrgn = winapi.CreateRoundRectRgn(0, 0, r.w + 1, r.h + 1, cr, cr)
	winapi.SetWindowRgn(self.win.hwnd, self._hrgn, true)
end

--closing --------------------------------------------------------------------

function window:forceclose()
	self.win._forceclose = true --because win:close() calls on_close().
	self.win:close()
end

function Window:on_close()
	if not self._forceclose and not self.frontend:_backend_closing() then
		return false
	end
end

--NOTE: closing a window's owner in the on_destroy() event triggers
--another on_destroy() event on the owned window!
function Window:on_destroy()
	if not self.nw_destroying then
		self.nw_destroying = true
		self.frontend:_backend_closed() --this may trigger on_destroy() again!
	end
	if not self.nw_destroyed then
		self.nw_destroyed = true
		self.backend:_free_bitmap()
		self.backend:_free_opengl()
		self.backend:_free_icon()
		self.backend:_free_drop_target()
		winmap[self] = nil

		--register another random window as the last active window so that
		--app:activate() works even before the next window gets activated.
		--in any case we want to release the reference to self.
		if last_active_window == self then
			local _, frontend = next(winmap)
			last_active_window = frontend.backend
		end
	end
end

--activation -----------------------------------------------------------------

function app:activate()
	--unlike OSX, in Windows you don't activate an app, you have to activate
	--a specific window. Activating this app means activating the last window
	--of this app that was active before the app got deactivated.
	local win = last_active_window
	if win and not win.frontend:dead() then
		win.win:setforeground()
	end
end

function app:active_window()
	--foreground_window returns the active window only if the app is active,
	--which is consistent with OSX.
	return winmap[winapi.Windows.foreground_window] or nil
end

function app:active()
	return self:active_window() and true or false
end

function window:activate()
	--for consistency with OSX, if the app is inactive, this function
	--doesn't activate the window, instead it marks the window that must
	--be activated on the next call to app:activate().
	last_active_window = self
	self.win:activate() --note: using activate() instead of setforeground()
end

function window:active()
	--returns true only if the app is active, consistent with OSX.
	return not self._inactive and self.app:active_window() == self.frontend
end

--NOTE: this also triggers when the app is inactive and another window
--was closed, so we need to set last_active_window here.
function Window:on_activate()
	self.backend._inactive = nil --no need for this anymore
	last_active_window = self.backend --for the next app:activate()
end

--this event is received when the window's titlebar is activated.
--this is more accurate event-wise than on_activate() which also triggers when
--the app is inactive and the window flashes its taskbar button instead of activating.
function Window:on_nc_activate()
	self.backend._inactive = nil --no need for this anymore
	self.backend.app.frontend:_backend_changed()
	self.backend:_reset_keystate()
	self.frontend:_backend_changed()
end

--NOTE: GetActiveWindow() and GetForegroundWindow() still point to the window
--that received the event at the time of the event, hence the _inactive flag.
function Window:on_deactivate()
	self.backend._inactive = true
	self.backend:_reset_keystate()
	self.frontend:_backend_changed()
end

function Window:on_deactivate_app() --triggered after on_deactivate().
	self.frontend.app:_backend_changed()
end

--single app instance --------------------------------------------------------

function app:id()
	return self.frontend.nw.app_id
		or winapi.GetModuleFilename():lower():gsub('[\\/%:]', '_')
end

function app:_init_wakeup()
	self._wakeup_wm_name = 'WM_'..self:id()
	self._wakeup_wm_code = winapi.RegisterWindowMessage(self._wakeup_wm_name)
end

function app:already_running()
	local mutex, err = winapi.CreateMutex(nil, false, self:id())
	return err == 'already_exists'
end

function app:wakeup_other_instances()
	winapi.PostMessage(winapi.HWND_BROADCAST, self._wakeup_wm_code, 0, 0)
end

--state/app visibility -------------------------------------------------------

function app:visible() return true end
function app:hide() end
function app:unhide() end

--state ----------------------------------------------------------------------

function window:visible()
	return self.win.visible
end

function window:show()
	if self.win.minimized then --NOTE: this assumes that minimize() is synchronous
		--show minimized without activating, consistent with Linux and OSX.
		--self.win:show() also shows the window in minimized state, but it
		--selects the window on the taskbar (it activates it).
		self:minimize()
	else
		self.win:show() --sync call
	end
end

function window:hide()
	self.win:hide() --sync call
end

function window:minimized()
	return self.win.minimized
end

--NOTE: minimize() is not activating the window, consistent with OSX and Linux.
function window:minimize()
	if self:fullscreen() then return end --TODO: remove this after fixing OSX
	self.win:minimize() --sync call, assumed by show()
end

function window:maximized()
	if self._fullscreen then
		return self._fs.maximized
	elseif self.win.minimized then
		return self.win.restore_to_maximized
	end
	return self.win.maximized
end

function window:maximize()
	if self:fullscreen() then return end --TODO: remove this after fixing OSX
	self.win:maximize() --sync call, assumed by enter_fullscreen()
end

function window:restore()
	self.win:restore() --sync call
	self.frontend.app:activate() --because maximized hidden windows don't activate
end

function window:shownormal()
	if self:fullscreen() then return end --TODO: remove this after fixing OSX
	self.win:shownormal() --sync call
	if not self:active() then
		--activating because minimize->hide->shownormal doesn't.
		self:activate()
		self.app:activate()
	end
end

function Window:on_pos_change(pos)
	if not self.frontend then return end --early resize from setting constraints: ignore
	self.frontend:_backend_changed()
end

--state/fullscreen -----------------------------------------------------------

function window:fullscreen()
	return self._fullscreen
end

function window:enter_fullscreen()
	if self._fullscreen then return end

	--save state for restoring
	self._fs = {
		maximized = self:maximized(), --NOTE: this assumes that maximize() is synchronous
		normal_rect = self.win.normal_rect,
		frame = self.win.frame,
		resizeable = self.win.resizeable,
	}

	--if it's a layered window, clear it, otherwise the taskbar won't
	--dissapear quite immediately when the window will be repainted (WinXP).
	self:_clear_layered()

	--disable events while we're changing the frame, size and state.
	local events = self.frontend:events(false)

	--this flickers but without it the taskbar won't dissapear immediately.
	self.win:hide()

	--remove the frame: this enlarges client_rect to what frame_rect was!
	self.win.frame = false
	self.win.border = false
	self.win.resizeable = false

	--set normal rect
	local display = self:display() or self.app:active_display()
	local dx, dy, dw, dh = display:screen_rect()
	self.win.normal_rect = pack_rect(nil, dx, dy, dw, dh)

	--restore events, invalidate and show.
	self._fullscreen = true
	self.frontend:events(events)

	--show synchronously to avoid re-entring.
	self.win:shownormal()
end

function window:exit_fullscreen()
	if not self._fullscreen then return end

	--disable events while we're changing the frame and size.
	local events = self.frontend:events(false)

	--put back the frame and normal rect
	self.win.frame = self._fs.frame
	self.win.border = self._fs.frame
	self.win.resizeable = self._fs.resizeable
	self.win.normal_rect = self._fs.normal_rect --we set this after maximize() above.

	--restore events, invalidate and show.
	self._fullscreen = false
	self.frontend:events(events)
	self:invalidate()

	--restore synchronously to avoid re-entring.
	if self._fs.maximized then
		self.win:maximize()
	end
	self.frontend:_backend_changed()
end

function Window:on_minimizing()
	--refuse to minimize a fullscreen window to avoid undefined behavior.
	if self.backend._fullscreen then
		return false
	end
end

--state/enabled --------------------------------------------------------------

function window:get_enabled()
	return self.win.enabled
end

function window:set_enabled(enabled)
	self.win.enabled = enabled
end

--positioning/frame extents --------------------------------------------------

local function frame_args(frame, has_menu, resizeable)
	local framed = frame == 'normal' or frame == 'toolbox'
	return {
		border = framed,
		frame = framed,
		window_edge = framed,
		resizeable = resizeable,
		tool_window = frame == 'toolbox',
		menu = has_menu or nil,
	}
end

function app:frame_extents(frame, has_menu, resizeable)
	local cx, cy, cw, ch = 200, 200, 400, 400
	local rect = pack_rect(nil, cx, cy, cw, ch)
	local rect = winapi.Window:client_to_frame(frame_args(frame, has_menu, resizeable), rect)
	local x, y, w, h = unpack_rect(rect)
	return cx-x, cy-y, w-cw-(cx-x), h-ch-(cy-y)
end

--positioning/rectangles -----------------------------------------------------

function window:get_client_size()
	local r = self.win.client_rect
	return r.w, r.h
end

function window:get_client_pos()
	local p = self.win:map_point(nil, 0, 0)
	return p.x, p.y
end

function window:get_normal_frame_rect()
	if self._fullscreen then
		return unpack_rect(self._fs.normal_rect)
	else
		return unpack_rect(self.win.normal_rect)
	end
end

function window:get_frame_rect()
	return unpack_rect(self.win.screen_rect)
end

function window:set_frame_rect(x, y, w, h)
	self.win.rect = pack_rect(nil, x, y, w, h)
	self.frontend:_backend_changed()
end

--positioning/constraints ----------------------------------------------------

function window:get_minsize()
	return self.win.min_cw, self.win.min_ch
end

function window:set_minsize(w, h)
	self.win.min_cw = w
	self.win.min_ch = h
	self.win:resize(self.win.w, self.win.h)
end

function window:get_maxsize()
	return self.win.max_cw, self.win.max_ch
end

function window:set_maxsize(w, h)
	self.win.max_cw = w
	self.win.max_ch = h
	self.win:resize(self.win.w, self.win.h)
end

--positioning/resizing -------------------------------------------------------

function Window:on_begin_sizemove()
	--when moving the window, we want its position relative to
	--the mouse position to remain constant, and we're going to enforce that.
	local m = winapi.Windows.cursor_pos
	self.nw_dx = m.x - self.x
	self.nw_dy = m.y - self.y

	--defer the start_resize event because we don't know whether
	--it's a move or resize event at this point.
	self.nw_start_resize = true
end

function Window:on_end_sizemove()
	self.nw_start_resize = false
	local how = self.nw_sizemove_how
	self.nw_sizemove_how = nil
	self.frontend:_backend_sizing('end', how)
end

function Window:nw_frame_changing(how, rect)

	self.nw_sizemove_how = how

	--trigger the deferred start_resize event, once.
	if self.nw_start_resize then
		self.nw_start_resize = false
		self.frontend:_backend_sizing('start', how)
	end

	if how == 'move' then
		--set window's position based on current mouse position and initial offset,
		--regardless of how the coordinates are adjusted by the user on each event.
		--this is consistent with OSX and it feels better.
		local m = winapi.Windows.cursor_pos
		local w, h = rect.w, rect.h
		rect.x1 = m.x - self.nw_dx
		rect.y1 = m.y - self.nw_dy
		rect.x2 = rect.x1 + w
		rect.y2 = rect.y1 + h
	end

	pack_rect(rect, self.frontend:_backend_sizing('progress', how, unpack_rect(rect)))

	if how == 'move' then
		--move sticky children too to emulate default OSX behavior.
		local children = self.frontend:children()
		if #children > 0 then
			local x, y = rect.x, rect.y
			local x0, y0 = self.backend:get_frame_rect()
			local dx = x - x0
			local dy = y - y0
			for _,win in ipairs(children) do
				if win:sticky() then
					local x, y = win:frame_rect()
					win.backend.win:move(x + dx, y + dy)
				end
			end
		end

	end
end

function Window:on_moving(rect)
	self:nw_frame_changing('move', rect)
	return true --signal that the position was modified
end

function Window:on_resizing(how, rect)
	self.nw_how = how
	self:nw_frame_changing(how, rect)
end

function Window:on_moved()
	if not self.frontend then return end
	self.frontend:_backend_changed()
end

function Window:on_resized(flag)
	if not self.backend then return end --early resize from setting constraints: ignore.

	if flag == 'maximized' then
		if self.nw_maximizing then return end
		--frameless windows maximize to the entire screen, covering the taskbar. fix that.
		if not self.frame then
			self.nw_maximizing = true --on_resized() barrier
			self.rect = pack_rect(nil, self.backend:display():desktop_rect())
			self.nw_maximizing = false
		end
		self.backend:invalidate()
	elseif flag == 'restored' then --also triggered on show and on resize
		self.backend:invalidate()
	end

	self.backend:_set_region()

	self.frontend:_backend_changed()
end

--positioning/magnets --------------------------------------------------------

function window:magnets()
	local t = {} --{{x, y, w, h}, ...}
	local rect
	for i,hwnd in ipairs(winapi.EnumChildWindows()) do --front-to-back order assured
		if hwnd ~= self.win.hwnd         --exclude self
			and winapi.IsVisible(hwnd)    --exclude invisible
			and not winapi.IsZoomed(hwnd) --exclude maximized (TODO: also excludes constrained maximized)
		then
			rect = winapi.GetWindowRect(hwnd, rect)
			t[#t+1] = {x = rect.x, y = rect.y, w = rect.w, h = rect.h}
		end
	end
	return t
end

--titlebar -------------------------------------------------------------------

function window:get_title()
	return self.win.title
end

function window:set_title(title)
	self.win.title = title
end

--z-order --------------------------------------------------------------------

function window:get_topmost()
	return self.win.topmost
end

function window:set_topmost(topmost)
	self.win.topmost = topmost
end

function window:raise(relto)
	self.win:bring_to_front(relto and relto.backend.win)
end

function window:lower(relto)
	self.win:send_to_back(relto and relto.backend.win)
end

--displays -------------------------------------------------------------------

function app:_display(monitor)

	local ok, info = pcall(winapi.GetMonitorInfo, monitor)
	if not ok then return end

	--skip displays that are mirroring pseudo-displays.
	local dd = winapi.EnumDisplayDevices(info.szDevice)
	if bit.band(dd.state_flags, winapi.DISPLAY_DEVICE_MIRRORING_DRIVER) ~= 0 then return end

	local sf = self:_get_scaling_factor(monitor)

	return self.frontend:_display{
		x = info.monitor_rect.x,
		y = info.monitor_rect.y,
		w = info.monitor_rect.w,
		h = info.monitor_rect.h,
		cx = info.work_rect.x,
		cy = info.work_rect.y,
		cw = info.work_rect.w,
		ch = info.work_rect.h,
		scalingfactor = sf,
	}
end

function app:displays()
	local monitors = winapi.EnumDisplayMonitors() --the order is undefined
	local displays = {}
	for i = 1, #monitors do
		local display = self:_display(monitors[i])
		if display then
			table.insert(displays, display)
		end
	end
	return displays
end

function app:display_count()
	--NOTE: SM_CMONITORS doesn't count mirroring pseudo-displays
	--so it matches the number of displays returned with app:displays().
	return winapi.GetSystemMetrics'SM_CMONITORS'
end

function app:main_display()
	local p = winapi.POINT(0,0) --primary display is at (0,0) by definition.
	return self:_display(winapi.MonitorFromPoint(p, 'MONITOR_DEFAULTTOPRIMARY'))
end

function app:active_display()
	--NOTE: we're using GetForegroundWindow() as opposed to GetActiveWindow()
	--or GetFocus() which only return handles from our own process.
	local hwnd = winapi.GetForegroundWindow()
	if hwnd then
		return self:_display(winapi.MonitorFromWindow(hwnd, 'MONITOR_DEFAULTTONEAREST'))
	else
		--in case there's no foreground window, fallback the primary display.
		return self:main_display()
	end
end

--NOTE: the default flag for self.win.monitor is MONITOR_DEFAULTTONULL,
--which is what we need to emulate OSX behavior for off-screen windows.
function window:display()
	return self.app:_display(self.win.monitor)
end

function Window:on_display_change(x, y, bpp)
	self.app.frontend:_backend_displays_changed()
end

--cursors --------------------------------------------------------------------

local cursors = {
	--pointers
	arrow = winapi.IDC_ARROW,
	text  = winapi.IDC_IBEAM,
	hand  = winapi.IDC_HAND,
	cross = winapi.IDC_CROSS,
	forbidden = winapi.IDC_NO,
	--move and resize
	size_diag1 = winapi.IDC_SIZENESW,
	size_diag2 = winapi.IDC_SIZENWSE,
	size_h = winapi.IDC_SIZEWE,
	size_v = winapi.IDC_SIZENS,
	move = winapi.IDC_SIZEALL,
	--app state
	busy_arrow = winapi.IDC_APPSTARTING,
}

--resize sides and corners
cursors.topleft     = cursors.size_diag2
cursors.topright    = cursors.size_diag1
cursors.bottomleft  = cursors.size_diag1
cursors.bottomright = cursors.size_diag2
cursors.top         = cursors.size_v
cursors.bottom      = cursors.size_v
cursors.left        = cursors.size_h
cursors.right       = cursors.size_h

function window:update_cursor()
	--trigger WM_SETCURSOR without having to invalidate the whole window.
	local p = winapi.GetCursorPos()
	winapi.SetCursorPos(p.x, p.y)
	if (self.win.capture_count or 0) > 0 then
		--when the mouse is captured, WM_SETCURSOR events are not sent.
		self.win:on_set_cursor(nil, winapi.HTCLIENT)
	end
end

function Window:on_set_cursor(_, ht)
	if ht ~= winapi.HTCLIENT then return end
	local cursor, visible = self.frontend:cursor()
	if not visible then
		winapi.SetCursor(nil)
	else
		local cursor = assert(cursors[cursor])
		winapi.SetCursor(winapi.LoadCursor(cursor))
	end
	return true --important
end

--keyboard -------------------------------------------------------------------

local keynames = { --vkey code -> vkey name

	[winapi.VK_OEM_1]      = ';',  --on US keyboards
	[winapi.VK_OEM_PLUS]   = '=',
 	[winapi.VK_OEM_COMMA]  = ',',
	[winapi.VK_OEM_MINUS]  = '-',
	[winapi.VK_OEM_PERIOD] = '.',
	[winapi.VK_OEM_2]      = '/',  --on US keyboards
	[winapi.VK_OEM_3]      = '`',  --on US keyboards
	[winapi.VK_OEM_4]      = '[',  --on US keyboards
	[winapi.VK_OEM_5]      = '\\', --on US keyboards
	[winapi.VK_OEM_6]      = ']',  --on US keyboards
	[winapi.VK_OEM_7]      = '\'', --on US keyboards

	[winapi.VK_BACK]   = 'backspace',
	[winapi.VK_TAB]    = 'tab',
	[winapi.VK_SPACE]  = 'space',
	[winapi.VK_ESCAPE] = 'esc',

	[winapi.VK_F1]  = 'F1',
	[winapi.VK_F2]  = 'F2',
	[winapi.VK_F3]  = 'F3',
	[winapi.VK_F4]  = 'F4',
	[winapi.VK_F5]  = 'F5',
	[winapi.VK_F6]  = 'F6',
	[winapi.VK_F7]  = 'F7',
	[winapi.VK_F8]  = 'F8',
	[winapi.VK_F9]  = 'F9',
	[winapi.VK_F10] = 'F10',
	[winapi.VK_F11] = 'F11',
	[winapi.VK_F12] = 'F12',

	[winapi.VK_CAPITAL]  = 'capslock',
	[winapi.VK_NUMLOCK]  = 'numlock',     --win keyboard; mapped to 'numclear' on mac
	[winapi.VK_SNAPSHOT] = 'printscreen', --win keyboard; mapped to 'F13' on mac;
		--taken on windows (screen snapshot)
	[winapi.VK_SCROLL]   = 'scrolllock',  --win keyboard; mapped to 'F14' on mac

	[winapi.VK_NUMPAD0] = 'num0',
	[winapi.VK_NUMPAD1] = 'num1',
	[winapi.VK_NUMPAD2] = 'num2',
	[winapi.VK_NUMPAD3] = 'num3',
	[winapi.VK_NUMPAD4] = 'num4',
	[winapi.VK_NUMPAD5] = 'num5',
	[winapi.VK_NUMPAD6] = 'num6',
	[winapi.VK_NUMPAD7] = 'num7',
	[winapi.VK_NUMPAD8] = 'num8',
	[winapi.VK_NUMPAD9] = 'num9',
	[winapi.VK_DECIMAL] = 'num.',
	[winapi.VK_MULTIPLY] = 'num*',
	[winapi.VK_ADD]      = 'num+',
	[winapi.VK_SUBTRACT] = 'num-',
	[winapi.VK_DIVIDE]   = 'num/',
	[winapi.VK_CLEAR]    = 'numclear',

	[winapi.VK_VOLUME_MUTE] = 'mute',
	[winapi.VK_VOLUME_DOWN] = 'volumedown',
	[winapi.VK_VOLUME_UP]   = 'volumeup',

	[0xff]           = 'lwin', --win keyboard; mapped to 'lcommand' on mac
	[winapi.VK_RWIN] = 'rwin', --win keyboard; mapped to 'rcommand' on mac
	[winapi.VK_APPS] = 'menu', --win keyboard

	[winapi.VK_OEM_NEC_EQUAL] = 'num=', --mac keyboard
}

for ascii = string.byte('0'), string.byte('9') do --ASCII 0-9 -> '0'-'9'
	keynames[ascii] = string.char(ascii)
end

for ascii = string.byte('A'), string.byte('Z') do --ASCII A-Z -> 'A'-'Z'
	keynames[ascii] = string.char(ascii)
end

local keynames_ext = {}

keynames_ext[false] = { --vkey code -> vkey name when flags.extended_key is false

	[winapi.VK_CONTROL] = 'lctrl',
	[winapi.VK_MENU]    = 'lalt',

	[winapi.VK_LEFT]   = 'numleft',
	[winapi.VK_UP]     = 'numup',
	[winapi.VK_RIGHT]  = 'numright',
	[winapi.VK_DOWN]   = 'numdown',
	[winapi.VK_PRIOR]  = 'numpageup',
	[winapi.VK_NEXT]   = 'numpagedown',
	[winapi.VK_END]    = 'numend',
	[winapi.VK_HOME]   = 'numhome',
	[winapi.VK_INSERT] = 'numinsert',
	[winapi.VK_DELETE] = 'numdelete',
	[winapi.VK_RETURN] = 'enter!',
}

keynames_ext[true] = { --vkey code -> vkey name when flags.extended_key is true

	[winapi.VK_CONTROL] = 'rctrl',
	[winapi.VK_MENU]    = 'ralt',

	[winapi.VK_LEFT]    = 'left!',
	[winapi.VK_UP]      = 'up!',
	[winapi.VK_RIGHT]   = 'right!',
	[winapi.VK_DOWN]    = 'down!',
	[winapi.VK_PRIOR]   = 'pageup!',
	[winapi.VK_NEXT]    = 'pagedown!',
	[winapi.VK_END]     = 'end!',
	[winapi.VK_HOME]    = 'home!',
	[winapi.VK_INSERT]  = 'insert!',
	[winapi.VK_DELETE]  = 'delete!',
	[winapi.VK_RETURN]  = 'numenter',
}

local keycodes = {}
for vk, name in pairs(keynames) do
	keycodes[name:lower()] = vk
end

--additional key codes that we can query directly
keycodes.lctrl    = winapi.VK_LCONTROL
keycodes.lalt     = winapi.VK_LMENU
keycodes.rctrl    = winapi.VK_RCONTROL
keycodes.ralt     = winapi.VK_RMENU

--ambiguous key codes that we can query directly
keycodes.ctrl     = winapi.VK_CONTROL
keycodes.alt      = winapi.VK_MENU
keycodes.left     = winapi.VK_LEFT
keycodes.up       = winapi.VK_UP
keycodes.right    = winapi.VK_RIGHT
keycodes.down     = winapi.VK_DOWN
keycodes.pageup   = winapi.VK_PRIOR
keycodes.pagedown = winapi.VK_NEXT
keycodes['end']   = winapi.VK_END
keycodes.home     = winapi.VK_HOME
keycodes.insert   = winapi.VK_INSERT
keycodes.delete   = winapi.VK_DELETE
keycodes.enter    = winapi.VK_RETURN

local ignore_numlock_keys = {
	numdelete   = 'num.',
	numinsert   = 'num0',
	numend      = 'num1',
	numdown     = 'num2',
	numpagedown = 'num3',
	numleft     = 'num4',
	numclear    = 'num5',
	numright    = 'num6',
	numhome     = 'num7',
	numup       = 'num8',
	numpageup   = 'num9',
}

local numlock_off_keys = glue.index(ignore_numlock_keys)

local keystate     --key state for keys that we can't get with GetKeyState()
local repeatstate  --repeat state for keys we want to prevent repeating for.
local altgr        --altgr flag, indicating that the next 'ralt' is actually 'altgr'.
local realkey      --set via raw input to distinguish break from ctrl+numlock, etc.

function window:_reset_keystate()
	keystate = {}
	repeatstate = {}
	altgr = nil
	realkey = nil
end

function Window:nw_setkey(vk, flags, down)
	if vk == winapi.VK_SHIFT then
		--shift is handled using raw input because we don't get key-up on shift
		--if the other shift is pressed!
		return
	end
	if winapi.IsAltGr(vk, flags) then
		altgr = true --next key is 'ralt' which we'll make into 'altgr'
		return
	end
	local name = realkey or keynames_ext[flags.extended_key][vk] or keynames[vk]
	realkey = nil --reset realkey. important!
	if altgr then
		altgr = nil
		if name == 'ralt' then
			name = 'altgr'
		end
	end
	if not name then return end --unmapped key
	local searchname = name:lower()
	if not keycodes[searchname] then
		--save the state of this key because we can't get it with GetKeyState()
		keystate[searchname] = down
	end
	if self.app.frontend:ignore_numlock() then
		--ignore the state of the numlock key
		name = ignore_numlock_keys[name] or name
	end
	return name
end

--prevent repeating these keys to emulate OSX behavior, and also because
--flags.prev_key_state doesn't work on them.
local norepeat = glue.index{
	'lshift', 'rshift', 'lalt', 'ralt', 'altgr', 'lctrl', 'rctrl', 'capslock',
}

--convert any non-nil return value to `true` to signal that the key press
--was handled and `keychar` events should not be triggered for that key.
--winapi expects returning `true` for this (returning `false` won't work).
local function truenil(ret)
	return ret ~= nil or nil
end

function Window:on_key_down(vk, flags)
	local key = self:nw_setkey(vk, flags, true)
	if not key then return end
	if norepeat[key] then
		if not repeatstate[key] then
			repeatstate[key] = true
			return
				truenil(self.frontend:_backend_keydown(key))
				or truenil(self.frontend:_backend_keypress(key))
		end
	elseif not flags.prev_key_state then
		return
			truenil(self.frontend:_backend_keydown(key))
			or truenil(self.frontend:_backend_keypress(key))
	else
		return truenil(self.frontend:_backend_keypress(key))
	end
end

function Window:on_key_up(vk, flags)
	local key = self:nw_setkey(vk, flags, false)
	if not key then return end
	if norepeat[key] then
		repeatstate[key] = false
	end
	return truenil(self.frontend:_backend_keyup(key))
end

--we get the ALT key with these messages instead
Window.on_syskey_down = Window.on_key_down
Window.on_syskey_up = Window.on_key_up

function Window:on_key_down_char(char)
	self.frontend:_backend_keychar(char)
end

Window.on_syskey_down_char = Window.on_key_down_char

--take control of the ALT and F10 keys
function Window:on_menu_key(char_code)
	if char_code == 0 then
		return false
	end
end

local toggle_keys = glue.index{'capslock', 'numlock', 'scrolllock'}

function app:key(name) --name is in lowercase!
	if name:find'^%^' then --'^key' means get the toggle state for that key
		name = name:sub(2)
		if not toggle_keys[name] then
			--Windows has toggle state for all keys, we don't want that.
			return false
		end
		local keycode = keycodes[name]
		if not keycode then return false end
		local _, on = winapi.GetKeyState(keycode)
		return on
	else
		if numlock_off_keys[name]
			and self.frontend:ignore_numlock()
			and not self:key'^numlock'
		then
			return self:key(numlock_off_keys[name])
		end
		local keycode = keycodes[name]
		if keycode then
			return (winapi.GetKeyState(keycode))
		else
			return keystate[name] or false
		end
	end
end

--TODO: finish this API
local exclude_keystate = glue.index{
	VK_SHIFT, VK_CONTROL, VK_MENU,  --we have L/R variants on those
}
local sort_first = glue.index{
	'lshift', 'rshift', 'lalt', 'ralt', 'altgr', 'lctrl', 'rctrl',
}
local t = {}
local function cmp(a, b)
	local sa = sort_first[a] and 1 or 0
	local sb = sort_first[b] and 1 or 0
	if sa == sb then
		return a < b
	else
		return sa < sb
	end
end
function app:keys_pressed()
	local keys = winapi.GetKeyboardState()
	local j = 0
	for i=0,255 do
		if not exclude_keystate[i] then
			local keyname = keynames[i]
			if keyname then
				local bits = keys[i]
				local down = bit.band(bits, 0x80) == 0x80
				if down then
					j = j + 1
					t[j] = keyname
				end
			end
		end
	end
	table.sort(t, cmp)
	return table.concat(t, ' ', 1, j)
end

function Window:on_raw_input(raw)
	local vk = raw.data.keyboard.VKey
	if vk == winapi.VK_SHIFT then
		vk = winapi.MapVirtualKey(raw.data.keyboard.MakeCode, winapi.MAPVK_VSC_TO_VK_EX)
		local key = vk == winapi.VK_LSHIFT and 'lshift' or 'rshift'
		if bit.band(raw.data.keyboard.Flags, winapi.RI_KEY_BREAK) == 0 then --keydown
			if not repeatstate[key] then
				keystate.shift = true
				keystate[key] = true
				repeatstate[key] = true
				return
					truenil(self.frontend:_backend_keydown(key))
					or truenil(self.frontend:_backend_keypress(key))
			end
		else
			keystate.shift = false
			keystate[key] = false
			repeatstate[key] = false
			return truenil(self.frontend:_backend_keyup(key))
		end
	elseif vk == winapi.VK_PAUSE then
		if bit.band(raw.data.keyboard.Flags, winapi.RI_KEY_E1) == 0 then --Ctrl+Numlock
			realkey = 'numlock'
		else
			realkey = 'break'
		end
	elseif vk == winapi.VK_CANCEL then
		if bit.band(raw.data.keyboard.Flags, winapi.RI_KEY_E0) == 0 then --Ctrl+ScrollLock
			realkey = 'scrolllock'
		else
			realkey = 'break'
		end
	end
end

--mouse ----------------------------------------------------------------------

function app:double_click_time()
	return winapi.GetDoubleClickTime() / 1000 --seconds
end

function app:caret_blink_time()
	local t = winapi.GetCaretBlinkTime()
	return t and t / 1000 --seconds
end

function app:double_click_target_area()
	local w = winapi.GetSystemMetrics'SM_CXDOUBLECLK'
	local h = winapi.GetSystemMetrics'SM_CYDOUBLECLK'
	return w, h
end

function app:get_mouse_pos()
	local p = winapi.GetCursorPos()
	return p.x, p.y
end

function app:set_mouse_pos(x, y)
	winapi.SetCursorPos(x, y)
end

--TODO: get lost mouse events http://blogs.msdn.com/b/oldnewthing/archive/2012/03/14/10282406.aspx

local function unpack_buttons(b)
	return b.lbutton, b.rbutton, b.mbutton, b.xbutton1, b.xbutton2
end

--the following methods apply to both window and view classes, so make sure
--that only fields and methods that are common to both are used.

local mouse = {}
local Mouse = {}

function mouse:_setmouse(x, y, buttons)
	--set mouse state
	local m = self.frontend._mouse
	m.x = x
	m.y = y
	m.left = buttons.lbutton
	m.right = buttons.rbutton
	m.middle = buttons.mbutton
	m.x1 = buttons.xbutton1
	m.x2 = buttons.xbutton2
	if not m.inside then --mouse entered
		m.inside = true
		winapi.TrackMouseEvent{hwnd = self.win.hwnd, flags = winapi.TME_LEAVE}
		self.frontend:_backend_mouseenter(x, y)
	end
end

function Mouse:on_mouse_move(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self.frontend:_backend_mousemove(x, y)
end

function Mouse:on_mouse_leave()
	if not self.frontend._mouse.inside then return end
	self.frontend._mouse.inside = false
	self.frontend:_backend_mouseleave()
end

function Mouse:capture_mouse()
	self.capture_count = (self.capture_count or 0) + 1
	winapi.SetCapture(self.hwnd)
end

function Mouse:uncapture_mouse()
	self.capture_count = math.max(0, (self.capture_count or 0) - 1)
	if self.capture_count == 0 then
		winapi.ReleaseCapture()
	end
end

function Mouse:on_lbutton_down(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:capture_mouse()
	self.frontend:_backend_mousedown('left', x, y)
end

function Mouse:on_mbutton_down(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:capture_mouse()
	self.frontend:_backend_mousedown('middle', x, y)
end

function Mouse:on_rbutton_down(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:capture_mouse()
	self.frontend:_backend_mousedown('right', x, y)
end

function Mouse:on_xbutton_down(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	if buttons.xbutton1 then
		self:capture_mouse()
		self.frontend:_backend_mousedown('x1', x, y)
	end
	if buttons.xbutton2 then
		self:capture_mouse()
		self.frontend:_backend_mousedown('x2', x, y)
	end
end

function Mouse:on_lbutton_up(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:uncapture_mouse()
	self.frontend:_backend_mouseup('left', x, y)
end

function Mouse:on_mbutton_up(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:uncapture_mouse()
	self.frontend:_backend_mouseup('middle', x, y)
end

function Mouse:on_rbutton_up(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	self:uncapture_mouse()
	self.frontend:_backend_mouseup('right', x, y)
end

function Mouse:on_xbutton_up(x, y, buttons)
	self.backend:_setmouse(x, y, buttons)
	if buttons.xbutton1 then
		self:uncapture_mouse()
		self.frontend:_backend_mouseup('x1', x, y)
	end
	if buttons.xbutton2 then
		self:uncapture_mouse()
		self.frontend:_backend_mouseup('x2', x, y)
	end
end

local wsl_buf = ffi.new'UINT[1]'
local function wheel_scroll_lines()
	winapi.SystemParametersInfo(winapi.SPI_GETWHEELSCROLLLINES, 0, wsl_buf)
	return wsl_buf[0]
end

function Mouse:on_mouse_wheel(x, y, buttons, delta)
	if (delta - 1) % 120 == 0 then --correction for my ms mouse when scrolling back
		delta = delta - 1
	end
	delta = delta / 120 * wheel_scroll_lines()
	local cx, cy = self.backend:get_client_pos()
	x = x - cx
	y = y - cy
	self.backend:_setmouse(x, y, buttons)
	self.frontend:_backend_mousewheel(delta, x, y)
end

local buf = ffi.new'UINT[1]'
local function wheel_scroll_chars()
	winapi.SystemParametersInfo(winapi.SPI_GETWHEELSCROLLCHARS, 0, buf)
	return buf[0]
end

function Mouse:on_mouse_hwheel(x, y, buttons, delta)
	delta = delta / 120 * wheel_scroll_chars()
	self.backend:_setmouse(x, y, buttons)
	self.frontend:_backend_mousehwheel(delta, x, y)
end

function mouse:mouse_pos()
	return winapi.GetMessagePos()
end

glue.update(window, mouse)
glue.update(Window, Mouse)

--rendering/common -----------------------------------------------------------

local rendering = {}
local Rendering = {}

function rendering:_repaint(hdc)
	if not self.frontend:events() then
		self:invalidate()
	else
		if not self._nosync and self:invalid() then
			self.frontend:_backend_sync()
		end
		self._nosync = false
		self:_paint_bitmap(hdc)
		self:_paint_gl(hdc)
	end
	--draw the default Windows background next time if not custom-painting.
	self._windows_background = not (self._bitmap or self._hrc)
end
function Rendering:on_paint(hdc)
	self.backend:_repaint(hdc)
end

function Rendering:WM_ERASEBKGND()
	if not self.backend._windows_background then
		return false
	end
end

--rendering/bitmap -----------------------------------------------------------

function rendering:_create_bitmap()
	local w, h = self:_bitmap_size()
	w = math.max(1, w)
	h = math.max(1, h)
	if not self._bitmap or w ~= self._bitmap.w or h ~= self._bitmap.h then
		self:_free_bitmap()
		self._bitmap = winapi.DIBitmap(w, h, self.win.hwnd)
	end
end

function rendering:bitmap()
	self:_create_bitmap()
	return self._bitmap
end

function rendering:_free_bitmap()
	if not self._bitmap then return end
	self.frontend:_backend_free_bitmap(self._bitmap)
	self._bitmap:free()
	self._bitmap = nil
end

function rendering:_paint_bitmap(hdc)
	self.frontend:_backend_repaint()
	if not self._bitmap then return end
	self._bitmap:paint(hdc)
end

--rendering/opengl -----------------------------------------------------------

local gl = glue.memoize(function()
	require'winapi.gl11'
	require'winapi.wglext'
	return winapi.gl
end)

function rendering:_init_opengl(t)
	if not t then return end

	local gl = gl()
	self._hdc = winapi.GetDC(self.win.hwnd)

	local pfd = winapi.PIXELFORMATDESCRIPTOR{
		flags = 'PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER',
		pixel_type = 'PFD_TYPE_RGBA',
		cColorBits = 32,
		cDepthBits = 24,
		cStencilBits = 8,
		layer_type = 'PFD_MAIN_PLANE',
	}
	winapi.SetPixelFormat(self._hdc, winapi.ChoosePixelFormat(self._hdc, pfd), pfd)
	self._hrc = gl.wglCreateContext(self._hdc)

	if t.vsync then
		if gl.wglSwapIntervalEXT then
			gl.wglSwapIntervalEXT(t.vsync == true and 1 or t.vsync)
		end
	end

	gl.wglMakeCurrent(self._hdc, self._hrc)

	if gl.wglChoosePixelFormatARB then
		local pixelFormat = ffi.new'int32_t[1]'
		local numFormats = ffi.new'uint32_t[1]'
		local fAttributes = ffi.new('float[?]', 2)
		local opts = {
			winapi.WGL_DRAW_TO_WINDOW_ARB, gl.GL_TRUE,
			winapi.WGL_SUPPORT_OPENGL_ARB, gl.GL_TRUE,
			winapi.WGL_ACCELERATION_ARB, winapi.WGL_FULL_ACCELERATION_ARB,
			winapi.WGL_COLOR_BITS_ARB, 32,
			winapi.WGL_DEPTH_BITS_ARB, 16,
			winapi.WGL_ALPHA_BITS_ARB, 8,
			winapi.WGL_STENCIL_BITS_ARB, 0,
			winapi.WGL_DOUBLE_BUFFER_ARB, gl.GL_TRUE,
			winapi.WGL_SAMPLE_BUFFERS_ARB, gl.GL_TRUE,
			winapi.WGL_SAMPLES_ARB, 4, --4x FSAA
			0, 0}
		local iAttributes = ffi.new('int32_t[?]', #opts, opts)

		--First We Check To See If We Can Get A Pixel Format For 4 Samples
		local valid = gl.wglChoosePixelFormatARB(self._hdc, iAttributes,
			fAttributes, 1, pixelFormat, numFormats)

		if valid == 0 or numFormats[0] == 0 then
			-- Our Pixel Format With 4 Samples Failed, Test For 2 Samples
			iAttributes[19] = 2
			valid = gl.wglChoosePixelFormatARB(self._hdc, iAttributes,
				fAttributes, 1, pixelFormat, numFormats)
		end

		if not (valid == 0 or numFormats[0] == 0) then
			--TODO: finish this
			--winapi.SetPixelFormat(self._hdc, pixelFormat[0], pfd)
		end
	end
end

function rendering:_free_opengl()
	if not self._hrc then return end
	local gl = gl()
	gl.wglDeleteContext(self._hrc)
	gl.wglMakeCurrent(self._hdc, nil)
	self._hrc = nil
	self._hdc = nil
end

function rendering:_paint_gl(hdc)
	if not self._hrc then return end
	assert(self._hdc == hdc, 'WGL need CS_OWNDC')
	local gl = gl()
	gl.wglMakeCurrent(self._hdc, self._hrc)
	self.frontend:_backend_repaint()
	if not self._gl_swap then return end
	winapi.SwapBuffers(hdc)
	self._gl_swap = false
end

function rendering:gl()
	self._gl_swap = true
	return gl()
end

--rendering/window -----------------------------------------------------------

function window:_update_layered()
	if not self._bitmap then return end
	local r = self.win.screen_rect
	self._bitmap:update_layered(self.win.hwnd, r.x, r.y)
end

--clear the bitmap's pixels and update the layered window.
function window:_clear_layered()
	if not self._bitmap or not self._layered then return end
	self._bitmap:clear()
	self:_update_layered()
end

function rendering:repaint(clock) --called by the main loop, not by Windows.
	if self._invalid_clock > clock then
		return
	end
	self._invalid_clock = 1/0
	if not self.win.visible then
		self.frontend:_backend_sync()
	elseif self._layered then
		self.frontend:_backend_sync()
		self.frontend:_backend_repaint()
		self:_update_layered()
	else
		self.frontend:_backend_sync()
		self._nosync = true --prevent _backend_sync() in WM_PAINT
		self.win:invalidate()
		self.win:update() --force WM_PAINT
	end
end

function window:invalidate(invalid_clock)
	self._invalid_clock =
		math.min(invalid_clock or -1/0, self._invalid_clock or 1/0)
end

function window:invalid(at_clock)
	return (at_clock or time.clock()) >= self._invalid_clock
end

window._bitmap_size = window.get_client_size

glue.update(window, rendering)
glue.update(Window, Rendering)

--views ----------------------------------------------------------------------

local view = {}
window.view = view

local View = winapi.subclass({}, winapi.Panel)

function view:new(window, frontend, t)
	local self = glue.update({
		window = window,
		app = window.app,
		frontend = frontend,
	}, self)

	self.win = View{
		parent = window.win,
		x = t.x, y = t.y, w = t.w, h = t.h,
		own_dc = true, --for opengl
		visible = false,
	}
	self.win.backend = self
	self.win.frontend = frontend

	self:_init_opengl(t.opengl)

	return self
end

function view:visible()
	return self.win.visible
end

function view:show()
	self.win:show() --sync call
end

function view:hide()
	self.win:hide() --sync call
end

function view:get_rect()
	local r = self.win.rect
	return r.x, r.y, r.w, r.h
end

function view:set_rect(x, y, w, h)
	self.win.rect = pack_rect(nil, x, y, w, h)
end

function view:invalidate(...)
	self.win:invalidate(...)
end

function view:_bitmap_size()
	return select(3, self:get_rect())
end

function view:free()
	self:_free_bitmap()
	self:_free_opengl()
	self.win:free()
	self.win = nil
end

function View:on_moved()
	self.frontend:_backend_changed()
end

function View:on_resized()
	self.frontend:_backend_changed()
end

glue.update(view, mouse, rendering)
glue.update(View, Mouse, Rendering)

--hi-dpi support -------------------------------------------------------------

function app:get_autoscaling()
	if self.frontend:ver'Windows 6.3' then --Win8.1+ per-monitor DPI
		return winapi.GetProcessDPIAwareness() == winapi.PROCESS_DPI_UNAWARE
	elseif self.frontend:ver'Windows 6.0' then --Vista+ global DPI
		return not winapi.IsProcessDPIAware()
	end
end

--NOTE: must call this before the stretcher kicks in, i.e. before creating
--any windows or calling monitor APIs. It will silently fail otherwise!
function app:disable_autoscaling()
	if self._scaling_disabled then return end --must not call these APIs twice
	if self.frontend:ver'Windows 6.3' then --Win8.1+ per-monitor DPI
		winapi.SetProcessDPIAwareness(winapi.PROCESS_PER_MONITOR_DPI_AWARE)
	elseif self.frontend:ver'Windows 6.0' then --Vista+ global DPI
		winapi.SetProcessDPIAware()
	end
	self._scaling_disabled = true --disable_autoscaling() barrier
end

function app:enable_autoscaling()
	--NOTE: autoscaling can't be re-enabled once disabled.
end

function app:_get_scaling_factor(monitor)
	if self.frontend:ver'Windows 6.3' then
		--in Win8.1+ we have per-monitor DPI
		local dpi = winapi.GetDPIForMonitor(monitor, winapi.MDT_EFFECTIVE_DPI)
		return dpi / 96
	else
		--before Win8.1 we only have a global DPI (that of primary monitor).
		--this value can't be changed without logoff so it's safe to memoize.
		if not self._scalingfactor then
			local hwnd = winapi.GetDesktopWindow()
			local hdc = winapi.GetDC(hwnd)
			local dpi = winapi.GetDeviceCaps(hdc, winapi.LOGPIXELSX)
			winapi.ReleaseDC(hwnd, hdc)
			self._scalingfactor = dpi / 96
		end
		return self._scalingfactor
	end
end

function Window:on_dpi_change(dpix)
	self.frontend:_backend_scalingfactor_changed(dpix / 96)
end

--menus ----------------------------------------------------------------------

local menu = {}

function app:menu()
	return menu:_new(winapi.Menu())
end

function menu:_new(winmenu)
	local self = glue.update({winmenu = winmenu}, menu)
	winmenu.nw_backend = self
	return self
end

local function menuitem(args)
	return {
		text = args.text,
		separator = args.separator,
		on_click = args.action,
		submenu = args.submenu and args.submenu.backend.winmenu,
		checked = args.checked,
		enabled = args.enabled,
	}
end

local function dump_menuitem(mi)
	return {
		text = mi.text,
		action = mi.submenu and mi.submenu.nw_backend.frontend or mi.on_click,
		checked = mi.checked,
		enabled = mi.enabled,
	}
end

function menu:add(index, args)
	return self.winmenu.items:add(index, menuitem(args))
end

function menu:set(index, args)
	self.winmenu.items:set(index, menuitem(args))
end

function menu:get(index)
	return dump_menuitem(self.winmenu.items:get(index))
end

function menu:item_count()
	return self.winmenu.items.count
end

function menu:remove(index)
	self.winmenu.items:remove(index)
end

function menu:get_checked(index)
	return self.winmenu.items:checked(index)
end

function menu:set_checked(index, checked)
	self.winmenu.items:setchecked(index, checked)
end

function menu:get_enabled(index)
	return self.winmenu.items:enabled(index)
end

function menu:set_enabled(index, enabled)
	self.winmenu.items:setenabled(index, enabled)
end

function window:menubar()
	if not self._menu then
		local menubar = winapi.MenuBar()
		self.win.menu = menubar
		self._menu = menu:_new(menubar)
	end
	return self._menu
end

function window:popup(menu, x, y)
	menu.backend.winmenu:popup(self.win, x, y)
end

--notification icons ---------------------------------------------------------

local notifyicon = {}
app.notifyicon = notifyicon

local NotifyIcon = winapi.subclass({}, winapi.NotifyIcon)

--get the singleton hidden window used to route mouse messages through.
local notifywindow
function notifyicon:_notify_window()
	notifywindow = notifywindow or winapi.Window{visible = false}
	return notifywindow
end

function notifyicon:new(app, frontend, opt)
	self = glue.update({app = app, frontend = frontend}, notifyicon)

	self.ni = NotifyIcon{window = self:_notify_window()}
	self.ni.backend = self
	self.ni.frontend = frontend

	self:_init_icon_api()

	return self
end

function notifyicon:free()
	self.ni:free()
	self:_free_icon()
	self.ni = nil
end

function NotifyIcon:on_rbutton_up()
	--if a menu was assigned, pop it up on right-click.
	local menu = self.backend.menu
	if menu and not menu:dead() then
		local win = self.backend:_notify_window()
		local pos = win.cursor_pos
		menu.backend.winmenu:popup(win, pos.x, pos.y)
	end
end

--make an API composed of three functions: one that gives you a bgra8 bitmap
--to draw into, another that creates a new icon everytime it is called with
--the contents of that bitmap, and a third one to free the icon and bitmap.
--the bitmap is recreated only if the icon size changed since last access.
--the bitmap is in bgra8 format, premultiplied alpha.
local function icon_api(which)

	local w, h, bmp, data, maskbmp

	local function free_bitmaps()
		if not bmp then return end
		winapi.DeleteObject(bmp)
		winapi.DeleteObject(maskbmp)
		w, h, bmp, data, maskbmp = nil
	end

	local function recreate_bitmaps(w1, h1)
		free_bitmaps()
		w, h = w1, h1
		--create a bgra8 bitmap.
		bmp, data = winapi.DIBitmap(w, h)
		--create an empty mask bitmap.
		maskbmp = winapi.CreateBitmap(w, h, 1, 1)
	end

	local icon

	local function free_icon()
		if not icon then return end
		winapi.DestroyIcon(icon)
		icon = nil
	end

	local function recreate_icon()
		free_icon()

		local ii = winapi.ICONINFO()
		ii.fIcon = true --icon, not cursor
		ii.xHotspot = 0
		ii.yHotspot = 0
		ii.hbmMask = maskbmp
		ii.hbmColor = bmp

		icon = winapi.CreateIconIndirect(ii)
	end

	local function size()
		local SM = which == 'small' and 'SM_CXSMICON' or 'SM_CXICON'
		local w = winapi.GetSystemMetrics(SM)
		local h = winapi.GetSystemMetrics(SM)
		return w, h
	end

	local bitmap

	local function get_bitmap()
		local w1, h1 = size()
		if w1 ~= w or h1 ~= h then
			recreate_bitmaps(w1, h1)
			bitmap = {
				w = w,
				h = h,
				data = data,
				stride = w * 4,
				size = w * h * 4,
				format = 'bgra8',
			}
		end
		return bitmap
	end

	local function get_icon()
		if not bmp then return end

		--counter-hack: in windows, an all-around zero-alpha image is shown as black.
		--we set the second pixel's alpha to a non-zero value to prevent this.
		local data = ffi.cast('int8_t*', data)
		for i = 3, w * h - 1, 4 do
			if data[i] ~= 0 then goto skip end
		end
		data[7] = 1 --write a low alpha value to the second pixel so it looks invisible.
		::skip::

		recreate_icon()
		return icon
	end

	local function free_all()
		free_bitmaps()
		free_icon()
	end

	return get_bitmap, get_icon, free_all
end

function notifyicon:_init_icon_api()
	self.bitmap, self._get_icon, self._free_icon = icon_api()
end

function notifyicon:invalidate()
	self.frontend:_backend_repaint()
	self.ni.icon = self:_get_icon()
end

function notifyicon:get_tooltip()
	return self.ni.tip
end

function notifyicon:set_tooltip(tooltip)
	self.ni.tip = tooltip
end

function notifyicon:get_menu()
	return self.menu
end

function notifyicon:set_menu(menu)
	self.menu = menu
end

function notifyicon:rect()
	return 0, 0, 0, 0 --TODO
end

--window icon ----------------------------------------------------------------

local function whicharg(which)
	assert(which == nil or which == 'small' or which == 'big')
	return which == 'small' and 'small' or 'big'
end

function window:_add_icon_api(which)
	which = whicharg(which)
	local get_bitmap, get_icon, free_all = icon_api(which)
	self._icon_api[which] = {get_bitmap = get_bitmap, get_icon = get_icon, free_all = free_all}
end

function window:_init_icon_api()
	self._icon_api = {}
	self:_add_icon_api'big'
	self:_add_icon_api'small'
end

function window:_call_icon_api(which, name, ...)
	return self._icon_api[which][name](...)
end

function window:_free_icon()
	self.win.icon = nil --must release the old ones first so we can free them.
	self.win.small_icon = nil --must release the old ones first so we can free them.
	self:_call_icon_api('big', 'free_all')
	self:_call_icon_api('small', 'free_all')
end

function window:icon_bitmap(which)
	which = whicharg(which)
	return self:_call_icon_api(which, 'get_bitmap')
end

function window:invalidate_icon(which)
	--TODO: both methods below work equally bad. The taskbar icon is not updated :(
	which = whicharg(which)
	self.frontend:_backend_repaint_icon(which)
	if false then
		winapi.SendMessage(self.win.hwnd, 'WM_SETICON',
			which == 'small' and winapi.ICON_SMALL or winapi.ICON_BIG,
			self:_call_icon_api(which, 'get_icon'))
	else
		local name = which == 'small' and 'small_icon' or 'icon'
		self.win[name] = nil --must release the old one first so we can free it.
		self.win[name] = self:_call_icon_api(which, 'get_icon')
	end
end

--file chooser ---------------------------------------------------------------

--given a list of file types eg. {'gif', ...} make a list of filters
--to pass to open/save dialog functions.
--we can't allow wildcards and custom text because OSX doesn't (so english only).
local function make_filters(filetypes)
	if not filetypes then
		--like in OSX, no filetypes means all filetypes.
		return {'All Files', '*.*'}
	end
	local filter = {}
	for i,ext in ipairs(filetypes) do
		table.insert(filter, ext:upper() .. ' Files')
		table.insert(filter, '*.' .. ext:lower())
	end
	return filter
end

function app:opendialog(opt)
	local filter = make_filters(opt.filetypes)

	local flags = opt.multiselect
		and bit.bor(winapi.OFN_ALLOWMULTISELECT, winapi.OFN_EXPLORER) or 0

	local ok, info = winapi.GetOpenFileName{
		title = opt.title,
		filter = filter,
		filter_index = 1, --first in list is default, like OSX
		flags = flags,
		initial_dir = opt.initial_dir,
	}

	if not ok then return end
	return winapi.GetOpenFileNamePaths(info)
end

function app:savedialog(opt)
	local filter = make_filters(opt.filetypes)

	local ok, info = winapi.GetSaveFileName{
		title = opt.title,
		filter = filter,
		--default is first in list (not optional in OSX)
		filter_index = 1,
		--append filetype automatically (not optional in OSX)
		--if user types in a file extension, the filetype will still be appended
		--but only if it's not in the list of accepted filetypes.
		--fortunately, this matches OSX behavior exactly.
		default_ext = opt.filetypes and opt.filetypes[1],
		filepath = opt.filename,
		initial_dir = opt.initial_dir,
		flags = 'OFN_OVERWRITEPROMPT', --like in OSX
	}

	if not ok then return end
	return info.filepath
end

--clipboard ------------------------------------------------------------------

function app:clipboard_empty(format)
	return winapi.CountClipboardFormats() == 0
end

local clipboard_formats = {
	[winapi.CF_TEXT] = 'text',
	[winapi.CF_UNICODETEXT] = 'text',
	[winapi.CF_HDROP] = 'files',
	[winapi.CF_DIB] = 'bitmap',
	[winapi.CF_DIBV5] = 'bitmap',
	[winapi.CF_BITMAP] = 'bitmap',
}

local function with_clipboard(func)
	if not winapi.OpenClipboard() then
		return
	end
	local ok, ret = glue.pcall(func)
	winapi.CloseClipboard()
	if not ok then error(ret, 2) end
	return ret
end

function app:get_clipboard_formats()
	return with_clipboard(function()
		local names = winapi.GetClipboardFormatNames()
		local t = {}
		for i=1,#names do
			local format = clipboard_formats[names[i]]
			if format then
				t[format] = true
			end
		end
		return t
	end)
end

function app:get_clipboard_data(format)
	return with_clipboard(function()
		if format == 'text' then
			return winapi.GetClipboardText()
		elseif format == 'files' then
			return winapi.GetClipboardFiles()
		elseif format == 'bitmap' then
			--NOTE: Windows synthesizes bitmap formats so we can always get
			--a CF_DIBV5 even if only CF_BITMAP or CF_DIB is listed.
			return winapi.GetClipboardDataBuffer('CF_DIBV5', function(buf, bufsize)

				local info = ffi.cast('BITMAPV5HEADER*', buf)

				--check if format is supported. palette formats are not supported!
				if info.bV5BitCount ~= 32 and info.bV5BitCount ~= 24 then return end
				if info.bV5Compression ~= winapi.BI_BITFIELDS
					and info.bV5Compression ~= winapi.BI_RGB then return end
				if info.bV5ProfileSize > 0 then return end

				--get bitmap metadata.
				local w = info.bV5Width
				local h = math.abs(info.bV5Height)
				local bpp = info.bV5BitCount
				local bitfields = info.bV5Compression == winapi.BI_BITFIELDS
				local format = bpp == 32 and (bitfields and 'bgra8' or 'bgrx8') or 'bgr8'
				local stride = bitmap.aligned_stride(w * bpp / 8)
				local size = stride * h
				local bottom_up = info.bV5Height >= 0 or nil

				--find the pixels: work around a winapi bug where there's
				--sometimes a 12 bytes gap between the header and the pixels.
				local gap = bitfields and (bufsize - info.bV5Size) > size and 12 or 0
				local data = ffi.cast('void*', ffi.cast('char*', buf) + info.bV5Size + gap)

				--create a temporary bitmap.
				local bmp = {w = w, h = h, format = format, stride = stride,
					size = size, data = data, bottom_up = bottom_up}

				--copy the bitmap because we don't own the memory, and also
				--because it may need to be converted to bgra8.
				return bitmap.copy(bmp, 'bgra8', false)
			end)
		end
	end)
end

function app:set_clipboard(t)
	return with_clipboard(function()
		winapi.EmptyClipboard()
		for i,t in ipairs(t) do
			local data, format = t.data, t.format
			if format == 'text' then
				winapi.SetClipboardText(data)
			elseif format == 'files' then
				winapi.SetClipboardFiles(data)
			elseif format == 'bitmap' then
				--NOTE: Windows synthesizes bitmap formats so it's enough to put
				--a CF_DIBV5 bitmap to be able to get a CF_BITMAP or CF_DIB.
				local bmp = data
				assert(bmp.format == 'bgra8', 'invalid bitmap format')
				local data_offset = ffi.sizeof'BITMAPV5HEADER'
				local dib_size = data_offset + bmp.size
				winapi.SetClipboardDataBuffer('CF_DIBV5', nil, dib_size, function(buf)
					--make a packed DIB and copy the pixels to it.
					local bi = dib_header(bmp.w, bmp.h, ffi.cast('BITMAPV5HEADER*', buf))
					local data_ptr = ffi.cast('uint8_t*', buf) + data_offset
					ffi.copy(data_ptr, bmp.data, bmp.size)
				end)
			else
				assert(false) --invalid args from frontend
			end
		end
		return true
	end) or false
end

--drag & drop ----------------------------------------------------------------

local ptonumber = winapi.ptonumber

function Window:WM_DROPFILES(hdrop)
	local files = winapi.DragQueryFiles(hdrop)
	local p, in_client_area = winapi.DragQueryPoint(hdrop)
	if not in_client_area then return end
	self.frontend:_backend_drop_files(p.x, p.y, files)
	winapi.DragFinish(hdrop)
end

--interface -> backend mapping

local imap = setmetatable({}, {__mode = 'v'})

function backend(self)
	return imap[ptonumber(self)]
end

function setbackend(self, backend)
	imap[ptonumber(ffi.cast('void*', self))] = backend
end

--IUnknown

local function QueryInterface(self, riid, ppvobject)
	ppvobject[0] = nil
	return E_NOINTERFACE
end

local function AddRef(self)
	self.refcount = self.refcount + 1
	return self.refcount
end

local function Release(self)
	self.refcount = self.refcount - 1
	return self.refcount
end

--IDropSource

local function QueryContinueDrag(self, esc_pressed, key_state)
	if esc_pressed ~= 0 then
		return winapi.DRAGDROP_S_CANCEL
	end
	if bit.band(key_state, winapi.MK_LBUTTON) == 0 then
		return winapi.DRAGDROP_S_DROP
	end
	return 0
end

local function GiveFeedback(self, dwEffect)
	return winapi.DRAGDROP_S_USEDEFAULTCURSORS
end

function window:start_drag()
	local data_object = ffi.new'IDataObject'
	local drop_source = ffi.new'IDropSource'
	drop_source.QueryContinueDrag = QueryContinueDrag
	drop_source.GiveFeedback = GiveFeedback
	setbackend(drop_source, self)

	--local ok_effects =
	--local effect =
	winapi.DoDragDrop(data_object, drop_source, ok_effects, effect)
end

--IDropTarget

local effects = {
	copy = winapi.DROPEFFECT_COPY,
	link = winapi.DROPEFFECT_LINK,
	none = winapi.DROPEFFECT_NONE,
	abort = winapi.DROPEFFECT_NONE,
}

local function drag_result(res, peffect)
	peffect[0] = effects[res]
	return res == 'abort' and 1 or 0
end

local function drag_payload(idataobject)

	--get an enumerator
	local ienum = ffi.new'IEnumFORMATETC*[1]'
	winapi.checkz(idataobject.lpVtbl.EnumFormatEtc(idataobject,
		winapi.DATADIR_GET, ienum))
	ienum = ienum[0]

	--get the data
	local t = {}
	local etc = ffi.new'FORMATETC'
	local stg = ffi.new'STGMEDIUM'

	while ienum.lpVtbl.Next(ienum, 1, etc, nil) == 0 do

		local format = clipboard_formats[etc.cfFormat]

		if format and not t[format] then --take only the first item for each format

			glue.fcall(function(finally)
				winapi.checkz(idataobject.lpVtbl.GetData(idataobject, etc, stg))
				finally(function() winapi.ReleaseStgMedium(stg) end)
				if stg.tymed == winapi.TYMED_HGLOBAL then
					local data
					local buf = winapi.GlobalLock(stg.hGlobal)
					finally(function() winapi.GlobalUnlock(stg.hGlobal) end)
					if format == 'text' then
						data = winapi.mbs(ffi.cast('WCHAR*', buf))
					elseif format == 'files' then
						local hdrop = ffi.cast('HDROP', buf)
						data = winapi.DragQueryFiles(hdrop)
					end
					t[format] = data
				end
			end)
		end
	end

	--release the enumerator
	ienum.lpVtbl.Release(ienum)

	return t
end

local function DragEnter(self, idataobject, key_state, x, y, peffect)
	local backend = backend(self)
	backend._drag_payload = drag_payload(idataobject)
	x, y = backend.frontend:to_client(x, y)
	return drag_result(backend.frontend:_backend_dragging('enter',
		backend._drag_payload, x, y), peffect)
end

local function DragOver(self, key_state, x, y, peffect)
	local backend = backend(self)
	x, y = backend.frontend:to_client(x, y)
	return drag_result(backend.frontend:_backend_dragging('hover',
		backend._drag_payload, x, y), peffect)
end

local function Drop(self, idataobject, key_state, x, y, peffect)
	local backend = backend(self)
	x, y = backend.frontend:to_client(x, y)
	drag_result(backend.frontend:_backend_dragging('drop',
		backend._drag_payload, x, y), peffect)
	backend._drag_payload = nil
	return 0 --S_OK
end

local function DragLeave(self)
	local backend = backend(self)
	backend.frontend:_backend_dragging'leave'
	backend._drag_payload = nil
	return 0 --S_OK
end

if ffi.abi'64bit' then
	--TODO: wrap with cbframe because of pt.
	DragEnter = nil
	DragOver = nil
	Drop = nil
end

local dtvtbl = ffi.new'IDropTargetVtbl'
dtvtbl.QueryInterface = QueryInterface
dtvtbl.AddRef = AddRef
dtvtbl.Release = Release
dtvtbl.DragEnter = DragEnter
dtvtbl.DragOver = DragOver
dtvtbl.DragLeave = DragLeave
dtvtbl.Drop = Drop

function window:_init_drop_target()
	local dt = ffi.new'IDropTarget'
	dt.lpVtbl = dtvtbl
	dt.refcount = 0
	setbackend(dt, self)
	winapi.RegisterDragDrop(self.win.hwnd, dt)
	self._drop_target = dt
end

function window:_free_drop_target()
	winapi.RevokeDragDrop(self.win.hwnd)
end

--tooltips -------------------------------------------------------------------

function window:set_tooltip(text)
	if self._tooltip_text == text then
		--using a same-text barrier because setting the tooltip's text
		--invalidates the tooltip's parent window which flickers the tooltip.
		return
	end
	self._tooltip_text = text
	if text then
		if not self._tooltip then
			self._tooltip = winapi.Tooltip{
				parent = self.win,
				text = text,
			}
		else
			self._tooltip.text = text --NOTE: this invalidates the window
			self._tooltip.rect = self.win.client_rect
			self._tooltip.active = true
		end
	elseif self._tooltip then
		self._tooltip.active = false
	end
end

function window:get_tooltip()
	return self._tooltip and self._tooltip_text or false
end

return nw
