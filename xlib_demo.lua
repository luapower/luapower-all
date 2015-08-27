local pp   = require'pp'
local time = require'time'
local glue = require'glue'
local xlib = require'xlib'
local glx  = require'glx'
local dbg  = require'xlib_debug'
local ffi  = require'ffi'
require'xlib_keysym_h'
require'gl11'

local xlib = xlib.connect()
local glx = glx.connect(xlib)
local dbg = dbg.connect(xlib)
local gl = glx.C
local C = xlib.C

--dbg.trace()

local testatom = xlib.atom'TEST_ATOM'
assert(xlib.atom_name(testatom) == 'TEST_ATOM')

print'screens:'
for i,s in xlib.screens() do
	print('', i, s.width, s.height, s.root_depth)
end

local glxctx
for fbconfig in glx.choose_rgb_fbconfigs() do
	glxctx = glx.create_context(fbconfig)
	break
end

print'### create_window'
local win = xlib.create_window{
	x = 300, y = 100, width = 500, height = 300,
	event_mask = bit.bor(
		C.KeyPressMask,
		C.PropertyChangeMask,
		C.ExposureMask,
		C.FocusChangeMask,
		C.StructureNotifyMask,
		C.SubstructureNotifyMask
	),
}
print'### set_title'
xlib.set_wm_name(win, 'win')

print'### set_wm_size_hints'
xlib.set_wm_size_hints(win, {x = 0, y = 0})--, min_width = 200, min_height = 200})

print'win props:'
for i,a in xlib.list_props(win) do
	print('', xlib.atom_name(a))
end

print'root props:'
for i,a in xlib.list_props(xlib.screen.root) do
	print('', xlib.atom_name(a))
end

local t = xlib.get_net_workarea()
print'_NET_WORKAREA:'
for i=1,#t do
	print('', unpack(t[i]))
end

