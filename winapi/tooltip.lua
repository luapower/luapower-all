
--proc/controls/tooltip: standard tooltip control
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.window'
require'winapi.comctl'

InitCommonControlsEx(ICC_TAB_CLASSES)

TOOLTIPS_CLASS = 'tooltips_class32'

-- ToolTip Icons (Set with TTM_SETTITLE)
TTI_NONE                = 0
TTI_INFO                = 1
TTI_WARNING             = 2
TTI_ERROR               = 3
TTI_INFO_LARGE          = 4
TTI_WARNING_LARGE       = 5
TTI_ERROR_LARGE         = 6

ffi.cdef[[
typedef struct tagTOOLINFOW {
    UINT cbSize;
    UINT uFlags;      // TTF_*
    HWND hwnd;
    UINT_PTR uId;
    RECT rect;
    HINSTANCE hinst;
    LPWSTR lpszText;  // V1 ends here
    LPARAM lParam;    // V2 ends here
} TTTOOLINFOW, *PTOOLINFOW, *LPTTTOOLINFOW;
]]

TTS_ALWAYSTIP           = 0x01
TTS_NOPREFIX            = 0x02
TTS_NOANIMATE           = 0x10
TTS_NOFADE              = 0x20
TTS_BALLOON             = 0x40
TTS_CLOSE               = 0x80
TTS_USEVISUALSTYLE      = 0x100  -- Use themed hyperlinks

TTF_IDISHWND            = 0x0001

-- Use this to center around trackpoint in trackmode
-- -OR- to center around tool in normal mode.
-- Use TTF_ABSOLUTE to place the tip exactly at the track coords when
-- in tracking mode.  TTF_ABSOLUTE can be used in conjunction with TTF_CENTERTIP
-- to center the tip absolutely about the track point.

TTF_CENTERTIP           = 0x0002
TTF_RTLREADING          = 0x0004
TTF_SUBCLASS            = 0x0010
TTF_TRACK               = 0x0020
TTF_ABSOLUTE            = 0x0080
TTF_TRANSPARENT         = 0x0100
TTF_PARSELINKS          = 0x1000

TTF_DI_SETITEM          = 0x8000 -- valid only on the TTN_NEEDTEXT callback

local tt_bitmask = bitmask{
	center_tip = TTF_CENTERTIP,
	rtl_reading = TTF_RTLREADING,
	subclass = TTF_SUBCLASS,
	track = TTF_TRACK,
	absolute = TTF_ABSOLUTE,
	transparent = TTF_TRANSPARENT,
	parse_links = TTF_PARSELINKS,
	id_is_hwnd = TTF_IDISHWND,
}

local function set_tt_flags(t, cdata)
	return tt_bitmask:set(cdata.uFlags, t)
end

local function get_tt_flags(uFlags)
	return tt_bitmask:get(uFlags)
end

TOOLINFO = struct{
	ctype = 'TTTOOLINFOW', size = 'cbSize',
	fields = sfields{
		'flags', 'uFlags', flags, pass,
		'flagbits', 'uFlags', set_tt_flags, get_tt_flags,
		'text', 'lpszText', wcs, mbs,
	},
}

TTDT_AUTOMATIC          = 0
TTDT_RESHOW             = 1
TTDT_AUTOPOP            = 2
TTDT_INITIAL            = 3

-- ToolTip Icons (Set with TTM_SETTITLE)
TTI_NONE                = 0
TTI_INFO                = 1
TTI_WARNING             = 2
TTI_ERROR               = 3
TTI_INFO_LARGE          = 4
TTI_WARNING_LARGE       = 5
TTI_ERROR_LARGE         = 6

