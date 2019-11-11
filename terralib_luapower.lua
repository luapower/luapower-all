
--terralib luapower extensions.

assert(terra, 'terra not loaded')

local ffi = require'ffi'
local List = require'asdl'.List

--TODO: expose '!' to Lua as package.exedir.
terralib.terrahome = package.path
	:gsub('^.[\\/].-;', '')
	:match'(.-)[\\/]lua[\\/]%?%.lua'

--$ mgit clone mingw64-headers
local mingw64_headers_dir = '../../csrc/mingw64-headers'

if ffi.os == 'Windows' then
	--Terra looks for Visual Studio headers by default but we use mingw64.
	terra.systemincludes = List()
	terra.systemincludes:insertall {
		('%s/mingw64/include'):format(mingw64_headers_dir),
		('%s/mingw64/include-fixed'):format(mingw64_headers_dir),
		('%s/mingw32'):format(mingw64_headers_dir),
	}
elseif ffi.os == 'Linux' then
	terra.systemincludes = List()
	terra.systemincludes:insertall {
		 '/usr/lib/gcc/x86_64-linux-gnu/7/include',
		 '/usr/local/include',
		 '/usr/lib/gcc/x86_64-linux-gnu/7/include-fixed',
		 '/usr/include/x86_64-linux-gnu',
		 '/usr/include',
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
