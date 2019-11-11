
--terralib luapower extensions.

assert(terra, 'terra not loaded')

local ffi = require'ffi'
local List = require'asdl'.List

--$ mgit clone mingw64-headers
local mingw64_headers_dir = terralib.terrahome..'/../../csrc/mingw64-headers'

terralib.clangresourcedirectory = clang_resource_dir

if ffi.os == 'Windows' then
	--Terra looks for Visual Studio headers by default but we use mingw64.
	terra.systemincludes = List()
	terra.systemincludes:insertall {
		('%s/mingw64/include'):format(mingw64_headers_dir),
		('%s/mingw64/include-fixed'):format(mingw64_headers_dir),
		('%s/mingw32'):format(mingw64_headers_dir),
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
