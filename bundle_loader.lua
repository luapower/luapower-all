
-- bundle loader module: runs when a bundled executable starts.
-- returns a "main" function which is called with the args from cmdline.
-- Written by Cosmin Apreutesei. Public domain.

local ffi = require'ffi'

return function(...)

	--overload ffi.load to fallback to ffi.C when the lib is not found,
	--so that statically linked symbols can be used instead.
	local ffi_load = ffi.load
	function ffi.load(...)
		local ok, C = pcall(ffi_load, ...)
		if not ok then
			return ffi.C
		else
			return C
		end
	end

	--portable way to get exe's directory, based on arg[0].
	--the resulted directory is relative to the current directory.
	local dir = arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
	dir = dir == '' and '.' or dir

	--set package paths relative to the exe dir.
	--NOTE: this only works as long as the current dir doesn't change,
	--but unlike the '!' symbol in package paths, it's portable.
	local slash = package.config:sub(1,1)
	package.path = string.format('%s/?.lua;%s/?/init.lua', dir, dir):gsub('/', slash)
	package.cpath = string.format('%s/clib/?.dll', dir):gsub('/', slash)

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