-- Tool Tip Messages
update(WM_NAMES, constants{
	TTM_ACTIVATE            = (WM_USER +  1),
	TTM_SETDELAYTIME        = (WM_USER +  3),
	TTM_ADDTOOL             = (WM_USER + 50),
	TTM_DELTOOL             = (WM_USER + 51),
	TTM_NEWTOOLRECT         = (WM_USER + 52),
	TTM_RELAYEVENT          = (WM_USER +  7), -- Win7: wParam = GetMessageExtraInfo() when relaying WM_MOUSEMOVE
	TTM_GETTOOLINFO         = (WM_USER + 53),
	TTM_SETTOOLINFO         = (WM_USER + 54),
	TTM_HITTEST             = (WM_USER + 55),
	TTM_GETTEXT             = (WM_USER + 56),
	TTM_UPDATETIPTEXT       = (WM_USER + 57),
	TTM_GETTOOLCOUNT        = (WM_USER + 13),
	TTM_ENUMTOOLS           = (WM_USER + 58),
	TTM_GETCURRENTTOOL      = (WM_USER + 59),
	TTM_WINDOWFROMPOINT     = (WM_USER + 16),
	TTM_TRACKACTIVATE       = (WM_USER + 17), -- wParam = TRUE/FALSE start end  lparam = LPTOOLINFO
	TTM_TRACKPOSITION       = (WM_USER + 18), -- lParam = dwPos
	TTM_SETTIPBKCOLOR       = (WM_USER + 19),
	TTM_SETTIPTEXTCOLOR     = (WM_USER + 20),
	TTM_GETDELAYTIME        = (WM_USER + 21),
	TTM_GETTIPBKCOLOR       = (WM_USER + 22),
	TTM_GETTIPTEXTCOLOR     = (WM_USER + 23),
	TTM_SETMAXTIPWIDTH      = (WM_USER + 24),
	TTM_GETMAXTIPWIDTH      = (WM_USER + 25),
	TTM_SETMARGIN           = (WM_USER + 26), -- lParam = lprc
	TTM_GETMARGIN           = (WM_USER + 27), -- lParam = lprc
	TTM_POP                 = (WM_USER + 28),
	TTM_UPDATE              = (WM_USER + 29),
	TTM_GETBUBBLESIZE       = (WM_USER + 30),
	TTM_ADJUSTRECT          = (WM_USER + 31),
	TTM_SETTITLE            = (WM_USER + 33), -- wParam = TTI_*, lParam = wchar* szTitle
	TTM_POPUP               = (WM_USER + 34),
	TTM_GETTITLE            = (WM_USER + 35), -- wParam = 0, lParam = TTGETTITLE*
})

ffi.cdef[[
typedef struct _TTGETTITLE
{
    DWORD dwSize;
    UINT uTitleBitmap;
    UINT cch;
    WCHAR* pszTitle;
} TTGETTITLE, *PTTGETTITLE;
]]

ffi.cdef[[
typedef struct _TT_HITTESTINFOW {
    HWND hwnd;
    POINT pt;
    TTTOOLINFOW ti;
} TTHITTESTINFOW, *LPTTHITTESTINFOW;
]]

local TTN_FIRST = tonumber(ffi.cast('uint32_t', -520))

update(WM_NOTIFY_NAMES, constants{
	TTN_GETDISPINFO         = (TTN_FIRST - 10),
	TTN_SHOW                = (TTN_FIRST - 1),
	TTN_POP                 = (TTN_FIRST - 2),
	TTN_LINKCLICK           = (TTN_FIRST - 3),
})

ffi.cdef[[
typedef struct tagNMTTDISPINFOW {
    NMHDR hdr;
    LPWSTR lpszText;
    WCHAR szText[80];
    HINSTANCE hinst;
    UINT uFlags;
    LPARAM lParam;
} NMTTDISPINFOW, *LPNMTTDISPINFOW;
]]

local nmt_bitmask = bitmask{
	rtl_reading = TTF_RTLREADING,
	id_is_hwnd = TTF_IDISHWND,
	setitem = TTF_DI_SETITEM,
}
local function set_nmt_flags(t, nmt) return tt_bitmask:set(nmt.uFlags, t) end
local function get_nmt_flags(uFlags) return tt_bitmask:get(uFlags) end

NMTTDISPINFO = struct{
	ctype = 'NMTTDISPINFOW',
	fields = sfields{
		'text', 'lpszText', wcs, mbs,
		'flags', 'uFlags', flags, pass,
		'flagbits', 'uFlags', set_nmt_flags, get_nmt_flags,
	},
}

function NM.TTN_GETDISPINFO(hdr, wParam)
	return ffi.cast('NMTTDISPINFOW*', hdr)
end
