
--bundle extension for luastate.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local luastate = require'luastate'

local M = {}

ffi.cdef'void bundle_add_loaders(lua_State* L);'

local function bundle_add_loaders(state)
	ffi.C.bundle_add_loaders(state)
end

--call this after initializing the Lua state in order to patch `require`
--and `ffi.load` inside the state just as the main exe was doing on init.
function M.init_bundle(state)
	local ok, err = pcall(bundle_add_loaders, state)
	if not ok then return end --not running a bundled luajit exe
	local top = state:gettop()
	state:push{[0] = arg[0]} --used to make `glue.bin`
	state:setglobal'arg'
	state:loadstring"return require'bundle_loader'()"
	local ok, ret = state:pcall()
	assert(state:gettop() == top)
	assert(ok)   --call didn't fail
	assert(ret)  --returned true as in "return to luajt"
end

return M
