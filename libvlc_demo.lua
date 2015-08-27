local ffi = require'ffi'
require'libvlc_h'
local vlc = ffi.load'libvlc'
local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.panelclass'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	title = 'VLC Playback Demo',
}

local panel = winapi.Panel{
	parent = main, x = 100, y = 100, w = main.client_w - 200, h = main.client_h - 200,
	anchors = {left=true, right=true, top=true, bottom=true}
}

do
	local self = panel
	self.vlc_inst = vlc.libvlc_new(0, nil)
	self.vlc_m = vlc.libvlc_media_new_path(self.vlc_inst,
		[[x:\trash\utorrent\2 stupid dogs\1993-1994 - Season 1\103-a Hollywood's Ark [Moonsong].avi]])
	self.vlc_mp = vlc.libvlc_media_player_new_from_media(self.vlc_m)
	vlc.libvlc_media_release(self.vlc_m)
	vlc.libvlc_media_player_set_hwnd(self.vlc_mp, self.hwnd)
	vlc.libvlc_media_player_play(self.vlc_mp)
end

function panel:on_close()
	vlc.libvlc_media_player_stop(self.vlc_mp)
	vlc.libvlc_media_player_release(self.vlc_mp)
	vlc.libvlc_release(self.vlc_inst)
end

main:show()
winapi.MessageLoop()
