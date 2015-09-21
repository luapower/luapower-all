
--native windows - frontend.
--Written by Cosmin Apreutesei. Public domain.

local ffi   = require'ffi'
local glue  = require'glue'
local box2d = require'box2d'
local time  = require'time'
local nw    = {}
local backends = {
	Windows = 'nw_winapi',
	OSX     = 'nw_cocoa',
	Linux   = 'nw_xlib',
}
local bkname = assert(backends[ffi.os], 'unsupported OS %s', ffi.os)
nw.backend = require(bkname)
nw.backend.frontend = nw

--helpers --------------------------------------------------------------------

local assert = glue.assert --assert with string.format
local indexof = glue.indexof

local function optarg(opt, true_arg, false_arg, nil_arg)
	opt = glue.index(opt)
	return function(arg)
		if arg == true then
			return true_arg
		elseif arg == false then
			return false_arg
		elseif arg == nil then
			return nil_arg
		elseif opt[arg] then
			return arg
		else
			error('invalid argument', 2)
		end
	end
end

--oo -------------------------------------------------------------------------

local object = {}

function object:dead()
	return self._dead or false
end

function object:_check()
	assert(not self._dead, 'dead object')
end

--create a read/write property that is implemented via a getter and setter in the backend.
function object:_property(name)
	local getter = 'get_'..name
	local setter = 'set_'..name
	self[name] = function(self, on)
		self:_check()
		if on == nil then
			return self.backend[getter](self.backend)
		else
			self.backend[setter](self.backend, on)
		end
	end
end

--events ---------------------------------------------------------------------

--register a function to be called for a specific event
function object:on(event, func)
	glue.attr(glue.attr(self, '_observers'), event)[func] = true --{event = {func = true}}
end

--handle a query event by calling its event handler
function object:_handle(event, ...)
	if self._dead then return end
	if self._events_disabled then return end
	if not self[event] then return end
	return self[event](self, ...)
end

--fire an event, i.e. call observers and create a meta event 'event'
function object:_fire(event, ...)
	if self._dead then return end
	if self._events_disabled then return end
	--call any observers
	if self._observers and self._observers[event] then
		for obs in pairs(self._observers[event]) do
			obs(self, ...)
		end
	end
	--fire the meta-event 'event'
	if event ~= 'event' then
		self:_event('event', event, ...)
	end
end

--handle and fire a non-query event.
function object:_event(event, ...)
	self:_handle(event, ...)
	self:_fire(event, ...)
end

--handle and fire a query event.
function object:_query(event)
	local allow = self:_handle(event) ~= false
	self:_fire(event, allow)
	return allow
end

--enable or disable events. returns the old state.
function object:events(enabled)
	if enabled == nil then
		return not self._events_disabled
	end
	local old = not self._events_disabled
	self._events_disabled = not enabled
	return old
end

--app object -----------------------------------------------------------------

local app = glue.update({}, object)

--return the singleton app object.
--load a default backend on the first call if no backend was set by the user.

function nw:app()
	if not self._app then
		self._app = app:_init(self, self.backend.app)
	end
	return self._app
end

function app:_init(nw, backend_class)
	self.nw = nw
	self._running = false
	self._windows = {} --{window1, ...}
	self._notifyicons = {} --{icon = true}
	self._autoquit = true --quit after the last window closes
	self._ignore_numlock = false --ignore the state of the numlock key on keyboard events
	self.backend = backend_class:init(self)
	self._state = self:_get_state()
	return self
end

--version checks -------------------------------------------------------------

--check if v2 >= v1, where v1 and v2 have the form 'maj.min.etc...'.
local function check_version(v1, v2)
	local v1 = v1:lower()
	local v2 = v2:lower()
	local ret
	while v1 ~= '' do       --while there's another part of ver1 to check...
		if v2 == '' then     --there's no part of ver2 to check against.
			return false
		end
		local n1, n2
		n1, v1 = v1:match'^(%d*)%.?(.*)' --eg. '3.0' -> '3', '0'
		n2, v2 = v2:match'^(%d*)%.?(.*)'
		assert(n1 ~= '', 'invalid syntax') --ver1 part is a dot.
		assert(n2 ~= '', 'invalid syntax') --ver2 part is a dot.
		if ret == nil then      --haven't decided yet
			if n1 ~= '' then     --above checks imply n2 ~= '' also.
				local n1 = tonumber(n1)
				local n2 = tonumber(n2)
				if n1 ~= n2 then  --version parts are different, decide now.
					ret = n2 > n1
				end
			end
		end
	end
	if ret ~= nil then      --a comparison has been made.
		return ret
	end
	return true             --no more parts of v1 to check.
end

local qcache = {} --{query = true|false}
function app:ver(q)
	if qcache[q] == nil then
		local what, qver = q:match'^([^%s]+)%s*(.*)$'
		assert(what, 'invalid query')
		local ver = self.backend:ver(what:lower())
		qcache[q] = ver and (qver == '' and ver or check_version(qver, ver)) or false
	end
	return qcache[q]
end

--message loop and timers ----------------------------------------------------

local password = {} --distinguish yielding via app:sleep() from other yielding

--sleep function that can be used inside the function passed to app:run().
--unlike time.sleep(), it allows processing of events while waiting.
function app:sleep(seconds) --no arg, true or false means sleep forever.
	coroutine.yield(password, seconds or true)
end

--start the main loop and/or run a function asynchronously.
function app:run(func)

	--schedule to run a function asynchronously.
	if func then
		local proc = coroutine.wrap(function()
			local ok, err = xpcall(func, debug.traceback)
			if not ok then
				error(err, 2)
			end
			coroutine.yield(password) --proc finished
		end)
		local was_running = self._running
		local function step()
			local pwd, sleep_time = proc()
			assert(pwd == password, 'yield in async proc')
			if not sleep_time then --proc finished
				--if app was not running when we started, stop it back
				if not was_running then
					self:stop()
				end
				return
			end
			if sleep_time == true then return end --sleep forever
			self:runafter(sleep_time, step)
		end
		self:runafter(0, step)
	end

	if self._running then return end --ignore while running
	self._running = true --run() barrier
	self.backend:run()
	self._running = false
	self._stopping = false --stop() barrier
end

