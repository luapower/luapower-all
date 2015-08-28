--oo/controls/static: standard label control
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')
require'winapi.controlclass'
require'winapi.static'

Static = subclass({
	__style_bitmask = bitmask{
	},
	__style_ex_bitmask = bitmask{
	},
	__default_style = {
	},
	__defaults = {
		text = 'Text',
		w = 100, h = 21,
	},
	__init_properties = {},
	__wm_command_handler_names = index{
	},
}, Control)

function Static:__before_create(info, args)
	Static.__index.__before_create(self, info, args)
	args.text = info.text
	args.class = WC_STATIC
end

--showcase

if not ... then
	require'winapi.showcase'
	local window = ShowcaseWindow{w=300,h=200}
	local s1 = Static{parent = window, x = 10, y = 10, w = 100, h = 60, text = 'Hi there my sweet lemon drops!'}
	MessageLoop()
end

