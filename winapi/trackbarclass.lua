
--oo/controls/trackbar: trackbar control
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.trackbar'
require'winapi.controlclass'

Trackbar = {
	__style_bitmask = bitmask{
		ticks = {
			auto = TBS_AUTOTICKS,
			none = TBS_NOTICKS,
		},
		orientation  = {
			vertical = TBS_VERT,
			horizontal = TBS_HORZ,
		},
		ticks_orientation = {
			top = TBS_TOP,
			bottom = TBS_BOTTOM,
			left = TBS_LEFT,
			right = TBS_RIGHT,
			both = TBS_BOTH,
		},
		range = TBS_ENABLESELRANGE,
		fixed_length = TBS_FIXEDLENGTH,
		thumb = {
			[true] = 0,
			[false] = TBS_NOTHUMB,
		},
		tooltips = TBS_TOOLTIPS,
		reversed = TBS_REVERSED,
		vertical_reversed = TBS_DOWNISLEFT,
		notify_before_remove = TBS_NOTIFYBEFOREMOVE,
		transparent_background = TBS_TRANSPARENTBKGND,
	},
	__defaults = {
		w = 100,
		h = 40,
	},
	__init_properties = {
		'pos', 'sel_start', 'sel_end',
		'min_range', 'max_range',
		'line_size', 'page_size',
		'tick_freq',
	},
}

subclass(Trackbar, Control)

function Trackbar:after___before_create(info, args)
	args.class = TRACKBAR_CLASS
end

function Trackbar:set_pos       (pos, redraw) SNDMSG(self.hwnd, TBM_SETPOS     , redraw ~= false, pos) end
function Trackbar:set_sel_start (pos, redraw) SNDMSG(self.hwnd, TBM_SETSELSTART, redraw ~= false, pos) end
function Trackbar:set_sel_end   (pos, redraw) SNDMSG(self.hwnd, TBM_SETSELEND  , redraw ~= false, pos) end
function Trackbar:set_min_range (pos, redraw) SNDMSG(self.hwnd, TBM_SETRANGEMIN, redraw ~= false, pos) end
function Trackbar:set_max_range (pos, redraw) SNDMSG(self.hwnd, TBM_SETRANGEMAX, redraw ~= false, pos) end
function Trackbar:set_line_size (size)        SNDMSG(self.hwnd, TBM_SETLINESIZE, 0, size) end
function Trackbar:set_page_size (size)        SNDMSG(self.hwnd, TBM_SETPAGESIZE, 0, size) end
function Trackbar:set_tick      (pos)  return SNDMSG(self.hwnd, TBM_SETTIC     , 0, pos) == 1 end
function Trackbar:set_tick_freq (freq)        SNDMSG(self.hwnd, TBM_SETTICFREQ , freq, 0) end
function Trackbar:clear_sel     (redraw)      SNDMSG(self.hwnd, TBM_CLEARSEL   , redraw ~= false, 0) end
function Trackbar:remove_ticks  (redraw)      SNDMSG(self.hwnd, TBM_CLEARTICS  , redraw ~= false, 0) end

function Trackbar:get_pos        ()  return SNDMSG(self.hwnd, TBM_GETPOS     , 0, 0) end
function Trackbar:get_sel_start  ()  return SNDMSG(self.hwnd, TBM_GETSELSTART, 0, 0) end
function Trackbar:get_sel_end    ()  return SNDMSG(self.hwnd, TBM_SETSELEND  , 0, 0) end
function Trackbar:get_min_range  ()  return SNDMSG(self.hwnd, TBM_GETRANGEMIN, 0, 0) end
function Trackbar:get_max_range  ()  return SNDMSG(self.hwnd, TBM_GETRANGEMAX, 0, 0) end
function Trackbar:get_line_size  ()  return SNDMSG(self.hwnd, TBM_GETLINESIZE, 0, 0) end
function Trackbar:get_page_size  ()  return SNDMSG(self.hwnd, TBM_GETPAGESIZE, 0, 0) end
function Trackbar:get_tick_count ()  return SNDMSG(self.hwnd, TBM_GETNUMTICS , 0, 0) end
function Trackbar:get_tick       (i) return SNDMSG(self.hwnd, TBM_GETTIC, countfrom0(i), 0) end

--[[
TBM_GETPTICS         = (WM_USER+14)
TBM_GETTICPOS        = (WM_USER+15)
TBM_GETTHUMBRECT     = (WM_USER+25)
TBM_GETCHANNELRECT   = (WM_USER+26)
TBM_SETTHUMBLENGTH   = (WM_USER+27)
TBM_GETTHUMBLENGTH   = (WM_USER+28)
TBM_SETTOOLTIPS      = (WM_USER+29)
TBM_GETTOOLTIPS      = (WM_USER+30)
TBM_SETTIPSIDE       = (WM_USER+31)
]]