function app:step()
	self.backend:step()
end

function app:running()
	return self._running
end

function app:stop()
	if not self._running then return end --ignore while not running
	if self._stopping then return end --ignore repeated attempts
	self._stopping = true
	self.backend:stop()
end

function app:runevery(seconds, func)
	seconds = math.max(0, seconds)
	self.backend:runevery(seconds, func)
end

function app:runafter(seconds, func)
	self:runevery(seconds, function()
		func()
		return false
	end)
end

--quitting -------------------------------------------------------------------

function app:autoquit(autoquit)
	if autoquit == nil then
		return self._autoquit
	else
		self._autoquit = autoquit
	end
end

--ask the app and all windows if they can quit. need unanimous agreement to quit.
function app:_canquit()
	self._quitting = true --quit() barrier

	local allow = self:_query'quitting' ~= false

	for i,win in ipairs(self:windows()) do
		if not win:dead() and not win:parent() then
			allow = win:_canclose() and allow
		end
	end

	self._quitting = nil
	return allow
end

function app:_forcequit()
	self._quitting = true --quit() barrier

	local t = self:windows()
	for i = #t, 1, -1 do
		local win = t[i]
		if not win:dead() and not win:parent() then
			win:close'force'
		end
	end

	if self:windows'#' == 0 then --no windows created while closing
		--free notify icons otherwise they hang around (both in XP and in OSX).
		self:_free_notifyicons()
		self:_free_dockicon()
		self:stop()
	end

	self._quitting = nil
end

function app:quit()
	if self._quitting then return end --ignore if already quitting
	if not self._running then return end --ignore if not running
	if self:_canquit() then
		self:_forcequit()
	end
end

function app:_backend_quitting()
	self:quit()
end

--window list ----------------------------------------------------------------

--get existing windows in creation order
function app:windows(arg, filter)
	if arg == '#' then
		if filter == 'root' then
			local n = 0
			for i,win in ipairs(self._windows) do
				n = n + (not win:dead() and not win:parent() and 1 or 0)
			end
			return n
		end
		return #self._windows
	end
	return glue.update({}, self._windows) --take a snapshot
end

function app:_window_created(win)
	table.insert(self._windows, win)
	self:_event('window_created', win)
end

function app:_window_closed(win)
	self:_event('window_closed', win)
	table.remove(self._windows, indexof(win, self._windows))
end

--windows --------------------------------------------------------------------

local window = glue.update({}, object)

local defaults = {
	--state
	visible = true,
	minimized = false,
	maximized = false,
	enabled = true,
	--positioning
	min_cw = 1,
	min_ch = 1,
	--frame
	title = '',
	transparent = false,
	--behavior
	topmost = false,
	minimizable = true,
	maximizable = true,
	closeable = true,
	resizeable = true,
	fullscreenable = true,
	activable = true, --only for 'toolbox' frames
	autoquit = false, --quit the app on closing
	edgesnapping = 'screen',
	sticky = false, --only for child windows
}

--default overrides for parented windows
local defaults_child = {
	minimizable = false,
	maximizable = false,
	fullscreenable = false,
	edgesnapping = 'parent siblings screen',
	sticky = true,
}

local opengl_defaults = {
	version = '1.0',
	vsync = true,
	fsaa = false,
}

local function opengl_options(t)
	if not t then return end
	local glopt = glue.update({}, opengl_defaults)
	if t ~= true then
		glue.update(glopt, t)
	end
	return glopt
end

local frame_types = glue.index{'normal', 'none', 'toolbox'}
local function checkframe(frame)
	frame =
		frame == true and 'normal' or
		frame == false and 'none' or
		frame or 'normal'
	assert(frame_types[frame], 'invalid frame type')
	return frame
end

function app:window(t)
	return window:_new(self, self.backend.window, t)
end

function window:_new(app, backend_class, useropt)

	--check/normalize args.
	local frame = checkframe(useropt.frame)
	local opt = glue.update({frame = frame},
		defaults,
		useropt.parent and defaults_child or nil,
		useropt)
	opt.opengl = opengl_options(useropt.opengl)

	if opt.parent then
		--prevent creating child windows in parent's closed() event or after.
		assert(not opt.parent._closed, 'parent is closed')
		--child windows can't be minimizable because they don't show in taskbar.
		assert(not opt.minimizable,    'child windows cannot be minimizable')
		assert(not opt.minimized,      'child windows cannot be minimized')
		--child windows can't be maximizable or fullscreenable (X11 limitation).
		assert(not opt.maximizable,    'child windows cannot be maximizable')
		assert(not opt.fullscreenable, 'child windows cannot be fullscreenable')
	end

	if opt.sticky then
		assert(opt.parent, 'sticky windows must have a parent')
	end

	--unparented toolboxes don't make sense because they don't show in taskbar
	--so they can't be activated when they are completely behind other windows.
	--they can't be (minimiz|maximiz|fullscreen)able either (winapi/X11 limitation).
	if frame == 'toolbox' then
		assert(opt.parent, 'toolbox windows must have a parent')
	end

	--only toolboxes can be non-activable (winapi limitation)
	if frame ~= 'toolbox' then
		assert(opt.activable, 'only toolbox windows can be non-activable')
	end

	--transparent windows must be frameless (winapi limitation)
	if opt.transparent then
		assert(opt.frame == 'none', 'transparent windows must be frameless')
	end

	--maxsize constraints result in undefined behavior in maximized and fullscreen state.
	--they work except in Unity which doesn't respect them when maximizing.
	--also Windows doesn't center the window on screen in fullscreen mode.
	if opt.max_cw or opt.max_ch or not opt.resizeable then
		assert(not opt.maximizable, 'a maximizable window cannot have a maximum size')
		assert(not opt.fullscreenable, 'a fullscreenable window cannot have a maximum size')
	end

	--if missing some frame coords but given some client coords, convert client
	--coords to frame coords, and replace missing frame coords with the result.
	if not (opt.x and opt.y and opt.w and opt.h) and (opt.cx or opt.cy or opt.cw or opt.ch) then
		local x1, y1, w1, h1 = app:client_to_frame(
			opt.frame,
			opt.menu and true or false,
			opt.cx or 0,
			opt.cy or 0,
			opt.cw or 0,
			opt.ch or 0)
		opt.x = opt.x or (opt.cx and x1)
		opt.y = opt.y or (opt.cy and y1)
		opt.w = opt.w or (opt.cw and w1)
		opt.h = opt.h or (opt.ch and h1)
	end

	--width and height must be given, either of the client area or of the frame.
	assert(opt.w, 'w or cw expected')
	assert(opt.h, 'h or ch expected')

	--either cascading or fixating the position, there's no mix.
	assert((not opt.x) == (not opt.y),
		'both x (or cx) and y (or cy) or none expected')

	--avoid zero client sizes
	opt.min_cw = math.max(opt.min_cw, 1)
	opt.min_ch = math.max(opt.min_ch, 1)

	self = glue.update({app = app}, self)

	self._mouse = {}
	self._down = {}
	self._views = {}
	self._cursor_visible = true
	self._cursor = 'arrow'

	self.backend = backend_class:new(app.backend, self, opt)

	--stored properties
	self._parent = opt.parent
	self._frame = opt.frame
	self._transparent = opt.transparent
	self._minimizable = opt.minimizable
	self._maximizable = opt.maximizable
	self._closeable = opt.closeable
	self._resizeable = opt.resizeable
	self._fullscreenable = opt.fullscreenable
	self._activable = opt.activable
	self._autoquit = opt.autoquit
	self._sticky = opt.sticky
	self._opengl = opt.opengl
	self:edgesnapping(opt.edgesnapping)

	self._state = self:_get_state()
	self._client_rect = {self:client_rect()}
	self._frame_rect = {self:frame_rect()}

	self.app:_window_created(self)

	--windows are created hidden to allow proper setup before events start.
	if opt.visible then
		self:show()
	end

	return self
