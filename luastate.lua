
--Lua C API binding, including LuaJIT2 extensions.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'luastate_test'; return end

require'luajit_h'
local ffi = require'ffi'
local C = ffi.C
local M = {C = C}
local cast = ffi.cast

local function not_implemented()
	error('Not implemented', 3)
end

--states

function M.open()
	local L = C.luaL_newstate()
	assert(L ~= nil, 'out of memory')
	ffi.gc(L, M.close)
	return L
end

function M.close(L)
	ffi.gc(L, nil)
	C.lua_close(L)
end

M.status = C.lua_status --0, error or LUA_YIELD

M.newthread = C.lua_newthread

--compiler

local function check(L, ret)
	if ret == 0 then return true end
	return false, M.tostring(L, -1)
end
M.check = check

function M.loadbuffer(L, buf, sz, chunkname)
	return check(L, C.luaL_loadbuffer(L, buf, sz, chunkname))
end

function M.loadstring(L, s, name)
	return M.loadbuffer(L, s, #s, name)
end

function M.loadfile(L, filename)
	return check(L, C.luaL_loadfile(L, filename))
end

function M.load(L, reader, data, chunkname)
	local reader_cb
	if type(reader) == 'function' then
		reader_cb = cast('lua_Reader', reader)
	end
	local ret = C.lua_load(L, reader_cb or reader, data, chunkname)
	if reader_cb then reader_cb:free() end
	return check(L, ret)
end

local lib_openers = {
	base = C.luaopen_base,
	table = C.luaopen_table,
	io = C.luaopen_io,
	os = C.luaopen_os,
	string = C.luaopen_string,
	math = C.luaopen_math,
	debug = C.luaopen_debug,
	package = C.luaopen_package,
	--luajit extensions
	bit = C.luaopen_bit,
	ffi = C.luaopen_ffi,
	jit = C.luaopen_jit,
}

function M.openlibs(L, ...) --open specific libs (or all libs if no args given)
	local n = select('#', ...)
	if n == 0 then
		C.luaL_openlibs(L)
	else
		for i=1,n do
			C.lua_pushcclosure(L, assert(lib_openers[select(i,...)]), 0)
			C.lua_call(L, 0, 0)
		end
	end
	return L
end

function M.dump(L, write)
	if not write then
		local t = {}
		function write(L, buf, sz, data)
			t[#t+1] = ffi.string(buf, sz)
			return 0 --no error
		end
		C.lua_dump(L, write, nil)
		return table.concat(t)
	else
		return C.lua_dump(L, write, data)
	end
end

--stack (indices)

function M.abs_index(L, i)
	return (i > 0 or i <= C.LUA_REGISTRYINDEX) and i or C.lua_gettop(L) + i + 1
end

M.gettop = C.lua_gettop
M.settop = C.lua_settop

function M.pop(L, n)
	C.lua_settop(L, -(n or 1) - 1)
end

function M.checkstack(L, n)
	assert(C.lua_checkstack(L, n) ~= 0, 'stack overflow')
end

--stack (read)

local lua_types = {
	[C.LUA_TNIL] = 'nil',
	[C.LUA_TBOOLEAN] = 'boolean',
	[C.LUA_TLIGHTUSERDATA] = 'lightuserdata',
	[C.LUA_TNUMBER] = 'number',
	[C.LUA_TSTRING] = 'string',
	[C.LUA_TTABLE] = 'table',
	[C.LUA_TFUNCTION] = 'function',
	[C.LUA_TUSERDATA] = 'userdata',
	[C.LUA_TTHREAD] = 'thread',
	[C.LUA_TCDATA] = 'cdata',
}

function M.type(L, index)
	local t = C.lua_type(L, index)
	assert(t ~= C.LUA_TNONE)
	return lua_types[t]
end

M.objlen = C.lua_objlen
M.strlen = C.lua_objlen

M.isnumber = C.lua_isnumber
M.isstring = C.lua_isstring
M.iscfunction = C.lua_iscfunction
M.isuserdata = C.lua_isuserdata
function M.isfunction(L, i) return C.lua_type(L, i) == C.LUA_TFUNCTION end
function M.istable(L, i) return C.lua_type(L, i) == C.LUA_TTABLE end
function M.islightuserdata(L, i) return C.lua_type(L, i) == C.LUA_TLIGHTUSERDATA end
function M.isnil(L, i) return C.lua_type(L, i) == C.LUA_TNIL end
function M.isboolean(L, i) return C.lua_type(L, i) == C.LUA_TBOOLEAN end
function M.isthread(L, i) return C.lua_type(L, i) == C.LUA_TTHREAD end
function M.isnone(L, i) return C.lua_type(L, i) == C.LUA_TNONE end
function M.isnoneornil(L, i) return C.lua_type(L, i) <= 0 end

function M.toboolean(L, index)
	return C.lua_toboolean(L, index) == 1
end

M.tonumber = C.lua_tonumber
M.tointeger = C.lua_tointeger
M.tothread = C.lua_tothread
M.touserdata = C.lua_touserdata
M.topointer = C.lua_topointer

local sz
function M.tolstring(L, index)
	sz = sz or ffi.new('size_t[1]')
	return C.lua_tolstring(L, index, sz), sz[0]
end

function M.tostring(L, index)
	return ffi.string(M.tolstring(L, index))
end

function M.next(L, index)
	return C.lua_next(L, index) ~= 0
end

M.gettable = C.lua_gettable
M.getfield = C.lua_getfield
M.rawget = C.lua_rawget
M.rawgeti = C.lua_rawgeti
M.getmetatable = C.lua_getmetatable

function M.get(L, index, opt)
	local copy_upvalues = opt and opt:find('u', 1, true)
	index = index or -1
	local t = M.type(L, index)
	if t == 'nil' then
		return nil
	elseif t == 'boolean' then
		return M.toboolean(L, index)
	elseif t == 'number' then
		return M.tonumber(L, index)
	elseif t == 'string' then
		return M.tostring(L, index)
	elseif t == 'function' then
		local top = M.gettop(L)
		index = M.abs_index(L, index)
		local s
		if false then
			--old method of dumping a function.
			--requires calling C.luaopen_string(L) before use.
			M.checkstack(L, 4)
			M.getglobal(L, 'string')
			M.getfield(L, -1, 'dump')
			M.pushvalue(L, index)
			C.lua_call(L, 1, 1)
			s = M.get(L) --result of string.dump()
			M.pop(L, 2)
		else
			s = M.dump(L)
		end
		assert(M.gettop(L) == top)
		local f = assert(loadstring(s))
		if copy_upvalues then
			local i = 1
			while true do
				if M.getupvalue(L, index, i) == nil then
					break
				end
				debug.setupvalue(f, i, M.get(L, -1, opt))
				M.pop(L)
				i = i + 1
			end
		end
		return f
	elseif t == 'table' then
		--NOTE: doesn't check duplicate refs
		--NOTE: stack-bound on table depth
		local top = M.gettop(L)
		M.checkstack(L, 2)
		local dt = {}
		index = M.abs_index(L, index)
		C.lua_pushnil(L) -- first key
		while C.lua_next(L, index) ~= 0 do
			local k = M.get(L, -2, opt)
			local v = M.get(L, -1, opt)
			dt[k] = v
			M.pop(L) -- remove 'value'; keep 'key' for next iteration
		end
		assert(M.gettop(L) == top)
		return dt
	elseif t == 'lightuserdata' or t == 'userdata' then
		--NOTE: there's no Lua API to create a (light)userdata, that can
		--only be done in a Lua/C module; best we can do is to get
		--it out as a cdata 'void*' pointer.
		return M.touserdata(L, index)
	elseif t == 'thread' then
		--NOTE: this will get out a cdata of type 'lua_State*', not a coroutine.
		return M.tothread(L, index)
	elseif t == 'cdata' then
		--NOTE: there's no LuaJIT C API extension to get the address of a cdata.
		not_implemented()
	end
end

--stack (write)

M.pushnil = C.lua_pushnil
M.pushboolean = C.lua_pushboolean
M.pushinteger = C.lua_pushinteger
M.pushnumber = C.lua_pushnumber
M.pushcclosure = C.lua_pushcclosure
function M.lua_upvalueindex(i)
	return C.LUA_GLOBALSINDEX - i
end
function M.pushcfunction(L, f)
	C.lua_pushcclosure(L, f, 0)
end
M.pushlightuserdata = C.lua_pushlightuserdata
M.pushlstring = C.lua_pushlstring
function M.pushstring(L, s, sz)
	C.lua_pushlstring(L, s, sz or #s)
end
M.pushthread = C.lua_pushthread
M.pushvalue = C.lua_pushvalue --push stack element
M.newuserdata = C.lua_newuserdata

M.settable = C.lua_settable
M.setfield = C.lua_setfield
M.rawset = C.lua_rawset
M.rawseti = C.lua_rawseti
M.setmetatable = C.lua_setmetatable
M.createtable = C.lua_createtable
function M.newtable(L)
	C.lua_createtable(L, 0, 0)
end
M.xmove = C.lua_xmove
M.insert = C.lua_insert
M.remove = C.lua_remove
M.replace = C.lua_replace

function M.push(L, v, opt)
	local copy_upvalues = opt and opt:find('u', 1, true)
	if type(v) == 'nil' then
		M.pushnil(L)
	elseif type(v) == 'boolean' then
		M.pushboolean(L, v)
	elseif type(v) == 'number' then
		M.pushnumber(L, v)
	elseif type(v) == 'string' then
		M.pushstring(L, v)
	elseif type(v) == 'function' then
		M.loadstring(L, string.dump(v))
		if copy_upvalues then
			local i = 1
			while true do
				local uname, uv = debug.getupvalue(v, i)
				if not uname then break end
				M.push(L, uv, opt)
				M.setupvalue(L, -2, i)
				i = i + 1
			end
		end
	elseif type(v) == 'table' then
		--NOTE: doesn't check duplicate refs
		--NOTE: doesn't check for cycles
		--NOTE: stack-bound on table depth
		M.checkstack(L, 3)
		M.newtable(L)
		local top = M.gettop(L)
		for k,v in pairs(v) do
			M.push(L, k, opt)
			M.push(L, v, opt)
			M.settable(L, top)
		end
		assert(M.gettop(L) == top)
	elseif type(v) == 'userdata' then
		--NOTE: there's no Lua API to get the size or lightness of a userdata,
		--so we don't have enough info to duplicate a userdata automatically.
		not_implemented()
	elseif type(v) == 'thread' then
		--NOTE: there's no Lua API to get the 'lua_State*' of a coroutine.
		not_implemented()
	elseif type(v) == 'cdata' then
		--NOTE: there's no Lua C API to push a cdata.
		--cdata are not shareable anyway because ctypes are not shareable.
		not_implemented()
	end
end

--stack (compare)

function M.equal(i1, i2)    return C.lua_equal(i1, i2) == 1 end
function M.rawequal(i1, i2) return C.lua_rawequal(i1, i2) == 1 end
function M.lessthan(i1, i2) return C.lua_lessthan(i1, i2) == 1 end

--debug

function M.getstack(level, dbg)
	return C.lua_getstack(level, dbg) == 1
end

function M.getinfo(what, dbg)
	assert(C.lua_getinfo(what, dbg) ~= 0)
end

M.getlocal = C.lua_getlocal
M.setlocal = C.lua_setlocal
M.getupvalue = C.lua_getupvalue
M.setupvalue = C.lua_setupvalue
M.sethook = C.lua_sethook
M.gethook = C.lua_gethook
M.gethookmask = C.lua_gethookmask
M.gethookcount = C.lua_gethookcount

--interpreter

--push multiple values
function M.pushvalues_opt(L, opt, ...)
	local argc = select('#', ...)
	for i = 1, argc do
		local v = select(i, ...)
		M.push(L, v, opt)
	end
	return argc
end

function M.pushvalues(L, ...)
	return M.pushvalues_opt(L, nil, ...)
end

--pop multiple values and return them
function M.popvalues_opt(L, opt, top_before_call)
	local n = M.gettop(L) - top_before_call + 1
	if n == 0 then
		return
	elseif n == 1 then
		local ret = M.get(L, -1, opt)
		M.pop(L)
		return ret
	else
		--collect/pop/unpack return values
		local t = {}
		for i = 1, n do
			t[i] = M.get(L, i - n - 1, opt)
		end
		M.pop(L, n)
		return unpack(t, 1, n)
	end
end

function M.popvalues(L, ...)
	return M.popvalues_opt(L, nil, ...)
end

--call the function at the top of the stack,
--wrapping the passing of args and the returning of return values.
--errfunc is an optional index where a debug.stacktrace-like function is.
function M.xpcall_opt(L, opt, errfunc, ...)
	local errfunc = errfunc and errfunc ~= 0 and M.abs_index(L, errfunc) or 0
	local top = M.gettop(L)
	local argc = M.pushvalues_opt(L, opt, ...)
	local ok, err = check(L, C.lua_pcall(L, argc, C.LUA_MULTRET, errfunc))
	if not ok then
		return false, err
	end
	return true, M.popvalues_opt(L, opt, top)
end

function M.xpcall(L, errfunc, ...)
	return M.xpcall_opt(L, nil, errfunc, ...)
end

function M.pcall_opt(L, opt, ...)
	return M.xpcall_opt(L, opt, nil, ...)
end

function M.pcall(L, ...)
	return M.pcall_opt(L, nil, ...)
end

local function pass(ok, ...)
	if not ok then error(..., 2) end
	return ...
end

function M.call_opt(L, opt, ...)
	return pass(M.pcall_opt(L, opt, ...))
end

function M.call(L, ...)
	return M.call_opt(L, nil, ...)
end

--resume the coroutine at the top of the stack,
--wrapping the passing of args and the returning of yielded values.
function M.resume_opt(L, opt, ...)
	local top = M.gettop(L)
	local argc = M.pushvalues_opt(L, opt, ...)
	local ret = C.lua_resume(L, argc)
	local ok = ret == 0 or ret == C.LUA_YIELD
	return ok, M.popvalues_opt(L, opt, top)
end

function M.resume(L, ...)
	return M.resume_opt(L, nil, ...)
end

--gc

M.gc = C.lua_gc

function M.getgccount(L)
	return C.lua_gc(L, C.LUA_GCCOUNT, 0)
end

--macros from lua.h

function M.upvalueindex(i)
	return C.LUA_GLOBALSINDEX - i
end

function M.register(L, n, f)
	C.lua_pushcfunction(L, f)
	C.lua_setglobal(L, n)
end

function M.getglobal(L, s)
	C.lua_getfield(L, C.LUA_GLOBALSINDEX, s)
end

function M.setglobal(L, s)
	C.lua_setfield(L, C.LUA_GLOBALSINDEX, s)
end

function M.getregistry(L)
	C.lua_pushvalue(L, C.LUA_REGISTRYINDEX)
end

function M.dofile(L, filename, opt, ...)
	local ok, err = M.loadfile(L, filename)
	if ok then
		return M.pcall(L, opt, ...)
	else
		return false, err
	end
end

function M.dostring(L, s, opt, ...)
	local ok, err = M.loadstring(L, s)
	if ok then
		return M.pcall(L, opt, ...)
	else
		return false, err
	end
end

--object interface

ffi.metatype('lua_State', {__index = {
	check = M.check,
	--states
	close = M.close,
	status = M.status,
	newthread = M.newthread,
	resume_opt = M.resume_opt,
	resume = M.resume,
	--compiler
	openlibs = M.openlibs,
	loadbuffer = M.loadbuffer,
	loadstring = M.loadstring,
	loadfile = M.loadfile,
	load = M.load,
	dofile = M.dofile,
	dostring = M.dostring,
	dump = M.dump,
	--stack / indices
	abs_index = M.abs_index,
	gettop = M.gettop,
	settop = M.settop,
	pop = M.pop,
	checkstack = M.checkstack,
	xmove = M.xmove,
	insert = M.insert,
	remove = M.remove,
	replace = M.replace,
	--stack / read
	type = M.type,
	objlen = M.objlen,
	strlen = M.strlen,
	isnumber = M.isnumber,
	isstring = M.isstring,
	iscfunction = M.iscfunction,
	isuserdata = M.isuserdata,
	isfunction = M.isfunction,
	istable = M.istable,
	islightuserdata = M.islightuserdata,
	isnil = M.isnil,
	isboolean = M.isboolean,
	isthread = M.isthread,
	isnone = M.isnone,
	isnoneornil = M.isnoneornil,
	toboolean = M.toboolean,
	tonumber = M.tonumber,
	tointeger = M.tointeger,
	tolstring = M.tolstring,
	tostring = M.tostring,
	tothread = M.tothread,
	touserdata = M.touserdata,
	topointer = M.topointer,
	--stack / read / tables
	next = M.next,
	gettable = M.gettable,
	getfield = M.getfield,
	rawget = M.rawget,
	rawgeti = M.rawgeti,
	getmetatable = M.getmetatable,
	--stack / get / synthesis
	get = M.get,
	--stack / write
	pushnil = M.pushnil,
	pushboolean = M.pushboolean,
	pushinteger = M.pushinteger,
	pushcclosure = M.pushcclosure,
	pushcfunction = M.pushcfunction,
	pushlightuserdata = M.pushlightuserdata,
	pushlstring = M.pushlstring,
	pushstring = M.pushstring,
	pushthread = M.pushthread,
	pushvalue = M.pushvalue,
	--stack / write / tables
	createtable = M.createtable,
	newtable = M.newtable,
	settable = M.settable,
	setfield = M.setfield,
	rawset = M.rawset,
	rawseti = M.rawseti,
	setmetatable = M.setmetatable,
	--stack / write / synthesis
	push = M.push,
	--stack / compare
	equal = M.equal,
	rawequal = M.rawequal,
	lessthan = M.lessthan,
	--interpreter
	pushvalues_opt = M.pushvalues_opt,
	popvalues_opt = M.popvalues_opt,
	pushvalues = M.pushvalues,
	popvalues = M.popvalues,
	xpcall_opt = M.xpcall_opt,
	pcall_opt = M.pcall_opt,
	call_opt = M.call_opt,
	xpcall = M.xpcall,
	pcall = M.pcall,
	call = M.call,
	lua_pcall = C.lua_pcall,
	lua_call = C.lua_call,
	--gc
	gc = M.gc,
	getgccount = M.getgccount,
	--macros
	upvalueindex = M.upvalueindex,
	register = M.register,
	setglobal = M.setglobal,
	getglobal = M.getglobal,
	getregistry = M.getregistry,
}})


return M
