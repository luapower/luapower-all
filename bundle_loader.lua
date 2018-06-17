
-- bundle loader module: runs when a bundled executable starts.
-- also runs when a new luastate is created (see bundle_luastate).
-- returns a "main" function which is called with the args from cmdline.
-- Written by Cosmin Apreutesei. Public domain.

local ffi = require'ffi'

return function(...)

	--portable way to get exe's directory, based on arg[0].
	--the resulted directory is relative to the current directory.
	local dir = arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
	dir = dir == '' and '.' or dir

	--set package paths relative to the exe dir.
	--NOTE: this only works as long as the current dir doesn't change,
	--but unlike the '!' symbol in package paths, it's portable.
	local slash = package.config:sub(1,1)
	package.path = string.format('%s/?.lua;%s/?/init.lua', dir, dir):gsub('/', slash)
	local ext = ffi.os == 'Windows' and 'dll' or 'so'
	package.cpath = string.format('%s/clib/?.%s', dir, ext):gsub('/', slash)

	local rel_path
	if ffi.os == 'Windows' then
		function rel_path(s)
			return not s:find'^[A-Z]%:' and not s:find'^[\\/]'
		end
	else
		function rel_path(s)
			return not s:find'^/'
		end
	end

	local function in_exe_dir(name)
		if rel_path(name) then
			local filename = name:find('%.'..ext..'$') and name or name..'.'..ext
			local filepath = dir..'/'..filename
			local f = io.open(filepath, 'rb')
			if f then
				f:close()
				return true
			end
		end
		return false
	end

	local libs_str = require'bundle_libs'
	local libs = {}
	for lib in libs_str:gmatch'[^%s]+' do
		libs[lib] = true
	end
	local function bundled(name)
		return libs[name] or false
	end

	--overload ffi.load to fallback to ffi.C for bundled libs.
	local ffi_load = ffi.load
	function ffi.load(name, ...)
		local ok, C = xpcall(ffi_load, debug.traceback, name, ...)
		if not ok then
			if bundled(name) then
				return ffi.C
			else
				error(C, 2)
			end
		elseif bundled(name) and not in_exe_dir(name) then
			--prevent loading bundled libs from system paths
			return ffi.C
		else
			return C
		end
	end

	--check if we have a main module, as set by bundle.c:bundle_main().
	local m = arg[-1]
	if not m then
		return true --no module specified: fallback to luajit frontend
	end

	--find a module in package.loaders, like require() does.
	local function find_module(name)
		for _, loader in ipairs(package.loaders) do
			local chunk = loader(name)
			if type(chunk) == 'function' then
				return chunk
			end
		end
	end

	--find the main module
	m = find_module(m)
	if not m then
		return true --module not found: fallback to luajit frontend
	end

	--run the main module, passing it all the command-line args.
	m(...)
end
