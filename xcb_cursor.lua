
--xcb/util-cursor binding (for loading themed cursors).
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'xcb_h'

--xcb_cursor.h
ffi.cdef[[
typedef struct xcb_cursor_context_t xcb_cursor_context_t;
int xcb_cursor_context_new(xcb_connection_t *conn, xcb_screen_t *screen, xcb_cursor_context_t **ctx);
xcb_cursor_t xcb_cursor_load_cursor(xcb_cursor_context_t *ctx, const char *name);
void xcb_cursor_context_free(xcb_cursor_context_t *ctx);
]]

local C = ffi.load'xcb-cursor'
local M = {C = C}
local ctx = {} --context methods

function M.context(c, screen)
	local ctx = ffi.new'xcb_cursor_context_t*[1]'
	if C.xcb_cursor_context_new(c, screen, ctx) < 0 then return end
	return ctx[0]
end

function ctx.free(ctx)
	C.xcb_cursor_context_free(ctx)
end

function ctx.load_direct(ctx, name)
	local cursor = C.xcb_cursor_load_cursor(ctx, name)
	if cursor == C.XCB_CURSOR_NONE then
		cursor = nil
	end
	return cursor
end

--source: http://lists.x.org/archives/xorg/2015-July/057498.html
--tested with: ubuntu 10, ubuntu 10/compiz, ubuntu 14.
M.cursors  = {
	--nw standard
	arrow       = {'left_ptr', 'arrow', 'dnd-none', 'op_left_arrow'},
	text        = {'ibeam', 'xterm', 'text'},
	hand        = {'pointing_hand', 'hand2', 'hand', 'hand1', 'pointer', 'e29285e634086352946a0e7090d73106', '9d800788f1b08800ae810202380a0822'},
 	cross       = {'cross', 'diamond-cross', 'cross-reverse', 'crosshair'},
	forbidden   = {'forbidden', 'circle', 'dnd-no-drop', 'not-allowed', '03b6e0fcb3499374a867c041f52298f0'},
	size_diag1  = {'size_bdiag', 'fd_double_arrow', 'bottom_left_corner', 'top_right_corner', 'fcf1c3c7cd4491d801f1e1c78f100000'},
	size_diag2  = {'size_fdiag', 'bd_double_arrow', 'bottom_right_corner', 'top_left_corner', 'c7088f0f3e6c8088236ef8e1e3e70000'},
	size_v      = {'size_ver', 'sb_v_double_arrow', 'v_double_arrow', 'n-resize', 's-resize', 'col-resize', 'top_side', 'bottom_side', 'base_arrow_up', 'base_arrow_down', 'based_arrow_down', 'based_arrow_up', '00008160000006810000408080010102'},
	size_h      = {'size_hor', 'sb_h_double_arrow', 'h_double_arrow', 'e-resize', 'w-resize', 'row-resize', 'right_side', 'left_side', '028006030e0e7ebffc7f7070c0600140'},
	move        = {'fleur', 'size_all'},
	busy_arrow  = {'left_ptr_watch', 'half-busy', '3ecb610c1bf2410f44200f48c40d3599', '00000000000000020006000e7e9ffc3f', '08e8e1c95fe2fc01f976f1e063a24ccd'},
	--extra
	up_arrow    = {'sb_up_arrow', 'centre_ptr', 'up_arrow', 'center_ptr'},
	wait        = {'wait', 'watch', 'progress'},
	help_arrow  = {'whats_this', 'left_ptr_help', 'help', 'question_arrow', 'dnd-ask', 'd9ce0ab605698f320427677b458ad60b', '5c6cd98b3f3ebcb1f9c7f1c204630408'},
	split_h     = {'split_h', '14fef782d02440884392942c11205230', 'size_hor'},
	split_v     = {'split_v', '2870a09082c103050810ffdffffe0204', 'size_ver'},
	hand_link   = {'dnd-link', 'link', 'alias', '3085a0e285430894940527032f8b26df', '640fb0e74195791501fd1ed57b41487f', 'a2a266d0498c3104214a47bd64ab0fc8'},
	hand_copy   = {'dnd-copy', 'copy', '1081e37283d90000800003c07f3ef6bf', '6407b0e94181790501fd1e167b474872', 'b66166c04f8c3109214a4fbd64a50fc8'},
	hand_move   = {'dnd-move', 'move'},
}

function ctx.load(ctx, name)
	local t = M.cursors[name]
	if t then
		for i,name in ipairs(t) do
			local cursor = ctx:load_direct(name)
			if cursor then
				return cursor
			end
		end
	else
		return ctx:load_direct(name)
	end
end

ffi.metatype('xcb_cursor_context_t', {__index = ctx})

return M