end

--closing --------------------------------------------------------------------

function window:_canclose()
	if self._closing then return false end --reject while closing (from quit() and user quit)

	self._closing = true --_backend_closing() and _canclose() barrier

	local allow = self:_query'closing' ~= false

	--children must agree too
	for i,win in ipairs(self:children()) do
		allow = win:_canclose() and allow
	end

	self._closing = nil
	return allow
end

function window:close(force)
	if force or self:_backend_closing() then
		self.backend:forceclose()
	end
end

function window:_backend_closing()
	if self._closed then return false end --reject if closed
	if self._closing then return false end --reject while closing

	if self:autoquit() or (
		self.app:autoquit()
		and not self:parent() --closing a root window
		and self.app:windows('#', 'root') == 1 --the only one
	) then
		self._quitting = true
		return self.app:_canquit()
	else
		return self:_canclose()
	end
end

function window:_backend_closed()
	if self._closed then return end --ignore if closed
	self._closed = true --_backend_closing() and _backend_closed() barrier

	self:_event'closed'
	self.app:_window_closed(self)

	self:_free_views()
	self._dead = true

	if self._quitting then
		self.app:_forcequit()
	end
end

--activation -----------------------------------------------------------------

local modes = glue.index{'alert', 'force', 'info'}
function app:activate(mode)
	mode = mode or 'alert'
	assert(modes[mode], 'invalid mode')
	self.backend:activate(mode)
end

function app:active_window()
	return self.backend:active_window()
end

function app:active()
	return self.backend:active()
end

function window:activate()
	self:_check()
	if not self:visible() then return end
	self.backend:activate()
end

function window:active()
	self:_check()
	if not self:visible() then return false end --false if hidden
	return self.backend:active()
end

--state/app visibility (OSX only) --------------------------------------------

function app:visible(visible)
	if visible == nil then
		return self.backend:visible()
	elseif visible then
		self:unhide()
	else
		self:hide()
	end
end

function app:unhide()
	self.backend:unhide()
end

function app:hide()
	self.backend:hide()
end

--state/visibility -----------------------------------------------------------

function window:visible(visible)
	self:_check()
	if visible == nil then
		return self.backend:visible()
	elseif visible then
		self:show()
	else
		self:hide()
	end
end

function window:show()
	self:_check()
	self.backend:show()
end

function window:hide()
	self:_check()
	if self:fullscreen() then return end
	self.backend:hide()
end

--state/minimizing -----------------------------------------------------------

function window:isminimized()
	self:_check()
	assert(not self:parent(), 'child windows cannot be minimized')
	return self.backend:minimized()
end

function window:minimize()
	self:_check()
	self.backend:minimize()
end

--state/maximizing -----------------------------------------------------------

function window:ismaximized()
	self:_check()
	return self.backend:maximized()
end

function window:maximize()
	self:_check()
	self.backend:maximize()
end

--state/restoring ------------------------------------------------------------

function window:restore()
	self:_check()
	if self:visible() and self:fullscreen() then
		self:fullscreen(false)
	else
		self.backend:restore()
	end
end

function window:shownormal()
	self:_check()
	self.backend:shownormal()
end

--state/fullscreen -----------------------------------------------------------

function window:fullscreen(fullscreen)
	self:_check()
	if fullscreen == nil then
		return self.backend:fullscreen()
	elseif fullscreen then
		self.backend:enter_fullscreen()
	else
		self.backend:exit_fullscreen()
	end
end

--state/state string ---------------------------------------------------------

function window:_get_state()
	local t = {}
	table.insert(t, self:visible() and 'visible' or nil)
	table.insert(t, self:isminimized() and 'minimized' or nil)
	table.insert(t, self:ismaximized() and 'maximized' or nil)
	table.insert(t, self:fullscreen() and 'fullscreen' or nil)
	table.insert(t, self:active() and 'active' or nil)
	return table.concat(t, ' ')
end

function app:_get_state()
	local t = {}
	table.insert(t, self:visible() and 'visible' or nil)
	table.insert(t, self:active() and 'active' or nil)
	return table.concat(t, ' ')
end

--state/change event ---------------------------------------------------------

local function diff(s, old, new)
	local olds = old:find(s, 1, true) and 1 or 0
	local news = new:find(s, 1, true) and 1 or 0
	return news - olds
end

local function trigger(self, diff, event_up, event_down)
	if diff > 0 then
		self:_event(event_up)
	elseif diff < 0 then
		self:_event(event_down)
	end
end