local t = {}
for atom in pairs(xlib.net_supported_map(win)) do
	t[#t+1] = xlib.atom_name(atom)
end
table.sort(t)
print('_NET_SUPPORTED: '..table.concat(t, ' '))

io.stdout:write'\n'

print'xsettings:'
for k,v in pairs(xlib.get_xsettings()) do
	print(string.format('\t%-24s %s', k, pp.format(v)))
end

print'xinerama screens:'
local screens, n = xlib.xinerama_screens()
for i=0,n-1 do
	local scr = screens[i]
	print(scr.screen_number, '', scr.x_org, scr.y_org, scr.width, scr.height)
end

--declare the X protocols that the window supports.
xlib.set_atom_map_prop(win, 'WM_PROTOCOLS', {
	WM_DELETE_WINDOW = true, --don't close the connection when a window is closed
	_NET_WM_PING = true,     --respond to ping events
})

--set required properties for _NET_WM_PING.
xlib.set_net_wm_ping_info(win)

--set motif hints before mapping the window.
local hints = ffi.new'PropMotifWmHints'
hints.flags = bit.bor(
	C.MWM_HINTS_FUNCTIONS,
	C.MWM_HINTS_DECORATIONS)
hints.functions = bit.bor(
	C.MWM_FUNC_RESIZE,
	C.MWM_FUNC_MOVE,
	C.MWM_FUNC_MINIMIZE,
	C.MWM_FUNC_MAXIMIZE,
	C.MWM_FUNC_CLOSE,
	0)
hints.decorations = bit.bor(
	C.MWM_DECOR_BORDER,
	C.MWM_DECOR_TITLE,
	C.MWM_DECOR_MENU,
	C.MWM_DECOR_RESIZEH,
	C.MWM_DECOR_MINIMIZE,
	C.MWM_DECOR_MAXIMIZE,
	0)
xlib.set_motif_wm_hints(win, hints)

--[[
xlib.set_net_wm_state(win, {
	_NET_WM_STATE_MAXIMIZED_HORZ = true,
	_NET_WM_STATE_MAXIMIZED_VERT = true,
	_NET_WM_STATE_HIDDEN = true,
})
]]

print'### map'
--finally show the window
xlib.map(win)

function gl_set_viewport(win)
	local _, _, w, h = xlib.get_geometry(win)
	gl.glViewport(0, 0, w, h)
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	gl.glFrustum(-1, 1, -1, 1, 1, 100) --so fov is 90 deg
	gl.glScaled(1, w/h, 1)
end

function gl_clear()
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
end

local r = 30
local function gl_cube(w)
	r = r + 1
	gl.glPushMatrix()
	gl.glTranslated(0,0,-3)
	gl.glScaled(w, w, 1)
	gl.glRotated(r,1,r,r)
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

--create a control window
print'### create win1'
local win1 = xlib.create_window{
	width = 500,
	height = 50,
	event_mask = bit.bor(C.KeyPressMask),
}
xlib.map(win1)


local wm_states = glue.index{
	WithdrawnState = 0,
	NormalState    = 1,
	IconicState    = 3,
}

--events
local t0 = time.clock()
local s0 = 1
local x, y, cw, ch
local s_max, s_fs, s_h

while true do

	local e = xlib.poll(0.5)
	if e then

		dbg.separator()
		print('event', dbg.event_tostring(e))

		if e.type == C.ClientMessage then
			local v = e.xclient.data.l[0]
			if v == xlib.atom'_NET_WM_PING' then
				print'pong!'
				xlib.pong(e)
			elseif v == xlib.atom'WM_DELETE_WINDOW' then
				print'close'
				xlib.destroy_window(win)
				break
			end
		elseif e.type == C.Expose then
			--
		elseif e.type == C.PropertyNotify then

		elseif e.type == C.KeyPress then
			local key = xlib.keysym(e.xkey.keycode, 0, 0)
			if key == C.XK_m then
				xlib.change_net_wm_state_maximized(win, true)
			elseif key == C.XK_r then
				xlib.change_net_wm_state_maximized(win, false)
			elseif key == C.XK_f then
				xlib.change_net_wm_state_fullscreen(win, true)
			elseif key == C.XK_g then
				xlib.change_net_wm_state_fullscreen(win, false)
			elseif key == C.XK_1 then
				s_h = true
			elseif key == C.XK_2 then
				s_h = false
			elseif key == C.XK_3 then
				s_max = true
			elseif key == C.XK_4 then
				s_max = false
			elseif key == C.XK_5 then
				s_fs = true
			elseif key == C.XK_6 then
				s_fs = false
			elseif key == C.XK_0 then
				local t = {
					_NET_WM_STATE_HIDDEN = s_h,
					_NET_WM_STATE_MAXIMIZED_HORZ = s_max,
					_NET_WM_STATE_MAXIMIZED_VERT = s_max,
					_NET_WM_STATE_FULLSCREEN = s_fs,
				}
				pp('set_net_wm_state', t)
				xlib.set_net_wm_state(win, t)
			elseif key == C.XK_n then
				xlib.iconify(win)
			elseif key == C.XK_h then
				xlib.withdraw(win)
			elseif key == C.XK_s then
				xlib.map(win)
			elseif key == C.XK_d then
				xlib.map(win)
				xlib.change_net_active_window(win)
			elseif key == C.XK_a then
				xlib.change_net_active_window(win)
			elseif key == C.XK_q then
				xlib.destroy_window(win)
				break
			end
		end

	else

		glx.make_current(win, glxctx)
		gl_set_viewport(win)
		gl_clear()
		gl_cube(1)
		glx.swap_buffers(win)

	end

	print('##### '..
		(wm_states[xlib.get_wm_state(win)] or tostring(xlib.get_wm_state(win)))..' '..
		(xlib.get_net_wm_state_hidden(win) and 'H' or '')..
		(xlib.get_net_wm_state_maximized(win) and 'M' or '')..
		(xlib.get_net_wm_state_fullscreen(win) and 'F' or '')..
		(xlib.get_net_active_window() == win and 'A' or '')
	)

end

glx.destroy_context(glxctx)
xlib.disconnect()
