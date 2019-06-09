
--terralib luapower extensions.

local ffi = require'ffi'
local List = require'asdl'.List

local bindir = terralib.terrahome

terralib.clangresourcedirectory = ('%s/../../csrc/clang-resource-dir'):format(bindir)

--reset include paths (terralib looks for Visual Studio ones by default).
terra.systemincludes = List()

--using mingw64 headers from `mingw64-headers` package.
if ffi.os == 'Windows' then
	terra.systemincludes:insertall {
		'-internal-isystem',
		('%s/../../csrc/mingw64-headers/mingw64/include'):format(bindir),
		'-internal-isystem',
		('%s/../../csrc/mingw64-headers/mingw64/include-fixed'):format(bindir),
		'-internal-isystem',
		('%s/../../csrc/mingw64-headers/mingw32'):format(bindir),
	}
end

--load Terra files from the same locations as Lua files.
package.terrapath = package.path:gsub('%.lua', '%.t')

--overload loadfile() to interpret *.t files as Terra code.
local lua_loadfile = loadfile
_G.loadfile = function(file)
	local loadfile = file:find'%.t$' and terra.loadfile or lua_loadfile
	return loadfile(file)
end
