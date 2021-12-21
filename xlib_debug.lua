--xlib pretty event crackers
local glue = require'glue'
local xlib = require'xlib'
local ffi = require'ffi'
local pp = require'pp'
local reflect = require'ffi_reflect'
local time = require'time'

local etypes = glue.index{
	KeyPress             = 2,
	KeyRelease           = 3,
	ButtonPress          = 4,
	ButtonRelease        = 5,
	MotionNotify         = 6,
	EnterNotify          = 7,
	LeaveNotify          = 8,
	FocusIn              = 9,
	FocusOut             = 10,
	KeymapNotify         = 11,
	Expose               = 12,
	GraphicsExpose       = 13,
	NoExpose             = 14,
	VisibilityNotify     = 15,
	CreateNotify         = 16,
	DestroyNotify        = 17,
	UnmapNotify          = 18,
	MapNotify            = 19,
	MapRequest           = 20,
	ReparentNotify       = 21,
	ConfigureNotify      = 22,
	ConfigureRequest     = 23,
	GravityNotify        = 24,
	ResizeRequest        = 25,
	CirculateNotify      = 26,
	CirculateRequest     = 27,
	PropertyNotify       = 28,
	SelectionClear       = 29,
	SelectionRequest     = 30,
	SelectionNotify      = 31,
	ColormapNotify       = 32,
	ClientMessage        = 33,
	MappingNotify        = 34,
	GenericEvent         = 35,
}

local t0 = time.clock()
local function separator()
	local dt = time.clock() - t0
	t0 = t0 + dt
	if dt > 0.5 then
		print(('-'):rep(100))
	end
end

local function connect(xlib)

	local dbg = {}

	function dbg.trace()
		local C = xlib.C
		xlib.setC(setmetatable({}, {__index = function(t, k, v)
			local r = C[k]
			local tp = type(r) == 'cdata' and reflect.typeof(r)
			if tp and tp.what == 'func' then
				local f = function(...)
					local dt = {}
					local i = 0
					for r in tp:arguments() do
						i = i + 1
						if r.type.what == 'int' then
							dt[i] = tostring(select(i, ...))
						elseif r.type.what == 'ptr' then
							local pt = r.type.element_type.what
							if pt == 'char' then
								dt[i] = tostring(select(i, ...))
							else
								dt[i] = pt..'*' -- tostring(select(i, ...))
							end
						else
							dt[i] = r.type.what
						end
					end
					local args = table.concat(dt, ', ')
					print('            C.'..k..'('..args..')')
					return r(...)
				end
				rawset(t, k, f)
				return f
			end
			return r
		end}))
		C = xlib.C
	end

	local C = xlib.C

	local getprop = {}

	function getprop._NET_WM_STATE(win)
		local t = xlib.get_net_wm_state(win)
		local dt = {}
		if t then
			for k,v in pairs(t) do
				dt[xlib.atom_name(k)] = v
			end
		end
		return pp.format(dt)
	end

	local states = glue.index{
		WithdrawnState       = 0,
		NormalState          = 1,
		ZoomState            = 2,
		IconicState          = 3,
		InactiveState        = 4,
	}
	function getprop.WM_STATE(win)
		local s = xlib.get_wm_state(win)
		return states[s] or s
	end

	function getprop.WM_HINTS(win)
		return pp.format(xlib.get_wm_hints(win))
	end

	function getprop._NET_FRAME_EXTENTS(win)
		return table.concat({xlib.get_frame_extents(win)}, ',')
	end

	local function client_rect(win)
		local cx, cy   = xlib.translate_coords(win, xlib.screen.root, 0, 0)
		local cw, ch = select(3, xlib.get_geometry(win))
		return cx, cy, cw, ch
	end

	local function win(win)
		local s = xlib.get_wm_name(win)
		return '['..(s ~= '' and s or tostring(win))..']'
	end

	local ev = {}

	ev[C.ClientMessage] = function(e)
		return win(e.xclient.window), xlib.atom_name(e.xclient.data.l[0])
	end

	ev[C.PropertyNotify] = function(e)
		local function decode(data, n, bits)
			return '#'..n..' ['..bits..']'--, ffi.string(data, n)
		end
		local getprop = getprop[xlib.atom_name(e.xproperty.atom)]
		local v
		if getprop then
			v = getprop(e.xproperty.window)
		else
			v = xlib.get_prop(e.xproperty.window, e.xproperty.atom, decode)
		end
		return win(e.xproperty.window), xlib.atom_name(e.xproperty.atom), v
	end

	ev[C.ConfigureNotify] = function(e)
		local c = e.xconfigure
		return
			win(e.xconfigure.window),
			'x='..c.x,
			'y='..c.y,
			'width='..c.width,
			'height='..c.height,
			'border_width='..c.border_width,
			'above='..tostring(c.above),
			'override_redirect='..c.override_redirect
	end

	local vis = glue.index{
		VisibilityUnobscured = 0,
		VisibilityPartiallyObscured = 1,
		VisibilityFullyObscured = 2,
	}
	ev[C.VisibilityNotify] = function(e)
		return win(e.xvisibility.window), vis[e.xvisibility.state] or e.xvisibility.state
	end

	function dbg.event_tostring(e)
		local t = {}
		glue.append(t, etypes[tonumber(e.type)] or e.type)
		local fmt = ev[tonumber(e.type)]
		if fmt then
			glue.append(t, fmt(e))
		end
		return table.concat(t, ' ')
	end

	dbg.separator = separator

	return dbg
end

return {
	connect = connect,
}