function window:_rect_changed(old_rect, new_rect, changed_event, moved_event, resized_event)
	if self:dead() then return end
	local x0, y0, w0, h0 = unpack(old_rect)
	local x1, y1, w1, h1 = unpack(new_rect)
	local moved = x1 ~= x0 or y1 ~= y0
	local resized = w1 ~= w0 or h1 ~= h0
	if moved or resized then
		self:_event(changed_event, x1, y1, w1, h1)
	end
	if moved then
		self:_event(moved_event, x1, y1)
	end
	if resized then
		self:_event(resized_event, w1, h1)
	end
	return new_rect
end

function window:_backend_changed()
	if self._events_disabled then return end
	--check if the state has really changed and generate synthetic events
	--for each state flag that has actually changed.
	local old = self._state
	local new = self:_get_state()
	self._state = new
	if new ~= old then
		self:_event('changed', old, new)
		trigger(self, diff('visible', old, new), 'shown', 'hidden')
		trigger(self, diff('minimized', old, new), 'minimized', 'unminimized')
		trigger(self, diff('maximized', old, new), 'maximized', 'unmaximized')
		trigger(self, diff('fullscreen', old, new), 'entered_fullscreen', 'exited_fullscreen')
		trigger(self, diff('active', old, new), 'activated', 'deactivated')
	end
	self._client_rect = self:_rect_changed(self._client_rect, {self:client_rect()},
		'client_rect_changed', 'client_moved', 'client_resized')
	self._frame_rect = self:_rect_changed(self._frame_rect, {self:frame_rect()},
		'frame_rect_changed', 'frame_moved', 'frame_resized')
end

function app:_backend_changed()
	local old = self._state
	local new = self:_get_state()
	self._state = new
	if new ~= old then
		self:_event('changed', old, new)
		trigger(self, diff('hidden', old, new), 'hidden', 'unhidden')
		trigger(self, diff('active', old, new), 'activated', 'deactivated')
	end
end

--state/enabled --------------------------------------------------------------

window:_property'enabled'

--positioning/frame extents --------------------------------------------------

function app:frame_extents(frame, has_menu)
	frame = checkframe(frame)
	if frame == 'none' then
		return 0, 0, 0, 0
	end
	return self.backend:frame_extents(frame, has_menu)
end

local function frame_rect(x, y, w, h, w1, h1, w2, h2)
	return x - w1, y - h1, w + w1 + w2, h + h1 + h2
end

local function unframe_rect(x, y, w, h, w1, h1, w2, h2)
	local x, y, w, h = frame_rect(x, y, w, h, -w1, -h1, -w2, -h2)
	w = math.max(1, w) --avoid zero client sizes
	h = math.max(1, h)
	return x, y, w, h
end

function app:client_to_frame(frame, has_menu, x, y, w, h)
	return frame_rect(x, y, w, h, self:frame_extents(frame, has_menu))
end

function app:frame_to_client(frame, has_menu, x, y, w, h)
	return unframe_rect(x, y, w, h, self:frame_extents(frame, has_menu))
end

--positioning/rectangles -----------------------------------------------------

function window:_get_client_size()
	--if self:minimized() then
	--	return 0, 0
	--end
	return self.backend:get_client_size()
end

function window:_get_client_pos()
	return self.backend:get_client_pos()
end

--convert point in client space to screen space.
function window:to_screen(x, y)
	self:_check()
	local cx, cy = self:_get_client_pos()
	return cx+x, cy+y
end

--convert point in screen space to client space.
function window:to_client(x, y)
	self:_check()
	local cx, cy = self:_get_client_pos()
	return x-cx, y-cy
end



local function override_rect(x, y, w, h, x1, y1, w1, h1)
	return x1 or x, y1 or y, w1 or w, h1 or h
end

function window:frame_rect(x1, y1, w1, h1) --returns x, y, w, h
	self:_check()
	if x1 or y1 or w1 or h1 then
		if self:fullscreen() then return end --ignore because OSX can't do it
		local x, y, w, h = self:frame_rect()
		self.backend:set_frame_rect(override_rect(x, y, w, h, x1, y1, w1, h1))
	--elseif self:minimized() then
	--	return self:normal_frame_rect()
	else
		return self.backend:get_frame_rect()
	end
end

function window:normal_frame_rect(x1, y1, w1, h1)
	self:_check()
	return self.backend:get_normal_frame_rect()
end

function window:client_rect(x1, y1, w1, h1)
	self:_check()
	if x1 or y1 or w1 or h1 then
		if self:fullscreen() then return end --ignore because OSX can't do it
		local cx, cy, cw, ch = self:client_rect()
		local ccw, cch = cw, ch
		local cx, cy, cw, ch = override_rect(cx, cy, cw, ch, x1, y1, w1, h1)
		local x, y, w, h = self:frame_rect()
		local dx, dy = self:to_client(x, y)
		local dw, dh = w - ccw, h - cch
		self.backend:set_frame_rect(cx + dx, cy + dy, cw + dw, ch + dh)
	else
		local x, y = self:_get_client_pos()
		return x, y, self:_get_client_size()
	end
end

function window:client_size(cw, ch) --sets or returns cw, ch
	self:_check()
	if cw or ch then
		if not cw or not ch then
			local cw0, ch0 = self:client_size()
			cw = cw or cw0
			ch = ch or ch0
		end
		self:client_rect(nil, nil, cw, ch)
	else
		return self:_get_client_size()
	end
end

--positioning/constraints ----------------------------------------------------

function window:minsize(w, h) --pass false to disable
	if w == nil and h == nil then
		return self.backend:get_minsize()
	else
		--clamp to maxsize to avoid undefined behavior in the backend.
		local maxw, maxh = self:maxsize()
		if w and maxw then w = math.min(w, maxw) end
		if h and maxh then h = math.min(h, maxh) end
		--clamp to 1 to avoid zero client sizes.
		w = math.max(1, w or 0)
		h = math.max(1, h or 0)
		self.backend:set_minsize(w, h)
	end
end

function window:maxsize(w, h) --pass false to disable
	if w == nil and h == nil then
		return self.backend:get_maxsize()
	else
		assert(not self:maximizable(), 'a maximizable window cannot have maxsize')
		assert(not self:fullscreenable(), 'a fullscreenable window cannot have maxsize')

		--clamp to minsize to avoid undefined behavior in the backend
		local minw, minh = self:minsize()
		if w and minw then w = math.max(w, minw) end
		if h and minh then h = math.max(h, minh) end
		self.backend:set_maxsize(w or nil, h or nil)
	end
