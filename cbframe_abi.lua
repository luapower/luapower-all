--NOTE: this is work-in-progress.
local cbframe = require'cbframe'
local reflect = require'ffi_reflect'
local ffi = require'ffi'
local pp = require'pp'

local function isstruct(rct)
	return rct.type and (rct.type.what == 'struct' or rct.type.what == 'union')
end

local function needs_wrapping(rct)
	do return true end
	for rct in rct.element_type:arguments() do
		if isstruct(rct) then return true end
	end
	return isstruct(rct.element_type.return_type)
end

local _ = string.format

local function expr_wrapper(expr, func)
	local code = _([[
		local ffi = require'ffi'
		local func = ...
		return function(cpu)
			%s
			local ret = func(%s)
			%s
		end]], table.concat(expr.header, '\n\t\t\t'), table.concat(expr, ', '), expr.ret or '')
	print(code)
	local chunk = assert(loadstring(code, '=expr'))
	return chunk(func)
end

--32bit cdecl (win/linux/osx)
--
local function wrap_cdecl_win(rct, func)
	local header = {}
	local expr = {header = header}
	local i = 1
	local argi = 1
	for rct in rct.element_type:arguments() do
		pp(rct)
		local s, h
		if rct.type.bool then
			s = _('cpu.ESP.dp[%d].i ~= 0', i)
			i = i + 1
		elseif rct.type.char then
			s = _('cpu.ESP.dp[%d].i', i)
			i = i + 1
		elseif rct.type.what == 'struct' or rct.type.what == 'union' then
			local sname = _('%s %s', rct.type.what, rct.type.name)
			h = _("local arg%d = ffi.new('%s', ffi.cast('%s&', %s))", argi, sname, sname, _('cpu.ESP.dp + %d', i))
			s = _('arg%d', argi)
			i = i + bit.rshift(ffi.sizeof(sname) + 3, 2)
		end
		header[#header+1] = h
		expr[#expr+1] = s
		argi = argi + 1
	end
	local rt = rct.element_type.return_type
	if rt.type and rt.type.bool then
		expr.ret = 'cpu.EAX.s = ret and 1 or 0'
	--elseif rt.type.char then
	--	expr.ret = 'cpu.EAX.s = ret'
	end
	return expr_wrapper(expr, func)
end

local function wrap_cdecl_gcc(rct, func)
	error'NYI'
end

local function wrap_stdcall_win(rct, func)
	error'NYI'
end

local function wrap_stdcall_gcc(rct, func)
	error'NYI'
end

local function wrap_x64_win(rct, func)
	error'NYI'
	local args = {}
	for rct in rct.element_type:arguments() do
		args[#args+1] = 0
	end
	return function(cpu)
		for i = 1, #args do
			--args[i] =
		end
		local ret = func(unpack(args))
	end
end

local function wrap_x64_linux(rct, func)
	error'NYI'
end

local function wrap_x64_osx(rct, func)
	error'NYI'
end

local wrapper = {
	x86 = {
		Windows = {cdecl = wrap_cdecl_win, stdcall = wrap_stdcall_win},
		Linux = {cdecl = wrap_cdecl_gcc, stdcall = wrap_stdcall_gcc},
		OSX = {cdecl = wrap_cdecl_gcc, stdcall = wrap_stdcall_gcc},
	},
	x64 = {
		Windows = {cdecl = wrap_x64_win},
		Linux = {cdecl = wrap_x64_linux},
		OSX = {cdecl = wrap_x64_osx},
	},
}

function cbframe.cast(ct, func, ...)
	local rct = reflect.typeof(ct)
	if not (rct.what == 'ptr' and rct.element_type.what == 'func' and needs_wrapping(rct)) then
		return ffi.cast(ct, func, ...)
	end
	local wrap = wrapper[ffi.arch]
	wrap = wrap and wrap[ffi.os]
	wrap = wrap and wrap[rct.element_type.convention]
	assert(wrap, 'platform not supported')
	return cbframe.new(wrap(rct, func))
end


if not ... then require'cbframe_abi_test' end
