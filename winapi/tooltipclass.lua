
--oo/controls/tooltip: standard tooltip control
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.basewindowclass'
require'winapi.tooltip'
require'winapi.controlclass'

Tooltip = subclass({
	__style_bitmask = bitmask{
		always_show = TTS_ALWAYSTIP, --show when owner window is inactive too
		no_prefix = TTS_NOPREFIX, --prevent stripping ampersants and tabs
		no_animate = TTS_NOANIMATE,
		no_fade = TTS_NOFADE,
		baloon = TTS_BALLOON,
		close_button = TTS_CLOSE, --only for baloon tooltips
		themed_hyperlinks = TTS_USEVISUALSTYLE, --needs TTF_PARSELINKS
		clip_siblings = WS_CLIPSIBLINGS, --set by Windows
	},
	__style_ex_bitmask = bitmask{
		tompost = WS_EX_TOPMOST,
	},
	__defaults = {
		--style bits
		clip_siblings = true, --avoid warning
		no_prefix = true,
		--ex style bits
		topmost = true,
		--window properties
		x = CW_USEDEFAULT,
		y = CW_USEDEFAULT,
		w = CW_USEDEFAULT,
		h = CW_USEDEFAULT,
		--TOOLINFO TTF_* flags
		subclass = true,
		center_tip = false,
		rtl_reading = false,
		track = false,
		absolute = false,
		transparent = false,
		parse_links = false,
		id_is_hwnd = false,
	},
	__wm_handler_names = index{
		on_activate = TTM_ACTIVATE, --TODO: not sent
		--[[ --TODO: finish these
		on_ = TTM_SETDELAYTIME,
		on_ = TTM_ADDTOOL,
		on_ = TTM_DELTOOL,
		on_ = TTM_NEWTOOLRECT,
		on_ = TTM_RELAYEVENT,
		on_ = TTM_GETTOOLINFO,
		on_ = TTM_SETTOOLINFO,
		on_ = TTM_HITTEST,
		on_ = TTM_GETTEXT,
		on_ = TTM_UPDATETIPTEXT,
		on_ = TTM_GETTOOLCOUNT,
		on_ = TTM_ENUMTOOLS,
		on_ = TTM_GETCURRENTTOOL,
		on_ = TTM_WINDOWFROMPOINT,
		on_ = TTM_TRACKACTIVATE,
		on_ = TTM_TRACKPOSITION,
		on_ = TTM_SETTIPBKCOLOR,
		on_ = TTM_SETTIPTEXTCOLOR,
		on_ = TTM_GETDELAYTIME,
		on_ = TTM_GETTIPBKCOLOR,
		on_ = TTM_GETTIPTEXTCOLOR,
		on_ = TTM_SETMAXTIPWIDTH,
		on_ = TTM_GETMAXTIPWIDTH,
		on_ = TTM_SETMARGIN,
		on_ = TTM_GETMARGIN,
		on_ = TTM_POP,
		on_ = TTM_UPDATE,
		on_ = TTM_GETBUBBLESIZE,
		on_ = TTM_ADJUSTRECT,
		on_ = TTM_SETTITLE,
		on_ = TTM_POPUP,
		on_ = TTM_GETTITLE,
		]]
	},
	__wm_notify_handler_names = index{
		on_get_display_info = TTN_GETDISPINFO,
		on_show = TTN_SHOW,
		on_pop = TTN_POP,
		on_link_click = TTN_LINKCLICK,
	},
	__init_properties = {},
}, BaseWindow)

function Tooltip:after___before_create(info, args)
	args.class = TOOLTIPS_CLASS
	args.parent = info.parent and info.parent.hwnd
end

local ti = TOOLINFO()

function Tooltip:__after_create(info, args)
	SetWindowPos(self.hwnd, HWND_TOPMOST,
		0, 0, 0, 0, bit.bor(SWP_NOMOVE, SWP_NOSIZE, SWP_NOACTIVATE))
	TOOLINFO:reset(ti)
	ti.text = info.text or ffi.cast('LPWSTR', -1)
	ti.flagbits = info
	ti.hwnd = args.parent
	ti.rect = info.rect or info.parent.client_rect
	checktrue(SNDMSG(self.hwnd, TTM_ADDTOOL, 0, ffi.cast('void*', ti)))
end

function Tooltip:get_parent()
	return Windows:find(GetWindowOwner(self.hwnd))
end

function Tooltip:set_rect(r)
	TOOLINFO:reset(ti)
	ti.hwnd = self.parent.hwnd
	ti.rect = r
	SNDMSG(self.hwnd, TTM_NEWTOOLRECT, 0, ffi.cast('void*', ti))
end

function Tooltip:set_active(active)
	SNDMSG(self.hwnd, TTM_ACTIVATE, active and 1 or 0, 0)
end

function Tooltip:set_text(text)
	TOOLINFO:reset(ti)
	ti.hwnd = self.parent.hwnd
	ti.text = text
	SNDMSG(self.hwnd, TTM_UPDATETIPTEXT, 0, ffi.cast('void*', ti))
end

--showcase -------------------------------------------------------------------

if not ... then
require'winapi.showcase'
local window = ShowcaseWindow{w=300,h=200}
local t1 = Tooltip{parent = window} --, text='xxxx'}--, visible = false}--, text = 'Hellooo!'}

local n = 10
function t1:on_get_display_info(nmt)
	print'on_get_display_info'
	n = n - 1
	nmt.text = string.format('H%s!!!!', ('o'):rep(n))
	nmt.uFlags = 0
end

function t1:on_show()
	print'on_show'
end

function t1:on_activate()
	print'on_activate'
end

function window:on_mouse_move(mx, my)
	t1.rect = t1.parent.client_rect
	n = n + .001
	--t1.text = string.format('H%s!!!!', ('o'):rep(math.floor(n)))
	t1.active = mx < window.client_w / 2
end

t1.active = false
--t1.text = 'xx'

MessageLoop()
end