end

--positioning/moving/resizing ------------------------------------------------

function window:_backend_sizing(when, how, x, y, w, h)

	if when ~= 'progress' then
		self._magnets = nil
		self:_event('sizing', when, how)
		return
	end

	local x1, y1, w1, h1

	if self:edgesnapping() then
		self._magnets = self._magnets or self:_getmagnets()
		if how == 'move' then
			x1, y1 = box2d.snap_pos(20, x, y, w, h, self._magnets, true)
		else
			x1, y1, w1, h1 = box2d.snap_edges(20, x, y, w, h, self._magnets, true)
		end
		x1, y1, w1, h1 = override_rect(x, y, w, h, x1, y1, w1, h1)
	else
		x1, y1, w1, h1 = x, y, w, h
	end

	x1, y1, w1, h1 = override_rect(x1, y1, w1, h1, self:_handle('sizing', when, how, x1, y1, w1, h1))
	self:_fire('sizing', when, how, x, y, w, h, x1, y1, w1, h1)
	return x1, y1, w1, h1
end

function window:edgesnapping(mode)
	self:_check()
	if mode == nil then
		return self._edgesnapping
	else
		if mode == true then
			mode = 'screen'
		end
		if mode == 'all' then
			mode = 'app other screen'
		end
		if self._edgesnapping ~= mode then
			self._magnets = nil
			self._edgesnapping = mode
		end
	end
end

--positioning/magnets --------------------------------------------------------

local modes = glue.index{'app', 'other', 'screen', 'parent', 'siblings'}

