
--Process & IPC API for Windows & POSIX.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'proc_test'; return end

local ffi = require'ffi'
local current_platform = ffi.os == 'Windows' and 'win' or 'posix'
local M = require('proc_'..current_platform)

local function extend(dt, t)
	if not t then return dt end
	local j = #dt
	for i=1,#t do dt[j+i]=t[i] end
end

function M.esc(s, platform)
	platform = platform or current_platform
	local esc =
		   platform == 'win'  and M.esc_win
		or platform == 'unix' and M.esc_unix
	assert(esc, 'invalid platform')
	return esc(s)
end

function M.quote_arg(s, platform)
	platform = platform or current_platform
	local quote_arg =
		   platform == 'win'  and M.quote_arg_win
		or platform == 'unix' and M.quote_arg_unix
	assert(quote_arg, 'invalid platform')
	return quote_arg(s)
end

--cmd|{cmd,arg1,...}, env, ...
--{cmd=cmd|{cmd,arg1,...}, env=, ...}
local exec = M.exec
function M.exec(t, ...)
	if type(t) == 'table' then
		return exec(t.cmd, t.env, t.dir, t.stdin, t.stdout, t.stderr,
			t.autokill, t.async, t.inherit_handles)
	else
		return exec(t, ...)
	end
end

--script|{script,arg1,...}, env, ...
--{script=, env=, ...}
function M.exec_luafile(arg, ...)
	local exepath = require'package.exepath'
	local script = type(arg) == 'string' and arg or arg.script
	local cmd = type(script) == 'string' and {exepath, script} or extend({exepath}, script)
	if type(arg) == 'string' then
		return M.exec(cmd, ...)
	else
		local t = {cmd = cmd}
		for k,v in pairs(arg) do
			if k ~= 'script' then
				t[k] = v
			end
		end
		return M.exec(t)
	end
end

return M
