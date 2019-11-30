
--oo/controls/trackbar: trackbar control
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.trackbar'
require'winapi.controlclass'

Trackbar = {
	__style_bitmask = bitmask{
		--
	},
	__defaults = {
		w = 100, h = 24,
	},
	__init_properties = {
		--
	},
}

subclass(Trackbar, Control)

function Trackbar:after___before_create(info, args)
	args.class = TRACKBAR_CLASS
end