function window:_getmagnets()
	local mode = self:edgesnapping()

	--parse and check options
	local opt = {}
	for s in mode:gmatch'[%a]+' do
		assert(modes[s], 'invalid option %s', s)
		opt[s] = true
	end

	--ask user for magnets
	local t = self:_handle('magnets', opt)
	self:_fire('magnets', opt, t)
	if t then return t end

	--ask backend for magnets
	if opt.app and opt.other then
		t = self.backend:magnets()
	elseif (opt.app or opt.parent or opt.siblings) and not opt.other then
		t = {}
		for i,win in ipairs(self.app:windows()) do
			if win ~= self then
				local x, y, w, h = win:frame_rect()
				if x then
					if opt.app
						or (opt.parent and win == self:parent())
						or (opt.siblings and win:parent() == self:parent())
					then
						t[#t+1] = {x = x, y = y, w = w, h = h}
					end
				end
			end
		end
	elseif opt.other then
		error'NYI' --TODO: magnets excluding app's windows
	end
	if opt.screen then
		t = t or {}
		for i,disp in ipairs(self.app:displays()) do
			local x, y, w, h = disp:desktop_rect()
			t[#t+1] = {x = x, y = y, w = w, h = h}
			local x, y, w, h = disp:screen_rect()
			t[#t+1] = {x = x, y = y, w = w, h = h}
		end
	end

	return t
end

--z-order --------------------------------------------------------------------

window:_property'topmost'

function window:raise(relto)
	self:_check()
	if relto then relto:_check() end
	self.backend:raise(relto)
end

function window:lower(relto)
	self:_check()
	if relto then relto:_check() end
	self.backend:lower(relto)
end

--title ----------------------------------------------------------------------

window:_property'title'

--displays -------------------------------------------------------------------

local display = {}

function app:_display(backend)
	return glue.update(backend, display)
end

function display:screen_rect()
	return self.x, self.y, self.w, self.h
end

function display:desktop_rect()
	return self.cx, self.cy, self.cw, self.ch
end

function app:displays(arg)
	if arg == '#' then
		return self.backend:display_count()
	end
	return self.backend:displays()
end

function app:main_display() --the display at (0,0)
	return self.backend:main_display()
end

function app:active_display() --the display which has the keyboard focus
	return self.backend:active_display()
end

function app:_backend_displays_changed()
	self:_event'displays_changed'
end

function window:display()
	self:_check()
	return self.backend:display()
end

--cursors --------------------------------------------------------------------

function window:cursor(name)
	if name ~= nil then
		if type(name) == 'boolean' then
			self._cursor_visible = name
		else
			self._cursor = name
		end
		self.backend:update_cursor()
	else
		return self._cursor, self._cursor_visible
	end
end

--frame ----------------------------------------------------------------------

function window:frame() self:_check(); return self._frame end
function window:transparent() self:_check(); return self._transparent end
function window:minimizable() self:_check(); return self._minimizable end
function window:maximizable() self:_check(); return self._maximizable end
function window:closeable() self:_check(); return self._closeable end
function window:resizeable() self:_check(); return self._resizeable end
function window:fullscreenable() self:_check(); return self._fullscreenable end
function window:activable() self:_check(); return self._activable end
function window:sticky() self:_check(); return self._sticky end

function window:autoquit(autoquit)
	self:_check()
	if autoquit == nil then
		return self._autoquit
	else
		self._autoquit = autoquit
	end
end

--parent ---------------------------------------------------------------------

function window:parent()
	self:_check()
	return self._parent
end

function window:children(filter)
	if filter then
		assert(filter == '#', 'invalid argument')
		local n = 0
		for i,win in ipairs(self.app:windows()) do
			if win:parent() == self then
				n = n + 1
			end
		end
		return n
	end
	local t = {}
	for i,win in ipairs(self.app:windows()) do
		if win:parent() == self then
			t[#t+1] = win
		end
	end
	return t
end

--keyboard -------------------------------------------------------------------

function app:ignore_numlock(ignore)
	if ignore == nil then
		return self._ignore_numlock
	else
		self._ignore_numlock = ignore
	end
end

--merge virtual key names into ambiguous key names.
local common_keynames = {
	lshift          = 'shift',      rshift        = 'shift',
	lctrl           = 'ctrl',       rctrl         = 'ctrl',
	lalt            = 'alt',        ralt          = 'alt',
	lcommand        = 'command',    rcommand      = 'command',

	['left!']       = 'left',       numleft       = 'left',
	['up!']         = 'up',         numup         = 'up',
	['right!']      = 'right',      numright      = 'right',
	['down!']       = 'down',       numdown       = 'down',
	['pageup!']     = 'pageup',     numpageup     = 'pageup',
	['pagedown!']   = 'pagedown',   numpagedown   = 'pagedown',
	['end!']        = 'end',        numend        = 'end',
	['home!']       = 'home',       numhome       = 'home',
	['insert!']     = 'insert',     numinsert     = 'insert',
	['delete!']     = 'delete',     numdelete     = 'delete',
	['enter!']      = 'enter',      numenter      = 'enter',
}

local function translate_key(vkey)
	return common_keynames[vkey] or vkey, vkey
end

function window:_backend_keydown(key)
	self:_event('keydown', translate_key(key))
end

function window:_backend_keypress(key)
	self:_event('keypress', translate_key(key))
end

function window:_backend_keyup(key)
	self:_event('keyup', translate_key(key))
end

function window:_backend_keychar(s)
	self:_event('keychar', s)
end

function app:key(keys)
	keys = keys:lower()
	if keys:find'[^%+]%+' then --'alt+f3' -> 'alt f3'; 'ctrl++' -> 'ctrl +'
		keys = keys:gsub('([^%+%s])%+', '%1 ')
	end
	if keys:find(' ', 1, true) then --it's a sequence, eg. 'alt f3'
		local found
		for key in keys:gmatch'[^%s]+' do
			if not self.backend:key(key) then
				return false
			end
			found = true
		end
		return assert(found, 'invalid key sequence')
	end
	return self.backend:key(keys)
end

--mouse ----------------------------------------------------------------------

function window:mouse(var)
	--hidden or minimized windows don't have a mouse state.
	if not self:visible() or self:isminimized() then return nil end
	if var then
		return self._mouse[var]
	else
		return self._mouse
	end
end

function window:_backend_mousedown(button, mx, my)
	local t = self._down[button]
	if not t then
		t = {count = 0}
		self._down[button] = t
	end

	if t.count > 0
		and time.clock() - t.time < t.interval
		and box2d.hit(mx, my, t.x, t.y, t.w, t.h)
	then
		t.count = t.count + 1
		t.time = time.clock()
	else
		t.count = 1
		t.time = time.clock()
		t.interval = self.app.backend:double_click_time()
		t.w, t.h = self.app.backend:double_click_target_area()
		t.x = mx - t.w / 2
		t.y = my - t.h / 2
	end

	self:_event('mousedown', button, mx, my)

	local reset = false
	reset = self:_handle('click', button, t.count, mx, my)
	self:_fire('click', button, t.count, mx, my, reset)
	if reset then
		t.count = 0
	end
end

function window:_backend_mouseup(button, x, y)
	self:_event('mouseup', button, x, y)
end

function window:_backend_mouseenter()
	self:_event'mouseenter'
end

function window:_backend_mouseleave()
	self:_event'mouseleave'
end

function window:_backend_mousemove(x, y)
	self:_event('mousemove', x, y)
end

function window:_backend_mousewheel(delta, x, y)
	self:_event('mousewheel', delta, x, y)
end

function window:_backend_mousehwheel(delta, x, y)
	self:_event('mousehwheel', delta, x, y)
end

--rendering ------------------------------------------------------------------

function window:invalidate(...)
	self:_check()
	return self.backend:invalidate(...)
end

function window:_backend_repaint(...)
	self:_event('repaint', ...)
end

--bitmap

local bitmap = {}

function bitmap:clear()
	ffi.fill(self.data, self.size)
end

function window:bitmap()
	assert(not self:opengl(), 'bitmap not available on OpenGL window/view')
	local self = self.backend:bitmap()
	return self and glue.update(self, bitmap)
end

--cairo

function bitmap:cairo()
	local cairo = require'cairo'
	if not self.cairo_surface then
		self.cairo_surface = cairo.cairo_image_surface_create_for_data(
			self.data, cairo.CAIRO_FORMAT_ARGB32, self.w, self.h, self.stride)
		self.cairo_context = self.cairo_surface:create_context()
	end
	return self.cairo_context
end

function window:_backend_free_bitmap(bitmap)
	if bitmap.cairo_context then
		self:_event('free_cairo', bitmap.cairo_context)
		bitmap.cairo_context:free()
		bitmap.cairo_surface:free()
	end
	self:_event('free_bitmap', bitmap)
end

--opengl

function window:opengl(opt)
	self:_check()
	if not opt then
		return self._opengl and true or false
	end
	assert(self._opengl, 'OpenGL not enabled')
	local val = self._opengl[opt]
	assert(val ~= nil, 'invalid option')
	return val
end

function window:gl()
	assert(self:opengl(), 'OpenGL not enabled')
	return self.backend:gl()
end

--hi-dpi support -------------------------------------------------------------

function app:autoscaling(enabled)
	if enabled == nil then
		return self.backend:get_autoscaling()
	end
	if enabled then
		self.backend:enable_autoscaling()
	else
		self.backend:disable_autoscaling()
	end
end

function window:_backend_scalingfactor_changed(scalingfactor)
	self:_event('scalingfactor_changed', scalingfactor)
end

--views ----------------------------------------------------------------------

local defaults = {
	anchors = 'lt',
}

local view = glue.update({}, object)

function window:views(arg)
	if arg == '#' then
		return #self._views
	end
	return glue.extend({}, self._views) --take a snapshot; creation order.
end

function window:view(t)
	assert(not self:opengl(),
		'cannot create view over OpenGL-enabled window') --OSX limitation
	return view:_new(self, self.backend.view, t)
end

function view:_new(window, backend_class, useropt)

	local opt = glue.update({}, defaults, useropt)
	opt.opengl = opengl_options(useropt.opengl)

	assert(opt.x and opt.y and opt.w and opt.h, 'x, y, w, h expected')
	opt.w = math.max(1, opt.w) --avoid zero sizes
	opt.h = math.max(1, opt.h)

	local self = glue.update({
		window = window,
		app = window.app,
	}, self)

	self._mouse = {}
	self._down = {}
	self._anchors = opt.anchors
	self._opengl = opt.opengl

	self.backend = backend_class:new(window.backend, self, opt)
	table.insert(window._views, self)

	self:_init_anchors()

	if opt.visible ~= false then
		self:show()
	end

	return self
end

function window:_free_views()
	while #self._views > 0 do
		self._views[#self._views]:free()
	end
end

function view:free()
	if self._dead then return end
	self:_event'freeing'
	self.backend:free()
	self._dead = true
	table.remove(self.window._views, indexof(self, self.window._views))
end

function view:visible(visible)
	if visible ~= nil then
		if visible then
			self:show()
		else
			self:hide()
		end
	else
		return self.backend:visible()
	end
end

function view:show()
	self.backend:show()
end

function view:hide()
	self.backend:hide()
end

--positioning

function view:rect(x, y, w, h)
	if x or y or w or h then
		if not (x and y and w and h) then
			x, y, w, h = override_rect(x, y, w, h, self.backend:get_rect())
		end
		w = math.max(1, w) --avoid zero sizes
		h = math.max(1, h)
		self.backend:set_rect(x, y, w, h)
	else
		return self.backend:get_rect()
	end
end

function view:size(w, h)
	if w or h then
		if not (w and h) then
			local w0, h0 = self:size()
			w = w or w0
			h = h or h0
		end
		self.backend:set_size(w, h)
	else
		return select(3, self.backend:get_rect())
	end
end

function view:to_screen(x, y)
	self:_check()
	local x0, y0 = self.window:_get_client_pos()
	local cx, cy = self.backend:get_rect()
	return x0+cx+x, y0+cy+y
end

function view:to_client(x, y)
	self:_check()
	local x0, y0 = self.window:_get_client_pos()
	local cx, cy = self.backend:get_rect()
	return x-cx-x0, y-cy-y0
end

--anchors

function view:anchors(a)
	if a ~= nil then
		self._anchors = a
	else
		return self._anchors
	end
end

function view:_init_anchors()
	self._rect = {self:rect()}

	local pw0, ph0 = self.window:client_size()
	local x1, y1, w0, h0 = self:rect()
	local x2, y2 = pw0-w0, ph0-h0

	local function anchor(left, right, x1, x2, w, dw)
		if left then
			if right then --resize
				return x1, w + dw, x1, x2 + dw
			end
		elseif right then --move
			return x1 + dw, w, x1 + dw, x2
		end
		return x1, w, x1, x2
	end

	self.window:on('client_resized', function(window, pw, ph)
		local a = self._anchors
		local x, y, w, h
		x, w, x1, x2 = anchor(a:find('l', 1, true), a:find('r', 1, true), x1, x2, w0, pw-pw0)
		y, h, y1, y2 = anchor(a:find('t', 1, true), a:find('b', 1, true), y1, y2, h0, ph-ph0)
		self:rect(x, y, w, h)
		pw0, ph0 = pw, ph
		w0, h0 = w, h
	end)
end

--events

view._rect_changed = window._rect_changed

function view:_backend_changed()
	self._rect = self:_rect_changed(self._rect, {self:rect()},
		'rect_changed', 'moved', 'resized')
end

--mouse

function view:mouse(var)
	--hidden or minimized windows don't have a mouse state.
	if not self.window:visible() or self.window:isminimized() then return nil end
	if var then
		return self._mouse[var]
	else
		return self._mouse
	end
end

view._backend_mousedown   = window._backend_mousedown
view._backend_mouseup     = window._backend_mouseup
view._backend_mouseenter  = window._backend_mouseenter
view._backend_mouseleave  = window._backend_mouseleave
view._backend_mousemove   = window._backend_mousemove
view._backend_mousewheel  = window._backend_mousewheel
view._backend_mousehwheel = window._backend_mousehwheel

--rendering

view.bitmap = window.bitmap
view.cairo = window.cairo
view.opengl = window.opengl
view.gl = window.gl
view.invalidate = window.invalidate
view._backend_repaint = window._backend_repaint
view._backend_free_bitmap = window._backend_free_bitmap

--menus ----------------------------------------------------------------------

local menu = glue.update({}, object)

local function wrap_menu(backend, menutype)
	if backend.frontend then
		return backend.frontend --already wrapped
	end
	local self = glue.update({backend = backend, menutype = menutype}, menu)
	backend.frontend = self
	return self
end

function app:menu(menu)
	return wrap_menu(self.backend:menu(), 'menu')
end

function app:menubar()
	return wrap_menu(self.backend:menubar(), 'menubar')
end

function window:menubar()
	return wrap_menu(self.backend:menubar(), 'menubar')
end

function window:popup(menu, x, y)
	return self.backend:popup(menu, x, y)
end

function view:popup(menu, x, y)
	local vx, vy = self:rect()
	return self.window:popup(menu, vx + x, vy + y)
end

function menu:popup(target, x, y)
	return target:popup(self, x, y)
end

function menu:_parseargs(index, text, action, options)
	local args = {}

	--args can have the form:
	--		([index, ]text, [action], [options])
	--		{index=, text=, action=, optionX=...}
	if type(index) == 'table' then
		args = glue.update({}, index)
		index = args.index
	elseif type(index) ~= 'number' then
		index, args.text, args.action, options = nil, index, text, action --index is optional
	else
		args.text, args.action = text, action
	end

	--default text is empty, i.e. separator.
	args.text = args.text or ''

	--action can be a function or a submenu.
	if type(args.action) == 'table' and args.action.menutype then
		args.action, args.submenu = nil, args.action
	end

	--options add to the sequential args but don't override them.
	glue.merge(args, options)

	--a title made of zero or more '-' means separator (not for menu bars).
	if self.menutype ~= 'menubar' and args.text:find'^%-*$' then
		args.separator = true
		args.text = ''
		args.action = nil
		args.submenu = nil
		args.enabled = true
		args.checked = false
	else
		if args.enabled == nil then args.enabled = true end
		if args.checked == nil then args.checked = false end
	end

	--the title can be followed by two or more spaces and then by a shortcut.
	local shortcut = args.text:reverse():match'^%s*(.-)%s%s'
	if shortcut then
		args.shortcut = shortcut:reverse()
		args.text = text
	end

	return index, args
end

function menu:add(...)
	return self.backend:add(self:_parseargs(...))
end

function menu:set(...)
	self.backend:set(self:_parseargs(...))
end

function menu:remove(index)
	self.backend:remove(index)
end

function menu:get(index, var)
	if var then
		local item = self.backend:get(index)
		return item and item[var]
	else
		return self.backend:get(index)
	end
end

function menu:items(var)
	if var == '#' then
		return self.backend:item_count()
	end
	local t = {}
	for i = 1, self:items'#' do
		t[i] = self:get(i, var)
	end
	return t
end

function menu:checked(i, checked)
	if checked == nil then
		return self.backend:get_checked(i)
	else
		self.backend:set_checked(i, checked)
	end
end

function menu:enabled(i, enabled)
	if enabled == nil then
		return self.backend:get_enabled(i)
	else
		self.backend:set_enabled(i, enabled)
	end
end

--notification icons ---------------------------------------------------------

local notifyicon = glue.update({}, object)

function app:notifyicon(opt)
	local icon = notifyicon:_new(self, self.backend.notifyicon, opt)
	table.insert(self._notifyicons, icon)
	return icon
end

function notifyicon:_new(app, backend_class, opt)
	self = glue.update({app = app}, self)
	self.backend = backend_class:new(app.backend, self, opt)
	return self
end

function notifyicon:free()
	if self._dead then return end
	self.backend:free()
	self._dead = true
	table.remove(self.app._notifyicons, indexof(self, self.app._notifyicons))
end

function app:_free_notifyicons() --called on app:quit()
	while #self._notifyicons > 0 do
		self._notifyicons[#self._notifyicons]:free()
	end
end

function app:notifyicons(arg)
	if arg == '#' then
		return #self._notifyicons
	end
	return glue.extend({}, self._notifyicons) --take a snapshot
end

function notifyicon:bitmap()
	self:_check()
	return self.backend:bitmap()
end

function notifyicon:invalidate()
	return self.backend:invalidate()
end

function notifyicon:_backend_repaint()
	self:_event'repaint'
end

function notifyicon:_backend_free_bitmap(bitmap)
	self:_event('free_bitmap', bitmap)
end

notifyicon:_property'tooltip'
notifyicon:_property'menu'
notifyicon:_property'text' --OSX only
notifyicon:_property'length' --OSX only

--window icon ----------------------------------------------------------------

local winicon = glue.update({}, object)

local function whicharg(which)
	assert(which == nil or which == 'small' or which == 'big')
	return which == 'small' and 'small' or 'big'
end

function window:icon(which)
	local which = whicharg(which)
	if self:frame() == 'toolbox' then return end --toolboxes don't have icons
	self._icons = self._icons or {}
	if not self._icons[which] then
		self._icons[which] = winicon:_new(self, which)
	end
	return self._icons[which]
end

function winicon:_new(window, which)
	self = glue.update({}, winicon)
	self.window = window
	self.which = which
	return self
end

function winicon:bitmap()
	return self.window.backend:icon_bitmap(self.which)
end

function winicon:invalidate()
	return self.window.backend:invalidate_icon(self.which)
end

function window:_backend_repaint_icon(which)
	which = whicharg(which)
	self._icons[which]:_event('repaint')
end

--dock icon ------------------------------------------------------------------

local dockicon = glue.update({}, object)

function app:dockicon()
	if not self._dockicon then
		self._dockicon = dockicon:_new(self)
	end
	return self._dockicon
end

function dockicon:_new(app)
	return glue.update({app = app}, self)
end

function dockicon:bitmap()
	return self.app.backend:dockicon_bitmap()
end

function dockicon:invalidate()
	self.app.backend:dockicon_invalidate()
end

function app:_free_dockicon()
	if not self.backend.dockicon_free then return end --only on OSX
	self.backend:dockicon_free()
end

function app:_backend_dockicon_repaint()
	self._dockicon:_event'repaint'
end

function app:_backend_dockicon_free_bitmap(bitmap)
	self._dockicon:_event('free_bitmap', bitmap)
end

--file chooser ---------------------------------------------------------------

--TODO: make default filetypes = {'*'} and add '*' filetype to indicate "all others".

local defaults = {
	title = nil,
	filetypes = nil, --{'png', 'txt', ...}; first is default
	multiselect = false,
	initial_dir = nil,
}

function app:opendialog(opt)
	opt = glue.update({}, defaults, opt)
	assert(not opt.filetypes or #opt.filetypes > 0, 'filetypes cannot be an empty list')
	local paths = self.backend:opendialog(opt)
	if not paths then return nil end
	return opt.multiselect and paths or paths[1] or nil
end

local defaults = {
	title = nil,
	filetypes = nil, --{'png', 'txt', ...}; first is default
	filename = nil,
	initial_dir = nil,
}

function app:savedialog(opt)
	opt = glue.update({}, defaults, opt)
	assert(not opt.filetypes or #opt.filetypes > 0, 'filetypes cannot be an empty list')
	return self.backend:savedialog(opt) or nil
end

--clipboard ------------------------------------------------------------------

function app:getclipboard(format)
	if not format then
		return self.backend:get_clipboard_formats()
	else
		return self.backend:get_clipboard_data(format)
	end
end

function app:setclipboard(data, format)
	local t
	if data == false then --clear clipboard
		assert(format == nil)
	elseif format == 'text' or (format == nil and type(data) == 'string') then
		t = {{format = 'text', data = data}}
	elseif format == 'files' and type(data) == 'table' then
		t = {{format = 'files', data = data}}
	elseif format == 'bitmap' or (format == nil and type(data) == 'table' and data.stride) then
		t = {{format = 'bitmap', data = data}}
	elseif format == nil and type(data) == 'table' and not data.stride then
		t = data
	else
		error'invalid argument'
	end
	return self.backend:set_clipboard(t)
end

--drag & drop ----------------------------------------------------------------

function window:_backend_drop_files(x, y, files)
	self:_event('dropfiles', x, y, files)
end

local effect_arg = optarg({'copy', 'link', 'none', 'abort'}, 'copy', 'abort', 'abort')

function window:_backend_dragging(stage, data, x, y)
	local effect = effect_arg(self:_handle('dragging', how, data, x, y))
	self:_fire('dragging', how, data, x, y, effect)
	return effect
end


return nw
