
--GLX binding.
--Written by Cosmin Apreutesei. Public Domain.

require'glx_h'
local ffi = require'ffi'
local C = ffi.abi'64bit' and ffi.load'libGL.so.1' or ffi.load'libGL.so'
local M = {C = C}

function M.connect(xlib)

	local M = {C = C}

	local display = xlib.display
	local screen_num = xlib.screen_number

	--XFBConfigs --------------------------------------------------------------

	local function fbiter(fbconfigs, n)
		local i = -1
		return function()
			i = i + 1
			if i >= n then return end
			return fbconfigs[i]
		end
	end

	function M.get_fbconfigs()
		local nbuf = ffi.new'int[1]'
		local fbconfigs = C.glXGetFBConfigs(display, screen_num, nbuf)
		return fbiter(fbconfigs, nbuf[0])
	end

	function M.choose_fbconfigs(...)
		local n = select('#', ...)
		local visdata = ffi.new('int[?]', n+1) --null-terminated
		for i=1,n do
			visdata[i-1] = select(i,...)
		end
		local nbuf = ffi.new'int[1]'
		local fbconfigs = C.glXChooseFBConfig(display, screen_num, visdata, nbuf)
		return fbiter(fbconfigs, nbuf[0])
	end

	function M.choose_rgb_fbconfigs()
		return M.choose_fbconfigs(
			C.GLX_DRAWABLE_TYPE, C.GLX_WINDOW_BIT,
			C.GLX_DOUBLEBUFFER, 1, --avoid horrible flicker
			C.GLX_BUFFER_SIZE, 24,
			C.GLX_RED_SIZE, 8,
			C.GLX_GREEN_SIZE, 8,
			C.GLX_BLUE_SIZE, 8,
			C.GLX_DEPTH_SIZE, 16,
			0)
	end

	function M.choose_rgba_fbconfigs()
		return M.choose_fbconfigs(
			C.GLX_RENDER_TYPE, C.GLX_RGBA_BIT,
			C.GLX_DRAWABLE_TYPE, C.GLX_WINDOW_BIT,
			C.GLX_DOUBLEBUFFER, 1,  --avoid horrible flicker
			C.GLX_BUFFER_SIZE, 32,
			C.GLX_RED_SIZE, 8,
			C.GLX_GREEN_SIZE, 8,
			C.GLX_BLUE_SIZE, 8,
			C.GLX_ALPHA_SIZE, 8,
			C.GLX_DEPTH_SIZE, 16,
			0)
	end

	local valbuf = ffi.new'int[1]'
	function M.get_fbconfig_attr(fbconfig, attr)
		if C.glXGetFBConfigAttrib(display, fbconfig, attr, valbuf) == 0 then
			return valbuf[0]
		end
	end

	function M.get_fbconfig_attrs(fbconfig)
		local t = {}
		for s in pairs{
			GLX_DOUBLEBUFFER=1,
			GLX_RENDER_TYPE=1,
			GLX_BUFFER_SIZE=1,
			GLX_RED_SIZE=1,
			GLX_GREEN_SIZE=1,
			GLX_BLUE_SIZE=1,
			GLX_ALPHA_SIZE=1,
			GLX_DEPTH_SIZE=1,
		} do
			t[s] = M.get_fbconfig_attr(fbconfig, C[s])
		end
		return t
	end

	function M.get_visual_of_fbconfig(fbconfig)
		return M.get_fbconfig_attr(fbconfig, C.GLX_VISUAL_ID)
	end

	function M.get_fbconfig_of_visual(visual)
		for fbconfig in M.get_fbconfigs() do
			if M.get_visual_of_fbconfig(fbconfig) == visual then
				return fbconfig
			end
		end
	end

	--GLX contexts ------------------------------------------------------------

	function M.create_context(fbconfig, share_list, direct)
		if direct == nil then direct = true end --default is direct rendering
		return C.glXCreateNewContext(display, fbconfig, C.GLX_RGBA_TYPE, share_list, direct)
	end

	function M.destroy_context(context)
		C.glXDestroyContext(display, context)
	end

	function M.make_current(window, context)
		assert(C.glXMakeCurrent(display, window, context) == 1)
	end

	function M.swap_buffers(window)
		C.glXSwapBuffers(display, window)
	end

	return M
end

return M
